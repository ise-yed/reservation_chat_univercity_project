import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../constants/app_constants.dart';
import '../constants/app_setting.dart';
import 'app_error.dart';
import 'network_connection.dart';

/// Public auth endpoints that must NEVER carry an Authorization header and
/// must NEVER trigger a token-refresh attempt.
/// Sending a stale/expired token to these paths causes a false 401.
const _publicAuthPaths = [
  'auth/login/',
  'auth/register/',
  'auth/refresh/',
  'auth/password/reset/',
  'auth/password/reset/request-otp/',
  'auth/password/reset/confirm/',
];

bool isPublicAuthPath(String path) =>
    _publicAuthPaths.any((p) => path.contains(p));

class ConnectivityAndErrorInterceptor extends Interceptor {
  final Connectivity _connectivity = Connectivity();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final status = await _connectivity.checkConnectivity();
    if (status == ConnectivityResult.none) {
      return handler.reject(
        DioException(
          requestOptions: options,
          error: AppException(AppErrorCode.noInternet),
          type: DioExceptionType.unknown,
        ),
      );
    }
    final online = await NetworkManager.hasInternetConnection();
    if (!online) {
      return handler.reject(
        DioException(
          requestOptions: options,
          error: AppException(AppErrorCode.noInternet),
          type: DioExceptionType.unknown,
        ),
      );
    }
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final sc = response.statusCode ?? 0;
    if (sc >= 200 && sc < 300) {
      return handler.next(response);
    }

    final data = response.data;
    final serverMessage = _extractMessage(
      data,
      headers: response.headers,
    );

    String? serverErrorCode;
    Map<String, dynamic>? errors;
    if (data is Map) {
      if (data['error_code'] is String) serverErrorCode = data['error_code'];
      if (data['errors'] is Map) errors = Map<String, dynamic>.from(data['errors']);
    }

