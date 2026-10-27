import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reservation_chat_univercity_project/core/constants/app_setting.dart';
import 'package:reservation_chat_univercity_project/core/themes/app_colors.dart';
import 'package:reservation_chat_univercity_project/core/utils/navigator.dart';
import 'package:reservation_chat_univercity_project/core/widgets/global_error_section.dart';
import 'package:reservation_chat_univercity_project/core/widgets/global_loading_section.dart';
import 'package:reservation_chat_univercity_project/features/appointments/bloc/appointments_bloc.dart';
import 'package:reservation_chat_univercity_project/features/appointments/screens/payment_gateway_screen.dart';
import 'package:reservation_chat_univercity_project/features/appointments/service/model/appointment_models.dart';
import 'package:reservation_chat_univercity_project/features/profile/screens/notification_screen.dart';

enum AppointmentFilterTab { upcoming, completed, cancelled }

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  AppointmentFilterTab _currentTab = AppointmentFilterTab.upcoming;
  late final AnimationController _pulseController;
  late final AppointmentsBloc _bloc;

  List<AppointmentModel> _appointments = const [];
  String? _loadingTargetId;

  bool get _isDoctorView => currentUserModel.role == 'provider';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _bloc = AppointmentsBloc()
      ..add(FetchAppointmentsListEvent(isProviderRole: _isDoctorView));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bloc.close();
    super.dispose();
  }

  List<AppointmentModel> _getFilteredAppointments(AppointmentFilterTab tab) {
    return _appointments.where((item) {
      switch (tab) {
        case AppointmentFilterTab.upcoming:
          return item.status == AppointmentStatusType.confirmed ||
              item.status == AppointmentStatusType.pending;
        case AppointmentFilterTab.completed:
          return item.status == AppointmentStatusType.completed;
        case AppointmentFilterTab.cancelled:
          return item.status == AppointmentStatusType.cancelledByCustomer ||
              item.status == AppointmentStatusType.cancelledByProvider ||
              item.status == AppointmentStatusType.noShow;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AppointmentsBloc>.value(
      value: _bloc,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Column(
            children: [
              _buildTopHeader(context),
              Expanded(
                child: BlocConsumer<AppointmentsBloc, AppointmentsState>(
                  listener: (context, state) async {
                    if (state is AppointmentsListSuccessState) {
                      setState(() {
                        _appointments = state.appointments;
                        _loadingTargetId = null;
                      });
                    } else if (state is AppointmentActionLoadingState) {
                      setState(() {
                        _loadingTargetId = state.targetId;
                      });
                    } else if (state is AppointmentActionSuccessState) {
                      setState(() {
                        _loadingTargetId = null;
                      });
                      if (state.payUrl != null && state.payUrl!.isNotEmpty) {
                        final paid = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => PaymentGatewayScreen(
                              payUrl: state.payUrl!,
                              paymentId: state.paymentId,
                            ),
                          ),
                        );
                        if (paid == true && context.mounted) {
                          _bloc.add(
                            FetchAppointmentsListEvent(
                              isProviderRole: _isDoctorView,
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.green,
                            content: Text(state.message),
                          ),
                        );
                      }
                    } else if (state is AppointmentActionFailedState) {
                      setState(() {
                        _loadingTargetId = null;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.statusCancelledFg,
                          content: Text(state.message),
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is AppointmentsListLoadingState &&
                        _appointments.isEmpty) {
                      return GlobalLoadingSection();
                    }

                    if (state is AppointmentsListFailedState &&
                        _appointments.isEmpty) {
                      return GlobalErrorSection(
                        message: state.message,
                        onRetry: () {
                          _bloc.add(
                            FetchAppointmentsListEvent(
                              isProviderRole: _isDoctorView,
                            ),
                          );
                        },
                      );
                    }

                    final filteredList = _getFilteredAppointments(_currentTab);

                    return RefreshIndicator(
                      onRefresh: () async {
                        _bloc.add(
                          FetchAppointmentsListEvent(
                            isProviderRole: _isDoctorView,
                          ),
                        );
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ۱. تب‌بندی وضعیت نوبت‌ها (بدون سوییچر نقش؛ هر کاربر فقط نقش خودش را می‌بیند)
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
                                separatorBuilder: (_, __) =>
                                    SizedBox(height: 14.h),
                                itemBuilder: (context, index) {
                                  final item = filteredList[index];
                                  return _buildAppointmentCard(context, item);
                                },
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
                    _isDoctorView ? 'مدیریت نوبت‌های بیماران' : 'نوبت‌های من',
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
                    toPersianDigits(count.toString()),
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
  // ۲. کارت نوبت
  // ---------------------------------------------------------------------------
  Widget _buildAppointmentCard(BuildContext context, AppointmentModel item) {
    final textTheme = Theme.of(context).textTheme;
    final bool isOnline = item.visitMode == VisitModeType.onlineChat;

    final String counterpartName = _isDoctorView
        ? item.customer.fullName
        : item.provider.displayName;
    final String counterpartSubtitle = _isDoctorView
        ? 'بیمار • ${item.offering.title}'
        : item.provider.specialtiesTitle;

    final bool isLiveOnlineSession =
        isOnline &&
        item.status == AppointmentStatusType.confirmed &&
        item.isCurrentlyInProgress;

    final bool canCancel =
        (item.status == AppointmentStatusType.confirmed ||
            item.status == AppointmentStatusType.pending) &&
        !item.hasStarted;

    final bool canDoctorComplete =
        _isDoctorView &&
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

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    _buildCounterpartAvatar(context, counterpartName),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            counterpartName,
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
                            counterpartSubtitle,
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
              _buildVisitModeBadge(context, item.visitMode),
            ],
          ),
          SizedBox(height: 12.h),

          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                            '#${item.shortId}',
                            style: textTheme.titleSmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      item.priceFormatted,
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

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

                if (item.notes.isNotEmpty) ...[
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
                          item.notes,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurface,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                if (item.cancelReason.isNotEmpty) ...[
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

          _buildStatusBanner(context, item),
          SizedBox(height: 12.h),

          _buildCardActions(
            context,
            item: item,
            counterpartName: counterpartName,
            isOnline: isOnline,
            canCancel: canCancel,
            canDoctorComplete: canDoctorComplete,
          ),
        ],
      ),
    );
  }

  Widget _buildCounterpartAvatar(BuildContext context, String name) {
    final String initial = name.trim().isNotEmpty
        ? name.trim().substring(0, 1)
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

  Widget _buildVisitModeBadge(BuildContext context, VisitModeType visitMode) {
    final textTheme = Theme.of(context).textTheme;
    final bool isOnline = visitMode == VisitModeType.onlineChat;

    final Color bgColor = isOnline
        ? AppColors.statusConfirmedBg
        : AppColors.statusPendingApprovalBg;
    final Color fgColor = isOnline
        ? AppColors.statusConfirmedFg
        : AppColors.statusPendingApprovalFg;

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

  Widget _buildStatusBanner(BuildContext context, AppointmentModel item) {
    final textTheme = Theme.of(context).textTheme;

    late final Color bgColor;
    late final Color fgColor;
    late final IconData icon;
    late final String statusText;

    final awaitingOnlinePayment =
        item.status == AppointmentStatusType.pending &&
        item.payment != null &&
        item.payment!.method == PaymentMethodType.online &&
        item.payment!.status != PaymentStatusType.paid;

    switch (item.status) {
      case AppointmentStatusType.pending:
        bgColor = AppColors.statusPendingPaymentBg;
        fgColor = AppColors.statusPendingPaymentFg;
        icon = Icons.hourglass_top_rounded;
        statusText = awaitingOnlinePayment
            ? 'در انتظار تکمیل پرداخت آنلاین'
            : 'در انتظار تأیید پزشک';
        break;
      case AppointmentStatusType.confirmed:
        bgColor = AppColors.surfaceContainer;
        fgColor = AppColors.primary500;
        icon = Icons.verified_rounded;
        statusText = item.visitMode == VisitModeType.onlineChat
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
      case AppointmentStatusType.noShow:
        bgColor = AppColors.statusCancelledBg;
        fgColor = AppColors.statusCancelledFg;
        icon = Icons.person_off_outlined;
        statusText = 'عدم مراجعه بیمار';
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
  // ۳. دکمه‌های عملیاتی روی کارت
  // ---------------------------------------------------------------------------
  Widget _buildCardActions(
    BuildContext context, {
    required AppointmentModel item,
    required String counterpartName,
    required bool isOnline,
    required bool canCancel,
    required bool canDoctorComplete,
  }) {
    final textTheme = Theme.of(context).textTheme;

    if (item.status == AppointmentStatusType.cancelledByCustomer ||
        item.status == AppointmentStatusType.cancelledByProvider ||
        item.status == AppointmentStatusType.noShow) {
      return const SizedBox.shrink();
    }

    final bool isBusy =
        _loadingTargetId == item.id ||
        (item.payment != null && _loadingTargetId == item.payment!.id);

    final bool canCustomerPayOnline =
        !_isDoctorView &&
        item.status == AppointmentStatusType.pending &&
        item.payment != null &&
        item.payment!.method == PaymentMethodType.online &&
        (item.payment!.status == PaymentStatusType.pending ||
            item.payment!.status == PaymentStatusType.failed);

    final bool canDoctorConfirmPending =
        _isDoctorView &&
        item.status == AppointmentStatusType.pending &&
        (item.payment == null ||
            item.payment!.method == PaymentMethodType.inPerson ||
            item.payment!.status == PaymentStatusType.paid);

    final bool canDoctorMarkInPersonPaid =
        _isDoctorView &&
        item.payment != null &&
        item.payment!.method == PaymentMethodType.inPerson &&
        item.payment!.status == PaymentStatusType.pending &&
        (item.status == AppointmentStatusType.confirmed ||
            item.status == AppointmentStatusType.completed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canCustomerPayOnline) ...[
          SizedBox(
            height: 46.h,
            child: ElevatedButton.icon(
              onPressed: isBusy
                  ? null
                  : () {
                      _bloc.add(
                        RetryOnlinePaymentEvent(paymentId: item.payment!.id),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              icon: Icon(Icons.payment_rounded, size: 18.r),
              label: const Text('پرداخت آنلاین نوبت'),
            ),
          ),
          SizedBox(height: 8.h),
        ],

        Row(
          children: [
            if (isOnline)
              Expanded(
                child: SizedBox(
                  height: 46.h,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // طبق دستور شما فعلاً دکمه ورود به اتاق چت کاری انجام نمی‌دهد
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary500,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    icon: Icon(Icons.chat_bubble_outline_rounded, size: 18.r),
                    label: Text(
                      _isDoctorView
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
            else if (canDoctorConfirmPending)
              Expanded(
                child: SizedBox(
                  height: 46.h,
                  child: OutlinedButton.icon(
                    onPressed: isBusy
                        ? null
                        : () {
                            _bloc.add(
                              ConfirmAppointmentByDoctorEvent(
                                appointmentId: item.id,
                              ),
                            );
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
                    icon: Icon(Icons.check_circle_outline_rounded, size: 18.r),
                    label: Text(
                      'تأیید نوبت بیمار',
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),

            if (canCancel) ...[
              if (isOnline || canDoctorConfirmPending) SizedBox(width: 8.w),
              Expanded(
                flex: (isOnline || canDoctorConfirmPending) ? 0 : 1,
                child: SizedBox(
                  height: 46.h,
                  child: TextButton.icon(
                    onPressed: isBusy
                        ? null
                        : () =>
                              _showCancelDialog(context, item, counterpartName),
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
              ),
            ],
          ],
        ),

        if (canDoctorMarkInPersonPaid) ...[
          SizedBox(height: 8.h),
          SizedBox(
            height: 44.h,
            child: OutlinedButton.icon(
              onPressed: isBusy
                  ? null
                  : () {
                      _bloc.add(
                        MarkInPersonPaymentPaidEvent(
                          paymentId: item.payment!.id,
                        ),
                      );
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary500,
                side: const BorderSide(color: AppColors.primary500),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              icon: Icon(Icons.payments_outlined, size: 18.r),
              label: const Text('تأیید دریافت هزینه حضوری در مطب'),
            ),
          ),
        ],

        if (canDoctorComplete) ...[
          SizedBox(height: 8.h),
          SizedBox(
            height: 44.h,
            child: ElevatedButton.icon(
              onPressed: isBusy
                  ? null
                  : () => _showCompleteVisitConfirmation(
                      context,
                      item,
                      counterpartName,
                    ),
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
            'لیست نوبت‌های شما در این وضعیت خالی است.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(
    BuildContext context,
    AppointmentModel item,
    String counterpartName,
  ) {
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
                  'لغو نوبت #${item.shortId}',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8.h),
                Text(
                  'آیا از لغو نوبت «$counterpartName» در تاریخ ${item.jalaliDateText} اطمینان دارید؟',
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
                          _bloc.add(
                            CancelAppointmentEvent(
                              appointmentId: item.id,
                              cancelReason: reasonController.text.trim(),
                              isProviderRole: _isDoctorView,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.statusCancelledFg,
                          foregroundColor: Colors.white,
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

  void _showCompleteVisitConfirmation(
    BuildContext context,
    AppointmentModel item,
    String counterpartName,
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
              'با ثبت پایان ویزیت، وضعیت نوبت «$counterpartName» به تکمیل‌شده تغییر می‌یابد و ارسال پیام برای بیمار قفل می‌شود.\n\nشما همچنان در هر زمان می‌توانید کد رهگیری نسخه یا دستور آزمایش را در چت برای بیمار ارسال کنید.',
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
                  _bloc.add(
                    CompleteOnlineVisitByDoctorEvent(appointmentId: item.id),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary500,
                  foregroundColor: Colors.white,
                ),
                child: const Text('ثبت پایان ویزیت'),
              ),
            ],
          ),
        );
      },
    );
  }
}
