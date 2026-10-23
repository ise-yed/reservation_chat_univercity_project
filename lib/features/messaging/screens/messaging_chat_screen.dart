import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reservation_chat_univercity_project/core/constants/app_setting.dart';
import 'package:reservation_chat_univercity_project/core/utils/snakbar.dart';
import 'package:reservation_chat_univercity_project/core/widgets/global_error_section.dart';
import 'package:reservation_chat_univercity_project/core/widgets/global_loading_section.dart';
import 'package:reservation_chat_univercity_project/features/messaging/bloc/chat_bloc.dart';

import 'package:reservation_chat_univercity_project/features/messaging/service/models/conversation_model.dart';
import 'package:reservation_chat_univercity_project/features/messaging/service/models/message_model.dart';
import 'package:reservation_chat_univercity_project/features/messaging/widget/chat/chat_appbar_widget.dart';
import 'package:reservation_chat_univercity_project/features/messaging/widget/chat/chat_bottom_section_widget.dart';
import 'package:reservation_chat_univercity_project/features/messaging/widget/chat/message_widget.dart';
import 'package:reservation_chat_univercity_project/features/profile/utils/format_chat_time_utils.dart';
import 'package:toastification/toastification.dart';

class MessagingChatScreen extends StatefulWidget {
  final String conversationId;
  final ConversationModel? initialConversation;
  final String? appointmentId;
  final VoidCallback? onBookNewAppointmentTap;

  const MessagingChatScreen({
    super.key,
    required this.conversationId,
    this.initialConversation,
    this.appointmentId,
    this.onBookNewAppointmentTap,
  });

  @override
  State<MessagingChatScreen> createState() => _MessagingChatScreenState();
}

