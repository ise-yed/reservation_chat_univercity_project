import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reservation_chat_univercity_project/core/themes/app_colors.dart';
import 'package:reservation_chat_univercity_project/features/appointments/service/model/appointment_models.dart';
import 'package:reservation_chat_univercity_project/features/home/services/model/home_models.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/bloc/provider_services_bloc.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/service/model/provider_services_models.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/widgets/provider_service_shared_widgets.dart';

/// Modal bottom sheet for creating or editing a provider offering.
class OfferingFormSheet extends StatefulWidget {
  final ProviderServicesBloc bloc;
  final List<CategoryModel> categories;
  final int defaultDurationMinutes;
  final ProviderOfferingModel? existing;

  const OfferingFormSheet({
    super.key,
    required this.bloc,
    required this.categories,
    required this.defaultDurationMinutes,
    this.existing,
  });

  @override
  State<OfferingFormSheet> createState() => _OfferingFormSheetState();
}

class _OfferingFormSheetState extends State<OfferingFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _durationController;
  late final TextEditingController _bufferBeforeController;
  late final TextEditingController _bufferAfterController;

  late VisitModeType _visitMode;
  String? _selectedSpecialtyId;
  late bool _requiresApproval;
  late bool _isActive;
  String? _errorMessage;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _titleController = TextEditingController(text: item?.title ?? '');
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    _priceController = TextEditingController(
      text: item != null ? item.priceValue.toInt().toString() : '0',
    );
    _durationController = TextEditingController(
      text: (item?.durationMinutes ?? widget.defaultDurationMinutes).toString(),
    );
    _bufferBeforeController = TextEditingController(
      text: (item?.bufferBeforeMinutes ?? 0).toString(),
    );
    _bufferAfterController = TextEditingController(
      text: (item?.bufferAfterMinutes ?? 0).toString(),
    );

    _visitMode = item?.visitMode ?? VisitModeType.inPerson;
    final existingSpecId = item?.specialty?.id;
    _selectedSpecialtyId =
        widget.categories.any((c) => c.id == existingSpecId)
        ? existingSpecId
        : null;
    _requiresApproval = item?.requiresApproval ?? false;
    _isActive = item?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _bufferBeforeController.dispose();
    _bufferAfterController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _errorMessage = null);

    final payload = OfferingFormPayload(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      visitMode: _visitMode,
      specialtyId: _selectedSpecialtyId,
      durationMinutes: int.parse(_durationController.text.trim()),
      bufferBeforeMinutes:
          int.tryParse(_bufferBeforeController.text.trim()) ?? 0,
      bufferAfterMinutes:
          int.tryParse(_bufferAfterController.text.trim()) ?? 0,
      price: int.tryParse(_priceController.text.trim()) ?? 0,
      requiresApproval: _requiresApproval,
      isActive: _isActive,
    );

    if (_isEditing) {
      widget.bloc.add(
        UpdateOfferingEvent(offeringId: widget.existing!.id, payload: payload),
      );
    } else {
      widget.bloc.add(CreateOfferingEvent(payload: payload));
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
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProviderSheetHeader(
                    title: _isEditing ? 'ویرایش خدمت' : 'تعریف خدمت جدید',
                    subtitle: 'عنوان، نوع ویزیت، مدت و تعرفه خدمت را مشخص کنید.',
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
                      labelText: 'عنوان خدمت *',
                      hintText: 'مثلاً ویزیت تخصصی قلب یا مشاوره آنلاین',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'وارد کردن عنوان خدمت الزامی است.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    'نوع ارائه خدمت',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  SegmentedButton<VisitModeType>(
                    segments: const [
                      ButtonSegment<VisitModeType>(
                        value: VisitModeType.inPerson,
                        icon: Icon(Icons.location_on_outlined),
                        label: Text('ویزیت حضوری'),
                      ),
                      ButtonSegment<VisitModeType>(
                        value: VisitModeType.onlineChat,
                        icon: Icon(Icons.chat_bubble_outline_rounded),
                        label: Text('مشاوره آنلاین'),
                      ),
                    ],
                    selected: {_visitMode},
                    onSelectionChanged: (selection) {
                      setState(() => _visitMode = selection.first);
                    },
                  ),
                  if (widget.categories.isNotEmpty) ...[
                    SizedBox(height: 14.h),
                    DropdownButtonFormField<String?>(
                      initialValue: _selectedSpecialtyId,
                      decoration: const InputDecoration(
                        labelText: 'تخصص مرتبط (اختیاری)',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('بدون دسته‌بندی تخصصی'),
                        ),
                        ...widget.categories.map(
                          (cat) => DropdownMenuItem<String?>(
                            value: cat.id,
                            child: Text(cat.name),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedSpecialtyId = value);
                      },
                    ),
                  ],
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'تعرفه (تومان) *',
                            hintText: '۰ برای رایگان',
                          ),
                          validator: (value) {
                            final parsed = int.tryParse(value?.trim() ?? '');
                            if (parsed == null || parsed < 0) {
                              return 'مبلغ معتبر نیست.';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: TextFormField(
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'مدت زمان (دقیقه) *',
                          ),
                          validator: (value) {
                            final parsed = int.tryParse(value?.trim() ?? '');
                            if (parsed == null || parsed < 1 || parsed > 480) {
                              return 'بین ۱ تا ۴۸۰ دقیقه';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _bufferBeforeController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'زمان آماده‌سازی قبل',
                            suffixText: 'دقیقه',
                          ),
                          validator: _validateBuffer,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: TextFormField(
                          controller: _bufferAfterController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'استراحت بعد ویزیت',
                            suffixText: 'دقیقه',
                          ),
                          validator: _validateBuffer,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    minLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'توضیحات خدمت (اختیاری)',
                      hintText: 'نکاتی که بیمار پیش از رزرو باید بداند...',
                    ),
                  ),
                  SizedBox(height: 8.h),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('نیازمند تأیید دستی پزشک'),
                    subtitle: Text(
                      'پیش از نهایی شدن نوبت، درخواست برای تأیید به شما ارسال شود.',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    value: _requiresApproval,
                    activeTrackColor: AppColors.primary500,
                    onChanged: (v) => setState(() => _requiresApproval = v),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('خدمت فعال و قابل رزرو باشد'),
                    value: _isActive,
                    activeTrackColor: AppColors.primary500,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                  SizedBox(height: 16.h),
                  ProviderPrimaryButton(
                    label: _isEditing ? 'ذخیره تغییرات' : 'ثبت خدمت',
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

  String? _validateBuffer(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final parsed = int.tryParse(trimmed);
    if (parsed == null || parsed < 0 || parsed > 240) {
      return '۰ تا ۲۴۰ دقیقه';
    }
    return null;
  }
}