    return handler.reject(
      DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: AppException(_mapStatus(sc), serverMessage: serverMessage, serverErrorCode: serverErrorCode, errors: errors),
        type: DioExceptionType.badResponse,
      ),
    );
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.error is AppException) {
      return handler.next(err);
    }

    if (err.type == DioExceptionType.cancel) {
      return handler.next(
        err.copyWith(error: AppException(AppErrorCode.cancelled)),
      );
    }

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return handler.next(
        err.copyWith(error: AppException(AppErrorCode.timeout)),
      );
    }

    if (err.type == DioExceptionType.badCertificate) {
      return handler.next(
        err.copyWith(error: AppException(AppErrorCode.sslError)),
      );
    }

    if (err.type == DioExceptionType.connectionError) {
      final underlying = err.error;
      if (underlying is SocketException) {
        final msg = underlying.message.toLowerCase();
        if (msg.contains('lookup') || msg.contains('failed host')) {
          return handler.next(
            err.copyWith(error: AppException(AppErrorCode.dnsError)),
          );
        }
        return handler.next(
          err.copyWith(error: AppException(AppErrorCode.noInternet)),
        );
      }
      if (underlying is HandshakeException) {
        return handler.next(
          err.copyWith(error: AppException(AppErrorCode.sslError)),
        );
      }
      if (underlying is HttpException) {
        return handler.next(
          err.copyWith(error: AppException(AppErrorCode.serverError)),
        );
      }
      return handler.next(
        err.copyWith(error: AppException(AppErrorCode.unknown)),
      );
    }

    if (err.type == DioExceptionType.badResponse) {
      final code = err.response?.statusCode ?? 0;
      final mapped = _mapStatus(code);
      final data = err.response?.data;
      final serverMessage = _extractMessage(
        data,
        headers: err.response?.headers,
      );

      String? serverErrorCode;
      Map<String, dynamic>? errors;
      if (data is Map) {
        if (data['error_code'] is String) serverErrorCode = data['error_code'];
        if (data['errors'] is Map) errors = Map<String, dynamic>.from(data['errors']);
      }

      return handler.next(
        err.copyWith(error: AppException(mapped, serverMessage: serverMessage, serverErrorCode: serverErrorCode, errors: errors)),
      );
    }

    return handler.next(
      err.copyWith(error: AppException(AppErrorCode.unknown)),
    );
  }

  String? _extractMessage(dynamic data, {Headers? headers, int maxLen = 256}) {
    String? contentType = headers?.value('content-type')?.toLowerCase();
    bool looksLikeHtml(String s) {
      final ss = s.trimLeft();
      return ss.startsWith('<!doctype html') ||
          ss.startsWith('<html') ||
          ss.contains('<head') ||
          ss.contains('<body');
    }

    String? msg;
    try {
      if (data is Map) {
        if (data['title'] is String && data['detail'] is String) {
          msg = '${data['title']}: ${data['detail']}';
        }
        msg ??= (data['message'] is String) ? data['message'] : null;
        msg ??= (data['detail'] is String) ? data['detail'] : null;
        msg ??= (data['error'] is String) ? data['error'] : null;

        if (msg == null && data['errors'] is Map) {
          final errors = data['errors'] as Map;
          final parts = <String>[];
          errors.forEach((k, v) {
            if (v is List && v.isNotEmpty) {
              parts.add(v.first.toString());
            } else if (v is String && v.trim().isNotEmpty) {
              parts.add(v);
            }
          });
          if (parts.isNotEmpty) msg = parts.join('\n');
        }
      } else if (data is List && data.isNotEmpty) {
        msg = data.first.toString();
      } else if (data is String) {
        final s = data.trim();
        final isHtmlCt =
            (contentType != null && contentType.contains('text/html'));
        if (!isHtmlCt && !looksLikeHtml(s)) msg = s;
      }
    } catch (_) {
      msg = null;
    }
    if (msg != null && msg.length > maxLen) {
      msg = '${msg.substring(0, maxLen).trimRight()}…';
    }
    return msg;
  }

  AppErrorCode _mapStatus(int code) {
    switch (code) {
      case 400:
      case 422:
        return AppErrorCode.badRequest;
      case 401:
        return AppErrorCode.unauthorized;
      case 403:
        return AppErrorCode.forbidden;
      case 404:
        return AppErrorCode.notFound;
      case 409:
        return AppErrorCode.conflict;
      case 429:
        return AppErrorCode.tooManyRequests;
      case 502:
      case 504:
        return AppErrorCode.gatewayError;
      case 503:
        return AppErrorCode.maintenance;
      default:
        if (code >= 500) return AppErrorCode.serverError;
        return AppErrorCode.unknown;
    }
  }
}

// ---------------------------------------------------------------------------
// Token Refresh Interceptor
// ---------------------------------------------------------------------------

/// Callback that the app registers so the interceptor can trigger a forced
/// logout + navigation to the login screen without depending on any widget.
typedef OnSessionExpired = Future<void> Function();

class TokenRefreshInterceptor extends Interceptor {
  /// The Dio instance used **only** for the refresh call (no interceptors).
  final Dio _refreshDio;

  /// Called when the refresh token is also expired / invalid.
  final OnSessionExpired onSessionExpired;

  /// Prevents multiple simultaneous refresh requests.
  bool _isRefreshing = false;

  /// Pending requests waiting for the refresh to complete.
  final List<_PendingRequest> _pendingQueue = [];

