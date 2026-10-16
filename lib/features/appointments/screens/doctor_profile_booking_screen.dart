import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:reservation_chat_univercity_project/core/themes/app_colors.dart';
import 'package:reservation_chat_univercity_project/core/widgets/app_cached_image.dart';

/// نوع ویزیت مطابق با apps/offerings/enums.py در بک‌اند جنگو
enum VisitModeType {
  inPerson('in_person'),
  onlineChat('online_chat');

  final String apiValue;
  const VisitModeType(this.apiValue);
}

class DoctorProfileBookingScreen extends StatefulWidget {
  final String? providerId;
  final String? initialDoctorName;
  final String? initialSpecialty;
  final String? initialAvatarUrl;
  final String? initialMedicalCode;

  const DoctorProfileBookingScreen({
    super.key,
    this.providerId,
    this.initialDoctorName,
    this.initialSpecialty,
    this.initialAvatarUrl,
    this.initialMedicalCode,
  });

  @override
  State<DoctorProfileBookingScreen> createState() =>
      _DoctorProfileBookingScreenState();
}

class _DoctorProfileBookingScreenState
    extends State<DoctorProfileBookingScreen> {
  bool _isBookmarked = false;
  bool _isBioExpanded = false;

  // نوع خدمت انتخاب شده (پیش‌فرض: ویزیت حضوری)
  VisitModeType _selectedVisitMode = VisitModeType.inPerson;

  // ایندکس روز انتخاب شده در تقویم افقی
  int _selectedDateIndex = 0;

  // ساعت انتخاب شده
  String? _selectedSlotId = 'slot_2';

  final TextEditingController _notesController = TextEditingController();

  late final List<_JalaliDayItem> _upcomingDays;

  // اطلاعات خدمات پزشک (معادل پاسخ GET /api/v1/offerings/?provider_id=...)
  final Map<VisitModeType, _OfferingItemModel> _offerings = const {
    VisitModeType.inPerson: _OfferingItemModel(
      id: 'off_in_person_1',
      title: 'ویزیت حضوری مطب',
      subtitle: 'معاینه فیزیکی کامل و چکاپ علائم حیاتی در مطب',
      badgeText: 'توصیه شده',
      durationMinutes: 30,
      priceFormatted: '۲۸۰,۰۰۰',
      priceValue: 280000,
      visitMode: VisitModeType.inPerson,
    ),
    VisitModeType.onlineChat: _OfferingItemModel(
      id: 'off_online_chat_1',
      title: 'مشاوره آنلاین متنی و صوتی',
      subtitle: 'گفت‌وگو در محیط چت و ارسال مدارک، عکس آزمایش و ویس',
      badgeText: 'چت و ویس پزشکی',
      durationMinutes: 45,
      priceFormatted: '۱۹۰,۰۰۰',
      priceValue: 190000,
      visitMode: VisitModeType.onlineChat,
    ),
  };

  // لیست ساعت‌های روز انتخابی (معادل پاسخ GET /api/v1/availability/slots/)
  final List<_TimeSlotItem> _slots = const [
    _TimeSlotItem(id: 'slot_1', timeLabel: '۱۶:۰۰', isAvailable: false),
    _TimeSlotItem(id: 'slot_2', timeLabel: '۱۶:۳۰', isAvailable: true),
    _TimeSlotItem(id: 'slot_3', timeLabel: '۱۷:۰۰', isAvailable: true),
    _TimeSlotItem(id: 'slot_4', timeLabel: '۱۷:۳۰', isAvailable: true),
    _TimeSlotItem(id: 'slot_5', timeLabel: '۱۸:۰۰', isAvailable: false),
    _TimeSlotItem(id: 'slot_6', timeLabel: '۱۸:۳۰', isAvailable: true),
    _TimeSlotItem(id: 'slot_7', timeLabel: '۱۹:۰۰', isAvailable: true),
    _TimeSlotItem(id: 'slot_8', timeLabel: '۱۹:۳۰', isAvailable: true),
  ];

  @override
  void initState() {
    super.initState();
    _upcomingDays = _generateUpcomingJalaliDays(7);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// تولید ۷ روز آینده بر اساس تقویم شمسی واقعی به همراه تاریخ میلادی برای ارسال به API
  List<_JalaliDayItem> _generateUpcomingJalaliDays(int count) {
    final now = DateTime.now();
    return List.generate(count, (index) {
      final date = now.add(Duration(days: index));
      final jalali = Jalali.fromDateTime(date);
      final formatter = jalali.formatter;

      String topLabel;
      if (index == 0) {
        topLabel = 'امروز';
      } else if (index == 1) {
        topLabel = 'فردا';
      } else if (index == 2) {
        topLabel = 'پس‌فردا';
      } else if (index == 3) {
        topLabel = 'تکمیل';
      } else {
        topLabel = formatter.mN;
      }

      final gregorianIso =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      return _JalaliDayItem(
        topLabel: topLabel,
        dayNumber: _toPersianDigits(jalali.day.toString()),
        weekDayName: formatter.wN,
        fullDisplayTitle:
            '${formatter.wN} ${_toPersianDigits(jalali.day.toString())} ${formatter.mN}',
        monthYearTitle:
            '${formatter.mN} ${_toPersianDigits(jalali.year.toString())}',
        gregorianDate: gregorianIso,
        isDisabled: index == 3, // نمونه روز تکمیل ظرفیت
        badgeCount: index == 2 ? '۳ نوبت' : null,
      );
    });
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

  _OfferingItemModel get _currentOffering => _offerings[_selectedVisitMode]!;

  _TimeSlotItem? get _selectedSlot {
    if (_selectedSlotId == null) return null;
    try {
      return _slots.firstWhere((s) => s.id == _selectedSlotId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            Column(
              children: [
                // هدر بالای صفحه
                _buildAppBar(context),

                // محتوای قابل اسکرول
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 140.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ۱. کارت اطلاعات جامع پزشک
                        _buildDoctorInfoCard(context),
                        SizedBox(height: 20.h),

                        // ۲. انتخابگر شیوه ویزیت (حضوری / چت آنلاین)
                        _buildVisitModeSection(context),
                        SizedBox(height: 16.h),

                        // باکس اطلاعات وابسته به نوع ویزیت (آدرس مطب یا قوانین چت آنلاین)
                        _buildVisitModeContextBox(context),
                        SizedBox(height: 20.h),

                        // ۳. تقویم شمسی افقی
                        _buildJalaliCalendarSection(context),
                        SizedBox(height: 20.h),

                        // ۴. شبکه ساعت‌های خالی (Time Slots Grid)
                        _buildTimeSlotsSection(context),
                        SizedBox(height: 20.h),

                        // فیلد اختیاری یادداشت/علائم بیمار برای پزشک
                        _buildPatientNotesField(context),
                        SizedBox(height: 16.h),

                        // کارت پشتیبانی و تضمین بازگشت وجه
                        _buildSupportAssuranceCard(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ۵. فوتر چسبان پایین صفحه (مبلغ و پرداخت زرین‌پال)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildStickyBottomBar(context),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // هدر بالای صفحه
  // ---------------------------------------------------------------------------
  Widget _buildAppBar(BuildContext context) {
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
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      size: 28.r,
                      color: AppColors.onSurface,
                    ),
                    tooltip: 'بازگشت',
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'پروفایل پزشک و رزرو نوبت',
                    style: textTheme.headlineMedium?.copyWith(
                      fontSize: 16.5.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.share_outlined,
                      size: 22.r,
                      color: AppColors.onSurfaceVariant,
                    ),
                    tooltip: 'اشتراک‌گذاری',
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isBookmarked = !_isBookmarked;
                      });
                    },
                    icon: Icon(
                      _isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 23.r,
                      color: _isBookmarked
                          ? AppColors.tertiary
                          : AppColors.onSurfaceVariant,
                    ),
                    tooltip: 'نشان کردن',
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
  // ۱. کارت اطلاعات جامع پزشک (Provider Details)
  // ---------------------------------------------------------------------------
  Widget _buildDoctorInfoCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final doctorName = widget.initialDoctorName ?? 'دکتر علیرضا رادمنش';
    final specialty =
        widget.initialSpecialty ?? 'فوق تخصص بیماری‌های قلب و عروق';
    final medicalCode = widget.initialMedicalCode ?? '۱۱۴۸۲۹';
    final avatarUrl =
        widget.initialAvatarUrl ??
        'https://lh3.googleusercontent.com/aida-public/AB6AXuDWsxLAcE0CLN0KLcP_YqNuLwqgIMSh94BDH8T1wJNlEBVgplGSkn96LmpWvIb0UiPyaLs9e4qelS4p3lY5QjEmr3XthmwzmG4qaiBmGykF7zR2VbkUw-T2Q2tYQ8-qmoYmmnRMqm2O5y5rjn7RWmSDBeUevqNNTC7fbpAt7get-0p91U1cn9Ml1q330aNdWhs7Oim-I6V2bcPo7cxFWPjWkxjHCzntfbf0nmi9sRTRFGOwkIGVi6kO';

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.text200Light),
        boxShadow: [
          BoxShadow(
            color: AppColors.text700Light.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عکس، نام، تخصص و کد نظام پزشکی
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 80.r,
                    height: 80.r,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: AppCachedImage(url: avatarUrl, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    bottom: -4.r,
                    left: -4.r,
                    child: Container(
                      width: 24.r,
                      height: 24.r,
                      decoration: BoxDecoration(
                        color: AppColors.primary500,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surfaceContainerLowest,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        size: 14.r,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            doctorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyLarge?.copyWith(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.verified_rounded,
                          size: 18.r,
                          color: AppColors.primary500,
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      specialty,
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 13.5.sp,
                        color: AppColors.primary500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'فلوشیپ آنژیوپلاستی و اینترونشنال کاردیولوژی',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(50.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            size: 13.r,
                            color: AppColors.outline,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'کد نظام پزشکی: $medicalCode',
                            style: textTheme.titleSmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // شبکه ۳ ستونه آمار عملکرد پزشک
          Container(
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.star_rounded,
                    iconColor: AppColors.yellow,
                    value: '۴.۹',
                    label: '۲۴۵ دیدگاه بیمار',
                  ),
                ),
                Container(
                  width: 1,
                  height: 32.h,
                  color: AppColors.text200Light,
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.history_edu_rounded,
                    iconColor: AppColors.primary500,
                    value: '۱۵+ سال',
                    label: 'سابقه طبابت',
                  ),
                ),
                Container(
                  width: 1,
                  height: 32.h,
                  color: AppColors.text200Light,
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.thumb_up_alt_rounded,
                    iconColor: AppColors.green,
                    value: '۹۸٪',
                    label: 'رضایت بیماران',
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),

          // بیوگرافی کوتاه با قابلیت باز و بسته شدن
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isBioExpanded
                    ? 'عضو هیئت علمی دانشگاه علوم پزشکی، دارای بورد تخصصی قلب و عروق و فلوشیپ اقدامات مداخله‌ای قلب (آنژیوگرافی و استنت‌گذاری). بیش از ۱۵ سال تجربه درمان بیماری‌های حاد دریچه‌ای، فشار خون مقاوم، آریتمی‌های قلبی و پیگیری‌های پس از جراحی قلب باز.'
                    : 'عضو هیئت علمی دانشگاه علوم پزشکی، دارای بورد تخصصی قلب و عروق و فلوشیپ اقدامات مداخله‌ای قلب (آنژیوگرافی و استنت‌گذاری). بیش از ۱۵ سال تجربه درمان بیماری‌های حاد دریچه‌ای و عروقی...',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.65,
                ),
              ),
              SizedBox(height: 4.h),
              InkWell(
                borderRadius: BorderRadius.circular(6.r),
                onTap: () {
                  setState(() {
                    _isBioExpanded = !_isBioExpanded;
                  });
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isBioExpanded ? 'بستن سوابق' : 'مشاهده کامل سوابق',
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.primary500,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Icon(
                        _isBioExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 16.r,
                        color: AppColors.primary500,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16.r, color: iconColor),
            SizedBox(width: 4.w),
            Text(
              value,
              style: textTheme.headlineMedium?.copyWith(
                fontSize: 15.5.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          textAlign: TextAlign.center,
          style: textTheme.titleSmall?.copyWith(
            fontSize: 10.5.sp,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ۲. انتخابگر نوع خدمت (Visit Mode Tabs: in_person vs online_chat)
  // ---------------------------------------------------------------------------
  Widget _buildVisitModeSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.medical_services_outlined,
                  size: 20.r,
                  color: AppColors.primary500,
                ),
                SizedBox(width: 6.w),
                Text(
                  'شیوه ویزیت را انتخاب کنید',
                  style: textTheme.headlineMedium?.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Text(
              '۲ شیوه نوبت‌دهی فعال',
              style: textTheme.titleSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        _buildVisitModeCard(
          context,
          offering: _offerings[VisitModeType.inPerson]!,
          icon: Icons.apartment_rounded,
          activeColor: AppColors.primary500,
          activeBgTint: AppColors.primary50,
          badgeBgColor: AppColors.primary500.withOpacity(0.12),
          badgeTextColor: AppColors.primary500,
        ),
        SizedBox(height: 10.h),
        _buildVisitModeCard(
          context,
          offering: _offerings[VisitModeType.onlineChat]!,
          icon: Icons.forum_rounded,
          activeColor: AppColors.secondary,
          activeBgTint: AppColors.surfaceContainer,
          badgeBgColor: AppColors.statusPendingPaymentBg,
          badgeTextColor: AppColors.statusPendingPaymentFg,
        ),
      ],
    );
  }

  Widget _buildVisitModeCard(
    BuildContext context, {
    required _OfferingItemModel offering,
    required IconData icon,
    required Color activeColor,
    required Color activeBgTint,
    required Color badgeBgColor,
    required Color badgeTextColor,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final bool isSelected = _selectedVisitMode == offering.visitMode;

    return Material(
      color: isSelected
          ? activeBgTint.withOpacity(0.65)
          : AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedVisitMode = offering.visitMode;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isSelected ? activeColor : AppColors.text200Light,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42.r,
                    height: 42.r,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? activeColor
                          : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      icon,
                      size: 22.r,
                      color: isSelected ? Colors.white : activeColor,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6.w,
                          runSpacing: 4.h,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              offering.title,
                              style: textTheme.headlineMedium?.copyWith(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: badgeBgColor,
                                borderRadius: BorderRadius.circular(50.r),
                              ),
                              child: Text(
                                offering.badgeText,
                                style: textTheme.titleSmall?.copyWith(
                                  fontSize: 10.sp,
                                  color: badgeTextColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          offering.subtitle,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    width: 22.r,
                    height: 22.r,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? activeColor
                          : AppColors.surfaceContainer,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            size: 15.r,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 16.r,
                          color: activeColor,
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          'مدت زمان ویزیت: ${_toPersianDigits(offering.durationMinutes.toString())} دقیقه',
                          style: textTheme.titleSmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          offering.priceFormatted,
                          style: textTheme.headlineMedium?.copyWith(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: activeColor,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'تومان',
                          style: textTheme.titleSmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // باکس جزئیات اختصاصی هر نوع ویزیت (آدرس مطب برای حضوری / قوانین چت برای آنلاین)
  // ---------------------------------------------------------------------------
  Widget _buildVisitModeContextBox(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (_selectedVisitMode == VisitModeType.inPerson) {
      return Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.text200Light),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36.r,
              height: 36.r,
              decoration: BoxDecoration(
                color: AppColors.primary50,
                borderRadius: BorderRadius.circular(10.r),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.location_on_rounded,
                size: 20.r,
                color: AppColors.primary500,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'کلینیک تخصصی قلب تهران (شعبه ونک)',
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'تهران، خیابان ولیعصر، بالاتر از میدان ونک، برج نگار، طبقه ۵، واحد ۱۲',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            InkWell(
              borderRadius: BorderRadius.circular(8.r),
              onTap: () {},
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'مسیریابی',
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.primary500,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.near_me_rounded,
                      size: 14.r,
                      color: AppColors.primary500,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // حالت مشاوره آنلاین متنی و صوتی (توضیح قوانین بازه زمانی چت طبق پرامپت)
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.onlineChatBg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.onlineChatFg.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.mic_none_rounded,
              size: 20.r,
              color: AppColors.onlineChatFg,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نحوه برگزاری ویزیت آنلاین متنی و صوتی',
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onlineChatFg,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'در رأس ساعت نوبت انتخابی، قفل گفت‌وگو برای شما باز می‌شود و می‌توانید در محیط چت با پزشک گفت‌وگو کنید و تصویر آزمایش، فایل یا پیام صوتی (ویس) بفرستید. پزشک در هر زمان امکان ارسال کد رهگیری نسخه یا دستور آزمایش را برای شما دارد.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurface,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ۳. تقویم شمسی افقی (Horizontal Jalali Date Picker)
  // ---------------------------------------------------------------------------
  Widget _buildJalaliCalendarSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final activeDay = _upcomingDays[_selectedDateIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  size: 20.r,
                  color: AppColors.primary500,
                ),
                SizedBox(width: 6.w),
                Text(
                  'انتخاب تاریخ ویزیت',
                  style: textTheme.headlineMedium?.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(50.r),
              ),
              child: Text(
                activeDay.monthYearTitle,
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 94.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _upcomingDays.length,
            separatorBuilder: (_, __) => SizedBox(width: 10.w),
            itemBuilder: (context, index) {
              final day = _upcomingDays[index];
              final bool isSelected = _selectedDateIndex == index;

              return GestureDetector(
                onTap: day.isDisabled
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedDateIndex = index;
                        });
                        // فراخوانی API دریافت اسلات‌های تاریخ جدید:
                        // GET /api/v1/availability/slots/?provider_id=...&offering_id=${_currentOffering.id}&date=${day.gregorianDate}
                      },
                child: Opacity(
                  opacity: day.isDisabled ? 0.5 : 1.0,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 76.w,
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary500
                              : (day.isDisabled
                                    ? AppColors.surfaceContainer
                                    : AppColors.surfaceContainerLowest),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary500
                                : AppColors.text200Light,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary500.withOpacity(
                                      0.25,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              day.topLabel,
                              style: textTheme.titleSmall?.copyWith(
                                fontSize: 10.5.sp,
                                color: isSelected
                                    ? Colors.white.withOpacity(0.9)
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              day.dayNumber,
                              style: textTheme.bodyLarge?.copyWith(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.onSurface,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              day.weekDayName,
                              style: textTheme.titleSmall?.copyWith(
                                fontSize: 11.sp,
                                color: isSelected
                                    ? Colors.white.withOpacity(0.9)
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (day.badgeCount != null)
                        Positioned(
                          top: -6.h,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 1.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.green,
                              borderRadius: BorderRadius.circular(50.r),
                            ),
                            child: Text(
                              day.badgeCount!,
                              style: TextStyle(
                                fontSize: 9.5.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ۴. شبکه ساعت‌های خالی (Time Slots Grid)
  // ---------------------------------------------------------------------------
  Widget _buildTimeSlotsSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final activeDay = _upcomingDays[_selectedDateIndex];
    final availableCount = _slots.where((s) => s.isAvailable).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 20.r,
                  color: AppColors.primary500,
                ),
                SizedBox(width: 6.w),
                Text(
                  'ساعت‌های در دسترس',
                  style: textTheme.headlineMedium?.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Text(
              activeDay.fullDisplayTitle,
              style: textTheme.titleSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),

        // سربرگ شیفت کاری
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.wb_twilight_rounded,
                    size: 17.r,
                    color: AppColors.primary500,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'شیفت بعد از ظهر (۱۶:۰۰ الی ۲۰:۰۰)',
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Text(
                '${_toPersianDigits(availableCount.toString())} نوبت باقی‌مانده',
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.primary500,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // شبکه ۳ ستونه ساعت‌ها
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _slots.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10.w,
            mainAxisSpacing: 10.h,
            childAspectRatio: 1.85,
          ),
          itemBuilder: (context, index) {
            final slot = _slots[index];
            final bool isSelected = _selectedSlotId == slot.id;

            return Material(
              color: !slot.isAvailable
                  ? AppColors.surfaceContainer.withOpacity(0.65)
                  : (isSelected
                        ? AppColors.primary500
                        : AppColors.surfaceContainerLowest),
              borderRadius: BorderRadius.circular(12.r),
              child: InkWell(
                borderRadius: BorderRadius.circular(12.r),
                onTap: !slot.isAvailable
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedSlotId = slot.id;
                        });
                      },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary100
                          : AppColors.text200Light,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            slot.timeLabel,
                            style: textTheme.titleMedium?.copyWith(
                              fontSize: 14.5.sp,
                              fontWeight: FontWeight.w700,
                              decoration: !slot.isAvailable
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: !slot.isAvailable
                                  ? AppColors.outline
                                  : (isSelected
                                        ? Colors.white
                                        : AppColors.onSurface),
                            ),
                          ),
                          if (isSelected) ...[
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.check_circle_rounded,
                              size: 14.r,
                              color: Colors.white,
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        !slot.isAvailable
                            ? 'رزرو شده'
                            : (isSelected ? 'انتخاب شما' : 'آزاد'),
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: !slot.isAvailable
                              ? AppColors.outline
                              : (isSelected
                                    ? Colors.white.withOpacity(0.9)
                                    : AppColors.green),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(height: 12.h),

        // راهنمای وضعیت اسلات‌ها (Legend)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendDot(
              context,
              color: AppColors.surfaceContainerLowest,
              borderColor: AppColors.text200Light,
              label: 'آزاد',
            ),
            SizedBox(width: 20.w),
            _buildLegendDot(
              context,
              color: AppColors.primary500,
              label: 'انتخاب شما',
            ),
            SizedBox(width: 20.w),
            _buildLegendDot(
              context,
              color: AppColors.surfaceContainer,
              label: 'تکمیل شده',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendDot(
    BuildContext context, {
    required Color color,
    Color? borderColor,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          width: 12.r,
          height: 12.r,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: borderColor != null ? Border.all(color: borderColor) : null,
          ),
        ),
        SizedBox(width: 6.w),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // فیلد یادداشت یا علائم اولیه بیمار (فیلد notes در مدل Appointment)
  // ---------------------------------------------------------------------------
  Widget _buildPatientNotesField(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'توضیحات یا علائم اولیه برای پزشک (اختیاری)',
          style: textTheme.titleMedium?.copyWith(
            fontSize: 13.5.sp,
            color: AppColors.onSurface,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: _notesController,
          maxLines: 2,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.onSurface),
          decoration: const InputDecoration(
            hintText: 'اگر داروی خاصی مصرف می‌کنید یا شرح حال اولیه‌ای دارید بنویسید...',
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // کارت پشتیبانی ۲۴ ساعته درمان‌یار
  // ---------------------------------------------------------------------------
  Widget _buildSupportAssuranceCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.security_rounded,
              size: 20.r,
              color: AppColors.primary500,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'پشتیبانی ۲۴ ساعته درمان‌یار',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'امکان لغو نوبت تا پیش از ساعت شروع ویزیت و بازگشت کامل وجه طبق قوانین کلینیک فراهم است.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ۵. فوتر چسبان پرداخت و ثبت نهایی نوبت (Sticky Bottom Bar)
  // ---------------------------------------------------------------------------
  Widget _buildStickyBottomBar(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final offering = _currentOffering;
    final selectedSlot = _selectedSlot;
    final selectedDay = _upcomingDays[_selectedDateIndex];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withOpacity(0.97),
        boxShadow: [
          BoxShadow(
            color: AppColors.text700Light.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // مبلغ قابل پرداخت
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مبلغ قابل پرداخت:',
                        style: textTheme.titleSmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            offering.priceFormatted,
                            style: textTheme.bodyLarge?.copyWith(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'تومان',
                            style: textTheme.titleSmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(width: 16.w),

                  // دکمه ثبت نوبت و پرداخت آنلاین (زرین‌پال)
                  Expanded(
                    child: SizedBox(
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: selectedSlot == null
                            ? null
                            : () => _onSubmitBooking(
                                context,
                                offering: offering,
                                day: selectedDay,
                                slot: selectedSlot,
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary500,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline_rounded, size: 18.r),
                            SizedBox(width: 6.w),
                            Flexible(
                              child: Text(
                                'ثبت نوبت و پرداخت آنلاین',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Icon(Icons.arrow_back_rounded, size: 18.r),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_user_rounded,
                    size: 14.r,
                    color: AppColors.green,
                  ),
                  SizedBox(width: 4.w),
                  Flexible(
                    child: Text(
                      selectedSlot != null
                          ? 'رزرو برای ${selectedDay.fullDisplayTitle} ساعت ${selectedSlot.timeLabel} • درگاه امن زرین‌پال'
                          : 'لطفاً یک ساعت خالی را برای ادامه انتخاب کنید',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontSize: 10.5.sp,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
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
  // متد ثبت نهایی نوبت (POST /api/v1/appointments/ و هدایت به زرین‌پال)
  // ---------------------------------------------------------------------------
  void _onSubmitBooking(
    BuildContext context, {
    required _OfferingItemModel offering,
    required _JalaliDayItem day,
    required _TimeSlotItem slot,
  }) {
    // نمونه Payload ارسالی به POST /api/v1/appointments/
    final Map<String, dynamic> appointmentPayload = {
      'provider_id': widget.providerId ?? 'provider-uuid',
      'offering_id': offering.id,
      'visit_mode': offering.visitMode.apiValue, // in_person | online_chat
      'date': day.gregorianDate,
      'slot_time': slot.timeLabel,
      'notes': _notesController.text.trim(),
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.all(20.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'تأیید اطلاعات و انتقال به درگاه زرین‌پال',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 12.h),
                Text(
                  '• نوع نوبت: ${offering.title}\n'
                  '• تاریخ: ${day.fullDisplayTitle} (${day.gregorianDate})\n'
                  '• ساعت: ${slot.timeLabel}\n'
                  '• مبلغ قابل پرداخت: ${offering.priceFormatted} تومان',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.8,
                  ),
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    debugPrint('Booking Payload: $appointmentPayload');
                    // ۱. ارسال درخواست POST /api/v1/appointments/
                    // ۲. ارسال درخواست POST /api/v1/payments/... و باز کردن لینک زرین‌پال
                  },
                  child: const Text('ورود به درگاه پرداخت زرین‌پال'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// مدل‌های داده داخلی صفحه رزرو نوبت
// -----------------------------------------------------------------------------
class _OfferingItemModel {
  final String id;
  final String title;
  final String subtitle;
  final String badgeText;
  final int durationMinutes;
  final String priceFormatted;
  final int priceValue;
  final VisitModeType visitMode;

  const _OfferingItemModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.durationMinutes,
    required this.priceFormatted,
    required this.priceValue,
    required this.visitMode,
  });
}

class _JalaliDayItem {
  final String topLabel;
  final String dayNumber;
  final String weekDayName;
  final String fullDisplayTitle;
  final String monthYearTitle;
  final String gregorianDate; // YYYY-MM-DD برای ارسال به بک‌اند
  final bool isDisabled;
  final String? badgeCount;

  const _JalaliDayItem({
    required this.topLabel,
    required this.dayNumber,
    required this.weekDayName,
    required this.fullDisplayTitle,
    required this.monthYearTitle,
    required this.gregorianDate,
    this.isDisabled = false,
    this.badgeCount,
  });
}

class _TimeSlotItem {
  final String id;
  final String timeLabel;
  final bool isAvailable;

  const _TimeSlotItem({
    required this.id,
    required this.timeLabel,
    required this.isAvailable,
  });
}
