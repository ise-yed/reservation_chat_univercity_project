import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:reservation_chat_univercity_project/core/constants/app_constants.dart';
import 'package:reservation_chat_univercity_project/core/constants/app_setting.dart';
import 'package:reservation_chat_univercity_project/core/themes/app_colors.dart';
import 'package:reservation_chat_univercity_project/core/utils/navigator.dart';
import 'package:reservation_chat_univercity_project/features/auth/screens/register_screen.dart';
import 'package:reservation_chat_univercity_project/features/onboarding/widgets/slide_button_widget.dart';

class OnboardingItem {
  final String image;
  final String title;
  final String summary;

  const OnboardingItem({
    required this.image,
    required this.title,
    required this.summary,
  });
}

class OnboardingsScreen extends StatefulWidget {
  const OnboardingsScreen({super.key});

  @override
  State<OnboardingsScreen> createState() => _OnboardingsScreenState();
}

class _OnboardingsScreenState extends State<OnboardingsScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _slides = const [
    OnboardingItem(
      image: 'assets/icons/onboarding1.svg',
      title: 'نوبت‌دهی آنلاین و حضوری',
      summary: 'رزرو آنی نوبت حضوری و آنلاین از برترین پزشکان متخصص، در کمترین زمان',
    ),
    OnboardingItem(
      image: 'assets/icons/onboarding2.svg',
      title: 'مشاوره آنلاین و تخصصی',
      summary: 'ارتباط مستقیم با پزشکان مجرب، دریافت مشاوره تخصصی و ارسال مدارک پزشکی در محیطی امن',
    ),
    OnboardingItem(
      image: 'assets/icons/onboarding3.svg',
      title: 'یادآوری و مدیریت نوبت‌ها',
      summary: 'پیگیری دقیق زمان ویزیت و یادآوری هوشمند نوبت‌ها برای حفظ سلامتی شما',
    ),
  ];

  void _finishOnboarding() {
    prefs.setBool(AppConstants.isOnboardingSeen, true);
    goScreen(
      context: context,
      screen: const RegisterScreen(),
      closeAllScreen: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safeH = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.vertical;
    final imgH = (safeH * 0.44).clamp(240.0, 480.0);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          child: Column(
            children: [
              // Top Bar with Skip Button
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _finishOnboarding,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  ),
                  child: Text(
                    'skip'.tr().isNotEmpty && 'skip'.tr() != 'skip'
                        ? 'skip'.tr()
                        : 'رد شدن',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),

              // SVG Illustration Carousel
              SizedBox(
                height: imgH,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 8.w),
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF132228)
                            : const Color(0xFFF1F8F9),
                        borderRadius: BorderRadius.circular(24.r),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF1E353E)
                              : const Color(0xFFE2EFF2),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          slide.image,
                          width: 220.w,
                          height: 220.h,
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 24.h),

              // Dot Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    width: _currentPage == index ? 22.w : 7.w,
                    height: 7.h,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppColors.primary500
                          : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 28.h),

              // Title
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: SizedBox(
                  key: ValueKey('title_$_currentPage'),
                  width: 300.w,
                  child: Text(
                    _slides[_currentPage].title,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: 14.h),

              // Summary / Description
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: SizedBox(
                  key: ValueKey('summary_$_currentPage'),
                  width: 320.w,
                  child: Text(
                    _slides[_currentPage].summary,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          height: 1.6,
                          fontSize: 14.sp,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              const Spacer(),

              // Slide Button to Start
              const SafeArea(
                top: false,
                minimum: EdgeInsets.only(bottom: 6),
                child: CustomSlideButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
