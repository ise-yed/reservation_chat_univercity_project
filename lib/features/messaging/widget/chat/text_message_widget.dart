import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:reservation_chat_univercity_project/core/themes/app_colors.dart';
import 'package:reservation_chat_univercity_project/core/widgets/format_reminder_date.dart';

class TextMessageWidget extends StatelessWidget {
  final bool seen;
  final String messageText;
  final bool isMine;
  final String time;

  const TextMessageWidget({
    super.key,
    required this.isMine,
    required this.messageText,
    required this.time,
    this.seen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isMine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18.r),
              topRight: Radius.circular(isMine ? 5.r : 18.r),
              bottomRight: Radius.circular(18.r),
              bottomLeft: Radius.circular(isMine ? 18.r : 5.r),
            ),
            color: isMine
                ? Theme.of(context).colorScheme.shadow
                : AppColors.primary400,
          ),
          child: Text(
            messageText,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              height: 1.5.h,
              fontWeight: FontWeight.w500,
              color: isMine
                  ? Theme.of(context).colorScheme.onSurface
                  : AppColors.text700Dark,
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: isMine
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            if (isMine) ...[
              SvgPicture.asset(
                seen ? 'assets/icons/seen.svg' : 'assets/icons/seen_one.svg',
                width: 20.w,
                height: 20.h,
                colorFilter: ColorFilter.mode(
                  seen ? AppColors.primary400 : AppColors.text500Light,
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(width: 4.w),
            ],
            Text(
              formatReminderDateTime(time)['time'] ?? '',
              style: Theme.of(context).textTheme.bodyMedium!
                  .copyWith(fontSize: 11.25.sp),
            ),
          ],
        ),
      ],
    );
  }
}
