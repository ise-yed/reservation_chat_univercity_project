import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reservation_chat_univercity_project/features/home/services/model/home_models.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/bloc/provider_services_bloc.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/widgets/provider_service_shared_widgets.dart';

/// Modal bottom sheet allowing a provider to update their title, bio, and base slot length.
class ProviderSettingsSheet extends StatefulWidget {
  final ProviderServicesBloc bloc;
  final ProviderProfileModel profile;

  const ProviderSettingsSheet({
    super.key,
    required this.bloc,
    required this.profile,
  });

  @override
  State<ProviderSettingsSheet> createState() => _ProviderSettingsSheetState();
}

class _ProviderSettingsSheetState extends State<ProviderSettingsSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _durationController;
  late final TextEditingController _bioController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.profile.title);
    _durationController = TextEditingController(
      text: widget.profile.defaultSlotDurationMinutes.toString(),
    );
    _bioController = TextEditingController(text: widget.profile.bio);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _errorMessage = null);
    widget.bloc.add(
      UpdateProviderScheduleSettingsEvent(
        title: _titleController.text.trim(),
        bio: _bioController.text.trim(),
        defaultSlotDurationMinutes: int.parse(_durationController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProviderSheetHeader(
                    title: 'تنظیمات پروفایل و زمان‌بندی',
                    subtitle: widget.profile.clinicDisplayTitle,
                  ),
                  if (_errorMessage != null) ...[
                    SizedBox(height: 10.h),
                    ProviderSheetErrorBanner(message: _errorMessage!),
                  ],
                  SizedBox(height: 14.h),
                  TextFormField(
                    controller: _titleController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'عنوان حرفه‌ای',
                      hintText: 'مثلاً متخصص بیماری‌های داخلی',
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextFormField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'مدت پایه نوبت (دقیقه) *',
                      helperText:
                          'برای تولید اسلات‌های پیش‌فرض در صورت نبود بازه اختصاصی',
                    ),
                    validator: (value) {
                      final parsed = int.tryParse(value?.trim() ?? '');
                      if (parsed == null || parsed < 1 || parsed > 480) {
                        return 'مدت زمان باید بین ۱ تا ۴۸۰ دقیقه باشد.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12.h),
                  TextFormField(
                    controller: _bioController,
                    maxLines: 3,
                    minLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'معرفی کوتاه و توضیحات پزشک',
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ProviderPrimaryButton(
                    label: 'ذخیره تنظیمات',
                    isLoading: isSubmitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

