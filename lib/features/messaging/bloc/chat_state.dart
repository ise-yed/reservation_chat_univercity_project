part of 'chat_bloc.dart';

enum ChatSocketConnectionStatus {
  initial,
  connecting,
  connected,
  reconnecting,
  disconnected,
  authExpired,
  forbidden,
}

@immutable
class ChatState {
  // وضعیت لیست گفت‌وگوها (Inbox)
  final bool isLoadingConversations;
  final List<ConversationModel> conversations;
  final bool hasMoreConversations;
  final int currentInboxPage;
  final String? inboxError;

  // وضعیت اتاق چت فعال
  final String? activeConversationId;
  final ConversationModel? activeConversation;
  final List<MessageModel> messages;
  final String? nextMessagesCursorUrl;
  final bool isLoadingMessages;
  final bool isLoadingMoreMessages;
  final String? messagesError;

  // وضعیت بلادرنگ و مجوز ارسال
  final ChatSocketConnectionStatus socketStatus;
  final bool isPeerTyping;
  final bool canSendMessage;
  final String? chatLockReason;
  final ChatAccessStatusModel? appointmentAccess;
  final bool isCompletingVisit;
  final bool visitCompletedSuccess;
  final String? actionError;

  // نشانگر خوانده‌شدن پیام‌ها توسط طرف مقابل
  final String? peerLastReadMessageId;
  final DateTime? peerLastReadAt;

  const ChatState({
    this.isLoadingConversations = false,
    this.conversations = const [],
    this.hasMoreConversations = false,
    this.currentInboxPage = 1,
    this.inboxError,
    this.activeConversationId,
    this.activeConversation,
    this.messages = const [],
    this.nextMessagesCursorUrl,
    this.isLoadingMessages = false,
    this.isLoadingMoreMessages = false,
    this.messagesError,
    this.socketStatus = ChatSocketConnectionStatus.initial,
    this.isPeerTyping = false,
    this.canSendMessage = true,
    this.chatLockReason,
    this.appointmentAccess,
    this.isCompletingVisit = false,
    this.visitCompletedSuccess = false,
    this.actionError,
    this.peerLastReadMessageId,
    this.peerLastReadAt,
  });

  bool get hasMoreMessages =>
      nextMessagesCursorUrl != null && nextMessagesCursorUrl!.isNotEmpty;

  /// مجموع تمام پیام‌های خوانده‌نشده در Inbox
  int get totalUnreadCount =>
      conversations.fold<int>(0, (sum, item) => sum + item.unreadCount);

  /// بررسی اینکه آیا پیام ارسال‌شده توسط من، توسط طرف مقابل خوانده شده است یا خیر
  bool isMessageSeenByPeer(MessageModel message, String currentUserId) {
    if (!message.isMine(currentUserId)) return true;
    if (message.sendStatus != MessageSendStatus.sent) return false;

    if (peerLastReadMessageId != null && peerLastReadMessageId == message.id) {
      return true;
    }

    if (peerLastReadAt != null && !message.createdAt.isAfter(peerLastReadAt!)) {
      return true;
    }

    if (peerLastReadMessageId != null) {
      final pointerIndex = messages.indexWhere(
        (m) => m.id == peerLastReadMessageId,
      );
      final msgIndex = messages.indexWhere((m) => m.id == message.id);
      // از آنجا که لیست messages به ترتیب نزولی (-created_at) است،
      // هر پیامی که اندیس آن بزرگ‌تر یا مساوی اندیس پیامِ مرجع باشد، قدیمی‌تر بوده و خوانده شده است.
      if (pointerIndex != -1 && msgIndex != -1 && msgIndex >= pointerIndex) {
        return true;
      }
    }

    return false;
  }

  ChatState copyWith({
    bool? isLoadingConversations,
    List<ConversationModel>? conversations,
    bool? hasMoreConversations,
    int? currentInboxPage,
    String? inboxError,
    bool clearInboxError = false,
    String? activeConversationId,
    bool clearActiveConversation = false,
    ConversationModel? activeConversation,
    List<MessageModel>? messages,
    String? nextMessagesCursorUrl,
    bool clearNextMessagesCursorUrl = false,
    bool? isLoadingMessages,
    bool? isLoadingMoreMessages,
    String? messagesError,
    bool clearMessagesError = false,
    ChatSocketConnectionStatus? socketStatus,
    bool? isPeerTyping,
    bool? canSendMessage,
    String? chatLockReason,
    bool clearChatLockReason = false,
    ChatAccessStatusModel? appointmentAccess,
    bool? isCompletingVisit,
    bool? visitCompletedSuccess,
    String? actionError,
    bool clearActionError = false,
    String? peerLastReadMessageId,
    DateTime? peerLastReadAt,
  }) {
    return ChatState(
      isLoadingConversations:
          isLoadingConversations ?? this.isLoadingConversations,
      conversations: conversations ?? this.conversations,
      hasMoreConversations: hasMoreConversations ?? this.hasMoreConversations,
      currentInboxPage: currentInboxPage ?? this.currentInboxPage,
      inboxError: clearInboxError ? null : (inboxError ?? this.inboxError),
      activeConversationId: clearActiveConversation
          ? null
          : (activeConversationId ?? this.activeConversationId),
      activeConversation: clearActiveConversation
          ? null
          : (activeConversation ?? this.activeConversation),
      messages: messages ?? this.messages,
      nextMessagesCursorUrl: clearNextMessagesCursorUrl
          ? null
          : (nextMessagesCursorUrl ?? this.nextMessagesCursorUrl),
      isLoadingMessages: isLoadingMessages ?? this.isLoadingMessages,
      isLoadingMoreMessages:
          isLoadingMoreMessages ?? this.isLoadingMoreMessages,
      messagesError: clearMessagesError
          ? null
          : (messagesError ?? this.messagesError),
      socketStatus: socketStatus ?? this.socketStatus,
      isPeerTyping: isPeerTyping ?? this.isPeerTyping,
      canSendMessage: canSendMessage ?? this.canSendMessage,
      chatLockReason: clearChatLockReason
          ? null
          : (chatLockReason ?? this.chatLockReason),
      appointmentAccess: clearActiveConversation
          ? null
          : (appointmentAccess ?? this.appointmentAccess),
      isCompletingVisit: isCompletingVisit ?? this.isCompletingVisit,
      visitCompletedSuccess:
          visitCompletedSuccess ?? this.visitCompletedSuccess,
      actionError: clearActionError ? null : (actionError ?? this.actionError),
      peerLastReadMessageId: clearActiveConversation
          ? null
          : (peerLastReadMessageId ?? this.peerLastReadMessageId),
      peerLastReadAt: clearActiveConversation
          ? null
          : (peerLastReadAt ?? this.peerLastReadAt),
    );
  }
}
