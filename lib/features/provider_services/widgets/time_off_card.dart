import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reservation_chat_univercity_project/core/themes/app_colors.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/service/model/provider_services_models.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/widgets/provider_service_shared_widgets.dart';

/// Card displaying a single provider time-off window.
class TimeOffCard extends StatelessWidget {
  final TimeOffModel timeOff;
  final bool isBusy;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onEdit;

  const TimeOffCard({
    super.key,
    required this.timeOff,
    required this.isBusy,
    required this.onToggleActive,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final active = timeOff.isActive;
    final (statusLabel, fgColor, bgColor) = _resolveStatusBadge();

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: active
            ? AppColors.surfaceContainerLowest
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: timeOff.isOngoing
              ? AppColors.primary300
              : (active ? AppColors.text200Light : AppColors.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.event_busy_rounded,
                  size: 20.r,
                  color: fgColor,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  timeOff.jalaliRangeSummary,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: active
                        ? AppColors.onSurface
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              ProviderStatusChip(
                label: statusLabel,
                fgColor: fgColor,
                bgColor: bgColor,
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            timeOff.reason.trim().isNotEmpty
                ? 'علت: ${timeOff.reason.trim()}'
                : 'بدون توضیح ثبت‌شده',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              if (isBusy)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: SizedBox(
                    width: 18.r,
                    height: 18.r,
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
                    Switch.adaptive(
                      value: active,
                      onChanged: onToggleActive,
                      activeTrackColor: AppColors.primary500,
                    ),
                    Text(
                      active ? 'بازه مسدود است' : 'لغو شده',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: isBusy ? null : onEdit,
                icon: Icon(Icons.edit_outlined, size: 16.r),
                label: const Text('ویرایش'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary500,
                  side: const BorderSide(color: AppColors.primary200),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  (String, Color, Color) _resolveStatusBadge() {
    if (!timeOff.isActive) {
      return (
        'لغوشده',
        AppColors.statusCancelledFg,
        AppColors.statusCancelledBg,
      );
    }
    if (timeOff.isOngoing) {
      return ('در جریان', AppColors.primary500, AppColors.primary50);
    }
    if (timeOff.isEnded) {
      return (
        'پایان‌یافته',
        AppColors.onSurfaceVariant,
        AppColors.surfaceContainer,
      );
    }
    return (
      'پیش‌رو',
      AppColors.statusConfirmedFg,
      AppColors.statusConfirmedBg,
    );
  }
}

