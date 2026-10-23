import 'package:dio/dio.dart';
import 'package:reservation_chat_univercity_project/core/utils/api_provider.dart';
import 'package:reservation_chat_univercity_project/core/utils/app_error.dart';
import 'package:reservation_chat_univercity_project/features/messaging/service/models/conversation_model.dart';
import 'package:reservation_chat_univercity_project/features/messaging/service/models/message_model.dart';

class ChatServices {
  /// دریافت لیست مکالمات (Inbox)
  /// GET /api/v1/chat/conversations/
  Future<PaginatedConversationsResponse> getConversations({
    int page = 1,
  }) async {
    try {
      final response = await apiProvider.get(
        'chat/conversations/',
        queryParameters: {'page': page},
      );
      return PaginatedConversationsResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }

  /// دریافت جزئیات یک مکالمه و نشانگرهای خوانده‌شدن
  /// GET /api/v1/chat/conversations/{conversation_id}/
  Future<ConversationModel> getConversationDetail({
    required String conversationId,
  }) async {
    try {
      final response = await apiProvider.get(
        'chat/conversations/$conversationId/',
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return ConversationModel.fromJson(data);
      }
      throw AppException(
        AppErrorCode.unknown,
        serverMessage: 'Invalid conversation detail response',
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }

  /// دریافت تاریخچه پیام‌ها با Cursor Pagination
  /// GET /api/v1/chat/conversations/{conversation_id}/messages/?cursor=...
  Future<PaginatedMessagesResponse> getConversationMessages({
    required String conversationId,
    String? cursorUrl,
  }) async {
    try {
      String? cursorToken;
      if (cursorUrl != null && cursorUrl.isNotEmpty) {
        final uri = Uri.tryParse(cursorUrl);
        cursorToken = uri?.queryParameters['cursor'] ?? cursorUrl;
      }

      final response = await apiProvider.get(
        'chat/conversations/$conversationId/messages/',
        queryParameters: {
          if (cursorToken != null && cursorToken.isNotEmpty)
            'cursor': cursorToken,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return PaginatedMessagesResponse.fromJson(data);
      }
      throw AppException(
        AppErrorCode.unknown,
        serverMessage: 'Invalid message history response',
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }

  /// ارسال پیام متنی (JSON) یا فایل/تصویر/ویس (Multipart)
  /// POST /api/v1/chat/conversations/{conversation_id}/messages/
  Future<MessageModel> sendMessage({
    required SendMessageRequest request,
  }) async {
    try {
      final endpoint = 'chat/conversations/${request.conversationId}/messages/';
      final Response response;

      if (request.type == ChatMessageType.text) {
        response = await apiProvider.post(
          endpoint,
          data: {'type': request.type.value, 'content': request.content.trim()},
        );
      } else {
        if (request.filePath == null || request.filePath!.isEmpty) {
          throw AppException(
            AppErrorCode.unknown,
            serverMessage: 'فایل پیوست انتخاب نشده است.',
          );
        }

        final multipartFile = await MultipartFile.fromFile(
          request.filePath!,
          filename: request.fileName,
        );

        final formData = FormData.fromMap({
          'type': request.type.value,
          if (request.content.trim().isNotEmpty)
            'content': request.content.trim(),
          'attachment': multipartFile,
        });

        response = await apiProvider.post(endpoint, data: formData);
      }

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return MessageModel.fromJson(data);
      }
      throw AppException(
        AppErrorCode.unknown,
        serverMessage: 'Invalid send message response',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw AppException(
          AppErrorCode.forbidden,
          serverMessage:
              'زمان ویزیت آنلاین شما فعال نیست یا مجوز ارسال پیام ندارید.',
        );
      }
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }

  /// حذف نرم پیام (فقط توسط پزشک)
  /// DELETE /api/v1/chat/messages/{message_id}/
  Future<void> deleteMessage({required String messageId}) async {
    try {
      await apiProvider.delete('chat/messages/$messageId/');
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }

  /// آپدیت نشانگر آخرین پیام خوانده‌شده از طریق REST
  /// POST /api/v1/chat/conversations/{conversation_id}/read/
  Future<bool> updateReadPointer({
    required String conversationId,
    required String lastReadMessageId,
  }) async {
    try {
      final response = await apiProvider.post(
        'chat/conversations/$conversationId/read/',
        data: {'last_read_message_id': lastReadMessageId},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }

  /// بررسی وضعیت دسترسی چت برای یک نوبت مشخص
  /// GET /api/v1/appointments/{appointment_id}/chat-access/
  Future<ChatAccessStatusModel> getAppointmentChatAccess({
    required String appointmentId,
  }) async {
    try {
      final response = await apiProvider.get(
        'appointments/$appointmentId/chat-access/',
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return ChatAccessStatusModel.fromJson(data);
      }
      throw AppException(
        AppErrorCode.unknown,
        serverMessage: 'Invalid chat access response',
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }

  /// خاتمه و تکمیل دستی ویزیت آنلاین توسط پزشک
  /// POST /api/v1/appointments/{appointment_id}/complete/
  Future<void> completeAppointmentVisit({required String appointmentId}) async {
    try {
      await apiProvider.post('appointments/$appointmentId/complete/');
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }
}