  TokenRefreshInterceptor({
    required String baseUrl,
    required this.onSessionExpired,
  }) : _refreshDio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            validateStatus: (_) => true,
          ),
        );

  // ── onError ──────────────────────────────────────────────────────────────
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;

    // Only intercept 401 for authenticated requests that carry a token.
    final hasToken =
        err.requestOptions.headers['Authorization']?.toString().isNotEmpty ==
            true;
    if (statusCode != 401 || !hasToken) {
      return handler.next(err);
    }

    // Skip if this IS the refresh endpoint itself (avoid infinite loop),
    // or any other public auth endpoint (login/register/password-reset)
    // — on these paths a 401 means bad credentials, not an expired token.
    if (isPublicAuthPath(err.requestOptions.path)) {
      return handler.next(err);
    }

    // ── Check internet connectivity ──────────────────────────────────────
    final isOnline = await NetworkManager.hasInternetConnection();
    if (!isOnline) {
      // No network: surface a noInternet error — do NOT log the user out.
      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: AppException(AppErrorCode.noInternet),
          type: DioExceptionType.unknown,
        ),
      );
    }

    // ── Refresh flow ─────────────────────────────────────────────────────
    final refreshToken = prefs.getString(AppConstants.userRefreshToken);
    if (refreshToken == null || refreshToken.isEmpty) {
      // No refresh token stored → session is effectively expired.
      await onSessionExpired();
      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: AppException(AppErrorCode.unauthorized),
          type: DioExceptionType.badResponse,
          response: err.response,
        ),
      );
    }

    if (_isRefreshing) {
      // Queue this request until the ongoing refresh resolves.
      final completer = Completer<Response>();
      _pendingQueue.add(_PendingRequest(err.requestOptions, completer));
      try {
        final response = await completer.future;
        return handler.resolve(response);
      } catch (e) {
        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: AppException(AppErrorCode.unauthorized),
            type: DioExceptionType.badResponse,
          ),
        );
      }
    }

    _isRefreshing = true;
    try {
      final newAccess = await _doRefresh(refreshToken);

      if (newAccess == null) {
        // Refresh call returned an error → session expired.
        _rejectPending();
        await onSessionExpired();
        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: AppException(AppErrorCode.unauthorized),
            type: DioExceptionType.badResponse,
            response: err.response,
          ),
        );
      }

      // Persist the new access token.
      await prefs.setString(AppConstants.userToken, newAccess);

      // Retry the original request with the new token.
      final retried = await _retry(err.requestOptions, newAccess);
      _resolvePending(newAccess);
      return handler.resolve(retried);
    } catch (_) {
      _rejectPending();
      await onSessionExpired();
      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: AppException(AppErrorCode.unauthorized),
          type: DioExceptionType.badResponse,
        ),
      );
    } finally {
      _isRefreshing = false;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Calls the refresh endpoint and returns the new access token, or null on
  /// failure (expired / invalid refresh token).
  Future<String?> _doRefresh(String refreshToken) async {
    try {
      final response = await _refreshDio.post(
        'auth/refresh/',
        data: {'refresh': refreshToken},
      );
      if (response.statusCode == 200) {
        final newAccess = response.data?['access']?.toString();
        return (newAccess != null && newAccess.isNotEmpty) ? newAccess : null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Retries the original request with a fresh access token.
  /// Handles [FormData] specially: since its stream is consumed after the
  /// first send, we rebuild it from its fields + files before retrying.
  Future<Response> _retry(RequestOptions opts, String newToken) async {
    opts.headers['Authorization'] = 'Bearer $newToken';

    dynamic data = opts.data;

    // FormData streams are one-shot — clone before re-sending.
    if (data is FormData) {
      final cloned = FormData();
      cloned.fields.addAll(data.fields);
      cloned.files.addAll(data.files);
      data = cloned;
    }

    return _refreshDio.request(
      opts.path,
      data: data,
      queryParameters: opts.queryParameters,
      options: Options(
        method: opts.method,
        headers: opts.headers,
        responseType: opts.responseType,
        contentType: opts.contentType,
      ),
    );
  }

  void _resolvePending(String newToken) {
    for (final pending in _pendingQueue) {
      _retry(pending.options, newToken)
          .then(pending.completer.complete)
          .catchError(pending.completer.completeError);
    }
    _pendingQueue.clear();
  }

  void _rejectPending() {
    for (final pending in _pendingQueue) {
      pending.completer.completeError(
        AppException(AppErrorCode.unauthorized),
      );
    }
    _pendingQueue.clear();
  }
}

class _PendingRequest {
  final RequestOptions options;
  final Completer<Response> completer;
  _PendingRequest(this.options, this.completer);
}
