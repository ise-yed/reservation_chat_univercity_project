import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reservation_chat_univercity_project/core/themes/app_colors.dart';
import 'package:reservation_chat_univercity_project/core/widgets/global_error_section.dart';
import 'package:reservation_chat_univercity_project/core/widgets/global_loading_section.dart';
import 'package:reservation_chat_univercity_project/features/appointments/service/model/appointment_models.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/bloc/provider_services_bloc.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/service/model/provider_services_models.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/widgets/offering_card.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/widgets/offering_form_sheet.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/widgets/provider_service_shared_widgets.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/widgets/provider_settings_sheet.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/widgets/time_off_card.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/widgets/time_off_form_sheet.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/widgets/working_hour_card.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/widgets/working_hour_form_sheet.dart';

/// Main screen for provider's "خدمات من" tab:
/// manages offerings/pricing (for clinic owners), weekly working hours,
/// time-offs, and base slot settings.
class MyServicesScreen extends StatefulWidget {
  final ProviderServicesBloc? bloc;

  const MyServicesScreen({super.key, this.bloc});

  @override
  State<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends State<MyServicesScreen> {
  late final ProviderServicesBloc _bloc;
  late final bool _ownsBloc;
  int _selectedTabIndex = 0;
  bool _isSheetOpen = false;

  @override
  void initState() {
    super.initState();
    _ownsBloc = widget.bloc == null;
    _bloc = widget.bloc ?? ProviderServicesBloc();
    if (_bloc.state is ProviderServicesInitial) {
      _bloc.add(LoadProviderServicesEvent());
    }
  }

  @override
  void dispose() {
    if (_ownsBloc) {
      _bloc.close();
    }
    super.dispose();
  }

  Future<void> _onRefresh() async {
    _bloc.add(LoadProviderServicesEvent(silent: true));
    await _bloc.stream
        .firstWhere(
          (state) =>
              state is ProviderServicesLoaded ||
              state is ProviderServicesEmptyProfile ||
              state is ProviderServicesError ||
              state is ProviderServiceActionError,
        )
        .timeout(
          const Duration(seconds: 12),
          onTimeout: () => _bloc.state,
        );
  }

  Future<void> _openSheet(Widget sheet) async {
    _isSheetOpen = true;
    try {
      await showProviderModalSheet<void>(
        context: context,
        builder: (_) => sheet,
      );
    } finally {
      _isSheetOpen = false;
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? AppColors.statusCancelledFg
            : AppColors.primary500,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppColors.surface,
          body: Column(
            children: [
              _MyServicesTopBar(
                onRefresh: () => _bloc.add(LoadProviderServicesEvent()),
              ),
              Expanded(
                child: BlocConsumer<ProviderServicesBloc, ProviderServicesState>(
                  listener: (context, state) {
                    if (state is ProviderServiceActionSuccess) {
                      _showSnackBar(state.message, isError: false);
                    } else if (state is ProviderServiceActionError &&
                        !_isSheetOpen) {
                      _showSnackBar(state.message, isError: true);
                    }
                  },
                  builder: (context, state) {
                    if (state is ProviderServicesInitial ||
                        state is ProviderServicesLoading) {
                      return GlobalLoadingSection();
                    }

                    if (state is ProviderServicesError) {
                      return GlobalErrorSection(
                        message: state.message,
                        onRetry: () => _bloc.add(LoadProviderServicesEvent()),
                      );
                    }

                    if (state is ProviderServicesEmptyProfile) {
                      return _EmptyProviderProfileView(
                        onRetry: () => _bloc.add(LoadProviderServicesEvent()),
                      );
                    }

                    final data = state.dataOrNull;
                    if (data == null) {
                      return GlobalLoadingSection();
                    }

                    final busyTargetId = state is ProviderServiceActionLoading
                        ? state.targetId
                        : null;

                    return RefreshIndicator(
                      color: AppColors.primary500,
                      onRefresh: _onRefresh,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (data.profiles.length > 1) ...[
                              ProviderProfileSwitcherBar(
                                profiles: data.profiles,
                                selectedProfileId: data.selectedProfile.id,
                                onSelect: (id) => _bloc.add(
                                  SelectProviderProfileEvent(providerId: id),
                                ),
                              ),
                              SizedBox(height: 12.h),
                            ],
                            ProviderProfileHeaderCard(
                              profile: data.selectedProfile,
                              canManageOfferings: data.canManageOfferings,
                              onEditSettings: () => _openSheet(
                                ProviderSettingsSheet(
                                  bloc: _bloc,
                                  profile: data.selectedProfile,
                                ),
                              ),
                            ),
                            SizedBox(height: 14.h),
                            _SegmentedTabs(
                              selectedIndex: _selectedTabIndex,
                              offeringsCount: data.offerings.length,
                              workingHoursCount: data.workingHours.length,
                              timeOffsCount: data.timeOffs.length,
                              onSelect: (index) {
                                setState(() => _selectedTabIndex = index);
                              },
                            ),
                            SizedBox(height: 16.h),
                            if (_selectedTabIndex == 0)
                              _buildOfferingsSection(data, busyTargetId)
                            else if (_selectedTabIndex == 1)
                              _buildWorkingHoursSection(data, busyTargetId)
                            else
                              _buildTimeOffsSection(data, busyTargetId),
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

  Widget _buildOfferingsSection(
    ProviderServicesData data,
    String? busyTargetId,
  ) {
    final canManage = data.canManageOfferings;

    void openOfferingSheet([ProviderOfferingModel? existing]) {
      _openSheet(
        OfferingFormSheet(
          bloc: _bloc,
          categories: data.categories,
          defaultDurationMinutes:
              data.selectedProfile.defaultSlotDurationMinutes,
          existing: existing,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProviderSectionHeaderRow(
          title: 'خدمات و تعرفه‌ها',
          count: data.offerings.length,
          actionLabel: canManage ? 'خدمت جدید' : null,
          onAction: canManage ? () => openOfferingSheet() : null,
        ),
        if (!canManage) ...[
          SizedBox(height: 10.h),
          const _ReadOnlyOfferingsNotice(),
        ],
        SizedBox(height: 12.h),
        if (data.offerings.isEmpty)
          ProviderSectionEmptyState(
            icon: Icons.medical_services_outlined,
            title: 'هنوز خدمتی ثبت نشده است',
            subtitle: canManage
                ? 'برای فعال‌سازی نوبت‌دهی بیماران، اولین خدمت و تعرفه ویزیت خود را اضافه کنید.'
                : 'مدیر مرکز هنوز خدمتی برای پروفایل شما تعریف نکرده است.',
            actionLabel: canManage ? 'افزودن خدمت جدید' : null,
            onAction: canManage ? () => openOfferingSheet() : null,
          )
        else
          ...data.offerings.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: OfferingCard(
                offering: item,
                canManage: canManage,
                isBusy: busyTargetId == item.id,
                onToggleActive: (value) => _bloc.add(
                  ToggleOfferingStatusEvent(offering: item, isActive: value),
                ),
                onEdit: () => openOfferingSheet(item),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWorkingHoursSection(
    ProviderServicesData data,
    String? busyTargetId,
  ) {
    void openWorkingHourSheet([WorkingHourModel? existing]) {
      _openSheet(
        WorkingHourFormSheet(
          bloc: _bloc,
          existingWorkingHours: data.workingHours,
          existing: existing,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProviderSectionHeaderRow(
          title: 'ساعات کاری هفتگی',
          count: data.workingHours.length,
          actionLabel: 'ساعت جدید',
          onAction: () => openWorkingHourSheet(),
        ),
        SizedBox(height: 12.h),
        WorkingWeekSummaryStrip(workingHours: data.workingHours),
        SizedBox(height: 12.h),
        if (data.workingHours.isEmpty)
          ProviderSectionEmptyState(
            icon: Icons.calendar_month_outlined,
            title: 'ساعت کاری ثبت نشده است',
            subtitle:
                'روزها و بازه‌های زمانی حضور خود را تعیین کنید تا اسلات‌های نوبت‌دهی ایجاد شوند.',
            actionLabel: 'افزودن ساعت کاری',
            onAction: () => openWorkingHourSheet(),
          )
        else
          ...data.workingHours.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: WorkingHourCard(
                workingHour: item,
                isBusy: busyTargetId == item.id,
                onToggleActive: (value) => _bloc.add(
                  ToggleWorkingHourStatusEvent(
                    workingHour: item,
                    isActive: value,
                  ),
                ),
                onEdit: () => openWorkingHourSheet(item),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTimeOffsSection(
    ProviderServicesData data,
    String? busyTargetId,
  ) {
    void openTimeOffSheet([TimeOffModel? existing]) {
      _openSheet(
        TimeOffFormSheet(
          bloc: _bloc,
          existing: existing,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProviderSectionHeaderRow(
          title: 'مرخصی‌ها و عدم حضور',
          count: data.timeOffs.length,
          actionLabel: 'ثبت مرخصی',
          onAction: () => openTimeOffSheet(),
        ),
        SizedBox(height: 12.h),
        if (data.timeOffs.isEmpty)
          ProviderSectionEmptyState(
            icon: Icons.event_busy_outlined,
            title: 'مرخصی‌ای ثبت نشده است',
            subtitle:
                'در صورت نیاز به مسدود کردن موقت نوبت‌ها در تاریخ مشخص، بازه مرخصی ثبت کنید.',
            actionLabel: 'ثبت مرخصی جدید',
            onAction: () => openTimeOffSheet(),
          )
        else
          ...data.timeOffs.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: TimeOffCard(
                timeOff: item,
                isBusy: busyTargetId == item.id,
                onToggleActive: (value) => _bloc.add(
                  ToggleTimeOffStatusEvent(timeOff: item, isActive: value),
                ),
                onEdit: () => openTimeOffSheet(item),
              ),
            ),
          ),
      ],
    );
  }
}

class _MyServicesTopBar extends StatelessWidget {
  final VoidCallback onRefresh;

  const _MyServicesTopBar({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.95),
        border: const Border(
          bottom: BorderSide(color: AppColors.text200Light, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          constraints: BoxConstraints(minHeight: 60.h),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            children: [
              Container(
                width: 38.r,
                height: 38.r,
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(11.r),
                ),
                child: Icon(
                  Icons.medical_services_rounded,
                  color: AppColors.primary500,
                  size: 20.r,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'خدمات من',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'مدیریت خدمات، ساعات کاری و مرخصی‌ها',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRefresh,
                tooltip: 'بروزرسانی',
                icon: Icon(
                  Icons.refresh_rounded,
                  color: AppColors.primary500,
                  size: 22.r,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final int selectedIndex;
  final int offeringsCount;
  final int workingHoursCount;
  final int timeOffsCount;
  final ValueChanged<int> onSelect;

  const _SegmentedTabs({
    required this.selectedIndex,
    required this.offeringsCount,
    required this.workingHoursCount,
    required this.timeOffsCount,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      ('خدمات و تعرفه‌ها', offeringsCount),
      ('ساعات کاری', workingHoursCount),
      ('مرخصی‌ها', timeOffsCount),
    ];

    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.text200Light),
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final selected = index == selectedIndex;
          final (label, count) = items[index];
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary500
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: selected
                            ? Colors.white
                            : AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.sp,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '(${toPersianDigits(count.toString())})',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.9)
                            : AppColors.onSurfaceVariant,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ReadOnlyOfferingsNotice extends StatelessWidget {
  const _ReadOnlyOfferingsNotice();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.primary200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18.r,
            color: AppColors.primary500,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'تعریف و تغییر تعرفه خدمات این مرکز بر عهده مدیر مرکز است؛ شما می‌توانید ساعات کاری، مرخصی‌ها و زمان‌بندی پایه خود را مدیریت کنید.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.primary700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyProviderProfileView extends StatelessWidget {
  final VoidCallback onRetry;

  const _EmptyProviderProfileView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64.r,
              height: 64.r,
              decoration: const BoxDecoration(
                color: AppColors.primary50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.badge_outlined,
                size: 32.r,
                color: AppColors.primary500,
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              'پروفایل پزشکی فعالی یافت نشد',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'حساب کاربری شما با نقش پزشک ثبت شده اما هنوز پروفایل درمانی به یک مرکز برای شما متصل نشده است.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 16.h),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('بررسی مجدد'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary500,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
