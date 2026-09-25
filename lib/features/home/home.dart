import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' as ui;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:reservation_chat_univercity_project/core/constants/app_constants.dart';
import 'package:reservation_chat_univercity_project/core/constants/app_setting.dart';
import 'package:reservation_chat_univercity_project/core/themes/app_colors.dart';
import 'package:reservation_chat_univercity_project/core/utils/navigator.dart';
import 'package:reservation_chat_univercity_project/core/widgets/app_cached_image.dart';
import 'package:reservation_chat_univercity_project/features/home/bloc/home_bloc.dart';
import 'package:reservation_chat_univercity_project/features/home/widgets/home_ads_carousel.dart';
import 'package:reservation_chat_univercity_project/features/home/widgets/home_around_you_banner_widget.dart';
import 'package:reservation_chat_univercity_project/features/home/widgets/home_chat_banner_widget.dart';

import 'package:reservation_chat_univercity_project/features/profile/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    context.read<HomeBloc>().add(GetAdsEvent());
    context.read<HomeBloc>().add(GetPartnersEvent());
  }

  void Function()? bannerFunc;

  @override
  Widget build(BuildContext context) {
    final bool isRTL = Directionality.of(context) == ui.TextDirection.rtl;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 26.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: SizedBox(
                  height: 48.h,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => goScreen(
                            context: context,
                            screen: ProfileScreen(),
                          ),
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            children: [
                              Container(
                                height: 48.r,
                                width: 48.r,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: ClipOval(
                                  child: AppCachedImage(
                                    url:
                                        "${AppConstants.appImgBaseUrl}${currentUserModel.avatar ?? ""}",
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                currentUserModel.petName ?? "",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium!
                                    .copyWith(fontSize: 15.25.sp),
                              ),
                            ],
                          ),
                        ),
                      ),

                      Expanded(
                        child: GestureDetector(
                          onTap: () {},
                          child: Container(
                            height: 41.h,
                            padding: EdgeInsets.symmetric(horizontal: 13.w),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.shadow,
                              borderRadius: BorderRadius.all(
                                Radius.circular(50),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    "  getSubscriptionStatusText()",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SvgPicture.asset(
                                  "assets/icons/direction-down 2.svg",
                                  height: 20.h,
                                  width: 20.w,
                                  colorFilter: ColorFilter.mode(
                                    Theme.of(context).colorScheme.onSurface,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                // const Icon(
                                //   Icons.keyboard_arrow_down_rounded,
                                //   size: 22,
                                // ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 25.w),
                      GestureDetector(
                        onTap: () async {},
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50.r),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          height: 41.h,
                          padding: EdgeInsets.symmetric(horizontal: 10.w),

                          width: isRTL ? 102.w : 130.w,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                "assets/icons/heart.svg",
                                height: 18.h,
                                width: 18.w,
                                colorFilter: ColorFilter.mode(
                                  Theme.of(context).colorScheme.onPrimary,
                                  BlendMode.srcIn,
                                ),
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                "collabration".tr(),
                                style: Theme.of(context).textTheme.bodySmall!
                                    .copyWith(
                                      color: AppColors.text700Dark,
                                      // fontSize: 5.75.sp,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 48.h),

              // !ads banner section
              SizedBox(height: 34.h),

              // ! around you shops section
              HomeAroundYouShopBannerWidget(isRTL: isRTL),
              SizedBox(height: 34.h),
              // ! ads groups section
              SizedBox(height: 120.h),
            ],
          ),
        ),
      ),
    );
  }
}
