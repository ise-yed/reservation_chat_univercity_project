import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reservation_chat_univercity_project/core/constants/app_setting.dart';
import 'package:reservation_chat_univercity_project/core/themes/app_colors.dart';
import 'package:reservation_chat_univercity_project/core/utils/navigator.dart';
import 'package:reservation_chat_univercity_project/core/widgets/app_cached_image.dart';
import 'package:reservation_chat_univercity_project/features/profile/screens/notification_screen.dart';

/// نقش نمایشی صفحه (بیمار یا پزشک)
enum AppointmentViewRole { patient, doctor }

/// تب‌های وضعیت نوبت
enum AppointmentFilterTab { upcoming, completed, cancelled }

/// نوع ویزیت مطابق بک‌اند جنگو (apps/offerings/enums.py)
enum AppointmentVisitMode {
  inPerson('in_person'),
  onlineChat('online_chat');

  final String value;
  const AppointmentVisitMode(this.value);
}

/// وضعیت نوبت مطابق بک‌اند جنگو (apps/appointments/enums.py)
enum AppointmentStatusType {
  pending('pending'),
  confirmed('confirmed'),
  completed('completed'),
  cancelledByCustomer('cancelled_by_customer'),
  cancelledByProvider('cancelled_by_provider');

  final String value;
  const AppointmentStatusType(this.value);
}

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  AppointmentViewRole _currentRole = AppointmentViewRole.patient;
  AppointmentFilterTab _currentTab = AppointmentFilterTab.upcoming;
  late final AnimationController _pulseController;

  // لیست نمونه نوبت‌های بیمار (معادل پاسخ GET /api/v1/appointments/my/)
  final List<_AppointmentItemModel> _patientAppointments = [
    _AppointmentItemModel(
      id: 'DRM-8492',
      counterpartName: 'دکتر علیرضا رادمنش',
      counterpartSubtitle: 'فوق تخصص بیماری‌های قلب و عروق',
      avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBvpZ_vboIDyEPGzaUNxfTYRZ_jibLqgSreBTJldnpDHPZmAs5n_J_qaFIHt-fmwzrw3wdyulY-gq1_Y-0v0sH-uk4CEf6OCK8sancGyH4yqWzgVSzvmxAoc95w5xDfQSQBZqKbR6PkU01yT5lEIVyrHmpxqzieFqxOhxHpyAfVk0PWcdYNMRVOpHOnRZm7lrqZmuwV-75vE4mdxEiSK8UwZiq3RM7UyjOPxEwBU-DrvajgL2StBRdq',
      visitMode: AppointmentVisitMode.onlineChat,
      status: AppointmentStatusType.confirmed,
      jalaliDateText: 'امروز، ۲۵ مهر ۱۴۰۵',
      timeRangeText: '۱۶:۳۰ الی ۱۷:۱۵',
      isCurrentlyInProgress: true, // در بازه start_at <= now < end_at قرار دارد
      hasStarted: true,
      conversationId: 'conv-101',
      priceText: '۱۹۰,۰۰۰ تومان',
      notes: 'تپش قلب و سابقه افت فشار خون',
    ),
    _AppointmentItemModel(
      id: 'DRM-5531',
      counterpartName: 'دکتر مریم کاظمی',
      counterpartSubtitle: 'متخصص پوست، مو و زیبایی',
      avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCHgNQkO27RC_GyQick4qbpIIBhxrC5MX3j01_KSLE7DwGY6G6zRWgb3Mz2b7Gl6s-rGahAY25gQT75x__1vcnUeHm9Vgs69gwh0CgLCgG4IgneK-OQPw-ntWvWOK6I8tmYN6CVqBGq5Ms74wCGIve1EAe3xI1R3UoYNDZrMpwU-KxTSAUJDRX7tAN6m249P6h7zJ5gMTRR9G30kK6Cw8dCdQ9UqJuK2sKyiD6lWnGC7cVZf_i3RFAg',
      visitMode: AppointmentVisitMode.inPerson,
      status: AppointmentStatusType.confirmed,
      jalaliDateText: 'دوشنبه، ۲۷ مهر ۱۴۰۵',
      timeRangeText: '۱۸:۳۰ الی ۱۹:۰۰',
      isCurrentlyInProgress: false,
      hasStarted: false, // هنوز شروع نشده، پس بیمار می‌تواند لغو کند
      clinicAddress: 'تهران، میدان ونک، خیابان ولیعصر، برج نگار، طبقه ۵',
      priceText: '۲۸۰,۰۰۰ تومان',
    ),
    _AppointmentItemModel(
      id: 'DRM-3104',
      counterpartName: 'دکتر علیرضا رادمنش',
      counterpartSubtitle: 'فوق تخصص بیماری‌های قلب و عروق',
      avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBvpZ_vboIDyEPGzaUNxfTYRZ_jibLqgSreBTJldnpDHPZmAs5n_J_qaFIHt-fmwzrw3wdyulY-gq1_Y-0v0sH-uk4CEf6OCK8sancGyH4yqWzgVSzvmxAoc95w5xDfQSQBZqKbR6PkU01yT5lEIVyrHmpxqzieFqxOhxHpyAfVk0PWcdYNMRVOpHOnRZm7lrqZmuwV-75vE4mdxEiSK8UwZiq3RM7UyjOPxEwBU-DrvajgL2StBRdq',
      visitMode: AppointmentVisitMode.onlineChat,
      status: AppointmentStatusType.completed,
      jalaliDateText: '۱۰ مهر ۱۴۰۵',
      timeRangeText: '۱۷:۰۰ الی ۱۷:۳۰',
      isCurrentlyInProgress: false,
      hasStarted: true,
      conversationId: 'conv-101',
      priceText: '۱۹۰,۰۰۰ تومان',
      notes: 'بررسی اولیه نوار قلب و تجویز آزمایش خون',
    ),
    _AppointmentItemModel(
      id: 'DRM-1920',
      counterpartName: 'دکتر کامران بهرامی',
      counterpartSubtitle: 'جراح مغز و اعصاب و ستون فقرات',
      visitMode: AppointmentVisitMode.inPerson,
      status: AppointmentStatusType.cancelledByCustomer,
      jalaliDateText: '۲ مهر ۱۴۰۵',
      timeRangeText: '۱۶:۱۵ الی ۱۶:۴۵',
      isCurrentlyInProgress: false,
      hasStarted: true,
      cancelReason: 'تداخل با سفر کاری',
      priceText: '۳۲۰,۰۰۰ تومان',
    ),
  ];

  // لیست نمونه نوبت‌های پزشک (معادل پاسخ GET /api/v1/appointments/providers/{provider_id}/)
  final List<_AppointmentItemModel> _doctorAppointments = [
    _AppointmentItemModel(
      id: 'PT-1042',
      counterpartName: 'سارا احمدی',
      counterpartSubtitle: 'بیمار • پرونده فعال',
      visitMode: AppointmentVisitMode.onlineChat,
      status: AppointmentStatusType.confirmed,
      jalaliDateText: 'امروز، ۲۵ مهر ۱۴۰۵',
      timeRangeText: '۱۶:۳۰ الی ۱۷:۱۵',
      isCurrentlyInProgress:
          true, // نوبت آنلاین در جریان (امکان خاتمه دستی توسط پزشک)
      hasStarted: true,
      conversationId: 'conv-101',
      notes: 'علائم: تپش قلب و سابقه افت فشار خون از هفته گذشته',
      priceText: '۱۹۰,۰۰۰ تومان',
    ),
    _AppointmentItemModel(
      id: 'PT-1089',
      counterpartName: 'محمد کریمی',
      counterpartSubtitle: 'بیمار • نوبت بعدی امروز',
      visitMode: AppointmentVisitMode.onlineChat,
      status: AppointmentStatusType.confirmed,
      jalaliDateText: 'امروز، ۲۵ مهر ۱۴۰۵',
      timeRangeText: '۱۷:۳۰ الی ۱۸:۰۰',
      isCurrentlyInProgress: false,
      hasStarted: false, // هنوز شروع نشده
      conversationId: 'conv-102',
      notes: 'ارسال جواب آزمایش چربی و قند خون جهت بررسی مجدد',
      priceText: '۱۹۰,۰۰۰ تومان',
    ),
    _AppointmentItemModel(
      id: 'PT-1105',
      counterpartName: 'زهرا محمدی',
      counterpartSubtitle: 'بیمار • مراجعه اول',
      visitMode: AppointmentVisitMode.inPerson,
      status: AppointmentStatusType.pending,
      jalaliDateText: 'فردا، ۲۶ مهر ۱۴۰۵',
      timeRangeText: '۱۸:۰۰ الی ۱۸:۳۰',
      isCurrentlyInProgress: false,
      hasStarted: false,
      clinicAddress: 'شعبه ونک - اتاق معاینه ۲',
      notes: 'درد قفسه سینه هنگام فعالیت ورزشی',
      priceText: '۲۸۰,۰۰۰ تومان',
    ),
    _AppointmentItemModel(
      id: 'PT-0988',
      counterpartName: 'رضا رضایی',
      counterpartSubtitle: 'بیمار • ویزیت تکمیل‌شده',
      visitMode: AppointmentVisitMode.onlineChat,
      status: AppointmentStatusType.completed,
      jalaliDateText: '۲۳ مهر ۱۴۰۵',
      timeRangeText: '۱۹:۰۰ الی ۱۹:۳۰',
      isCurrentlyInProgress: false,
      hasStarted: true,
      conversationId: 'conv-103',
      notes: 'تنظیم دوز داروی فشار خون',
      priceText: '۱۹۰,۰۰۰ تومان',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // اگر کاربر لاگین‌شده در سیستم نقش provider داشته باشد، پیش‌فرض روی نمای پزشک برود
    if (currentUserModel.role == 'provider') {
      _currentRole = AppointmentViewRole.doctor;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  List<_AppointmentItemModel> get _activeRoleList =>
      _currentRole == AppointmentViewRole.patient
      ? _patientAppointments
      : _doctorAppointments;

  List<_AppointmentItemModel> _getFilteredAppointments(
    AppointmentFilterTab tab,
  ) {
    return _activeRoleList.where((item) {
      switch (tab) {
        case AppointmentFilterTab.upcoming:
          return item.status == AppointmentStatusType.confirmed ||
              item.status == AppointmentStatusType.pending;
        case AppointmentFilterTab.completed:
          return item.status == AppointmentStatusType.completed;
        case AppointmentFilterTab.cancelled:
          return item.status == AppointmentStatusType.cancelledByCustomer ||
              item.status == AppointmentStatusType.cancelledByProvider;
      }
    }).toList();
  }

  String _toPersianDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    String output = input;
    for (int i = 0; i < english.length; i++) {
      output = output.replaceAll(english[i], persian[i]);
    }
    return output;
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _getFilteredAppointments(_currentTab);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            // هدر بالای صفحه
            _buildTopHeader(context),

            // بدنه اصلی
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // سوییچر تغییر نمای بیمار / نمای پزشک
                    _buildRoleSwitcher(context),
                    SizedBox(height: 16.h),

                    //۱. تب‌بندی بالای صفحه (پیش‌رو، تکمیل‌شده، لغوشده)
                    _buildStatusTabs(context),
                    SizedBox(height: 18.h),

                    // ۲. لیست کارت‌های نوبت
                    if (filteredList.isEmpty)
                      _buildEmptyState(context)
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredList.length,
                        separatorBuilder: (_, __) => SizedBox(height: 14.h),
                        itemBuilder: (context, index) {
                          final item = filteredList[index];
                          return _buildAppointmentCard(context, item);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // هدر بالای صفحه
  // ---------------------------------------------------------------------------
  Widget _buildTopHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: AppColors.text700Light.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 60.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 34.r,
                    height: 34.r,
                    decoration: BoxDecoration(
                      color: AppColors.primary50,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.calendar_month_rounded,
                      size: 20.r,
                      color: AppColors.primary500,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'مدیریت نوبت‌ها',
                    style: textTheme.headlineMedium?.copyWith(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      goScreen(context: context, screen: NotificationScreen());
                    },
                    icon: Icon(
                      Icons.notifications_none_rounded,
                      size: 23.r,
                      color: AppColors.onSurfaceVariant,
                    ),
                    tooltip: 'اعلان‌ها',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // سوییچر نمای دوگانه: نمای بیمار / نمای پزشک
  // ---------------------------------------------------------------------------
  Widget _buildRoleSwitcher(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool isPatient = _currentRole == AppointmentViewRole.patient;

    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(50.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (isPatient) return;
                HapticFeedback.selectionClick();
                setState(() {
                  _currentRole = AppointmentViewRole.patient;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: isPatient ? AppColors.primary500 : Colors.transparent,
                  borderRadius: BorderRadius.circular(50.r),
                  boxShadow: isPatient
                      ? [
                          BoxShadow(
                            color: AppColors.primary500.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 18.r,
                      color: isPatient
                          ? Colors.white
                          : AppColors.onSurfaceVariant,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'نمای بیمار',
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w700,
                        color: isPatient
                            ? Colors.white
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isPatient) return;
                HapticFeedback.selectionClick();
                setState(() {
                  _currentRole = AppointmentViewRole.doctor;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: !isPatient ? AppColors.primary500 : Colors.transparent,
                  borderRadius: BorderRadius.circular(50.r),
                  boxShadow: !isPatient
                      ? [
                          BoxShadow(
                            color: AppColors.primary500.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.medical_information_outlined,
                      size: 18.r,
                      color: !isPatient
                          ? Colors.white
                          : AppColors.onSurfaceVariant,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'نمای پزشک',
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w700,
                        color: !isPatient
                            ? Colors.white
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ۱. تب‌بندی وضعیت نوبت‌ها (پیش‌رو، تکمیل‌شده، لغوشده)
  // ---------------------------------------------------------------------------
  Widget _buildStatusTabs(BuildContext context) {
    final upcomingCount = _getFilteredAppointments(
      AppointmentFilterTab.upcoming,
    ).length;
    final completedCount = _getFilteredAppointments(
      AppointmentFilterTab.completed,
    ).length;
    final cancelledCount = _getFilteredAppointments(
      AppointmentFilterTab.cancelled,
    ).length;

    return Container(
      padding: EdgeInsets.all(6.r),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          _buildTabButton(
            context,
            tab: AppointmentFilterTab.upcoming,
            label: 'پیش‌رو',
            count: upcomingCount,
          ),
          SizedBox(width: 4.w),
          _buildTabButton(
            context,
            tab: AppointmentFilterTab.completed,
            label: 'تکمیل‌شده',
            count: completedCount,
          ),
          SizedBox(width: 4.w),
          _buildTabButton(
            context,
            tab: AppointmentFilterTab.cancelled,
            label: 'لغوشده',
            count: cancelledCount,
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    BuildContext context, {
    required AppointmentFilterTab tab,
    required String label,
    required int count,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final bool isSelected = _currentTab == tab;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (isSelected) return;
          HapticFeedback.selectionClick();
          setState(() {
            _currentTab = tab;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 9.h, horizontal: 6.w),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.surfaceContainerLowest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.text700Light.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? AppColors.primary500
                        : AppColors.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (count > 0) ...[
                SizedBox(width: 5.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 1.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary500
                        : AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(50.r),
                  ),
                  child: Text(
                    _toPersianDigits(count.toString()),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ۲. کارت نوبت (مشترک برای بیمار و پزشک با دکمه‌های هوشمند)
  // ---------------------------------------------------------------------------
  Widget _buildAppointmentCard(
    BuildContext context,
    _AppointmentItemModel item,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final bool isDoctorView = _currentRole == AppointmentViewRole.doctor;
    final bool isOnline = item.visitMode == AppointmentVisitMode.onlineChat;

    // آیا نوبت آنلاین هم‌اکنون در جریان است؟
    final bool isLiveOnlineSession =
        isOnline &&
        item.status == AppointmentStatusType.confirmed &&
        item.isCurrentlyInProgress;

    // آیا امکان لغو نوبت وجود دارد؟ (قبل از زمان شروع و در وضعیت پیش‌رو)
    final bool canCancel =
        (item.status == AppointmentStatusType.confirmed ||
            item.status == AppointmentStatusType.pending) &&
        !item.hasStarted;

    // آیا پزشک می‌تواند ویزیت آنلاین را خاتمه دهد؟ (فقط پزشک + آنلاین + تایید شده + شروع شده)
    final bool canDoctorComplete =
        isDoctorView &&
        isOnline &&
        item.status == AppointmentStatusType.confirmed &&
        item.hasStarted;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isLiveOnlineSession
              ? AppColors.primary300
              : AppColors.text200Light,
          width: isLiveOnlineSession ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.text700Light.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // بنر بالای کارت برای نوبت‌های آنلاین در حال برگزاری
          if (isLiveOnlineSession) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.primary50,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      FadeTransition(
                        opacity: Tween<double>(
                          begin: 0.3,
                          end: 1.0,
                        ).animate(_pulseController),
                        child: Container(
                          width: 9.r,
                          height: 9.r,
                          decoration: const BoxDecoration(
                            color: AppColors.primary500,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'مشاوره آنلاین در جریان است',
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.primary500,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      'هم‌اکنون | ${item.timeRangeText}',
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.primary500,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
          ],

          // هدر کارت: آواتار، نام پزشک/بیمار و برچسب رنگی نوع نوبت (چت آنلاین: سبز / حضوری: آبی)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    _buildCounterpartAvatar(context, item),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.counterpartName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.headlineMedium?.copyWith(
                              fontSize: 15.5.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            item.counterpartSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),

              // برچسب رنگی نوع نوبت (طبق پرامپت: چت آنلاین سبز / ویزیت حضوری آبی)
              _buildVisitModeBadge(context, item.visitMode),
            ],
          ),
          SizedBox(height: 12.h),

          // باکس جزئیات زمان نوبت (start_at تا end_at)، شناسه و آدرس/شرح حال
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // تاریخ شمسی و بازه زمانی دقیق
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          size: 16.r,
                          color: isOnline
                              ? AppColors.primary500
                              : AppColors.secondary,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          item.jalaliDateText,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      item.timeRangeText,
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),

                // شناسه نوبت و مبلغ
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.tag_rounded,
                          size: 15.r,
                          color: AppColors.outline,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'شناسه نوبت: ',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 1.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            '#${item.id}',
                            style: textTheme.titleSmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item.priceText != null)
                      Text(
                        item.priceText!,
                        style: textTheme.titleSmall?.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),

                // نمایش آدرس کلینیک برای نوبت‌های حضوری
                if (!isOnline && item.clinicAddress != null) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Divider(height: 1, color: AppColors.text200Light),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 16.r,
                        color: AppColors.primary500,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          item.clinicAddress!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // نمایش یادداشت/علائم بیمار (مخصوصاً برای پزشک یا یادآوری بیمار)
                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Divider(height: 1, color: AppColors.text200Light),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.notes_rounded,
                        size: 16.r,
                        color: AppColors.secondary,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          item.notes!,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurface,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // نمایش علت لغو در تب لغوشده
                if (item.cancelReason != null &&
                    item.cancelReason!.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Divider(height: 1, color: AppColors.text200Light),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16.r,
                        color: AppColors.statusCancelledFg,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'علت لغو: ${item.cancelReason}',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.statusCancelledFg,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 10.h),

          // نوار وضعیت نوبت (Status Pill)
          _buildStatusBanner(context, item),
          SizedBox(height: 12.h),

          // ۳. دکمه‌های عملیاتی هوشمند روی کارت
          _buildCardActions(
            context,
            item: item,
            isDoctorView: isDoctorView,
            isOnline: isOnline,
            canCancel: canCancel,
            canDoctorComplete: canDoctorComplete,
          ),
        ],
      ),
    );
  }

  Widget _buildCounterpartAvatar(
    BuildContext context,
    _AppointmentItemModel item,
  ) {
    if (item.avatarUrl != null && item.avatarUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: AppCachedImage(
          url: item.avatarUrl!,
          width: 48.r,
          height: 48.r,
          fit: BoxFit.cover,
        ),
      );
    }

    final String initial = item.counterpartName.trim().isNotEmpty
        ? item.counterpartName.trim().substring(0, 1)
        : 'ب';

    return Container(
      width: 48.r,
      height: 48.r,
      decoration: BoxDecoration(
        color: AppColors.secondaryFixed,
        borderRadius: BorderRadius.circular(12.r),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: AppColors.onSecondaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// برچسب نوع ویزیت: «چت آنلاین» (سبز) یا «ویزیت حضوری» (آبی)
  Widget _buildVisitModeBadge(
    BuildContext context,
    AppointmentVisitMode visitMode,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final bool isOnline = visitMode == AppointmentVisitMode.onlineChat;

    final Color bgColor = isOnline
        ? AppColors
              .statusConfirmedBg // سبز ملایم
        : AppColors.statusPendingApprovalBg; // آبی ملایم
    final Color fgColor = isOnline
        ? AppColors
              .statusConfirmedFg // سبز تیره
        : AppColors.statusPendingApprovalFg; // آبی تیره

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(50.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline ? Icons.forum_rounded : Icons.apartment_rounded,
            size: 14.r,
            color: fgColor,
          ),
          SizedBox(width: 4.w),
          Text(
            isOnline ? 'چت آنلاین' : 'ویزیت حضوری',
            style: textTheme.titleSmall?.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// نمایش وضعیت نوبت بر اساس Status System
  Widget _buildStatusBanner(BuildContext context, _AppointmentItemModel item) {
    final textTheme = Theme.of(context).textTheme;

    late final Color bgColor;
    late final Color fgColor;
    late final IconData icon;
    late final String statusText;

    switch (item.status) {
      case AppointmentStatusType.pending:
        bgColor = AppColors.statusPendingPaymentBg;
        fgColor = AppColors.statusPendingPaymentFg;
        icon = Icons.hourglass_top_rounded;
        statusText = 'در انتظار تأیید پزشک';
        break;
      case AppointmentStatusType.confirmed:
        bgColor = AppColors.surfaceContainer;
        fgColor = AppColors.primary500;
        icon = Icons.verified_rounded;
        statusText = item.visitMode == AppointmentVisitMode.onlineChat
            ? (item.isCurrentlyInProgress
                  ? 'تأیید شده — پنجره زمانی ارسال پیام برای بیمار باز است'
                  : 'تأیید شده — در رأس ساعت نوبت، ارسال پیام برای بیمار فعال می‌شود')
            : 'تأیید شده — لطفاً ۱۵ دقیقه پیش از ساعت نوبت در کلینیک حضور یابید';
        break;
      case AppointmentStatusType.completed:
        bgColor = AppColors.statusCompletedBg;
        fgColor = AppColors.statusCompletedFg;
        icon = Icons.task_alt_rounded;
        statusText = 'تکمیل شده — تاریخچه گفت‌وگو و نسخه‌ها قابل مشاهده است';
        break;
      case AppointmentStatusType.cancelledByCustomer:
        bgColor = AppColors.statusCancelledBg;
        fgColor = AppColors.statusCancelledFg;
        icon = Icons.cancel_outlined;
        statusText = 'لغو شده توسط بیمار';
        break;
      case AppointmentStatusType.cancelledByProvider:
        bgColor = AppColors.statusCancelledBg;
        fgColor = AppColors.statusCancelledFg;
        icon = Icons.cancel_outlined;
        statusText = 'لغو شده توسط پزشک';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17.r, color: fgColor),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              statusText,
              style: textTheme.titleSmall?.copyWith(
                color: fgColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ۳. دکمه‌های عملیاتی روی کارت (ورود به چت، لغو نوبت، خاتمه ویزیت توسط پزشک)
  // ---------------------------------------------------------------------------
  Widget _buildCardActions(
    BuildContext context, {
    required _AppointmentItemModel item,
    required bool isDoctorView,
    required bool isOnline,
    required bool canCancel,
    required bool canDoctorComplete,
  }) {
    final textTheme = Theme.of(context).textTheme;

    // در تب لغوشده نیازی به دکمه عملیاتی نیست
    if (item.status == AppointmentStatusType.cancelledByCustomer ||
        item.status == AppointmentStatusType.cancelledByProvider) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // دکمه اصلی: اگر نوبت از نوع online_chat است -> ورود به اتاق چت با پزشک/بیمار
            if (isOnline)
              Expanded(
                child: SizedBox(
                  height: 46.h,
                  child: ElevatedButton.icon(
                    onPressed: () => _onOpenChatRoom(context, item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary500,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    icon: Icon(Icons.chat_bubble_outline_rounded, size: 18.r),
                    label: Text(
                      isDoctorView
                          ? (item.status == AppointmentStatusType.completed
                                ? 'ورود به چت (ارسال نسخه / آزمایش)'
                                : 'ورود به اتاق چت با بیمار')
                          : 'ورود به اتاق چت با پزشک',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 13.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              )
            else
              // اگر نوبت حضوری است
              Expanded(
                child: SizedBox(
                  height: 46.h,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // نمایش جزئیات آدرس یا تأیید نوبت برای پزشک
                      if (isDoctorView &&
                          item.status == AppointmentStatusType.pending) {
                        _handleConfirmAppointmentByDoctor(context, item);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      side: const BorderSide(
                        color: AppColors.secondary,
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    icon: Icon(
                      isDoctorView &&
                              item.status == AppointmentStatusType.pending
                          ? Icons.check_circle_outline_rounded
                          : Icons.directions_rounded,
                      size: 18.r,
                    ),
                    label: Text(
                      isDoctorView &&
                              item.status == AppointmentStatusType.pending
                          ? 'تأیید نوبت بیمار'
                          : 'مشاهده جزئیات و مسیریابی',
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),

            // دکمه ثانویه: اگر زمان شروع نوبت هنوز نرسیده است -> «لغو نوبت»
            if (canCancel) ...[
              SizedBox(width: 8.w),
              SizedBox(
                height: 46.h,
                child: TextButton.icon(
                  onPressed: () => _showCancelDialog(context, item),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.statusCancelledBg,
                    foregroundColor: AppColors.statusCancelledFg,
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  icon: Icon(Icons.close_rounded, size: 17.r),
                  label: Text(
                    'لغو نوبت',
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.statusCancelledFg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),

        // دکمه اختصاصی پزشک برای نوبت آنلاین در جریان: «خاتمه و تکمیل ویزیت»
        // متصل به POST /api/v1/appointments/{appointment_id}/complete/
        if (canDoctorComplete) ...[
          SizedBox(height: 8.h),
          SizedBox(
            height: 44.h,
            child: ElevatedButton.icon(
              onPressed: () => _showCompleteVisitConfirmation(context, item),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tertiaryContainer,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              icon: Icon(Icons.task_alt_rounded, size: 18.r),
              label: Text(
                'خاتمه و تکمیل ویزیت (قفل ارسال پیام بیمار)',
                style: textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // وضعیت خالی بودن لیست
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 48.h, horizontal: 24.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.text200Light),
      ),
      child: Column(
        children: [
          Container(
            width: 64.r,
            height: 64.r,
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.event_busy_rounded,
              size: 32.r,
              color: AppColors.outline,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'نوبتی در این بخش وجود ندارد',
            style: textTheme.headlineMedium?.copyWith(
              fontSize: 15.5.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'لیست نوبت‌های انتخابی شما در این وضعیت خالی است.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // متدهای عملیاتی متصل به منطق API بک‌اند
  // ---------------------------------------------------------------------------

  /// ۱. ورود به اتاق چت (ابتدا بررسی GET /api/v1/appointments/{id}/chat-access/)
  void _onOpenChatRoom(BuildContext context, _AppointmentItemModel item) {
    final bool isDoctorView = _currentRole == AppointmentViewRole.doctor;
    final bool canSend =
        isDoctorView ||
        (item.status == AppointmentStatusType.confirmed &&
            item.isCurrentlyInProgress);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.onSurface,
        content: Text(
          canSend
              ? 'ورود به گفت‌وگو (${item.conversationId}) — ارسال پیام، عکس و ویس فعال است.'
              : 'ورود به گفت‌وگو (${item.conversationId}) — فقط خواندنی (خارج از بازه زمانی نوبت).',
          style: TextStyle(fontFamily: 'IRANYekan', fontSize: 12.sp),
        ),
      ),
    );
  }

  /// ۲. لغو نوبت پیش از شروع (POST /api/v1/appointments/{pk}/cancel/)
  void _showCancelDialog(BuildContext context, _AppointmentItemModel item) {
    final TextEditingController reasonController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20.w,
              right: 20.w,
              top: 20.h,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'لغو نوبت #${item.id}',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8.h),
                Text(
                  'آیا از لغو نوبت «${item.counterpartName}» در تاریخ ${item.jalaliDateText} اطمینان دارید؟',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'علت لغو نوبت (اختیاری)...',
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size.fromHeight(46.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: const Text('انصراف'),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() {
                            item.status =
                                _currentRole == AppointmentViewRole.patient
                                ? AppointmentStatusType.cancelledByCustomer
                                : AppointmentStatusType.cancelledByProvider;
                            item.cancelReason =
                                reasonController.text.trim().isNotEmpty
                                ? reasonController.text.trim()
                                : 'لغو توسط کاربر پیش از شروع نوبت';
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.statusCancelledFg,
                          minimumSize: Size.fromHeight(46.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: const Text('تأیید و لغو نوبت'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ۳. خاتمه دستی ویزیت آنلاین توسط پزشک (POST /api/v1/appointments/{appointment_id}/complete/)
  void _showCompleteVisitConfirmation(
    BuildContext context,
    _AppointmentItemModel item,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Text(
              'خاتمه و تکمیل ویزیت آنلاین',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            content: Text(
              'با ثبت پایان ویزیت، وضعیت نوبت «${item.counterpartName}» به تکمیل‌شده تغییر می‌یابد و ارسال پیام برای بیمار قفل می‌شود.\n\nشما همچنان در هر زمان می‌توانید کد رهگیری نسخه یا دستور آزمایش را در چت برای بیمار ارسال کنید.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.onSurfaceVariant, height: 1.6),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('انصراف'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    item.status = AppointmentStatusType.completed;
                    item.isCurrentlyInProgress = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary500,
                ),
                child: const Text('ثبت پایان ویزیت'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ۴. تأیید نوبت در انتظار توسط پزشک (PATCH /api/v1/appointments/{pk}/status/)
  void _handleConfirmAppointmentByDoctor(
    BuildContext context,
    _AppointmentItemModel item,
  ) {
    setState(() {
      item.status = AppointmentStatusType.confirmed;
    });
  }
}

// -----------------------------------------------------------------------------
// مدل داده داخلی کارت نوبت
// -----------------------------------------------------------------------------
class _AppointmentItemModel {
  final String id;
  final String counterpartName;
  final String counterpartSubtitle;
  final String? avatarUrl;
  final AppointmentVisitMode visitMode;
  AppointmentStatusType status;
  final String jalaliDateText;
  final String timeRangeText;
  bool isCurrentlyInProgress;
  final bool hasStarted;
  final String? conversationId;
  final String? clinicAddress;
  final String? notes;
  String? cancelReason;
  final String? priceText;

  _AppointmentItemModel({
    required this.id,
    required this.counterpartName,
    required this.counterpartSubtitle,
    this.avatarUrl,
    required this.visitMode,
    required this.status,
    required this.jalaliDateText,
    required this.timeRangeText,
    required this.isCurrentlyInProgress,
    required this.hasStarted,
    this.conversationId,
    this.clinicAddress,
    this.notes,
    this.cancelReason,
    this.priceText,
  });
}