class _MessagingChatScreenState extends State<MessagingChatScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  late final ChatBloc _chatBloc;
  bool _isForeground = true;

  String get _myUserId => (currentUserModel.id ?? '').toString();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chatBloc = context.read<ChatBloc>();

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatBloc.add(
        EnterConversationEvent(
          conversationId: widget.conversationId,
          initialConversation: widget.initialConversation,
          appointmentId: widget.appointmentId,
        ),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _chatBloc.add(const LeaveConversationEvent());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = state == AppLifecycleState.resumed;
    if (_isForeground) {
      _markNewestIncomingMessageSeen(_chatBloc.state.messages);
    }
    super.didChangeAppLifecycleState(state);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 200) {
      _chatBloc.add(const LoadMoreMessagesEvent());
    }
  }

  /// ارسال نشانگر خوانده‌شدن (Watermark) فقط برای جدیدترین پیامِ دریافتی از طرف مقابل
  void _markNewestIncomingMessageSeen(List<MessageModel> messages) {
    if (!_isForeground || messages.isEmpty) return;

    for (final msg in messages) {
      if (!msg.isMine(_myUserId) && !msg.id.startsWith('temp_')) {
        _chatBloc.add(MarkLatestMessageSeenEvent(messageId: msg.id));
        break;
      }
    }
  }

  ChatHeaderStatus _resolveHeaderStatus(ChatState state) {
    if (state.isPeerTyping) return ChatHeaderStatus.typing;
    return switch (state.socketStatus) {
      ChatSocketConnectionStatus.connected => ChatHeaderStatus.connected,
      ChatSocketConnectionStatus.connecting ||
      ChatSocketConnectionStatus.reconnecting => ChatHeaderStatus.connecting,
      ChatSocketConnectionStatus.authExpired ||
      ChatSocketConnectionStatus.forbidden ||
      ChatSocketConnectionStatus.disconnected ||
      ChatSocketConnectionStatus.initial => ChatHeaderStatus.disconnected,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: BlocConsumer<ChatBloc, ChatState>(
          listener: (context, state) {
            if (state.messages.isNotEmpty) {
              _markNewestIncomingMessageSeen(state.messages);
            }

            if (state.actionError != null && state.actionError!.isNotEmpty) {
              showCustomSnackBar(
                context: context,
                title: 'خطا',
                content: state.actionError!,
                status: ToastificationType.error,
              );
            }

            if (state.visitCompletedSuccess) {
              showCustomSnackBar(
                context: context,
                title: 'پایان ویزیت',
                content: 'ویزیت آنلاین با موفقیت خاتمه یافت و چت بیمار قفل شد.',
                status: ToastificationType.success,
              );
            }
          },
          builder: (context, state) {
            final conv = state.activeConversation ?? widget.initialConversation;
            final peer = conv?.getPeerUser(_myUserId);
            final isDoctor = conv?.isCurrentUserProvider(_myUserId) ?? false;

            return Column(
              children: [
                ChatAppbarWidget(
                  title: peer?.displayName ?? 'گفت‌وگو',
                  subtitleRole: peer?.isProvider == true ? 'پزشک' : 'بیمار',
                  status: _resolveHeaderStatus(state),
                  canCompleteVisit:
                      isDoctor &&
                      widget.appointmentId != null &&
                      (state.appointmentAccess?.reason == 'active' ||
                          state.appointmentAccess == null),
                  isCompletingVisit: state.isCompletingVisit,
                  onCompleteVisit: widget.appointmentId != null
                      ? () {
                          _chatBloc.add(
                            CompleteAppointmentVisitEvent(
                              appointmentId: widget.appointmentId!,
                            ),
                          );
                        }
                      : null,
                  onBack: () => Navigator.pop(context),
                ),
                Expanded(child: _buildMessagesList(context, state, isDoctor)),
                ChatBottomSectionChat(
                  conversationId: widget.conversationId,
                  isSendingAllowed: isDoctor ? true : state.canSendMessage,
                  lockReason: state.chatLockReason,
                  onBookNewAppointmentTap: widget.onBookNewAppointmentTap,
                  onSendText: (text) {
                    _chatBloc.add(
                      SendChatMessageEvent(
                        type: ChatMessageType.text,
                        content: text,
                      ),
                    );
                  },
                  onSendImageFile: (filePath, fileName) {
                    _chatBloc.add(
                      SendChatMessageEvent(
                        type: ChatMessageType.image,
                        filePath: filePath,
                        fileName: fileName,
                      ),
                    );
                  },
                  onSendDocumentFile: (filePath, fileName) {
                    _chatBloc.add(
                      SendChatMessageEvent(
                        type: ChatMessageType.document,
                        filePath: filePath,
                        fileName: fileName,
                      ),
                    );
                  },
                  onSendVoiceFile: (filePath, fileName) {
                    _chatBloc.add(
                      SendChatMessageEvent(
                        type: ChatMessageType.voice,
                        filePath: filePath,
                        fileName: fileName,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMessagesList(
    BuildContext context,
    ChatState state,
    bool isDoctor,
  ) {
    if (state.isLoadingMessages && state.messages.isEmpty) {
      return GlobalLoadingSection();
    }

    if (state.messagesError != null && state.messages.isEmpty) {
      return GlobalErrorSection(
        message: state.messagesError!,
        onRetry: () {
          _chatBloc.add(
            EnterConversationEvent(
              conversationId: widget.conversationId,
              initialConversation: widget.initialConversation,
              appointmentId: widget.appointmentId,
            ),
          );
        },
      );
    }

    if (state.messages.isEmpty) {
      return Center(
        child: Text(
          'هنوز پیامی در این گفت‌وگو ارسال نشده است.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final messages = state.messages;

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      itemCount: messages.length + (state.isLoadingMoreMessages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final currentMessage = messages[index];
        final currentLocal = currentMessage.createdAt.toLocal();
        final currentDateOnly = DateTime(
          currentLocal.year,
          currentLocal.month,
          currentLocal.day,
        );

        DateTime? previousDateOnly;
        if (index < messages.length - 1) {
          final prevLocal = messages[index + 1].createdAt.toLocal();
          previousDateOnly = DateTime(
            prevLocal.year,
            prevLocal.month,
            prevLocal.day,
          );
        }

        final showDayHeader = previousDateOnly != currentDateOnly;
        final currentIsMine = currentMessage.isMine(_myUserId);
        final previousIsMine =
            index > 0 && messages[index - 1].isMine(_myUserId);

        final isSeenByPeer = state.isMessageSeenByPeer(
          currentMessage,
          _myUserId,
        );

        return Column(
          children: [
            if (showDayHeader)
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 12.h,
                  ),
                  child: Text(
                    formatDayHeader(currentMessage.createdAt.toIso8601String()),
                    style: Theme.of(context).textTheme.bodyMedium!
                        .copyWith(fontSize: 11.25.sp),
                  ),
                ),
              ),
            Padding(
              padding: index > 0 && currentIsMine != previousIsMine
                  ? EdgeInsets.only(bottom: 14.h)
                  : EdgeInsets.zero,
              child: MessageWidget(
                key: ValueKey(currentMessage.id),
                message: currentMessage,
                isMine: currentIsMine,
                isSeen: isSeenByPeer,
                canDelete: isDoctor && !currentMessage.isDeleted,
                onDelete: isDoctor && !currentMessage.isDeleted
                    ? () {
                        _chatBloc.add(
                          DeleteChatMessageEvent(messageId: currentMessage.id),
                        );
                      }
                    : null,
                onRetry: currentMessage.sendStatus == MessageSendStatus.failed
                    ? () {
                        _chatBloc.add(
                          SendChatMessageEvent(
                            type: currentMessage.type,
                            content: currentMessage.content,
                            filePath: currentMessage.localFilePath,
                            fileName: currentMessage.fileName,
                            retryTempId: currentMessage.id,
                          ),
                        );
                      }
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }
}
