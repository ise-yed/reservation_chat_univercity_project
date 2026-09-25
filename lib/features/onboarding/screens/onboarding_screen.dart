import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reservation_chat_univercity_project/core/themes/app_colors.dart';
import 'package:reservation_chat_univercity_project/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:reservation_chat_univercity_project/features/onboarding/widgets/slide_button_widget.dart';

import '../../../core/widgets/app_cached_image.dart';
import '../../../core/widgets/global_error_section.dart';
import '../../../core/widgets/global_loading_section.dart';

class OnboardingsScreen extends StatefulWidget {
  const OnboardingsScreen({super.key});

  @override
  State<OnboardingsScreen> createState() => _OnboardingsScreenState();
}

class _OnboardingsScreenState extends State<OnboardingsScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // BlocProvider.of<OnboardingBloc>(context).add(GetOnboardingEvent());
  }

  @override
  Widget build(BuildContext context) {
    final safeH =
        MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.vertical;
    final imgH = (safeH * 0.463).clamp(250.0, 520.0);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: BlocBuilder<OnboardingBloc, OnboardingState>(
                builder: (context, state) {
                  if (state is GetOnboardingSuccess) {
                    return Padding(
                      padding: EdgeInsets.only(
                        left: 24.w,
                        right: 24.w,
                        top: 24.h,
                        bottom: 10.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: imgH,
                            child: PageView.builder(
                              controller: _controller,
                              itemCount: state.onboarding.length,
                              onPageChanged: (index) {
                                setState(() => _currentPage = index);
                              },
                              itemBuilder: (context, index) {
                                final page = state.onboarding[index];
                                return AppCachedImage(
                                  url: page.image,
                                  fit: BoxFit.fill,
                                  borderRadius: BorderRadius.circular(12.r),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 27.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              state.onboarding.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: EdgeInsets.symmetric(horizontal: 3.w),
                                width: _currentPage == index ? 19.w : 6.w,
                                height: 6.h,
                                decoration: BoxDecoration(
                                  color: _currentPage == index
                                      ? AppColors.primary500
                                      : Colors.grey,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 30.h),
                          SizedBox(
                            width: 231.w,
                            child: Text(
                              state.onboarding[_currentPage].title,
                              style: Theme.of(context).textTheme.titleMedium!
                                  .copyWith(fontSize: 23.sp),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          SizedBox(
                            width: 291.w,
                            child: Text(
                              state.onboarding[_currentPage].summary,
                              style: Theme.of(context).textTheme.bodyMedium!
                                  .copyWith(height: 1.5.h),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(height: 18.h),
                          const Spacer(),
                          SafeArea(
                            top: false,
                            minimum: EdgeInsets.only(bottom: 4.h),
                            child: const CustomSlideButton(),
                          ),
                        ],
                      ),
                    );
                  } else if (state is GetOnboardingError) {
                    return GlobalErrorSection(
                      message: state.message,
                      onRetry: () {
                        BlocProvider.of<OnboardingBloc>(context)
                            .add(GetOnboardingEvent());
                      },
                    );
                  } else {
                    return GlobalLoadingSection();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
