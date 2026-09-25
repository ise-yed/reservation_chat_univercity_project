import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reservation_chat_univercity_project/core/utils/image_handler.dart';
import 'package:reservation_chat_univercity_project/core/widgets/dropdown.dart';
import 'package:reservation_chat_univercity_project/core/widgets/format_reminder_date.dart';
import 'package:reservation_chat_univercity_project/core/widgets/main_button.dart';
import 'package:reservation_chat_univercity_project/core/widgets/main_textfield.dart';
import 'package:reservation_chat_univercity_project/features/profile/bloc/profile_bloc.dart';
// import 'package:reservation_chat_univercity_project/features/reminder/widgets/add_reminder/date_picker_widget.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:toastification/toastification.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_setting.dart';
import '../../../core/utils/navigator.dart';
import '../../../core/utils/snakbar.dart';
import '../../auth/models/user_model.dart';

import '../../root/root_screen.dart';
import '../widgets/avatar_picker.dart';
import '../widgets/pet_breed_row.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.isEdit, this.initial});

  final UserModel? initial;
  final bool isEdit;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _canScroll = false;
  GlobalKey<FormState> formKey = GlobalKey();
  final TextEditingController _petNameController = TextEditingController();
  final TextEditingController _supervisorNameController =
      TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  ImageHandler imagePicker = ImageHandler();
  XFile? imagefile;
  Uint8List? _webImageBytes;
  String? selectedPet;
  String? selectedBreeds;
  String? selectedPetSex;
  String? _uploadedAvatarFileName;
  bool _uploadError = false;
  final int _avatarUploadTempId = DateTime.now().microsecondsSinceEpoch;
  String? dateError;
  DateTime? selectedDate;
  Map<String, dynamic>? date;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      final u = widget.initial!;
      _uploadedAvatarFileName = u.avatar;
      _petNameController.text = u.petName ?? '';
      _supervisorNameController.text = u.name ?? '';
      _addressController.text = u.address ?? '';
      selectedDate = u.petBirthDay;
      selectedPet = u.pet;
      selectedPetSex = u.petSex;

      selectedBreeds = u.petBreed;
      if (selectedPet != null && selectedPet!.isNotEmpty) {
        context.read<ProfileBloc>().add(GetBreedsEvent(pet: selectedPet!));
      }
    }
    if (selectedDate != null) {
      date = formatReminderDateTime(selectedDate.toString());
    }
    context.read<ProfileBloc>().add(GetPetsEvent());
  }

  Future<void> _pickAndUploadAvatar() async {
    await imagePicker.pickAndCompressImage(source: ImageSource.gallery);
    final picked = imagePicker.getImage;
    if (picked == null) return;
    Uint8List? webBytes;
    if (kIsWeb) {
      webBytes = await picked.readAsBytes();
    }
    setState(() {
      imagefile = picked;
      _webImageBytes = webBytes;
    });
    BlocProvider.of<ProfileBloc>(context)
        .add(UploadFileEvent(file: picked, tempId: _avatarUploadTempId));
  }

  void _retryUploadAvatar() {
    if (imagefile != null) {
      BlocProvider.of<ProfileBloc>(context)
          .add(UploadFileEvent(file: imagefile!, tempId: _avatarUploadTempId));
    }
  }

  void _onPetSelected(String name) {
    setState(() {
      selectedPet = name;
      selectedBreeds = null;
    });
    BlocProvider.of<ProfileBloc>(context).add(GetBreedsEvent(pet: name));
  }

  void _onBreedSelected(String name) {
    setState(() => selectedBreeds = name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.w, 39.h, 24.w, 8.h),
          child: MultiBlocListener(
            listeners: [
              BlocListener<ProfileBloc, ProfileState>(
                listenWhen: (prev, curr) =>
                    curr is UploadFileLoading ||
                    curr is UploadFileSuccess ||
                    curr is UploadFileError,
                listener: (context, state) {
                  if (state is UploadFileLoading) {
                    setState(() => _uploadError = false);
                  } else if (state is UploadFileSuccess) {
                    setState(() {
                      _uploadedAvatarFileName = state.fileName;
                      _uploadError = false;
                      showCustomSnackBar(
                        context: context,
                        title: 'success'.tr(),
                        content: 'upload_success'.tr(),
                        status: ToastificationType.success,
                      );
                    });
                  } else if (state is UploadFileError) {
                    setState(() => _uploadError = true);
                    showCustomSnackBar(
                      context: context,
                      title: 'error_title'.tr(),
                      content: state.message,
                      status: ToastificationType.error,
                    );
                  }
                },
              ),
              BlocListener<ProfileBloc, ProfileState>(
                listenWhen: (prev, curr) =>
                    curr is EditProfileSuccess || curr is EditProfileError,
                listener: (context, state) async {
                  if (state is EditProfileSuccess) {
                    currentUserModel = state.user;
                    prefs.setBool(AppConstants.isAppStarted, true);
                    final uid = currentUserModel.id;
                    if (widget.isEdit) {
                      Navigator.pop(context);
                      showCustomSnackBar(
                        context: context,
                        title: 'success'.tr(),
                        content: 'snack_success'.tr(),
                        status: ToastificationType.success,
                      );
                    } else {
                      // final hasSub = await hasActiveSubscription();
                      // if (hasSub) {
                      //   goScreen(context: context, screen: RootScreen());
                      // } else {
                      //   goScreen(
                      //     context: context,
                      //     screen: const PremiumBuyScreen(showBack: false),
                      //     closeAllScreen: true,
                      //   );
                      // }
                      // if (uid != null && uid.isNotEmpty) {
                      //   MessagingService.instance.onLogin(uid);
                      // }
                    }
                  }
                  if (state is EditProfileError) {
                    showCustomSnackBar(
                      context: context,
                      title: 'error_title'.tr(),
                      content: state.message,
                      status: ToastificationType.error,
                    );
                  }
                },
              ),
            ],
            child: NotificationListener<ScrollMetricsNotification>(
              onNotification: (n) {
                final can = n.metrics.maxScrollExtent > 0;
                if (can != _canScroll) setState(() => _canScroll = can);
                return false;
              },
              child: CustomScrollView(
                physics: _canScroll
                    ? const BouncingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Center(
                          child: Text(
                            widget.isEdit
                                ? 'edit_profile_info'.tr()
                                : "complete_account_info".tr(),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        SizedBox(height: 26.h),
                        AvatarPicker(
                          uploadedAvatarFileName: _uploadedAvatarFileName,
                          imageFile: imagefile,
                          webImageBytes: _webImageBytes,
                          uploadError: _uploadError,
                          onPickTap: _pickAndUploadAvatar,
                          onRetryTap: _retryUploadAvatar,
                        ),
                        SizedBox(height: 21.h),
                      ],
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "pet_fullname".tr(),
                            style: Theme.of(context).textTheme.titleMedium!
                                .copyWith(fontWeight: FontWeight.w500),
                          ),
                          SizedBox(height: 9.h),
                          CoreTextField(
                            controller: _petNameController,
                            hint: "sample_pet_name".tr(),
                            validator: (String? e) =>
                                (e == null || e.trim().isEmpty)
                                ? tr('required.pet_name')
                                : null,
                          ),
                          SizedBox(height: 17.h),
                          PetBreedRow(
                            selectedPet: selectedPet,
                            selectedBreeds: selectedBreeds,
                            onPetSelected: _onPetSelected,
                            onBreedSelected: _onBreedSelected,
                          ),
                          SizedBox(height: 17.h),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 10,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "birthdate".tr(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium!
                                          .copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                    SizedBox(height: 9.h),
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () async {
                                        // showCustomPersianDatePicker(
                                        //   context,
                                        //   (value) {
                                        //     selectedDate = value.toDateTime();
                                        //     setState(() {
                                        //       date = formatReminderDateTime(
                                        //         selectedDate.toString(),
                                        //       );
                                        //       dateError = null;
                                        //     });
                                        //   },
                                        //   initialDate: selectedDate != null
                                        //       ? Jalali.fromDateTime(
                                        //           selectedDate!,
                                        //         )
                                        //       : null,
                                        // );
                                      },
                                      child: Container(
                                        height: 58.h,
                                        alignment: Alignment.centerRight,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                          vertical: 14.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surfaceBright,
                                          border: Border.all(
                                            width: 1,
                                            color: dateError != null
                                                ? Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                : Theme.of(context)
                                                      .colorScheme
                                                      .surfaceDim,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                        ),
                                        child: Text(
                                          date?['date'] ?? "select_date".tr(),

                                          style: date?['date'] == null
                                              ? Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                              : Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium!
                                                    .copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                        ),
                                      ),
                                    ),
                                    if (dateError != null) ...[
                                      Padding(
                                        padding: EdgeInsets.only(
                                          top: 10.h,
                                          right: 4.w,
                                          left: 4.w,
                                        ),
                                        child: Text(
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          dateError ?? "ghfghf",
                                          style:
                                              Theme.of(context)
                                                  .inputDecorationTheme
                                                  .errorStyle ??
                                              Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .error,
                                                  ),
                                        ),
                                      ),
                                    ],

                                    // CoreTextField(
                                    //   controller: _ageController,
                                    //   hint: "sample_pet_age".tr(),
                                    //   inputFormatters: [
                                    //     FilteringTextInputFormatter.digitsOnly,
                                    //   ],
                                    //   keyboardType: TextInputType.number,
                                    //   validator: (String? e) =>
                                    //       (e == null || e.trim().isEmpty)
                                    //       ? tr('required.age')
                                    //       : null,
                                    // ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "gender".tr(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium!
                                          .copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                    SizedBox(height: 9.h),
                                    AnimatedSize(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      curve: Curves.easeInOut,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minHeight: 58.h,
                                        ),
                                        child: DropdownWidget(
                                          isEnabled: true,
                                          enableSearch: false,
                                          defaultTitle: (selectedPetSex != null)
                                              ? (selectedPetSex == 'male'
                                                    ? 'male'.tr()
                                                    : 'female'.tr())
                                              : null,
                                          loadingText: 'in_loading'.tr(),
                                          retryLabel: 'retry'.tr(),
                                          hintText: "select".tr(),
                                          dataList: [
                                            FilterModel(
                                              name: 'male'.tr(),
                                              id: 'male',
                                              code: 1,
                                            ),
                                            FilterModel(
                                              name: 'female'.tr(),
                                              id: 'female',
                                              code: 2,
                                            ),
                                          ],
                                          validator: (int? value) =>
                                              value == null
                                              ? 'required.gender'.tr()
                                              : null,
                                          onChanged: (selected) {
                                            setState(() {
                                              selectedPetSex = selected!.id;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 17.h),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "supervisor_name".tr(),
                                style: Theme.of(context).textTheme.titleMedium!
                                    .copyWith(fontWeight: FontWeight.w500),
                              ),
                              SizedBox(height: 9.h),
                              CoreTextField(
                                controller: _supervisorNameController,
                                hint: "name".tr(),
                                validator: (String? e) =>
                                    (e == null || e.trim().isEmpty)
                                    ? tr('required.supervisor_name')
                                    : null,
                              ),
                            ],
                          ),
                          SizedBox(height: 17.h),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "${"address".tr()} ",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium!
                                          .copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                    TextSpan(
                                      text: "${"optional".tr()} ",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 9.h),
                              CoreTextField(
                                controller: _addressController,
                                hint: "address".tr(),
                              ),
                            ],
                          ),
                          SizedBox(height: 24.h),
                          const Spacer(),
                          SafeArea(
                            top: false,
                            minimum: EdgeInsets.only(bottom: 20.h),
                            child: BlocBuilder<ProfileBloc, ProfileState>(
                              buildWhen: (prev, curr) =>
                                  curr is EditProfileLoading ||
                                  curr is EditProfileSuccess ||
                                  curr is EditProfileError,
                              builder: (context, state) {
                                final isSaving = state is EditProfileLoading;
                                return CustomElevatedButton(
                                  loading: isSaving,
                                  onTap: () async {
                                    if (selectedDate == null) {
                                      setState(
                                        () => dateError = 'required.birthday'
                                            .tr(),
                                      );
                                      return;
                                    }
                                    if (formKey.currentState!.validate()) {
                                      // final avatarFile =
                                      //     _uploadedAvatarFileName;
                                      // String? firebaseToken;

                                      // try {
                                      //   firebaseToken = await MessagingService
                                      //       .instance
                                      //       .getToken();
                                      // } catch (e) {
                                      //   firebaseToken = null;
                                      //   debugPrint("FCM not available: $e");
                                      // }
                                      // UserModel user = UserModel(
                                      //   avatar: avatarFile,
                                      //   name: _supervisorNameController.text,
                                      //   petName: _petNameController.text,
                                      //   pet: selectedPet,
                                      //   petBreed: selectedBreeds,
                                      //   petAge: 0,
                                      //   petSex: selectedPetSex,
                                      //   address: _addressController.text,
                                      //   firebaseToken: firebaseToken,
                                      //   petBirthDay: selectedDate?.toUtc(),
                                      // );
                                      // BlocProvider.of<ProfileBloc>(context)
                                      //     .add(EditProfileEvent(user: user));
                                    }
                                  },
                                  text: widget.isEdit
                                      ? 'save'.tr()
                                      : "enter_to_app".tr(),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
