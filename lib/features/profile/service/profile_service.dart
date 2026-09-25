import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:reservation_chat_univercity_project/features/profile/model/notification_model.dart';
import 'package:reservation_chat_univercity_project/features/profile/model/ticket_data_model.dart';
import 'package:reservation_chat_univercity_project/features/profile/model/ticket_list_model.dart';

import '../../../core/constants/app_setting.dart';
import '../../../core/utils/api_provider.dart';
import '../../../core/utils/app_error.dart';
import '../../auth/models/user_model.dart';
import '../model/app_const_setting_model.dart';
import '../model/pet_model.dart';

class ProfileService {
  Future<UserModel> editProfile({required UserModel user}) async {
    try {
      final response = await apiProvider.patch('user/', data: user.toJson());
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }

  Future<List<PetModel>> getPets() async {
    try {
      final response = await apiProvider.get('pet/');
      return PetModel.listFromJson(response.data);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    } catch (e) {
      throw AppException(AppErrorCode.unknown, serverMessage: e.toString());
    }
  }

  Future<List<PetModel>> getBreeds(String petId) async {
    try {
      final response = await apiProvider.get('pet/$petId');
      return PetModel.listFromJson(response.data);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    } catch (e) {
      throw AppException(AppErrorCode.unknown, serverMessage: e.toString());
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
      final response = await apiProvider.get('user/');
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
  }) async {
    try {
      await apiProvider.post(
        'notifications/devices/register/',
        data: {'registration_id': firebaseToken},
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

  Future<List<TicketListModel>> getTickets() async {
    try {
      final response = await apiProvider.get('ticket/');
      return ticketListModelFromJson(response.data);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    } catch (e) {
      throw AppException(AppErrorCode.unknown, serverMessage: e.toString());
    }
  }

  Future<TicketListModel> createTicket({
    required String subject,
    required String description,
    required String message,
  }) async {
    try {
      final response = await apiProvider.post(
        'ticket/',
        data: {
          "subject": subject,
          "description": description,
          "message": message,
        },
      );

      return TicketListModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    } catch (e) {
      throw AppException(AppErrorCode.unknown, serverMessage: e.toString());
    }
  }

  // !must chekck
  // todo:
  Future<TicketListModel> closeTicket({required String id}) async {
    try {
      final response = await apiProvider.delete('ticket/$id');

      return TicketListModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    } catch (e) {
      throw AppException(AppErrorCode.unknown, serverMessage: e.toString());
    }
  }

  Future<SingleTicketModel> getMessageTicket({required String id}) async {
    try {
      final response = await apiProvider.get('ticket/$id');

      return SingleTicketModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    } catch (e) {
      throw AppException(AppErrorCode.unknown, serverMessage: e.toString());
    }
  }

  Future<TicketMessageData> replayTicket({
    String? message,
    String? document,
    required String id,
  }) async {
    try {
      final response = await apiProvider.post(
        'ticket/$id',
        data: {"message": message ?? "", "document": document ?? ""},
      );

      return TicketMessageData.fromJson(response.data);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    } catch (e) {
      throw AppException(AppErrorCode.unknown, serverMessage: e.toString());
    }
  }

  Future<NotificationModel> getNotificationData({int? page, int? limit}) async {
    try {
      final response = await apiProvider.get(
        'notification',

        queryParameters: {'page': page, 'limit': limit},
      );

      return NotificationModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    } catch (e) {
      throw AppException(AppErrorCode.unknown, serverMessage: e.toString());
    }
  }

  Future<dynamic> seenNotification() async {
    try {
      var data = await apiProvider.patch('notification');
      return data.data;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    } catch (e) {
      throw AppException(AppErrorCode.unknown, serverMessage: e.toString());
    }
  }
}
