import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reservation_chat_univercity_project/core/themes/app_colors.dart';
import 'package:reservation_chat_univercity_project/core/widgets/global_error_section.dart';
import 'package:reservation_chat_univercity_project/core/widgets/global_loading_section.dart';
import 'package:reservation_chat_univercity_project/features/appointments/bloc/appointments_bloc.dart';
import 'package:reservation_chat_univercity_project/features/appointments/bloc/doctor_booking_bloc.dart';
import 'package:reservation_chat_univercity_project/features/appointments/screens/payment_gateway_screen.dart';
import 'package:reservation_chat_univercity_project/features/appointments/service/model/appointment_models.dart';
import 'package:reservation_chat_univercity_project/features/home/services/model/home_models.dart';
import 'package:shamsi_date/shamsi_date.dart';

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

  int _selectedDateIndex = 0;
  String? _selectedSlotStartAt;
  PaymentMethodType _selectedInPersonPaymentMethod = PaymentMethodType.online;

  final TextEditingController _notesController = TextEditingController();

  late final List<_JalaliDayItem> _upcomingDays;
  late final DoctorBookingBloc _bookingBloc;
  late final AppointmentsBloc _submitBloc;

  @override
  void initState() {
    super.initState();
    _upcomingDays = _generateUpcomingJalaliDays(7);
    _bookingBloc = DoctorBookingBloc();
    _submitBloc = AppointmentsBloc();

    if (widget.providerId != null && widget.providerId!.isNotEmpty) {
      _bookingBloc.add(
        LoadProviderAndOfferingsEvent(
          providerId: widget.providerId!,
          initialDate: _upcomingDays.first.gregorianDate,
        ),
      );
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _bookingBloc.close();
    _submitBloc.close();
    super.dispose();
  }

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
      } else {
        topLabel = formatter.mN;
      }

      final gregorianIso =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      return _JalaliDayItem(
        topLabel: topLabel,
        dayNumber: toPersianDigits(jalali.day.toString()),
        weekDayName: formatter.wN,
        fullDisplayTitle:
            '${formatter.wN} ${toPersianDigits(jalali.day.toString())} ${formatter.mN}',
        monthYearTitle:
            '${formatter.mN} ${toPersianDigits(jalali.year.toString())}',
        gregorianDate: gregorianIso,
      );
    });
  }

  AvailableSlotModel? _findSelectedSlot(List<AvailableSlotModel> slots) {
    if (_selectedSlotStartAt == null) return null;
    try {
      return slots.firstWhere((s) => s.rawStartAt == _selectedSlotStartAt);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DoctorBookingBloc>.value(value: _bookingBloc),
        BlocProvider<AppointmentsBloc>.value(value: _submitBloc),
      ],
      child: BlocListener<AppointmentsBloc, AppointmentsState>(
        listenWhen: (previous, current) =>
            current is CreateAppointmentSuccessState ||
            current is CreateAppointmentFailedState,
        listener: (context, state) async {
          if (state is CreateAppointmentFailedState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.statusCancelledFg,
                content: Text(state.message),
              ),
            );
          } else if (state is CreateAppointmentSuccessState) {
            final appointment = state.appointment;
            if (appointment.payUrl != null &&
                appointment.payUrl!.trim().isNotEmpty) {
              final paid = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => PaymentGatewayScreen(
                    payUrl: appointment.payUrl!,
                    paymentId: appointment.payment?.id,
                    doctorName: appointment.provider.displayName,
                    offeringTitle: appointment.offering.title,
                    amountText: appointment.offering.priceFormatted,
                  ),
                ),
              );

              if (!context.mounted) return;
              if (paid == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.green,
                    content: Text('نوبت شما با موفقیت ثبت و پرداخت شد.'),
                  ),
                );
                Navigator.of(context).maybePop(true);
              } else {
                // رفرش اسلات‌ها در صورت عدم تکمیل پرداخت
                final activeDay = _upcomingDays[_selectedDateIndex];
                _bookingBloc.add(
                  SelectBookingDateEvent(date: activeDay.gregorianDate),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.green,
                  content: Text('نوبت شما با موفقیت ثبت شد.'),
                ),
              );
              Navigator.of(context).maybePop(true);
            }
          }
        },
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: BlocBuilder<DoctorBookingBloc, DoctorBookingState>(
              builder: (context, state) {
                if (state is DoctorBookingLoadingState ||
                    state is DoctorBookingInitial) {
                  return Column(
                    children: [
                      _buildAppBar(context),
                      Expanded(child: GlobalLoadingSection()),
                    ],
                  );
                }

                if (state is DoctorBookingFailedState) {
                  return Column(
                    children: [
                      _buildAppBar(context),
                      Expanded(
                        child: GlobalErrorSection(
                          message: state.message,
                          onRetry: () {
                            if (widget.providerId != null) {
                              _bookingBloc.add(
                                LoadProviderAndOfferingsEvent(
                                  providerId: widget.providerId!,
                                  initialDate: _upcomingDays[_selectedDateIndex]
                                      .gregorianDate,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  );
                }

                if (state is DoctorBookingLoadedState) {
                  final selectedSlot = _findSelectedSlot(state.slots);

                  return Stack(
                    children: [
                      Column(
                        children: [
                          _buildAppBar(context),
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                16.w,
                                12.h,
                                16.w,
                                150.h,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // ۱. کارت اطلاعات پزشک
                                  _buildDoctorInfoCard(context, state.provider),
                                  SizedBox(height: 20.h),

                                  // ۲. انتخابگر شیوه ویزیت (اگر ۲ خدمت دارد هر دو، اگر ۱ خدمت دارد انتخاب خودکار)
                                  if (state.offerings.isEmpty)
                                    _buildNoOfferingsBox(context)
                                  else ...[
                                    if (state.hasBothVisitModes) ...[
                                      _buildVisitModeSection(context, state),
                                      SizedBox(height: 16.h),
                                    ] else if (state.selectedOffering !=
                                        null) ...[
                                      _buildSingleOfferingSummary(
                                        context,
                                        state.selectedOffering!,
                                      ),
                                      SizedBox(height: 16.h),
                                    ],

                                    if (state.selectedOffering != null) ...[
                                      _buildVisitModeContextBox(
                                        context,
                                        provider: state.provider,
                                        offering: state.selectedOffering!,
                                      ),
                                      SizedBox(height: 20.h),

                                      // ۳. تقویم شمسی افقی
                                      _buildJalaliCalendarSection(
                                        context,
                                        state,
                                      ),
                                      SizedBox(height: 20.h),

                                      // ۴. شبکه ساعت‌های خالی
                                      _buildTimeSlotsSection(context, state),
                                      SizedBox(height: 20.h),

                                      // ۵. یادداشت بیمار
                                      _buildPatientNotesField(context),
                                      SizedBox(height: 16.h),
                                    ],
                                  ],

                                  _buildSupportAssuranceCard(context),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (state.selectedOffering != null)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _buildStickyBottomBar(
                            context,
                            provider: state.provider,
                            offering: state.selectedOffering!,
                            selectedSlot: selectedSlot,
                          ),
                        ),
                    ],
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
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
  // ۱. کارت اطلاعات پزشک (بدون امتیاز، کد نظام پزشکی و نشانگر آنلاین)
  // ---------------------------------------------------------------------------
  Widget _buildDoctorInfoCard(
    BuildContext context,
    ProviderProfileModel provider,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final doctorName = provider.displayName.isNotEmpty
        ? provider.displayName
        : (widget.initialDoctorName ?? '');
    final specialty = provider.specialtiesTitle.isNotEmpty
        ? provider.specialtiesTitle
        : (widget.initialSpecialty ?? '');
    final String initial = provider.user.fullName.trim().isNotEmpty
        ? provider.user.fullName.trim().substring(0, 1)
        : 'پ';
    final String bioText = provider.bio.trim();

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 76.r,
                height: 76.r,
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: textTheme.headlineMedium?.copyWith(
                    fontSize: 26.sp,
                    color: AppColors.primary500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
                    if (provider.organization.name.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(
                            Icons.apartment_rounded,
                            size: 15.r,
                            color: AppColors.onSurfaceVariant,
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              provider.clinicDisplayTitle,
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
                  ],
                ),
              ),
            ],
          ),
          if (bioText.isNotEmpty) ...[
            SizedBox(height: 14.h),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bioText,
                  maxLines: _isBioExpanded ? null : 2,
                  overflow: _isBioExpanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.65,
                  ),
                ),
                if (bioText.length > 100) ...[
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
                            _isBioExpanded
                                ? 'بستن توضیحات'
                                : 'مشاهده کامل بیوگرافی',
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
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoOfferingsBox(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.all(20.r),
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.text200Light),
      ),
      alignment: Alignment.center,
      child: Text(
        'برای این پزشک هنوز خدمت فعالی تعریف نشده است.',
        style: textTheme.bodyMedium?.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ۲. انتخابگر شیوه ویزیت (نمایش فقط در صورتی که پزشک هر دو نوع ویزیت را داشته باشد)
  // ---------------------------------------------------------------------------
  Widget _buildVisitModeSection(
    BuildContext context,
    DoctorBookingLoadedState state,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final inPerson = state.inPersonOffering;
    final onlineChat = state.onlineChatOffering;

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
        if (inPerson != null) ...[
          _buildVisitModeCard(
            context,
            offering: inPerson,
            isSelected: state.selectedOffering?.id == inPerson.id,
            icon: Icons.apartment_rounded,
            activeColor: AppColors.primary500,
            activeBgTint: AppColors.primary50,
            badgeBgColor: AppColors.primary500.withOpacity(0.12),
            badgeTextColor: AppColors.primary500,
          ),
          SizedBox(height: 10.h),
        ],
        if (onlineChat != null)
          _buildVisitModeCard(
            context,
            offering: onlineChat,
            isSelected: state.selectedOffering?.id == onlineChat.id,
            icon: Icons.forum_rounded,
            activeColor: AppColors.secondary,
            activeBgTint: AppColors.surfaceContainer,
            badgeBgColor: AppColors.statusPendingPaymentBg,
            badgeTextColor: AppColors.statusPendingPaymentFg,
          ),
      ],
    );
  }

  Widget _buildSingleOfferingSummary(
    BuildContext context,
    OfferingModel offering,
  ) {
    final isOnline = offering.visitMode == VisitModeType.onlineChat;
    return _buildVisitModeCard(
      context,
      offering: offering,
      isSelected: true,
      icon: isOnline ? Icons.forum_rounded : Icons.apartment_rounded,
      activeColor: isOnline ? AppColors.secondary : AppColors.primary500,
      activeBgTint: isOnline ? AppColors.surfaceContainer : AppColors.primary50,
      badgeBgColor: isOnline
          ? AppColors.statusPendingPaymentBg
          : AppColors.primary500.withOpacity(0.12),
      badgeTextColor: isOnline
          ? AppColors.statusPendingPaymentFg
          : AppColors.primary500,
    );
  }

  Widget _buildVisitModeCard(
    BuildContext context, {
    required OfferingModel offering,
    required bool isSelected,
    required IconData icon,
    required Color activeColor,
    required Color activeBgTint,
    required Color badgeBgColor,
    required Color badgeTextColor,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: isSelected
          ? activeBgTint.withOpacity(0.65)
          : AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () {
          if (isSelected) return;
          HapticFeedback.selectionClick();
          setState(() {
            _selectedSlotStartAt = null;
          });
          final activeDay = _upcomingDays[_selectedDateIndex];
          _bookingBloc.add(
            SelectVisitModeOfferingEvent(
              offering: offering,
              date: activeDay.gregorianDate,
            ),
          );
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
                          offering.displaySubtitle,
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
                          'مدت زمان ویزیت: ${toPersianDigits(offering.durationMinutes.toString())} دقیقه',
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
  // باکس جزئیات اختصاصی هر نوع ویزیت
  // ---------------------------------------------------------------------------
  Widget _buildVisitModeContextBox(
    BuildContext context, {
    required ProviderProfileModel provider,
    required OfferingModel offering,
  }) {
    final textTheme = Theme.of(context).textTheme;

    if (offering.visitMode == VisitModeType.inPerson) {
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
                    provider.clinicDisplayTitle,
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    provider.clinicAddressDisplay,
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
  // ۳. تقویم شمسی افقی
  // ---------------------------------------------------------------------------
  Widget _buildJalaliCalendarSection(
    BuildContext context,
    DoctorBookingLoadedState state,
  ) {
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
                onTap: () {
                  if (isSelected) return;
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedDateIndex = index;
                    _selectedSlotStartAt = null;
                  });
                  _bookingBloc.add(
                    SelectBookingDateEvent(date: day.gregorianDate),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 76.w,
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary500
                        : AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary500
                          : AppColors.text200Light,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary500.withOpacity(0.25),
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
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ۴. شبکه ساعت‌های خالی (متصل به GET /api/v1/availability/slots/)
  // ---------------------------------------------------------------------------
  Widget _buildTimeSlotsSection(
    BuildContext context,
    DoctorBookingLoadedState state,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final activeDay = _upcomingDays[_selectedDateIndex];
    final slots = state.slots;

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
                    'نوبت‌های آزاد روز انتخابی',
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Text(
                '${toPersianDigits(slots.length.toString())} نوبت خالی',
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.primary500,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        if (state.isSlotsLoading)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 28.h),
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (state.slotsError != null)
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.text200Light),
            ),
            child: Column(
              children: [
                Text(
                  state.slotsError!,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.statusCancelledFg,
                  ),
                ),
                SizedBox(height: 8.h),
                TextButton.icon(
                  onPressed: () {
                    _bookingBloc.add(
                      SelectBookingDateEvent(date: activeDay.gregorianDate),
                    );
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('تلاش مجدد'),
                ),
              ],
            ),
          )
        else if (slots.isEmpty)
          Container(
            padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 16.w),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColors.text200Light),
            ),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(
                  Icons.event_busy_rounded,
                  size: 28.r,
                  color: AppColors.outline,
                ),
                SizedBox(height: 8.h),
                Text(
                  'در این تاریخ نوبت خالی برای پزشک وجود ندارد.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: slots.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 10.h,
              childAspectRatio: 1.85,
            ),
            itemBuilder: (context, index) {
              final slot = slots[index];
              final bool isSelected = _selectedSlotStartAt == slot.rawStartAt;

              return Material(
                color: isSelected
                    ? AppColors.primary500
                    : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12.r),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.r),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedSlotStartAt = slot.rawStartAt;
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
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.onSurface,
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
                          isSelected ? 'انتخاب شما' : 'آزاد',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white.withOpacity(0.9)
                                : AppColors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ۵. فیلد یادداشت بیمار
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
  // ۶. فوتر چسبان ثبت نوبت
  // ---------------------------------------------------------------------------
  Widget _buildStickyBottomBar(
    BuildContext context, {
    required ProviderProfileModel provider,
    required OfferingModel offering,
    required AvailableSlotModel? selectedSlot,
  }) {
    final textTheme = Theme.of(context).textTheme;
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
                            selectedSlot?.priceFormatted ??
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
                  Expanded(
                    child: BlocBuilder<AppointmentsBloc, AppointmentsState>(
                      buildWhen: (prev, curr) =>
                          curr is CreateAppointmentLoadingState ||
                          curr is CreateAppointmentSuccessState ||
                          curr is CreateAppointmentFailedState,
                      builder: (context, submitState) {
                        final isSubmitting =
                            submitState is CreateAppointmentLoadingState;

                        return SizedBox(
                          height: 48.h,
                          child: ElevatedButton(
                            onPressed: (selectedSlot == null || isSubmitting)
                                ? null
                                : () => _showBookingConfirmationSheet(
                                    context,
                                    provider: provider,
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
                            child: isSubmitting
                                ? SizedBox(
                                    width: 22.r,
                                    height: 22.r,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.lock_outline_rounded,
                                        size: 18.r,
                                      ),
                                      SizedBox(width: 6.w),
                                      Flexible(
                                        child: Text(
                                          'ثبت نوبت',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: textTheme.titleMedium
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      SizedBox(width: 6.w),
                                      Icon(
                                        Icons.arrow_back_rounded,
                                        size: 18.r,
                                      ),
                                    ],
                                  ),
                          ),
                        );
                      },
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
                          ? 'رزرو برای ${selectedDay.fullDisplayTitle} ساعت ${selectedSlot.timeLabel}'
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
  // باتم‌شیت تأیید نهایی و انتخاب روش پرداخت (آنلاین یا در مطب برای حضوری)
  // ---------------------------------------------------------------------------
  void _showBookingConfirmationSheet(
    BuildContext context, {
    required ProviderProfileModel provider,
    required OfferingModel offering,
    required _JalaliDayItem day,
    required AvailableSlotModel slot,
  }) {
    final bool isOnlineVisit = offering.visitMode == VisitModeType.onlineChat;
    if (isOnlineVisit) {
      _selectedInPersonPaymentMethod = PaymentMethodType.online;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final effectiveMethod = isOnlineVisit
                ? PaymentMethodType.online
                : _selectedInPersonPaymentMethod;

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: EdgeInsets.all(20.r),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'تأیید اطلاعات نوبت',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      '• پزشک: ${provider.displayName}\n'
                      '• نوع نوبت: ${offering.title}\n'
                      '• تاریخ: ${day.fullDisplayTitle}\n'
                      '• ساعت: ${slot.timeLabel}\n'
                      '• مبلغ قابل پرداخت: ${slot.priceFormatted} تومان',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.8,
                      ),
                    ),
                    if (!isOnlineVisit) ...[
                      SizedBox(height: 14.h),
                      Text(
                        'انتخاب روش پرداخت:',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPaymentMethodOption(
                              context,
                              title: 'پرداخت آنلاین',
                              icon: Icons.credit_card_rounded,
                              isSelected:
                                  effectiveMethod == PaymentMethodType.online,
                              onTap: () {
                                setSheetState(() {
                                  _selectedInPersonPaymentMethod =
                                      PaymentMethodType.online;
                                });
                              },
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: _buildPaymentMethodOption(
                              context,
                              title: 'پرداخت در مطب',
                              icon: Icons.payments_outlined,
                              isSelected:
                                  effectiveMethod == PaymentMethodType.inPerson,
                              onTap: () {
                                setSheetState(() {
                                  _selectedInPersonPaymentMethod =
                                      PaymentMethodType.inPerson;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 18.h),
                    SizedBox(
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _submitBloc.add(
                            CreateAppointmentBookingEvent(
                              providerId: provider.id,
                              offeringId: offering.id,
                              startAt: slot.rawStartAt,
                              paymentMethod: effectiveMethod.apiValue,
                              notes: _notesController.text.trim(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary500,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          effectiveMethod == PaymentMethodType.online
                              ? 'تأیید و انتقال به درگاه پرداخت'
                              : 'تأیید و ثبت نهایی نوبت',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentMethodOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 10.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary50
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primary500 : AppColors.text200Light,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18.r,
              color: isSelected
                  ? AppColors.primary500
                  : AppColors.onSurfaceVariant,
            ),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelMedium?.copyWith(
                  color: isSelected
                      ? AppColors.primary500
                      : AppColors.onSurface,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JalaliDayItem {
  final String topLabel;
  final String dayNumber;
  final String weekDayName;
  final String fullDisplayTitle;
  final String monthYearTitle;
  final String gregorianDate;

  const _JalaliDayItem({
    required this.topLabel,
    required this.dayNumber,
    required this.weekDayName,
    required this.fullDisplayTitle,
    required this.monthYearTitle,
    required this.gregorianDate,
  });
}
