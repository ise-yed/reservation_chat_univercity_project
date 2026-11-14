import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reservation_chat_univercity_project/core/themes/app_colors.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/service/model/provider_services_models.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/widgets/provider_service_shared_widgets.dart';

/// Compact 7-day coverage indicator ordered Saturday..Friday.
class WorkingWeekSummaryStrip extends StatelessWidget {
  final List<WorkingHourModel> workingHours;

  const WorkingWeekSummaryStrip({super.key, required this.workingHours});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final activeDays = workingHours
        .where((w) => w.isActive)
        .map((w) => w.weekday)
        .toSet();

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.text200Light),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'پوشش هفتگی نوبت‌دهی',
            style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: PersianWeekdays.orderedCodes.map((code) {
              final hasShift = activeDays.contains(code);
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: hasShift
                      ? AppColors.primary500
                      : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  PersianWeekdays.nameOf(code),
                  style: textTheme.labelMedium?.copyWith(
                    color: hasShift ? Colors.white : AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.sp,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Card displaying a single weekly working-hour shift.
class WorkingHourCard extends StatelessWidget {
  final WorkingHourModel workingHour;
  final bool isBusy;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onEdit;

  const WorkingHourCard({
    super.key,
    required this.workingHour,
    required this.isBusy,
    required this.onToggleActive,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final active = workingHour.isActive;

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: active
            ? AppColors.surfaceContainerLowest
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: active ? AppColors.text200Light : AppColors.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 72.w,
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 6.w),
            decoration: BoxDecoration(
              color: active ? AppColors.primary50 : AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                Text(
                  workingHour.persianWeekdayName,
                  textAlign: TextAlign.center,
                  style: textTheme.labelLarge?.copyWith(
                    color: active
                        ? AppColors.primary500
                        : AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  active ? 'فعال' : 'غیرفعال',
                  style: textTheme.labelSmall?.copyWith(
                    color: active
                        ? AppColors.statusConfirmedFg
                        : AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workingHour.timeRangeLabel,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: active
                        ? AppColors.onSurface
                        : AppColors.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 6.h),
                ProviderStatusChip(
                  label: workingHour.durationLabel,
                  fgColor: AppColors.onSurfaceVariant,
                  bgColor: active
                      ? AppColors.surface
                      : AppColors.surfaceContainerLowest,
                  icon: Icons.schedule_rounded,
                ),
              ],
            ),
          ),
          if (isBusy)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: SizedBox(
                width: 20.r,
                height: 20.r,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary500,
                ),
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onEdit,
                  tooltip: 'ویرایش ساعت کاری',
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 20.r,
                    color: AppColors.primary500,
                  ),
                ),
                Switch.adaptive(
                  value: active,
                  onChanged: onToggleActive,
                  activeTrackColor: AppColors.primary500,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

