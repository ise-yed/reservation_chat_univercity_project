import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:reservation_chat_univercity_project/core/themes/app_colors.dart';
import 'package:reservation_chat_univercity_project/core/widgets/format_reminder_date.dart';
import 'package:reservation_chat_univercity_project/features/profile/model/notification_model.dart';

enum NofificationState { success, failed, progress }

class NotificationsItemWidget extends StatelessWidget {
  final bool isActive;
  final NotificationDoc notificationdata;
  const NotificationsItemWidget({
    super.key,
    required this.isActive,
    required this.notificationdata,
  });

  Widget setNotifState(String type, BuildContext context) {
    switch (type) {
      case "reminder":
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.green2,
          ),
          height: 55.r,
          width: 55.r,

          child: Center(
            child: SvgPicture.asset(
              "assets/icons/calling.svg",
              width: 24.w,
              height: 24.h,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.onSurface,
                BlendMode.srcIn,
              ),
            ),
          ),
        );

      case "message":
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.red,
          ),
          height: 55.r,
          width: 55.r,

          child: Center(
            child: SvgPicture.asset(
              "assets/icons/description.svg",
              width: 24.w,
              height: 24.h,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.onSurface,
                BlendMode.srcIn,
              ),
            ),
          ),
        );
      case "ticket":
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.yellow,
          ),
          height: 55.r,
          width: 55.r,

          child: Center(
            child: SvgPicture.asset(
              "assets/icons/description.svg",
              width: 24.w,
              height: 24.h,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.onSurface,
                BlendMode.srcIn,
              ),
            ),
          ),
        );
      case "handover":
        return Container(
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue),
          height: 55.r,
          width: 55.r,

          child: Center(
            child: SvgPicture.asset(
              "assets/icons/heart_fill.svg",
              width: 24.w,
              height: 24.h,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.onSurface,
                BlendMode.srcIn,
              ),
            ),
          ),
        );

      default:
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.deepPurpleAccent,
          ),
          height: 55.r,
          width: 55.r,

          child: Center(
            child: SvgPicture.asset(
              "assets/icons/StarFour.svg",
              width: 24.w,
              height: 24.h,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.onSurface,
                BlendMode.srcIn,
              ),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 24.w, right: 24.w, bottom: 10.h),
      // height: 133.h,
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.shadow,
        borderRadius: BorderRadius.circular(25.r),
      ),
      child: Row(
        children: [
          setNotifState(notificationdata.type, context),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notificationdata.title,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(),
                ),
                SizedBox(height: 12.h),
                Text(
                  notificationdata.message,
                  style: Theme.of(context).textTheme.bodyMedium!
                      .copyWith(fontSize: 12.75.sp),
                ),
                SizedBox(height: 12.h),
                Text(
                  formatReminderDateTime(
                    notificationdata.createdAt.toString(),
                  )['date']!,

                  style: Theme.of(context).textTheme.bodyMedium!
                      .copyWith(fontSize: 12.75.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
