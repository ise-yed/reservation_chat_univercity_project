import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:reservation_chat_univercity_project/core/themes/app_colors.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/bloc/provider_services_bloc.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/service/model/provider_services_models.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/widgets/provider_service_shared_widgets.dart';

/// Modal bottom sheet for creating or editing a provider time-off range.
class TimeOffFormSheet extends StatefulWidget {
  final ProviderServicesBloc bloc;
  final TimeOffModel? existing;

  const TimeOffFormSheet({
    super.key,
    required this.bloc,
    this.existing,
  });

  @override
  State<TimeOffFormSheet> createState() => _TimeOffFormSheetState();
}

class _TimeOffFormSheetState extends State<TimeOffFormSheet> {
  late Jalali _startDate;
  late TimeOfDay _startTime;
  late Jalali _endDate;
  late TimeOfDay _endTime;
  late final TextEditingController _reasonController;
  late bool _isActive;
  String? _errorMessage;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    if (item != null) {
      _startDate = Jalali.fromDateTime(item.startAt);
      _startTime = TimeOfDay.fromDateTime(item.startAt);
      _endDate = Jalali.fromDateTime(item.endAt);
      _endTime = TimeOfDay.fromDateTime(item.endAt);
    } else {
      final now = DateTime.now().add(const Duration(hours: 1));
      _startDate = Jalali.fromDateTime(now);
      _startTime = TimeOfDay(hour: now.hour, minute: 0);
      final later = now.add(const Duration(hours: 4));
      _endDate = Jalali.fromDateTime(later);
      _endTime = TimeOfDay(hour: later.hour, minute: 0);
    }
    _reasonController = TextEditingController(text: item?.reason ?? '');
    _isActive = item?.isActive ?? true;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  DateTime _combine(Jalali date, TimeOfDay time) {
    final g = date.toDateTime();
    return DateTime(g.year, g.month, g.day, time.hour, time.minute);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final nowJalali = Jalali.now();
    final firstDate = Jalali(nowJalali.year - 1, 1, 1);
    final lastDate = Jalali(nowJalali.year + 2, 12, 29);

    final picked = await showPersianDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: isStart ? 'تاریخ شروع مرخصی' : 'تاریخ پایان مرخصی',
      cancelText: 'انصراف',
      confirmText: 'تأیید',
      locale: const Locale('fa', 'IR'),
      textDirection: TextDirection.rtl,
      builder: (dialogCtx, child) {
        return Localizations.override(
          context: dialogCtx,
          locale: const Locale('fa', 'IR'),
          delegates: const [PersianMaterialLocalizations.delegate],
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
        _startDate = picked;
        if (_endDate.compareTo(_startDate) < 0) {
          _endDate = _startDate;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      helpText: isStart ? 'ساعت شروع مرخصی' : 'ساعت پایان مرخصی',
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
    final startAt = _combine(_startDate, _startTime);
    final endAt = _combine(_endDate, _endTime);

    if (!endAt.isAfter(startAt)) {
      setState(() {
        _errorMessage = 'زمان پایان مرخصی باید بعد از زمان شروع باشد.';
      });
      return;
    }

    setState(() => _errorMessage = null);

    if (_isEditing) {
      widget.bloc.add(
        UpdateTimeOffEvent(
          timeOffId: widget.existing!.id,
          startAt: startAt,
          endAt: endAt,
          reason: _reasonController.text.trim(),
          isActive: _isActive,
        ),
      );
    } else {
      widget.bloc.add(
        CreateTimeOffEvent(
          startAt: startAt,
          endAt: endAt,
          reason: _reasonController.text.trim(),
          isActive: _isActive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final startAtPreview = _combine(_startDate, _startTime);
    final endAtPreview = _combine(_endDate, _endTime);

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
                  title: _isEditing ? 'ویرایش مرخصی' : 'ثبت مرخصی یا عدم حضور',
                  subtitle: 'در بازه مرخصی فعال، نوبت جدیدی برای شما ثبت نخواهد شد.',
                ),
                if (_errorMessage != null) ...[
                  SizedBox(height: 10.h),
                  ProviderSheetErrorBanner(message: _errorMessage!),
                ],
                SizedBox(height: 14.h),
                _DateTimeRow(
                  sectionLabel: 'شروع مرخصی',
                  dateLabel: TimeOffModel.formatJalaliDate(startAtPreview),
                  timeLabel: TimeOffModel.formatClock(startAtPreview),
                  onPickDate: () => _pickDate(isStart: true),
                  onPickTime: () => _pickTime(isStart: true),
                ),
                SizedBox(height: 12.h),
                _DateTimeRow(
                  sectionLabel: 'پایان مرخصی',
                  dateLabel: TimeOffModel.formatJalaliDate(endAtPreview),
                  timeLabel: TimeOffModel.formatClock(endAtPreview),
                  onPickDate: () => _pickDate(isStart: false),
                  onPickTime: () => _pickTime(isStart: false),
                ),
                SizedBox(height: 14.h),
                TextField(
                  controller: _reasonController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'علت / توضیح (اختیاری)',
                    hintText: 'مثلاً مرخصی استحقاقی یا شرکت در کنگره پزشکی',
                  ),
                ),
                if (_isEditing) ...[
                  SizedBox(height: 8.h),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('بازه مرخصی فعال باشد'),
                    value: _isActive,
                    activeTrackColor: AppColors.primary500,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                ],
                SizedBox(height: 16.h),
                ProviderPrimaryButton(
                  label: _isEditing ? 'ذخیره تغییرات' : 'ثبت مرخصی',
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

class _DateTimeRow extends StatelessWidget {
  final String sectionLabel;
  final String dateLabel;
  final String timeLabel;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  const _DateTimeRow({
    required this.sectionLabel,
    required this.dateLabel,
    required this.timeLabel,
    required this.onPickDate,
    required this.onPickTime,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sectionLabel,
          style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 6.h),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _PickerTile(
                icon: Icons.calendar_today_outlined,
                text: dateLabel,
                onTap: onPickDate,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              flex: 2,
              child: _PickerTile(
                icon: Icons.access_time_rounded,
                text: timeLabel,
                onTap: onPickTime,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.text200Light),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17.r, color: AppColors.primary500),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

