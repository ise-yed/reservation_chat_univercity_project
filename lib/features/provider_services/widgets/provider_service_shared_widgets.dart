import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reservation_chat_univercity_project/core/themes/app_colors.dart';
import 'package:reservation_chat_univercity_project/features/appointments/service/model/appointment_models.dart';
import 'package:reservation_chat_univercity_project/features/home/services/model/home_models.dart';

/// Compact rounded pill used across offering, working-hour, and time-off cards.
class ProviderStatusChip extends StatelessWidget {
  final String label;
  final Color fgColor;
  final Color bgColor;
  final IconData? icon;

  const ProviderStatusChip({
    super.key,
    required this.label,
    required this.fgColor,
    required this.bgColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13.r, color: fgColor),
            SizedBox(width: 4.w),
          ],
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w700,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section header with title, Persian item count, and optional action button.
class ProviderSectionHeaderRow extends StatelessWidget {
  final String title;
  final int count;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ProviderSectionHeaderRow({
    super.key,
    required this.title,
    required this.count,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Text(
                title,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  toPersianDigits(count.toString()),
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.primary500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          FilledButton.icon(
            onPressed: onAction,
            icon: Icon(Icons.add_rounded, size: 18.r),
            label: Text(actionLabel!),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary500,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              textStyle: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

/// Empty-state card displayed when a tab currently has no items.
class ProviderSectionEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ProviderSectionEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 28.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.text200Light),
      ),
      child: Column(
        children: [
          Container(
            width: 56.r,
            height: 56.r,
            decoration: const BoxDecoration(
              color: AppColors.primary50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28.r, color: AppColors.primary500),
          ),
          SizedBox(height: 12.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6.h),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: 16.h),
            FilledButton.icon(
              onPressed: onAction,
              icon: Icon(Icons.add_rounded, size: 18.r),
              label: Text(actionLabel!),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary500,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Top clinic summary card with quick access to edit base scheduling settings.
class ProviderProfileHeaderCard extends StatelessWidget {
  final ProviderProfileModel profile;
  final bool canManageOfferings;
  final VoidCallback onEditSettings;

  const ProviderProfileHeaderCard({
    super.key,
    required this.profile,
    required this.canManageOfferings,
    required this.onEditSettings,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.text200Light),
        boxShadow: [
          BoxShadow(
            color: AppColors.text700Light.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42.r,
                height: 42.r,
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.local_hospital_rounded,
                  color: AppColors.primary500,
                  size: 22.r,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.clinicDisplayTitle,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      profile.specialtiesTitle,
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
                onPressed: onEditSettings,
                tooltip: 'تنظیمات پایه زمان‌بندی',
                icon: Icon(
                  Icons.tune_rounded,
                  color: AppColors.primary500,
                  size: 22.r,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            children: [
              ProviderStatusChip(
                label:
                    'مدت پایه اسلات: ${toPersianDigits(profile.defaultSlotDurationMinutes.toString())} دقیقه',
                fgColor: AppColors.primary500,
                bgColor: AppColors.primary50,
                icon: Icons.schedule_rounded,
              ),
              ProviderStatusChip(
                label: canManageOfferings
                    ? 'دسترسی کامل خدمات و تعرفه'
                    : 'مدیریت زمان‌بندی و مرخصی',
                fgColor: canManageOfferings
                    ? AppColors.statusConfirmedFg
                    : AppColors.onSurfaceVariant,
                bgColor: canManageOfferings
                    ? AppColors.statusConfirmedBg
                    : AppColors.surfaceContainerLow,
                icon: canManageOfferings
                    ? Icons.verified_user_rounded
                    : Icons.event_available_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Clinic selector strip shown when a provider belongs to multiple centers.
class ProviderProfileSwitcherBar extends StatelessWidget {
  final List<ProviderProfileModel> profiles;
  final String selectedProfileId;
  final ValueChanged<String> onSelect;

  const ProviderProfileSwitcherBar({
    super.key,
    required this.profiles,
    required this.selectedProfileId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      height: 40.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: profiles.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final item = profiles[index];
          final selected = item.id == selectedProfileId;
          return ChoiceChip(
            selected: selected,
            onSelected: (_) => onSelect(item.id),
            label: Text(item.clinicDisplayTitle),
            labelStyle: textTheme.labelMedium?.copyWith(
              color: selected ? Colors.white : AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
            selectedColor: AppColors.primary500,
            backgroundColor: AppColors.surfaceContainerLowest,
            side: BorderSide(
              color: selected ? AppColors.primary500 : AppColors.text200Light,
            ),
            showCheckmark: false,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          );
        },
      ),
    );
  }
}

/// Standard modal bottom sheet header matching the app's RTL design system.
class ProviderSheetHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const ProviderSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
        ),
        SizedBox(height: 14.h),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      subtitle!,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ],
    );
  }
}

/// Inline error callout rendered inside modal bottom sheets on failed submits.
class ProviderSheetErrorBanner extends StatelessWidget {
  final String message;

  const ProviderSheetErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.statusCancelledBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.statusCancelledFg.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 18.r,
            color: AppColors.statusCancelledFg,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.statusCancelledFg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Primary submit button with built-in loading spinner state.
class ProviderPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const ProviderPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary500,
        foregroundColor: Colors.white,
        minimumSize: Size.fromHeight(48.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      child: isLoading
          ? SizedBox(
              width: 20.r,
              height: 20.r,
              child: const CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
    );
  }
}

/// Shows the app-consistent Persian bottom sheet wrapper.
Future<T?> showProviderModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceContainerLowest,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
    ),
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: builder(ctx),
    ),
  );
}

