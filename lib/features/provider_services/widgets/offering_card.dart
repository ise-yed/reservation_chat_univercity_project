import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reservation_chat_univercity_project/core/themes/app_colors.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/service/model/provider_services_models.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/widgets/provider_service_shared_widgets.dart';

/// Card displaying a single provider offering (consultation/visit service).
class OfferingCard extends StatelessWidget {
  final ProviderOfferingModel offering;
  final bool canManage;
  final bool isBusy;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onEdit;

  const OfferingCard({
    super.key,
    required this.offering,
    required this.canManage,
    required this.isBusy,
    required this.onToggleActive,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool active = offering.isActive;
    final bool isOnline = offering.isOnline;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: active
            ? AppColors.surfaceContainerLowest
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: active ? AppColors.text200Light : AppColors.outlineVariant,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.text700Light.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42.r,
                height: 42.r,
                decoration: BoxDecoration(
                  color: isOnline
                      ? AppColors.onlineChatBg
                      : AppColors.inPersonVisitBg,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  isOnline
                      ? Icons.chat_bubble_outline_rounded
                      : Icons.medical_services_outlined,
                  size: 20.r,
                  color: isOnline
                      ? AppColors.onlineChatFg
                      : AppColors.inPersonVisitFg,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            offering.title,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: active
                                  ? AppColors.onSurface
                                  : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        ProviderStatusChip(
                          label: active ? 'فعال' : 'غیرفعال',
                          fgColor: active
                              ? AppColors.statusConfirmedFg
                              : AppColors.onSurfaceVariant,
                          bgColor: active
                              ? AppColors.statusConfirmedBg
                              : AppColors.surfaceContainer,
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 6.h,
                      children: [
                        ProviderStatusChip(
                          label: offering.visitModeLabel,
                          fgColor: isOnline
                              ? AppColors.onlineChatFg
                              : AppColors.inPersonVisitFg,
                          bgColor: isOnline
                              ? AppColors.onlineChatBg
                              : AppColors.inPersonVisitBg,
                          icon: isOnline
                              ? Icons.videocam_outlined
                              : Icons.location_on_outlined,
                        ),
                        if (offering.specialty != null)
                          ProviderStatusChip(
                            label: offering.specialty!.name,
                            fgColor: AppColors.primary500,
                            bgColor: AppColors.primary50,
                          ),
                        if (offering.requiresApproval)
                          const ProviderStatusChip(
                            label: 'نیازمند تأیید پزشک',
                            fgColor: AppColors.statusPendingApprovalFg,
                            bgColor: AppColors.statusPendingApprovalBg,
                            icon: Icons.verified_outlined,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (offering.description.trim().isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              offering.description.trim(),
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: active ? AppColors.surface : AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 16.r,
                  color: AppColors.onSurfaceVariant,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    offering.hasBuffers
                        ? '${offering.durationLabel} • ${offering.bufferSummaryText}'
                        : 'مدت ویزیت: ${offering.durationLabel}',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  offering.priceLabel,
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.primary500,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (canManage) ...[
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
                        active ? 'قابل رزرو' : 'متوقف‌شده',
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
        ],
      ),
    );
  }
}

