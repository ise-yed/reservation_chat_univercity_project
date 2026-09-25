import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_constants.dart';
import '../constants/app_setting.dart';
import 'error_interceptor.dart';

/// Called by [TokenRefreshInterceptor] when the session can no longer be
/// recovered (refresh token expired / missing).  We clear local credentials
/// and flip [isLogin] so that the app's root [ValueListenableBuilder]
/// automatically redirects to the login / splash screen.
Future<void> _handleSessionExpired() async {
  await prefs.remove(AppConstants.userToken);
  await prefs.remove(AppConstants.userRefreshToken);
  isLogin.value = false;
}

final Dio apiProvider =
    Dio(
        BaseOptions(
          baseUrl: AppConstants.appBaseUrl,
          validateStatus: (_) => true,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ),
      )
      ..interceptors.addAll([
        ConnectivityAndErrorInterceptor(),
        LoggingInterceptor(),
        TokenRefreshInterceptor(
          baseUrl: AppConstants.appBaseUrl,
          onSessionExpired: _handleSessionExpired,
        ),
      ]);

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Do NOT attach a token to public auth endpoints.
    // An old / expired token would cause the backend to return 401
    // even when the user provides correct credentials.
    // isPublicAuthPath is defined in error_interceptor.dart.
    if (!isPublicAuthPath(options.path)) {
      final currentToken = prefs.getString(AppConstants.userToken) ?? '';
      if (currentToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $currentToken';
      }
    }

    // Send Accept-Language header so the backend returns messages
    // in the user's current language (fa or en)
    final locale = EasyLocalization.of(navigatorKey.currentContext!)?.locale;
    final langCode = locale?.languageCode ?? 'fa';
    options.headers['Accept-Language'] = langCode;

    super.onRequest(options, handler);
  }
}
