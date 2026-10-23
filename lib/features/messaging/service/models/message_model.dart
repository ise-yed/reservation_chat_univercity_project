import 'package:reservation_chat_univercity_project/core/constants/app_constants.dart';

enum ChatMessageType {
  text('text'),
  image('image'),
  document('document'),
  voice('voice');

  final String value;
  const ChatMessageType(this.value);

  static ChatMessageType fromValue(String? raw) {
    return switch (raw?.toLowerCase()) {
      'image' => ChatMessageType.image,
      'document' => ChatMessageType.document,
      'voice' => ChatMessageType.voice,
      _ => ChatMessageType.text,
    };
  }
}

enum MessageSendStatus { sending, sent, failed }

class PaginatedMessagesResponse {
  final String? nextCursorUrl;
  final String? previousCursorUrl;
  final List<MessageModel> results;

  const PaginatedMessagesResponse({
    required this.results,
    this.nextCursorUrl,
    this.previousCursorUrl,
  });

  bool get hasMore => nextCursorUrl != null && nextCursorUrl!.isNotEmpty;

  factory PaginatedMessagesResponse.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'];
    final items = rawResults is List
        ? rawResults
              .whereType<Map<String, dynamic>>()
              .map(MessageModel.fromJson)
              .toList()
        : <MessageModel>[];

    return PaginatedMessagesResponse(
      nextCursorUrl: json['next']?.toString(),
      previousCursorUrl: json['previous']?.toString(),
      results: items,
    );
  }
}

class MessageModel {
  final String id;
  final String senderId;
  final ChatMessageType type;
  final String content;
  final String? attachment;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime createdAt;

  // فیلدهای محلی کلاینت برای مدیریت Optimistic UI و تلاش مجدد
  final MessageSendStatus sendStatus;
  final String? localFilePath;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.type,
    required this.content,
    this.attachment,
    this.fileName,
    this.fileSize,
    this.mimeType,
    required this.isDeleted,
    this.deletedAt,
    required this.createdAt,
    this.sendStatus = MessageSendStatus.sent,
    this.localFilePath,
  });

  bool isMine(String currentUserId) => senderId == currentUserId;

  /// ساخت آدرس کامل فایل پیوست (پشتیبانی از آدرس نسبی WebSocket و آدرس کامل REST)
  String get resolvedAttachmentUrl {
    final raw = attachment?.trim() ?? '';
    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    final base = AppConstants.appBaseUrl.endsWith('/')
        ? AppConstants.appBaseUrl.substring(
            0,
            AppConstants.appBaseUrl.length - 1,
          )
        : AppConstants.appBaseUrl;
    final path = raw.startsWith('/') ? raw : '/$raw';
    return '$base$path';
  }

  /// متن پیش‌نمایش برای نمایش در لیست مکالمات (Inbox)
  String get inboxPreviewText {
    if (isDeleted) {
      return 'این پیام توسط پزشک حذف شده است';
    }
    return switch (type) {
      ChatMessageType.text => content,
      ChatMessageType.image => '📷 تصویر',
      ChatMessageType.document =>
        '📎 ${fileName != null && fileName!.isNotEmpty ? fileName : 'فایل پیوست'}',
      ChatMessageType.voice => '🎤 پیام صوتی',
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final parsedCreatedAt = json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString())
        : null;

    return MessageModel(
      id: (json['id'] ?? '').toString(),
      senderId: (json['sender_id'] ?? '').toString(),
      type: ChatMessageType.fromValue(json['type']?.toString()),
      content: (json['content'] ?? '').toString(),
      attachment: json['attachment']?.toString(),
      fileName: json['file_name']?.toString(),
      fileSize: json['file_size'] is int
          ? json['file_size'] as int
          : int.tryParse(json['file_size']?.toString() ?? ''),
      mimeType: json['mime_type']?.toString(),
      isDeleted: json['is_deleted'] == true,
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'].toString())
          : null,
      createdAt: parsedCreatedAt ?? DateTime.now().toUtc(),
      sendStatus: MessageSendStatus.sent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'type': type.value,
      'content': content,
      'attachment': attachment,
      'file_name': fileName,
      'file_size': fileSize,
      'mime_type': mimeType,
      'is_deleted': isDeleted,
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    ChatMessageType? type,
    String? content,
    String? attachment,
    String? fileName,
    int? fileSize,
    String? mimeType,
    bool? isDeleted,
    DateTime? deletedAt,
    DateTime? createdAt,
    MessageSendStatus? sendStatus,
    String? localFilePath,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      content: content ?? this.content,
      attachment: attachment ?? this.attachment,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      sendStatus: sendStatus ?? this.sendStatus,
      localFilePath: localFilePath ?? this.localFilePath,
    );
  }
}

class SendMessageRequest {
  final String conversationId;
  final ChatMessageType type;
  final String content;
  final String? filePath;
  final String? fileName;

  const SendMessageRequest({
    required this.conversationId,
    required this.type,
    this.content = '',
    this.filePath,
    this.fileName,
  });
}
