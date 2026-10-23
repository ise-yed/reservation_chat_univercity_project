import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

class MessagingEmptyStateWidget extends StatelessWidget {
  const MessagingEmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/chat_2.svg',
              height: 72.h,
              width: 72.w,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.onTertiary,
                BlendMode.srcIn,
              ),
            ),
            SizedBox(height: 32.h),
            Text(
              'گفت‌وگویی یافت نشد',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 12.h),
            Text(
              'گفت‌وگوی شما با پزشک پس از رزرو و تأیید اولین نوبت ویزیت آنلاین به صورت خودکار در این بخش ایجاد می‌شود.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium!
                  .copyWith(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
