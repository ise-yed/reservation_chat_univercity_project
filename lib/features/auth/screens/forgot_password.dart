import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reservation_chat_univercity_project/core/utils/navigator.dart';
import 'package:reservation_chat_univercity_project/core/widgets/main_button.dart';
import 'package:reservation_chat_univercity_project/core/widgets/main_textfield.dart';
import 'package:reservation_chat_univercity_project/features/auth/bloc/auth_bloc.dart';
import 'package:reservation_chat_univercity_project/features/auth/screens/change_password.dart';
import 'package:toastification/toastification.dart';

import '../../../core/utils/snakbar.dart';
import '../widgets/back_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final Map<String, String> _fieldErrors = {};

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
                SizedBox(height: 82.h),
                Text(
                  "forgot_password_title".tr(),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                SizedBox(height: 17.h),
                Text(
                  "enter_phone_or_username_to_create_new_password".tr(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                SizedBox(height: 33.h),
                CoreTextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  hint: "email".tr(),
                  errorText: _fieldErrors['email'],
                  onChanged: (v) {
                    if (_fieldErrors.containsKey('email')) {
                      setState(() => _fieldErrors.remove('email'));
                    }
                  },
                  validator: (String? e) => (e == null || e.trim().isEmpty)
                      ? tr('required.email')
                      : null,
                ),
                Spacer(),
                BlocConsumer<AuthBloc, AuthState>(
                  buildWhen: (previous, current) =>
                      current is ForgetPasswordRequestLoading ||
                      current is ForgetPasswordRequestSuccess ||
                      current is ForgetPasswordRequestError,
                  listener: (context, state) {
                    if (state is ForgetPasswordRequestSuccess) {
                      showCustomSnackBar(
                        context: context,
                        title: 'success'.tr(),
                        content: state.message,
                        status: ToastificationType.success,
                      );
                      goScreen(
                        context: context,
                        screen: ChangePasswordScreen(
                          email: _emailController.text.trim(),
                          isReset: true,
                        ),
                      );
                    }
                    if (state is ForgetPasswordRequestError) {
                      if (state.fieldErrors != null &&
                          state.fieldErrors!.isNotEmpty) {
                        setState(() {
                          state.fieldErrors!.forEach((key, value) {
                            if (value is List && value.isNotEmpty) {
                              _fieldErrors[key] = value.first.toString();
                            } else {
                              _fieldErrors[key] = value.toString();
                            }
                          });
                        });
                      }
                      if (state.message.isNotEmpty) {
                        showCustomSnackBar(
                          context: context,
                          title: 'error_title'.tr(),
                          content: state.message,
                          status: ToastificationType.error,
                        );
                      }
                    }
                  },
                  builder: (context, state) {
                    return CustomElevatedButton(
                      loading: state is ForgetPasswordRequestLoading,
                      onTap: () {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _fieldErrors.clear();
                          });
                          BlocProvider.of<AuthBloc>(context).add(
                            ForgetPasswordRequestEvent(
                              email: _emailController.text,
                            ),
                          );
                        }
                      },
                      text: "get_verification_code".tr(),
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
