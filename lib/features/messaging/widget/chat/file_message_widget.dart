import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:reservation_chat_univercity_project/core/themes/app_colors.dart';
import 'package:reservation_chat_univercity_project/core/widgets/format_reminder_date.dart';
import 'package:reservation_chat_univercity_project/features/messaging/service/models/message_model.dart';
import 'package:url_launcher/url_launcher.dart';

class FileMessageWidget extends StatelessWidget {
  final bool isMine;
  final bool isSeen;
  final MessageModel message;

  const FileMessageWidget({
    super.key,
    required this.isMine,
    required this.message,
    this.isSeen = false,
  });

  Future<void> _openOrDownloadFile() async {
    final fullUrl = message.resolvedAttachmentUrl;
    if (fullUrl.isEmpty) return;
    final uri = Uri.tryParse(fullUrl);
    if (uri == null) return;

    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      }
    } catch (_) {}
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final displayFileName =
        (message.fileName != null && message.fileName!.isNotEmpty)
        ? message.fileName!
        : 'فایل پیوست (PDF)';
    final sizeLabel = _formatFileSize(message.fileSize);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openOrDownloadFile,
      child: Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            height: 74.h,
            padding: EdgeInsetsDirectional.only(start: 16.w),
            decoration: BoxDecoration(
              color: isMine
                  ? Theme.of(context).colorScheme.shadow
                  : AppColors.primary400,
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayFileName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.titleMedium!
                            .copyWith(
                              fontWeight: FontWeight.w500,
                              color: isMine
                                  ? Theme.of(context).colorScheme.onSurface
                                  : AppColors.text700Dark,
                            ),
                      ),
                      if (sizeLabel.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          sizeLabel,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontSize: 10.sp,
                                color: isMine
                                    ? Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                    : AppColors.text700Dark.withOpacity(0.8),
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  height: 74.h,
                  width: 72.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18.r),
                    color: isMine
                        ? AppColors.primary400
                        : AppColors.text700Dark,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/description.svg',
                      width: 24.w,
                      height: 24.h,
                      colorFilter: ColorFilter.mode(
                        isMine ? AppColors.text700Dark : AppColors.primary400,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMine) ...[
                SvgPicture.asset(
                  isSeen
                      ? 'assets/icons/seen.svg'
                      : 'assets/icons/seen_one.svg',
                  width: 20.w,
                  height: 20.h,
                  colorFilter: ColorFilter.mode(
                    isSeen ? AppColors.primary400 : AppColors.text500Light,
                    BlendMode.srcIn,
                  ),
                ),
                SizedBox(width: 4.w),
              ],
              Text(
                formatReminderDateTime(
                      message.createdAt.toIso8601String(),
                    )['time'] ??
                    '',
                style: Theme.of(context).textTheme.bodyMedium!
                    .copyWith(fontSize: 11.25.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
