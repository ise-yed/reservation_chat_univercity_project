import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reservation_chat_univercity_project/features/messaging/service/models/message_model.dart';
import 'package:reservation_chat_univercity_project/features/messaging/widget/chat/file_message_widget.dart';
import 'package:reservation_chat_univercity_project/features/messaging/widget/chat/image_message_widget.dart';
import 'package:reservation_chat_univercity_project/features/messaging/widget/chat/text_message_widget.dart';
import 'package:reservation_chat_univercity_project/features/messaging/widget/chat/voice_message_widget.dart';

class MessageWidget extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final bool isSeen;
  final bool canDelete;
  final VoidCallback? onDelete;
  final VoidCallback? onRetry;

  const MessageWidget({
    super.key,
    required this.message,
    required this.isMine,
    required this.isSeen,
    this.canDelete = false,
    this.onDelete,
    this.onRetry,
  });

  Widget _buildBubbleByType(BuildContext context) {
    // نمایش پیام حذف‌شده (Tombstone)
    if (message.isDeleted) {
      final cs = Theme.of(context).colorScheme;
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.6),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block, size: 15.sp, color: cs.outline),
            SizedBox(width: 6.w),
            Text(
              'این پیام توسط پزشک حذف شده است',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final timeIso = message.createdAt.toIso8601String();

    return switch (message.type) {
      ChatMessageType.voice => VoiceMessageWidget(
        key: ValueKey(message.id),
        isMine: isMine,
        isSeen: isSeen,
        audioUrl: message.resolvedAttachmentUrl,
        time: timeIso,
      ),
      ChatMessageType.image => ImageMessageWidget(
        isMine: isMine,
        isSeen: isSeen,
        imageUrl: message.resolvedAttachmentUrl,
        localFilePath: message.localFilePath,
        time: timeIso,
      ),
      ChatMessageType.document => FileMessageWidget(
        isMine: isMine,
        isSeen: isSeen,
        message: message,
      ),
      ChatMessageType.text => TextMessageWidget(
        isMine: isMine,
        seen: isSeen,
        messageText: message.content,
        time: timeIso,
      ),
    };
  }

  void _showDoctorDeleteSheet(BuildContext context) {
    if (!canDelete || onDelete == null) return;
    showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'حذف پیام (مخصوص پزشک)',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onDelete?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bubble = GestureDetector(
      onLongPress: canDelete ? () => _showDoctorDeleteSheet(context) : null,
      child: _buildBubbleByType(context),
    );

    Widget? statusIndicator;
    if (message.sendStatus == MessageSendStatus.sending) {
      statusIndicator = SizedBox(
        width: 16.w,
        height: 16.w,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (message.sendStatus == MessageSendStatus.failed) {
      statusIndicator = GestureDetector(
        onTap: onRetry,
        child: Icon(
          Icons.error_outline,
          color: Theme.of(context).colorScheme.error,
          size: 20.w,
        ),
      );
    }

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: 14.h,
          right: isMine ? 24.w : 72.w,
          left: isMine ? 72.w : 24.w,
        ),
        child: statusIndicator == null
            ? bubble
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: isMine
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: isMine
                    ? [
                        Flexible(child: bubble),
                        SizedBox(width: 6.w),
                        statusIndicator,
                      ]
                    : [
                        statusIndicator,
                        SizedBox(width: 6.w),
                        Flexible(child: bubble),
                      ],
              ),
      ),
    );
  }
}
