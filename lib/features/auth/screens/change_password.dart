import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:reservation_chat_univercity_project/core/widgets/main_button.dart';
import 'package:reservation_chat_univercity_project/core/widgets/main_textfield.dart';
import 'package:reservation_chat_univercity_project/features/auth/screens/login.dart';
import 'package:reservation_chat_univercity_project/features/auth/widgets/back_button.dart';
import 'package:toastification/toastification.dart';

import '../../../core/utils/navigator.dart';
import '../../../core/utils/snakbar.dart';
import '../bloc/auth_bloc.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({
    super.key,
    required this.isReset,
    this.email,
    required this.code,
  });

  final bool isReset;
  final String? email;
  final String code;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPassController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _rePassController = TextEditingController();
  final Map<String, String> _fieldErrors = {};

  void _handleErrors(Map<String, dynamic>? errors, String message) {
    if (errors != null && errors.isNotEmpty) {
      setState(() {
        errors.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            _fieldErrors[key] = value.first.toString();
          } else {
            _fieldErrors[key] = value.toString();
          }
        });
      });
    }
    if (message.isNotEmpty) {
      showCustomSnackBar(
        context: context,
        title: 'error_title'.tr(),
        content: message,
        status: ToastificationType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsetsGeometry.only(
            left: 24.w,
            right: 24.w,
            bottom: 28.h,
            top: 26.h,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AuthBackButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                SizedBox(height: 72.h),
                Text(
                  "change_password_title".tr(),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                SizedBox(height: 17.h),
                Text(
                  "set_a_secure_password".tr(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                SizedBox(height: 33.h),

                if (!widget.isReset) ...[
                  CoreTextField(
                    controller: _currentPassController,
                    obscure: true,
                    hint: "current_password".tr(),
                    errorText: _fieldErrors['current_password'],
                    onChanged: (v) {
                      if (_fieldErrors.containsKey('current_password')) {
                        setState(() => _fieldErrors.remove('current_password'));
                      }
                    },
                    suffix: SvgPicture.asset(
                      "assets/icons/lock.svg",
                      width: 24.w,
                      height: 24.h,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.tertiary,
                        BlendMode.srcIn,
                      ),
                    ),
                    validator: (String? e) => (e == null || e.trim().isEmpty)
                        ? tr('required.password')
                        : null,
                  ),
                  SizedBox(height: 12.h),
                ],

                CoreTextField(
                  controller: _passController,
                  obscure: true,
                  hint: "new_password_hint".tr(),
                  errorText: _fieldErrors['new_password'],
                  onChanged: (v) {
                    if (_fieldErrors.containsKey('new_password')) {
                      setState(() => _fieldErrors.remove('new_password'));
                    }
                  },
                  suffix: SvgPicture.asset(
                    "assets/icons/lock.svg",
                    width: 24.w,
                    height: 24.h,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.tertiary,
                      BlendMode.srcIn,
                    ),
                  ),
                  validator: (String? e) => (e == null || e.trim().isEmpty)
                      ? tr('required.password')
                      : null,
                ),
                SizedBox(height: 12.h),
                CoreTextField(
                  controller: _rePassController,
                  obscure: true,
                  hint: "rePassword_hint".tr(),
                  errorText: _fieldErrors['new_password_confirm'],
                  onChanged: (v) {
                    if (_fieldErrors.containsKey('new_password_confirm')) {
                      setState(() => _fieldErrors.remove('new_password_confirm'));
                    }
                  },
                  suffix: SvgPicture.asset(
                    "assets/icons/lock.svg",
                    width: 24.w,
                    height: 24.h,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.tertiary,
                      BlendMode.srcIn,
                    ),
                  ),
                  validator: (String? e) => (e == null || e.trim().isEmpty)
                      ? tr('required.re_password')
                      : null,
                ),
                Spacer(),
                BlocConsumer<AuthBloc, AuthState>(
                  buildWhen: (previous, current) {
                    if (current is ChangePasswordLoading ||
                        current is ChangePasswordSuccess ||
                        current is ChangePasswordError ||
                        current is ForgetPasswordVerifyLoading ||
                        current is ForgetPasswordVerifySuccess ||
                        current is ForgetPasswordVerifyError) {
                      return true;
                    } else {
                      return false;
                    }
                  },
                  listener: (context, state) {
                    if (state is ChangePasswordSuccess ||
                        state is ForgetPasswordVerifySuccess) {
                      showCustomSnackBar(
                        context: context,
                        title: 'success'.tr(),
                        content: 'change_password_success'.tr(),
                        status: ToastificationType.success,
                      );
                      if (widget.isReset) {
                        goScreen(
                          context: context,
                          screen: LoginScreen(),
                          closeAllScreen: true,
                        );
                      } else {
                        Navigator.pop(context);
                      }
                    }
                    if (state is ChangePasswordError) {
                      _handleErrors(state.fieldErrors, state.message);
                    }
                    if (state is ForgetPasswordVerifyError) {
                      _handleErrors(state.fieldErrors, state.message);
                    }
                  },
                  builder: (context, state) {
                    return CustomElevatedButton(
                      loading:
                          state is ChangePasswordLoading ||
                          state is ForgetPasswordVerifyLoading,
                      onTap: () {
                        if (_formKey.currentState!.validate()) {
                          if (_passController.text == _rePassController.text) {
                            setState(() {
                              _fieldErrors.clear();
                            });
                            if (widget.isReset) {
                              BlocProvider.of<AuthBloc>(context).add(
                                ForgetPasswordVerifyEvent(
                                  email: widget.email ?? '',
                                  code: widget.code,
                                  newPassword: _passController.text,
                                  newPasswordConfirm: _rePassController.text,
                                ),
                              );
                            } else {
                              BlocProvider.of<AuthBloc>(context).add(
                                ChangePasswordEvent(
                                  currentPassword: _currentPassController.text,
                                  code: widget.code,
                                  newPassword: _passController.text,
                                  newPasswordConfirm: _rePassController.text,
                                ),
                              );
                            }
                          } else {
                            showCustomSnackBar(
                              context: context,
                              title: 'error_title'.tr(),
                              content: 'pass_and_repass_error'.tr(),
                              status: ToastificationType.error,
                            );
                          }
                        }
                      },
                      text: "change_password".tr(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
