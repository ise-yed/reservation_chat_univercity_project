import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:reservation_chat_univercity_project/core/constants/app_setting.dart';
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
    this.code,
  });

  final bool isReset;
  final String? email;
  final String? code;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _currentPassController;
  late final TextEditingController _codeController;
  late final TextEditingController _passController;
  late final TextEditingController _rePassController;
  final Map<String, String> _fieldErrors = {};

  final ValueNotifier<int> _secsLeft = ValueNotifier<int>(120);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentPassController = TextEditingController();
    _codeController = TextEditingController(text: widget.code ?? '');
    _passController = TextEditingController();
    _rePassController = TextEditingController();

    _startCountdown();

    // If change password (logged in) and no code pre-filled, request OTP on open
    if (!widget.isReset && (_codeController.text.isEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AuthBloc>().add(ChangePasswordRequestEvent());
      });
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _secsLeft.value = 120;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secsLeft.value <= 1) {
        _secsLeft.value = 0;
        t.cancel();
      } else {
        _secsLeft.value -= 1;
      }
    });
  }

  void _resendOtp() {
    if (_secsLeft.value > 0) return;

    if (widget.isReset) {
      final email = widget.email ?? '';
      if (email.isNotEmpty) {
        context.read<AuthBloc>().add(ForgetPasswordRequestEvent(email: email));
      }
    } else {
      context.read<AuthBloc>().add(ChangePasswordRequestEvent());
    }

    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _secsLeft.dispose();
    _currentPassController.dispose();
    _codeController.dispose();
    _passController.dispose();
    _rePassController.dispose();
    super.dispose();
  }

  String _fmt(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _handleErrors(Map<String, dynamic>? errors, String message) {
    if (errors != null && errors.isNotEmpty) {
      setState(() {
        errors.forEach((key, value) {
          String errText = '';
          if (value is List && value.isNotEmpty) {
            errText = value.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).join('\n');
          } else {
            errText = value.toString().trim();
          }

          if (key == 'code') {
            _fieldErrors['code'] = errText.isNotEmpty
                ? errText
                : 'invalid_otp_error'.tr();
          } else if (key == 'current_password') {
            _fieldErrors['current_password'] = errText;
          } else if (key == 'new_password') {
            _fieldErrors['new_password'] = errText;
          } else if (key == 'new_password_confirm') {
            _fieldErrors['new_password_confirm'] = errText;
          } else if (key == 'non_field_errors' || key == 'detail') {
            if (errText.contains('رمز') || errText.toLowerCase().contains('password')) {
              _fieldErrors['new_password'] = errText;
            } else {
              _fieldErrors['non_field_errors'] = errText;
            }
          } else {
            _fieldErrors[key] = errText;
          }
        });
      });
    }

    // If error mentions invalid code in message
    if (message.toLowerCase().contains('code') ||
        message.toLowerCase().contains('otp') ||
        message.contains('کد')) {
      setState(() {
        _fieldErrors['code'] = message;
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
    final targetEmail = widget.email ?? currentUserModel.email ?? '';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
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
                SizedBox(height: 36.h),
                Text(
                  widget.isReset
                      ? "forgot_password_title".tr()
                      : "change_password_title".tr(),
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(fontSize: 20.sp, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 10.h),
                Text(
                  targetEmail.isNotEmpty
                      ? "${"enter_code_part1".tr()} $targetEmail"
                      : "set_a_secure_password".tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12.5.sp,
                    color: Theme.of(context).colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.8),
                  ),
                ),
                SizedBox(height: 28.h),

                // 1. Current Password (only for change password of logged in user)
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
                  SizedBox(height: 14.h),
                ],

                // 2. OTP Code Field
                CoreTextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  hint: "code_hint".tr(),
                  errorText: _fieldErrors['code'],
                  onChanged: (v) {
                    if (_fieldErrors.containsKey('code')) {
                      setState(() => _fieldErrors.remove('code'));
                    }
                  },
                  suffix: SvgPicture.asset(
                    "assets/icons/chat.svg",
                    width: 22.w,
                    height: 22.h,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.tertiary,
                      BlendMode.srcIn,
                    ),
                  ),
                  validator: (String? e) {
                    if (e == null || e.trim().isEmpty) {
                      return tr('required.otp_code');
                    }
                    if (e.trim().length != 6) {
                      return "code_hint".tr();
                    }
                    return null;
                  },
                ),
                SizedBox(height: 8.h),

                // Timer & Resend Row (completely outside CoreTextField)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ValueListenableBuilder<int>(
                        valueListenable: _secsLeft,
                        builder: (context, secs, _) {
                          if (secs > 0) {
                            return Text(
                              "ارسال مجدد کد تا ${_fmt(secs)} دیگر",
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withValues(alpha: 0.8),
                                    fontSize: 12.sp,
                                  ),
                            );
                          }
                          return TextButton(
                            onPressed: _resendOtp,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              "resend_code".tr(),
                              style: TextStyle(
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),

                // 3. New Password
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
                  validator: (String? e) {
                    if (e == null || e.trim().isEmpty) {
                      return tr('required.password');
                    }
                    if (e.trim().length < 8) {
                      return "کلمه عبور باید حداقل ۸ کاراکتر باشد";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 14.h),

                // 4. Confirm New Password
                CoreTextField(
                  controller: _rePassController,
                  obscure: true,
                  hint: "rePassword_hint".tr(),
                  errorText: _fieldErrors['new_password_confirm'],
                  onChanged: (v) {
                    if (_fieldErrors.containsKey('new_password_confirm')) {
                      setState(
                        () => _fieldErrors.remove('new_password_confirm'),
                      );
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
                SizedBox(height: 36.h),

                // 5. Submit Button
                BlocConsumer<AuthBloc, AuthState>(
                  buildWhen: (previous, current) {
                    return current is ChangePasswordLoading ||
                        current is ChangePasswordSuccess ||
                        current is ChangePasswordError ||
                        current is ForgetPasswordVerifyLoading ||
                        current is ForgetPasswordVerifySuccess ||
                        current is ForgetPasswordVerifyError ||
                        current is ChangePasswordRequestSuccess ||
                        current is ForgetPasswordRequestSuccess;
                  },
                  listener: (context, state) {
                    if (state is ChangePasswordRequestSuccess) {
                      showCustomSnackBar(
                        context: context,
                        title: 'success'.tr(),
                        content: 'otp_sent'.tr(),
                        status: ToastificationType.success,
                      );
                    }
                    if (state is ForgetPasswordRequestSuccess) {
                      showCustomSnackBar(
                        context: context,
                        title: 'success'.tr(),
                        content: 'otp_sent'.tr(),
                        status: ToastificationType.success,
                      );
                    }
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
                          screen: const LoginScreen(),
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
                    final isLoading =
                        state is ChangePasswordLoading ||
                        state is ForgetPasswordVerifyLoading;

                    return CustomElevatedButton(
                      loading: isLoading,
                      onTap: () {
                        if (!_formKey.currentState!.validate()) return;

                        if (_passController.text != _rePassController.text) {
                          showCustomSnackBar(
                            context: context,
                            title: 'error_title'.tr(),
                            content: 'pass_and_repass_error'.tr(),
                            status: ToastificationType.error,
                          );
                          return;
                        }

                        setState(() {
                          _fieldErrors.clear();
                        });

                        if (widget.isReset) {
                          BlocProvider.of<AuthBloc>(context).add(
                            ForgetPasswordVerifyEvent(
                              email: targetEmail,
                              code: _codeController.text.trim(),
                              newPassword: _passController.text,
                              newPasswordConfirm: _rePassController.text,
                            ),
                          );
                        } else {
                          BlocProvider.of<AuthBloc>(context).add(
                            ChangePasswordEvent(
                              currentPassword: _currentPassController.text,
                              code: _codeController.text.trim(),
                              newPassword: _passController.text,
                              newPasswordConfirm: _rePassController.text,
                            ),
                          );
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
