import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:reservation_chat_univercity_project/core/widgets/app_cached_image.dart';
import 'package:reservation_chat_univercity_project/features/blog/service/model/blog_model.dart';
import 'package:reservation_chat_univercity_project/core/widgets/reminders_appbar_widget.dart';
// import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../../core/constants/app_constants.dart';

class SingleBlogScreen extends StatefulWidget {
  final Blog singleBlog;

  const SingleBlogScreen({super.key, required this.singleBlog});

  @override
  State<SingleBlogScreen> createState() => _SingleBlogScreenState();
}

class _SingleBlogScreenState extends State<SingleBlogScreen> {
  @override
  Widget build(BuildContext context) {
    final bool isRTL = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.shadow,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: 40.h),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RemindersAppbarWidget(
                      horizontalPadding: 0,
                      title: widget.singleBlog.title ?? '',
                      leadingIcon: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: RotatedBox(
                          quarterTurns: isRTL ? 0 : 2,
                          child: SvgPicture.asset(
                            "assets/icons/arrow-right.svg",
                            width: 24.w,
                            height: 24.h,
                            colorFilter: ColorFilter.mode(
                              Theme.of(context).colorScheme.onSurface,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 13.h),
                    SizedBox(
                      height: 258.h,
                      width: MediaQuery.of(context).size.width,
                      child: ClipRRect(
                        borderRadius: BorderRadiusGeometry.circular(17.r),
                        child: AppCachedImage(
                          url:
                              '${AppConstants.appImgBaseUrl}${widget.singleBlog.image}',
                        ),
                      ),
                    ),
                    SizedBox(height: 29.h),
                    Text(
                      widget.singleBlog.title ?? '',
                      style: Theme.of(context).textTheme.headlineMedium!
                          .copyWith(height: 1.5.h, fontSize: 17.5.sp),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                    SizedBox(height: 29.h),
                    // HtmlWidget(
                    //   """${widget.singleBlog.content}""",
                    //   textStyle: TextStyle(
                    //     color: Theme.of(context).colorScheme.secondary,
                    //     height: 1.9,
                    //     fontSize: 14.sp,
                    //   ),
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
