import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reservation_chat_univercity_project/core/themes/app_colors.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/bloc/provider_services_bloc.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/service/model/provider_services_models.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/widgets/provider_service_shared_widgets.dart';

/// Modal bottom sheet for creating or editing a weekly working hour shift.
class WorkingHourFormSheet extends StatefulWidget {
  final ProviderServicesBloc bloc;
  final List<WorkingHourModel> existingWorkingHours;
  final WorkingHourModel? existing;

  const WorkingHourFormSheet({
    super.key,
    required this.bloc,
    required this.existingWorkingHours,
    this.existing,
  });

  @override
  State<WorkingHourFormSheet> createState() => _WorkingHourFormSheetState();
}

class _WorkingHourFormSheetState extends State<WorkingHourFormSheet> {
  late int _weekday;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late bool _isActive;
  String? _errorMessage;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _weekday = item?.weekday ?? 5; // Default to Saturday.
    _startTime = item?.startTimeOfDay ?? const TimeOfDay(hour: 9, minute: 0);
    _endTime = item?.endTimeOfDay ?? const TimeOfDay(hour: 13, minute: 0);
    _isActive = item?.isActive ?? true;
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: isStart ? 'ساعت شروع کار' : 'ساعت پایان کار',
      cancelText: 'انصراف',
      confirmText: 'تأیید',
      builder: (dialogCtx, child) {
        return MediaQuery(
          data: MediaQuery.of(dialogCtx).copyWith(alwaysUse24HourFormat: true),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
    if (picked == null) return;
    setState(() {
      _errorMessage = null;
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  void _submit() {
    final startMin = WorkingHourModel.timeOfDayToMinutes(_startTime);
    final endMin = WorkingHourModel.timeOfDayToMinutes(_endTime);

    if (endMin <= startMin) {
      setState(() {
        _errorMessage = 'ساعت پایان باید بعد از ساعت شروع باشد.';
      });
      return;
    }

    if (_isActive) {
      final hasOverlap = widget.existingWorkingHours.any(
        (item) => item.overlapsWith(
          candidateWeekday: _weekday,
          candidateStartMinutes: startMin,
          candidateEndMinutes: endMin,
          excludingId: widget.existing?.id,
        ),
      );
      if (hasOverlap) {
        setState(() {
          _errorMessage =
              'این بازه با یکی از ساعات کاری فعال روز ${PersianWeekdays.nameOf(_weekday)} هم‌پوشانی دارد.';
        });
        return;
      }
    }

    setState(() => _errorMessage = null);

    final startStr = WorkingHourModel.formatTimeOfDayApi(_startTime);
    final endStr = WorkingHourModel.formatTimeOfDayApi(_endTime);

    if (_isEditing) {
      widget.bloc.add(
        UpdateWorkingHourEvent(
          workingHourId: widget.existing!.id,
          weekday: _weekday,
          startTime: startStr,
          endTime: endStr,
          isActive: _isActive,
        ),
      );
    } else {
      widget.bloc.add(
        CreateWorkingHourEvent(
          weekday: _weekday,
          startTime: startStr,
          endTime: endStr,
          isActive: _isActive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return BlocProvider.value(
      value: widget.bloc,
      child: BlocConsumer<ProviderServicesBloc, ProviderServicesState>(
        listener: (context, state) {
          if (state is ProviderServiceActionSuccess) {
            Navigator.of(context).pop();
          } else if (state is ProviderServiceActionError) {
            setState(() => _errorMessage = state.message);
          }
        },
        builder: (context, state) {
          final isSubmitting = state is ProviderServiceActionLoading;
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20.w,
              right: 20.w,
              top: 14.h,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProviderSheetHeader(
                  title: _isEditing ? 'ویرایش ساعت کاری' : 'افزودن ساعت کاری',
                  subtitle: 'روز هفته و بازه زمانی حضور برای نوبت‌دهی را انتخاب کنید.',
                ),
                if (_errorMessage != null) ...[
                  SizedBox(height: 10.h),
                  ProviderSheetErrorBanner(message: _errorMessage!),
                ],
                SizedBox(height: 16.h),
                Text(
                  'انتخاب روز هفته',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: PersianWeekdays.orderedCodes.map((code) {
                    final selected = code == _weekday;
                    return ChoiceChip(
                      selected: selected,
                      onSelected: (_) => setState(() {
                        _errorMessage = null;
                        _weekday = code;
                      }),
                      label: Text(PersianWeekdays.nameOf(code)),
                      selectedColor: AppColors.primary500,
                      backgroundColor: AppColors.surfaceContainerLow,
                      labelStyle: textTheme.labelMedium?.copyWith(
                        color: selected ? Colors.white : AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: _TimePickerBox(
                        label: 'ساعت شروع',
                        value: WorkingHourModel.formatTimeOfDayPersian(
                          _startTime,
                        ),
                        onTap: () => _pickTime(isStart: true),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _TimePickerBox(
                        label: 'ساعت پایان',
                        value: WorkingHourModel.formatTimeOfDayPersian(
                          _endTime,
                        ),
                        onTap: () => _pickTime(isStart: false),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('ساعت کاری فعال باشد'),
                  value: _isActive,
                  activeTrackColor: AppColors.primary500,
                  onChanged: (v) => setState(() {
                    _errorMessage = null;
                    _isActive = v;
                  }),
                ),
                SizedBox(height: 16.h),
                ProviderPrimaryButton(
                  label: _isEditing ? 'ذخیره تغییرات' : 'ثبت ساعت کاری',
                  isLoading: isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TimePickerBox extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TimePickerBox({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.text200Light),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 18.r,
                  color: AppColors.primary500,
                ),
                SizedBox(width: 8.w),
                Text(
                  value,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

