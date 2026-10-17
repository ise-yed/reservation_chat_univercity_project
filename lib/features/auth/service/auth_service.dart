import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_setting.dart';
import '../../../core/utils/api_provider.dart';
import '../../../core/utils/app_error.dart';
import '../models/user_model.dart';

class AuthServices {
  Future<String> register({
    required String email,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String password,
    required String passwordConfirm,
  }) async {
    try {
      final response = await apiProvider.post(
        'auth/register/',
        data: {
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          'phone_number': phoneNumber,
          'password': password,
          'password_confirm': passwordConfirm,
        },
      );

      final raw = response.data?['message'];
      if (raw is String) {
        return raw;
      }
      return 'Registration successful'; // Fallback
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiProvider.post(
        'auth/login/',
        data: {'email': email, 'password': password},
      );

      final tokens = response.data?['tokens'];
      final accessToken = tokens?['access']?.toString();
      final refreshToken = tokens?['refresh']?.toString();
      
      if (accessToken != null && accessToken.isNotEmpty) {
        await prefs.setString(AppConstants.userToken, accessToken);
      }
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await prefs.setString(AppConstants.userRefreshToken, refreshToken);
      }

      final userJson = response.data?['user'];
      if (userJson is Map<String, dynamic>) {
        return UserModel.fromJson(userJson);
      }

      throw AppException(
        AppErrorCode.unknown,
        serverMessage: 'No access token',
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = prefs.getString(AppConstants.userRefreshToken);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await apiProvider.post(
          'auth/logout/',
          data: {'refresh': refreshToken},
        );
      }
      await prefs.remove(AppConstants.userToken);
      await prefs.remove(AppConstants.userRefreshToken);
    } on DioException catch (e) {
      // Ignore logout errors
      await prefs.remove(AppConstants.userToken);
      await prefs.remove(AppConstants.userRefreshToken);
    }
  }

  /// Tries to refresh the access token silently at app startup.
  /// Returns [true] if a new access token was obtained and saved.
  /// Returns [false] if the refresh token is missing or expired.
  /// On success, [prefs] is updated with the new access token.
  Future<bool> refreshTokenOnStartup() async {
    final refreshToken = prefs.getString(AppConstants.userRefreshToken);
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }
    try {
      // Use a plain Dio (no interceptors) to avoid loops.
      final dio = Dio(
        BaseOptions(
          baseUrl: AppConstants.appBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          validateStatus: (_) => true,
        ),
      );
      final response = await dio.post(
        'auth/token/refresh/',
        data: {'refresh': refreshToken},
        options: Options(contentType: 'application/json'),
      );
      if (response.statusCode == 200) {
        final newAccess = response.data?['access']?.toString();
        if (newAccess != null && newAccess.isNotEmpty) {
          await prefs.setString(AppConstants.userToken, newAccess);
          return true;
        }
      }
      // Refresh token is invalid/expired — clear credentials.
      await prefs.remove(AppConstants.userToken);
      await prefs.remove(AppConstants.userRefreshToken);
      return false;
    } catch (_) {
      // Network error — keep credentials; user may be offline.
      return false;
    }
  }

  Future<String> forgetPasswordRequest({required String email}) async {
    try {
      final response = await apiProvider.post(
        'auth/password/reset/request-otp/',
        data: {'email': email},
      );

      final raw = response.data?['message'];
      if (raw is String) {
        return raw;
      }

      return 'OTP sent successfully';
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }

  Future<String> forgetPasswordVerify({
    required String email,
    required String code,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    try {
      final response = await apiProvider.post(
        'auth/password/reset/confirm/',
        data: {
          'email': email, 
          'code': code,
          'new_password': newPassword,
          'new_password_confirm': newPasswordConfirm,
        },
      );

      final raw = response.data?['message'];
      if (raw is String) {
        return raw;
      }
      return 'Password reset successful';
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }
  
  Future<String> changePasswordRequest() async {
    try {
      final response = await apiProvider.post(
        'auth/password/change/request-otp/',
      );

      final raw = response.data?['message'];
      if (raw is String) {
        return raw;
      }
      return 'OTP sent successfully';
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }

  Future<String> changePassword({
    required String currentPassword,
    required String code,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    try {
      final response = await apiProvider.post(
        'auth/password/change/confirm/',
        data: {
          'current_password': currentPassword,
          'code': code,
          'new_password': newPassword,
          'new_password_confirm': newPasswordConfirm,
        },
      );

      final raw = response.data?['message'];
      if (raw is String) {
        return raw;
      }
      return 'Password changed successfully';
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }
}
