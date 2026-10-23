import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' as ui;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

enum ChatHeaderStatus { connected, typing, connecting, disconnected }

class ChatAppbarWidget extends StatelessWidget {
  final String title;
  final String? subtitleRole;
  final ChatHeaderStatus status;
  final bool canCompleteVisit;
  final bool isCompletingVisit;
  final VoidCallback? onCompleteVisit;
  final VoidCallback onBack;

  const ChatAppbarWidget({
    super.key,
    required this.title,
    this.subtitleRole,
    required this.status,
    this.canCompleteVisit = false,
    this.isCompletingVisit = false,
    this.onCompleteVisit,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRTL = Directionality.of(context) == ui.TextDirection.rtl;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      color: cs.shadow,
      height: 88.h,
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBack,
            child: RotatedBox(
              quarterTurns: isRTL ? 0 : 2,
              child: SvgPicture.asset(
                'assets/icons/arrow-right.svg',
                width: 24.w,
                height: 24.h,
                colorFilter: ColorFilter.mode(cs.onSurface, BlendMode.srcIn),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          CircleAvatar(
            radius: 24.r,
            backgroundColor: cs.primaryContainer,
            child: Text(
              title.isNotEmpty ? title.characters.first : '؟',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.headlineMedium!
                      .copyWith(fontSize: 13.5.sp),
                ),
                SizedBox(height: 6.h),
                _buildStatusSubtitle(context),
              ],
            ),
          ),
          if (canCompleteVisit && onCompleteVisit != null) ...[
            SizedBox(width: 8.w),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.errorContainer,
                foregroundColor: cs.onErrorContainer,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              onPressed: isCompletingVisit
                  ? null
                  : () => _confirmCompleteVisit(context),
              icon: isCompletingVisit
                  ? SizedBox(
                      width: 14.w,
                      height: 14.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.check_circle_outline, size: 16.sp),
              label: Text(
                'پایان ویزیت',
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusSubtitle(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (status) {
      case ChatHeaderStatus.typing:
        return Text(
          'در حال نوشتن...',
          style: Theme.of(context).textTheme.bodyMedium!
              .copyWith(fontSize: 12.sp, color: cs.primary),
        );
      case ChatHeaderStatus.connecting:
        return Text(
          'در حال اتصال...',
          style: Theme.of(context).textTheme.bodyMedium!
              .copyWith(fontSize: 12.sp, color: cs.primary),
        );
      case ChatHeaderStatus.disconnected:
        return Text(
          'در انتظار اتصال مجدد...',
          style: Theme.of(context).textTheme.bodyMedium!
              .copyWith(fontSize: 12.sp, color: cs.error),
        );
      case ChatHeaderStatus.connected:
        return Text(
          subtitleRole ?? 'گفت‌وگوی پزشکی',
          style: Theme.of(context).textTheme.bodyMedium!
              .copyWith(fontSize: 12.sp),
        );
    }
  }

  void _confirmCompleteVisit(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('پایان ویزیت آنلاین'),
        content: const Text(
          'آیا از خاتمه این ویزیت آنلاین اطمینان دارید؟ پس از تایید، امکان ارسال پیام توسط بیمار بسته می‌شود اما شما همچنان می‌توانید پیام یا کد نسخه ارسال کنید.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onCompleteVisit?.call();
            },
            child: const Text('تایید و پایان ویزیت'),
          ),
        ],
      ),
    );
  }
}
