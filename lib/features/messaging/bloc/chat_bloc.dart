import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:meta/meta.dart';
import 'package:reservation_chat_univercity_project/core/constants/app_setting.dart';
import 'package:reservation_chat_univercity_project/core/utils/app_error.dart';
import 'package:reservation_chat_univercity_project/core/utils/network_connection.dart';
import 'package:reservation_chat_univercity_project/features/messaging/service/chat_service.dart';
import 'package:reservation_chat_univercity_project/features/messaging/service/chat_socket_service.dart';
import 'package:reservation_chat_univercity_project/features/messaging/service/models/conversation_model.dart';
import 'package:reservation_chat_univercity_project/features/messaging/service/models/message_model.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatServices chatServices;

  ChatBloc(this.chatServices) : super(const ChatState()) {
    on<LoadConversationsEvent>(_onLoadConversations);
    on<EnterConversationEvent>(_onEnterConversation);
    on<LeaveConversationEvent>(_onLeaveConversation);
    on<LoadMoreMessagesEvent>(_onLoadMoreMessages);
    on<CheckAppointmentChatAccessEvent>(_onCheckAppointmentChatAccess);
    on<CompleteAppointmentVisitEvent>(_onCompleteAppointmentVisit);
    on<SendChatMessageEvent>(_onSendChatMessage);
    on<DeleteChatMessageEvent>(_onDeleteChatMessage);
    on<MarkLatestMessageSeenEvent>(_onMarkLatestMessageSeen);
    on<SendTypingStatusEvent>(_onSendTypingStatus);
    on<_SocketPacketReceivedEvent>(_onSocketPacketReceived);
    on<_SocketDisconnectedInternalEvent>(_onSocketDisconnectedInternal);
    on<_RetrySocketConnectEvent>(_onRetrySocketConnect);

    _socketEventsSub = chatSocketService.eventsStream.listen((packet) {
      add(_SocketPacketReceivedEvent(packet));
    });

    chatSocketService.setOnDisconnectCallback((conversationId, closeCode) {
      add(
        _SocketDisconnectedInternalEvent(
          conversationId: conversationId,
          closeCode: closeCode,
        ),
      );
    });

    _internetSub = NetworkManager.internetStatusStream.listen(
      _onInternetStatusChanged,
    );
  }

  static const int maxReconnectRetries = 5;
  static const Duration baseRetryDelay = Duration(seconds: 2);

  StreamSubscription<RealtimeSocketPacket>? _socketEventsSub;
  StreamSubscription<bool>? _internetSub;
  Timer? _reconnectTimer;

  bool _hasInternet = true;
  bool _refreshHistoryOnReconnect = false;
  String? _lastSentSeenMessageId;
  String? _pendingOfflineSeenMessageId;

  String get _myUserId => (currentUserModel.id ?? '').toString();

  // --------------------
  // Inbox Handlers
  // --------------------

  Future<void> _onLoadConversations(
    LoadConversationsEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (event.page == 1) {
      emit(state.copyWith(isLoadingConversations: true, clearInboxError: true));
    }

    try {
      final response = await chatServices.getConversations(page: event.page);
      final updatedList = event.page == 1 || event.refresh
          ? response.results
          : <ConversationModel>[...state.conversations, ...response.results];

      emit(
        state.copyWith(
          isLoadingConversations: false,
          conversations: updatedList,
          hasMoreConversations: response.hasMore,
          currentInboxPage: event.page,
          clearInboxError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(isLoadingConversations: false, inboxError: _errMsg(e)),
      );
    }
  }

  // --------------------
  // Room Lifecycle & History Handlers
  // --------------------

  Future<void> _onEnterConversation(
    EnterConversationEvent event,
    Emitter<ChatState> emit,
  ) async {
    _reconnectTimer?.cancel();
    _lastSentSeenMessageId = null;
    _pendingOfflineSeenMessageId = null;

    final initialConv = event.initialConversation;
    final isDoctor = initialConv?.isCurrentUserProvider(_myUserId) ?? false;

    emit(
      state.copyWith(
        activeConversationId: event.conversationId,
        activeConversation: initialConv,
        messages: const [],
        clearNextMessagesCursorUrl: true,
        isLoadingMessages: true,
        isLoadingMoreMessages: false,
        clearMessagesError: true,
        clearActionError: true,
        isPeerTyping: false,
        visitCompletedSuccess: false,
        canSendMessage: isDoctor ? true : (initialConv?.canSendMessage ?? true),
        peerLastReadMessageId: initialConv?.getPeerLastReadMessageId(_myUserId),
        peerLastReadAt: initialConv?.getPeerLastReadAt(_myUserId),
        socketStatus: ChatSocketConnectionStatus.connecting,
      ),
    );

    // ۱. بررسی دسترسی نوبت (در صورت پاس داده شدن appointmentId)
    if (event.appointmentId != null && event.appointmentId!.isNotEmpty) {
      add(CheckAppointmentChatAccessEvent(appointmentId: event.appointmentId!));
    }

    // ۲. دریافت جزئیات مکالمه و تاریخچه پیام‌ها به صورت موازی
    try {
      final results = await Future.wait([
        chatServices.getConversationDetail(
          conversationId: event.conversationId,
        ),
        chatServices.getConversationMessages(
          conversationId: event.conversationId,
        ),
      ]);

      final convDetail = results[0] as ConversationModel;
      final messagesPage = results[1] as PaginatedMessagesResponse;
      final userIsDoctor = convDetail.isCurrentUserProvider(_myUserId);

      // صفر کردن unread_count این مکالمه در لیست Inbox
      final updatedInbox = state.conversations.map((c) {
        if (c.id == convDetail.id) {
          return convDetail.copyWith(unreadCount: 0);
        }
        return c;
      }).toList();

      emit(
        state.copyWith(
          activeConversation: convDetail,
          conversations: updatedInbox,
          messages: messagesPage.results,
          nextMessagesCursorUrl: messagesPage.nextCursorUrl,
          clearNextMessagesCursorUrl: !messagesPage.hasMore,
          isLoadingMessages: false,
          canSendMessage: userIsDoctor
              ? true
              : (state.appointmentAccess?.canSend ??
                    convDetail.canSendMessage ??
                    true),
          peerLastReadMessageId: convDetail.getPeerLastReadMessageId(_myUserId),
          peerLastReadAt: convDetail.getPeerLastReadAt(_myUserId),
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoadingMessages: false, messagesError: _errMsg(e)));
    }

    // ۳. اتصال به وب‌سوکت اختصاصی مکالمه
    await _connectSocket(event.conversationId, emit, attempt: 0);
  }

  Future<void> _onLeaveConversation(
    LeaveConversationEvent event,
    Emitter<ChatState> emit,
  ) async {
    _reconnectTimer?.cancel();
    await chatSocketService.disconnect();
    emit(
      state.copyWith(
        clearActiveConversation: true,
        messages: const [],
        clearNextMessagesCursorUrl: true,
        isPeerTyping: false,
        socketStatus: ChatSocketConnectionStatus.disconnected,
      ),
    );
  }

  Future<void> _onLoadMoreMessages(
    LoadMoreMessagesEvent event,
    Emitter<ChatState> emit,
  ) async {
    final convId = state.activeConversationId;
    final cursorUrl = state.nextMessagesCursorUrl;

    if (convId == null ||
        cursorUrl == null ||
        cursorUrl.isEmpty ||
        state.isLoadingMoreMessages ||
        state.isLoadingMessages) {
      return;
    }

    emit(state.copyWith(isLoadingMoreMessages: true, clearActionError: true));

    try {
      final page = await chatServices.getConversationMessages(
        conversationId: convId,
        cursorUrl: cursorUrl,
      );

      final existingIds = state.messages.map((m) => m.id).toSet();
      final newUniqueMessages = page.results
          .where((m) => !existingIds.contains(m.id))
          .toList();

      emit(
        state.copyWith(
          isLoadingMoreMessages: false,
          messages: <MessageModel>[...state.messages, ...newUniqueMessages],
          nextMessagesCursorUrl: page.nextCursorUrl,
          clearNextMessagesCursorUrl: !page.hasMore,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(isLoadingMoreMessages: false, actionError: _errMsg(e)),
      );
    }
  }

  Future<void> _onCheckAppointmentChatAccess(
    CheckAppointmentChatAccessEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final access = await chatServices.getAppointmentChatAccess(
        appointmentId: event.appointmentId,
      );
      emit(
        state.copyWith(
          appointmentAccess: access,
          canSendMessage: access.canSend,
          chatLockReason: access.canSend ? null : access.reason,
          clearChatLockReason: access.canSend,
        ),
      );
    } catch (e) {
      log('[ChatBloc] CheckAppointmentChatAccess error: $e');
    }
  }

  Future<void> _onCompleteAppointmentVisit(
    CompleteAppointmentVisitEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(
      state.copyWith(
        isCompletingVisit: true,
        visitCompletedSuccess: false,
        clearActionError: true,
      ),
    );
    try {
      await chatServices.completeAppointmentVisit(
        appointmentId: event.appointmentId,
      );
      emit(
        state.copyWith(isCompletingVisit: false, visitCompletedSuccess: true),
      );
      add(CheckAppointmentChatAccessEvent(appointmentId: event.appointmentId));
    } catch (e) {
      emit(state.copyWith(isCompletingVisit: false, actionError: _errMsg(e)));
    }
  }

  // --------------------
  // Send, Delete, Seen & Typing Handlers
  // --------------------

  Future<void> _onSendChatMessage(
    SendChatMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    final convId = state.activeConversationId;
    if (convId == null || convId.isEmpty) return;

    final tempId =
        event.retryTempId ??
        'temp_${DateTime.now().microsecondsSinceEpoch}_${event.content.hashCode}';

    final optimisticMessage = MessageModel(
      id: tempId,
      senderId: _myUserId,
      type: event.type,
      content: event.content,
      fileName: event.fileName,
      isDeleted: false,
      createdAt: DateTime.now().toUtc(),
      sendStatus: MessageSendStatus.sending,
      localFilePath: event.filePath,
    );

    // درج یا بروزرسانی پیام خوش‌بینانه در ابتدای لیست (جدیدترین اول)
    final currentMessages = List<MessageModel>.from(state.messages);
    final existingTempIndex = currentMessages.indexWhere((m) => m.id == tempId);
    if (existingTempIndex != -1) {
      currentMessages[existingTempIndex] = optimisticMessage;
    } else {
      currentMessages.insert(0, optimisticMessage);
    }

    emit(state.copyWith(messages: currentMessages, clearActionError: true));

    try {
      final serverMessage = await chatServices.sendMessage(
        request: SendMessageRequest(
          conversationId: convId,
          type: event.type,
          content: event.content,
          filePath: event.filePath,
          fileName: event.fileName,
        ),
      );

      final updatedList = List<MessageModel>.from(state.messages);
      // ممکن است رویداد WebSocket (message.new) زودتر از پاسخ HTTP رسیده باشد
      final alreadyInsertedBySocket = updatedList.any(
        (m) => m.id == serverMessage.id,
      );

      if (alreadyInsertedBySocket) {
        updatedList.removeWhere((m) => m.id == tempId);
      } else {
        final tempIndex = updatedList.indexWhere((m) => m.id == tempId);
        if (tempIndex != -1) {
          updatedList[tempIndex] = serverMessage;
        } else {
          updatedList.insert(0, serverMessage);
        }
      }

      _updateInboxLastMessage(convId, serverMessage, emit, updatedList);
    } on AppException catch (e) {
      final failedList = state.messages.map((m) {
        if (m.id == tempId) {
          return m.copyWith(sendStatus: MessageSendStatus.failed);
        }
        return m;
      }).toList();

      // اگر خطای 403 (پایان زمان نوبت بیمار) برگشت، کادر ارسال قفل شود
      final isForbidden = e.code == AppErrorCode.forbidden;
      emit(
        state.copyWith(
          messages: failedList,
          canSendMessage: isForbidden ? false : state.canSendMessage,
          chatLockReason: isForbidden ? 'ended' : state.chatLockReason,
          actionError: _errMsg(e),
        ),
      );
    } catch (e) {
      final failedList = state.messages.map((m) {
        if (m.id == tempId) {
          return m.copyWith(sendStatus: MessageSendStatus.failed);
        }
        return m;
      }).toList();

      emit(state.copyWith(messages: failedList, actionError: _errMsg(e)));
    }
  }

  Future<void> _onDeleteChatMessage(
    DeleteChatMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(clearActionError: true));
    try {
      await chatServices.deleteMessage(messageId: event.messageId);

      // تبدیل آنی پیام به Tombstone در کلاینت
      final updatedMessages = state.messages.map((msg) {
        if (msg.id == event.messageId) {
          return msg.copyWith(
            isDeleted: true,
            content: '',
            attachment: null,
            fileName: null,
            fileSize: null,
            mimeType: null,
            type: ChatMessageType.text,
            deletedAt: DateTime.now().toUtc(),
          );
        }
        return msg;
      }).toList();

      emit(state.copyWith(messages: updatedMessages));
    } catch (e) {
      emit(state.copyWith(actionError: _errMsg(e)));
    }
  }

  Future<void> _onMarkLatestMessageSeen(
    MarkLatestMessageSeenEvent event,
    Emitter<ChatState> emit,
  ) async {
    final convId = state.activeConversationId;
    final messageId = event.messageId;
    if (convId == null ||
        messageId.isEmpty ||
        messageId.startsWith('temp_') ||
        _lastSentSeenMessageId == messageId) {
      return;
    }

    if (!_hasInternet) {
      _pendingOfflineSeenMessageId = messageId;
      return;
    }

    _lastSentSeenMessageId = messageId;
    _pendingOfflineSeenMessageId = null;

    // اگر سوکت وصل است رویداد message.seen را از طریق سوکت می‌فرستیم،
    // و در غیر این صورت از طریق اندپوینت REST آپدیت می‌کنیم.
    if (chatSocketService.isConnected) {
      chatSocketService.sendMessageSeen(messageId);
    } else {
      try {
        await chatServices.updateReadPointer(
          conversationId: convId,
          lastReadMessageId: messageId,
        );
      } catch (e) {
        _lastSentSeenMessageId = null;
        _pendingOfflineSeenMessageId = messageId;
      }
    }
  }

  Future<void> _onSendTypingStatus(
    SendTypingStatusEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (!_hasInternet ||
        !chatSocketService.isConnected ||
        !state.canSendMessage) {
      return;
    }
    if (event.isTyping) {
      chatSocketService.sendTypingStart();
    } else {
      chatSocketService.sendTypingStop();
    }
  }

  // --------------------
  // WebSocket & Network Handlers
  // --------------------

  Future<void> _connectSocket(
    String conversationId,
    Emitter<ChatState> emit, {
    required int attempt,
  }) async {
    final ok = await chatSocketService.connectToConversation(conversationId);
    if (emit.isDone) return;

    if (ok) {
      emit(state.copyWith(socketStatus: ChatSocketConnectionStatus.connected));

      if (_refreshHistoryOnReconnect) {
        _refreshHistoryOnReconnect = false;
        try {
          final latestPage = await chatServices.getConversationMessages(
            conversationId: conversationId,
          );
          if (!emit.isDone) {
            emit(
              state.copyWith(
                messages: latestPage.results,
                nextMessagesCursorUrl: latestPage.nextCursorUrl,
              ),
            );
          }
        } catch (_) {}
      }
    } else {
      final nextAttempt = attempt + 1;
      emit(
        state.copyWith(socketStatus: ChatSocketConnectionStatus.disconnected),
      );
      if (nextAttempt <= maxReconnectRetries && _hasInternet) {
        final delayMs =
            (baseRetryDelay.inMilliseconds * (1 << (nextAttempt - 1))).clamp(
              1000,
              30000,
            );
        _reconnectTimer?.cancel();
        _reconnectTimer = Timer(Duration(milliseconds: delayMs), () {
          if (state.activeConversationId == conversationId) {
            add(
              _RetrySocketConnectEvent(
                conversationId: conversationId,
                attempt: nextAttempt,
              ),
            );
          }
        });
      }
    }
  }

  Future<void> _onRetrySocketConnect(
    _RetrySocketConnectEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (state.activeConversationId != event.conversationId) return;
    emit(state.copyWith(socketStatus: ChatSocketConnectionStatus.reconnecting));
    await _connectSocket(event.conversationId, emit, attempt: event.attempt);
  }

  Future<void> _onSocketDisconnectedInternal(
    _SocketDisconnectedInternalEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (state.activeConversationId == null) return;

    if (event.closeCode == 4001) {
      emit(
        state.copyWith(
          socketStatus: ChatSocketConnectionStatus.authExpired,
          isPeerTyping: false,
        ),
      );
      return;
    }

    if (event.closeCode == 4003) {
      emit(
        state.copyWith(
          socketStatus: ChatSocketConnectionStatus.forbidden,
          isPeerTyping: false,
        ),
      );
      return;
    }

    _refreshHistoryOnReconnect = true;
    emit(
      state.copyWith(
        socketStatus: ChatSocketConnectionStatus.disconnected,
        isPeerTyping: false,
      ),
    );

    if (_hasInternet && state.activeConversationId != null) {
      add(
        _RetrySocketConnectEvent(
          conversationId: state.activeConversationId!,
          attempt: 1,
        ),
      );
    }
  }

  Future<void> _onSocketPacketReceived(
    _SocketPacketReceivedEvent event,
    Emitter<ChatState> emit,
  ) async {
    final packet = event.packet;
    final convId = state.activeConversationId;

    switch (packet.event) {
      case 'message.new':
        final incoming = MessageModel.fromJson(packet.data);
        final currentList = List<MessageModel>.from(state.messages);

        // جلوگیری از درج تکراری (Deduplication)
        final existingIdx = currentList.indexWhere((m) => m.id == incoming.id);
        if (existingIdx != -1) {
          currentList[existingIdx] = incoming;
        } else {
          // اگر این پیام از سمت خود کاربر است و هنوز نسخه temp_ در لیست است، جایگزین شود
          final matchingTempIdx = currentList.indexWhere(
            (m) =>
                m.id.startsWith('temp_') &&
                m.senderId == incoming.senderId &&
                m.type == incoming.type &&
                m.content == incoming.content,
          );
          if (matchingTempIdx != -1) {
            currentList[matchingTempIdx] = incoming;
          } else {
            currentList.insert(0, incoming);
          }
        }

        if (convId != null) {
          _updateInboxLastMessage(
            convId,
            incoming,
            emit,
            currentList,
            resetPeerTyping: !incoming.isMine(_myUserId),
          );
        }
        break;

      case 'message.deleted':
        final deletedMsg = MessageModel.fromJson(packet.data);
        final updatedList = state.messages.map((m) {
          if (m.id == deletedMsg.id) {
            return deletedMsg;
          }
          return m;
        }).toList();
        emit(state.copyWith(messages: updatedList));
        break;

      case 'message.seen':
        final readerId = packet.data['user_id']?.toString() ?? '';
        final lastReadMsgId =
            packet.data['last_read_message_id']?.toString() ?? '';

        if (readerId.isNotEmpty &&
            readerId != _myUserId &&
            lastReadMsgId.isNotEmpty) {
          final readMsg = state.messages
              .where((m) => m.id == lastReadMsgId)
              .firstOrNull;
          emit(
            state.copyWith(
              peerLastReadMessageId: lastReadMsgId,
              peerLastReadAt: readMsg?.createdAt ?? DateTime.now().toUtc(),
            ),
          );
        }
        break;

      case 'typing.changed':
        final typingUserId = packet.data['user_id']?.toString() ?? '';
        final isTyping = packet.data['is_typing'] == true;
        if (typingUserId.isNotEmpty && typingUserId != _myUserId) {
          emit(state.copyWith(isPeerTyping: isTyping));
        }
        break;

      case 'auth.expired':
        emit(
          state.copyWith(
            socketStatus: ChatSocketConnectionStatus.authExpired,
            isPeerTyping: false,
          ),
        );
        await chatSocketService.disconnect();
        break;
    }
  }

  void _updateInboxLastMessage(
    String conversationId,
    MessageModel message,
    Emitter<ChatState> emit,
    List<MessageModel> updatedMessages, {
    bool resetPeerTyping = false,
  }) {
    final updatedConversations = List<ConversationModel>.from(
      state.conversations,
    );
    final idx = updatedConversations.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      final updatedConv = updatedConversations[idx].copyWith(
        lastMessage: message,
        updatedAt: message.createdAt,
        unreadCount: 0,
      );
      updatedConversations.removeAt(idx);
      updatedConversations.insert(0, updatedConv);
    }

    emit(
      state.copyWith(
        messages: updatedMessages,
        conversations: updatedConversations,
        isPeerTyping: resetPeerTyping ? false : state.isPeerTyping,
      ),
    );
  }

  void _onInternetStatusChanged(bool isOnline) {
    _hasInternet = isOnline;
    if (isOnline) {
      if (_pendingOfflineSeenMessageId != null) {
        add(
          MarkLatestMessageSeenEvent(messageId: _pendingOfflineSeenMessageId!),
        );
      }
      if (state.activeConversationId != null &&
          !chatSocketService.isConnected) {
        add(
          _RetrySocketConnectEvent(
            conversationId: state.activeConversationId!,
            attempt: 1,
          ),
        );
      }
    }
  }

  String _errMsg(Object e) {
    if (e is AppException) {
      if (e.serverMessage != null && e.serverMessage!.isNotEmpty) {
        return e.serverMessage!;
      }
      return e.i18nKey.tr();
    }
    return e.toString();
  }

  @override
  Future<void> close() async {
    _reconnectTimer?.cancel();
    await _socketEventsSub?.cancel();
    await _internetSub?.cancel();
    await chatSocketService.disconnect();
    return super.close();
  }
}
