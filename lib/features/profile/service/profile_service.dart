import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:reservation_chat_univercity_project/features/profile/model/notification_model.dart';

import '../../../core/constants/app_setting.dart';
import '../../../core/utils/api_provider.dart';
import '../../../core/utils/app_error.dart';
import '../../auth/models/user_model.dart';
import '../model/app_const_setting_model.dart';

class ProfileService {
  Future<UserModel> editProfile({required UserModel user}) async {
    try {
      final response = await apiProvider.patch('auth/me/', data: user.toJson());
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }

  Future<String> uploadFile(
    XFile file, {
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final fileName = file.name.isNotEmpty ? file.name : 'upload.jpg';

      MultipartFile part;
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        part = MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        );
      } else {
        part = await MultipartFile.fromFile(file.path, filename: fileName);
      }

      final formData = FormData.fromMap({'file': part});

      final response = await apiProvider.post(
        'upload/',
        data: formData,
        onSendProgress: onProgress,
      );

      return response.data['file'] as String;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    } catch (e) {
      throw AppException(AppErrorCode.unknown, serverMessage: e.toString());
    }
  }

  Future<UserModel> getCurrentUser() async {
    try {
      final response = await apiProvider.get('auth/me/');
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.error is AppException) {
        final appEx = e.error as AppException;
        if (appEx.code == AppErrorCode.unauthorized) {
          final uid = currentUserModel.id;
          await prefs.clear();
          isLogin.value = false;
          currentUserModel = UserModel();
          if (uid != null && uid.isNotEmpty) {
            debugPrint('User $uid logged out due to unauthorized access.');
          }
        }
        throw appEx;
      }
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }

  Future<void> updateFirebaseToken({
    required String? firebaseToken,
    String? deviceType,
  }) async {
    try {
      await apiProvider.post(
        'notifications/devices/register/',
        data: {
          'registration_id': firebaseToken,
          if (deviceType != null) 'device_type': deviceType,
        },
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }

  Future<AppConstSettingModel> getAppConstSetting() async {
    try {
      final response = await apiProvider.get('setting/text-plains');
      return AppConstSettingModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    } catch (e) {
      throw AppException(AppErrorCode.unknown, serverMessage: e.toString());
    }
  }

  Future<NotificationModel> getNotificationData({int? page, int? limit}) async {
    try {
      final p = page ?? 1;
      final l = limit ?? 20;
      final response = await apiProvider.get(
        'notifications/',
        queryParameters: {
          'page': p,
          'page_size': l,
        },
      );

      return NotificationModel.fromJson(
        response.data,
        currentPage: p,
        limit: l,
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    } catch (e) {
      throw AppException(AppErrorCode.unknown, serverMessage: e.toString());
    }
  }

  Future<NotificationDoc> getNotificationDetail(String id) async {
    try {
      final response = await apiProvider.get('notifications/$id/');
      return NotificationDoc.fromJson(response.data);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    } catch (e) {
      throw AppException(AppErrorCode.unknown, serverMessage: e.toString());
    }
  }

  Future<NotificationDoc> markNotificationAsRead(String id) async {
    try {
      final response = await apiProvider.post('notifications/$id/mark-read/');
      return NotificationDoc.fromJson(response.data);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    } catch (e) {
      throw AppException(AppErrorCode.unknown, serverMessage: e.toString());
    }
  }

  Future<int> markAllNotificationsAsRead() async {
    try {
      final response = await apiProvider.post('notifications/mark-all-read/');
      final count = (response.data['marked_as_read'] as num?)?.toInt() ?? 0;
      return count;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    } catch (e) {
      throw AppException(AppErrorCode.unknown, serverMessage: e.toString());
    }
  }

  Future<dynamic> seenNotification() async {
    return markAllNotificationsAsRead();
  }
}

