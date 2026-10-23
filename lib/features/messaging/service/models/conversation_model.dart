import 'package:reservation_chat_univercity_project/features/messaging/service/models/chat_user_model.dart';
import 'package:reservation_chat_univercity_project/features/messaging/service/models/message_model.dart';

class PaginatedConversationsResponse {
  final int count;
  final String? nextUrl;
  final String? previousUrl;
  final List<ConversationModel> results;

  const PaginatedConversationsResponse({
    required this.count,
    required this.results,
    this.nextUrl,
    this.previousUrl,
  });

  bool get hasMore => nextUrl != null && nextUrl!.isNotEmpty;

  factory PaginatedConversationsResponse.fromJson(dynamic json) {
    // پشتیبانی از هر دو حالت صفحه‌بندی DRF (Map) یا لیست مستقیم
    if (json is List) {
      final list = json
          .whereType<Map<String, dynamic>>()
          .map(ConversationModel.fromJson)
          .toList();
      return PaginatedConversationsResponse(count: list.length, results: list);
    }

    if (json is Map<String, dynamic>) {
      final rawResults = json['results'];
      final items = rawResults is List
          ? rawResults
                .whereType<Map<String, dynamic>>()
                .map(ConversationModel.fromJson)
                .toList()
          : <ConversationModel>[];

      return PaginatedConversationsResponse(
        count: (json['count'] as int?) ?? items.length,
        nextUrl: json['next']?.toString(),
        previousUrl: json['previous']?.toString(),
        results: items,
      );
    }

    return const PaginatedConversationsResponse(count: 0, results: []);
  }
}

class ConversationModel {
  final String id;
  final ChatUserModel customer;
  final ChatUserModel provider;
  final MessageModel? lastMessage;
  final String? patientLastReadMessageId;
  final String? doctorLastReadMessageId;
  final DateTime? patientLastReadAt;
  final DateTime? doctorLastReadAt;
  final int unreadCount;
  final bool? canSendMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ConversationModel({
    required this.id,
    required this.customer,
    required this.provider,
    this.lastMessage,
    this.patientLastReadMessageId,
    this.doctorLastReadMessageId,
    this.patientLastReadAt,
    this.doctorLastReadAt,
    required this.unreadCount,
    this.canSendMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  /// تشخیص کاربر مقابل (پزشک یا بیمار) بر اساس شناسه کاربر لاگین‌شده
  ChatUserModel getPeerUser(String myUserId) {
    if (customer.id == myUserId) {
      return provider;
    }
    return customer;
  }

  /// بررسی اینکه آیا کاربر جاری در این مکالمه نقش پزشک را دارد یا خیر
  bool isCurrentUserProvider(String myUserId) => provider.id == myUserId;

  /// شناسه آخرین پیامی که طرف مقابل خوانده است (برای نمایش دو تیک روی پیام‌های من)
  String? getPeerLastReadMessageId(String myUserId) {
    if (customer.id == myUserId) {
      return doctorLastReadMessageId;
    }
    return patientLastReadMessageId;
  }

  /// زمان آخرین پیامی که طرف مقابل خوانده است
  DateTime? getPeerLastReadAt(String myUserId) {
    if (customer.id == myUserId) {
      return doctorLastReadAt;
    }
    return patientLastReadAt;
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: (json['id'] ?? '').toString(),
      customer: ChatUserModel.fromJson(
        (json['customer'] as Map<String, dynamic>?) ?? const {},
      ),
      provider: ChatUserModel.fromJson(
        (json['provider'] as Map<String, dynamic>?) ?? const {},
      ),
      lastMessage: json['last_message'] is Map<String, dynamic>
          ? MessageModel.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      patientLastReadMessageId: json['patient_last_read_message']?.toString(),
      doctorLastReadMessageId: json['doctor_last_read_message']?.toString(),
      patientLastReadAt: json['patient_last_read_at'] != null
          ? DateTime.tryParse(json['patient_last_read_at'].toString())
          : null,
      doctorLastReadAt: json['doctor_last_read_at'] != null
          ? DateTime.tryParse(json['doctor_last_read_at'].toString())
          : null,
      unreadCount: (json['unread_count'] as int?) ?? 0,
      canSendMessage: json['can_send_message'] as bool?,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now().toUtc(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now().toUtc(),
    );
  }

  ConversationModel copyWith({
    String? id,
    ChatUserModel? customer,
    ChatUserModel? provider,
    MessageModel? lastMessage,
    String? patientLastReadMessageId,
    String? doctorLastReadMessageId,
    DateTime? patientLastReadAt,
    DateTime? doctorLastReadAt,
    int? unreadCount,
    bool? canSendMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      customer: customer ?? this.customer,
      provider: provider ?? this.provider,
      lastMessage: lastMessage ?? this.lastMessage,
      patientLastReadMessageId:
          patientLastReadMessageId ?? this.patientLastReadMessageId,
      doctorLastReadMessageId:
          doctorLastReadMessageId ?? this.doctorLastReadMessageId,
      patientLastReadAt: patientLastReadAt ?? this.patientLastReadAt,
      doctorLastReadAt: doctorLastReadAt ?? this.doctorLastReadAt,
      unreadCount: unreadCount ?? this.unreadCount,
      canSendMessage: canSendMessage ?? this.canSendMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ChatAccessStatusModel {
  final String? conversationId;
  final bool canRead;
  final bool canSend;
  final String reason;
  final DateTime? serverNow;
  final DateTime? startsAt;
  final DateTime? endsAt;

  const ChatAccessStatusModel({
    this.conversationId,
    required this.canRead,
    required this.canSend,
    required this.reason,
    this.serverNow,
    this.startsAt,
    this.endsAt,
  });

  factory ChatAccessStatusModel.fromJson(Map<String, dynamic> json) {
    return ChatAccessStatusModel(
      conversationId: json['conversation_id']?.toString(),
      canRead: json['can_read'] == true,
      canSend: json['can_send'] == true,
      reason: (json['reason'] ?? '').toString(),
      serverNow: json['server_now'] != null
          ? DateTime.tryParse(json['server_now'].toString())
          : null,
      startsAt: json['starts_at'] != null
          ? DateTime.tryParse(json['starts_at'].toString())
          : null,
      endsAt: json['ends_at'] != null
          ? DateTime.tryParse(json['ends_at'].toString())
          : null,
    );
  }
}
