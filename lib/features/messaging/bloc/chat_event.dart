part of 'chat_bloc.dart';

@immutable
sealed class ChatEvent {
  const ChatEvent();
}

// --------------------
// Inbox Events
// --------------------

class LoadConversationsEvent extends ChatEvent {
  final int page;
  final bool refresh;

  const LoadConversationsEvent({this.page = 1, this.refresh = false});
}

// --------------------
// Active Chat Room Lifecycle & History Events
// --------------------

class EnterConversationEvent extends ChatEvent {
  final String conversationId;
  final ConversationModel? initialConversation;
  final String? appointmentId;

  const EnterConversationEvent({
    required this.conversationId,
    this.initialConversation,
    this.appointmentId,
  });
}

class LeaveConversationEvent extends ChatEvent {
  const LeaveConversationEvent();
}

class LoadMoreMessagesEvent extends ChatEvent {
  const LoadMoreMessagesEvent();
}

class CheckAppointmentChatAccessEvent extends ChatEvent {
  final String appointmentId;
  const CheckAppointmentChatAccessEvent({required this.appointmentId});
}

class CompleteAppointmentVisitEvent extends ChatEvent {
  final String appointmentId;
  const CompleteAppointmentVisitEvent({required this.appointmentId});
}

// --------------------
// Message Actions (Send / Retry / Delete / Seen / Typing)
// --------------------

class SendChatMessageEvent extends ChatEvent {
  final ChatMessageType type;
  final String content;
  final String? filePath;
  final String? fileName;
  final String? retryTempId;

  const SendChatMessageEvent({
    required this.type,
    this.content = '',
    this.filePath,
    this.fileName,
    this.retryTempId,
  });
}

class DeleteChatMessageEvent extends ChatEvent {
  final String messageId;
  const DeleteChatMessageEvent({required this.messageId});
}

class MarkLatestMessageSeenEvent extends ChatEvent {
  final String messageId;
  const MarkLatestMessageSeenEvent({required this.messageId});
}

class SendTypingStatusEvent extends ChatEvent {
  final bool isTyping;
  const SendTypingStatusEvent({required this.isTyping});
}

// --------------------
// Internal WebSocket & Connectivity Events
// --------------------

class _SocketPacketReceivedEvent extends ChatEvent {
  final RealtimeSocketPacket packet;
  const _SocketPacketReceivedEvent(this.packet);
}

class _SocketDisconnectedInternalEvent extends ChatEvent {
  final String? conversationId;
  final int? closeCode;
  const _SocketDisconnectedInternalEvent({this.conversationId, this.closeCode});
}

class _RetrySocketConnectEvent extends ChatEvent {
  final String conversationId;
  final int attempt;
  const _RetrySocketConnectEvent({
    required this.conversationId,
    required this.attempt,
  });
}
