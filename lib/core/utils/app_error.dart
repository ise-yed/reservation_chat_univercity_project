enum AppErrorCode {
  noInternet,
  timeout,
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  tooManyRequests,
  maintenance,
  serverError,
  gatewayError,
  sslError,
  dnsError,
  cancelled,
  unknown,
}

class AppException implements Exception {
  final AppErrorCode code;
  final String? serverMessage;
  final String? serverErrorCode;
  final Map<String, dynamic>? errors;

  AppException(
    this.code, {
    this.serverMessage,
    this.serverErrorCode,
    this.errors,
  });

  String get i18nKey {
    switch (code) {
      case AppErrorCode.noInternet:
        return 'error.no_internet';
      case AppErrorCode.timeout:
        return 'error.timeout';
      case AppErrorCode.badRequest:
        return 'error.bad_request';
      case AppErrorCode.unauthorized:
        return 'error.unauthorized';
      case AppErrorCode.forbidden:
        return 'error.forbidden';
      case AppErrorCode.notFound:
        return 'error.not_found';
      case AppErrorCode.conflict:
        return 'error.conflict';
      case AppErrorCode.tooManyRequests:
        return 'error.too_many_requests';
      case AppErrorCode.maintenance:
        return 'error.maintenance';
      case AppErrorCode.serverError:
        return 'error.server_error';
      case AppErrorCode.gatewayError:
        return 'error.gateway_error';
      case AppErrorCode.sslError:
        return 'error.ssl_error';
      case AppErrorCode.dnsError:
        return 'error.dns_error';
      case AppErrorCode.cancelled:
        return 'error.cancelled';
      case AppErrorCode.unknown:
        return 'error.unknown';
    }
  }

  @override
  String toString() => 'AppException($code, $serverErrorCode, $serverMessage, $errors)';
}