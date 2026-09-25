import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' as ui;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:reservation_chat_univercity_project/core/constants/app_setting.dart';
import 'package:reservation_chat_univercity_project/core/utils/navigator.dart';
import 'package:reservation_chat_univercity_project/core/utils/snakbar.dart';
import 'package:reservation_chat_univercity_project/core/widgets/main_button.dart';
import 'package:reservation_chat_univercity_project/core/widgets/main_textfield.dart';
import 'package:reservation_chat_univercity_project/features/auth/screens/login.dart';
import 'package:toastification/toastification.dart';

import '../bloc/auth_bloc.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _canScroll = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _rePassController = TextEditingController();
  final Map<String, String> _fieldErrors = {};

  @override
  Widget build(BuildContext context) {
    final bool isRTL = Directionality.of(context) == ui.TextDirection.rtl;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.w, 29.h, 24.w, 10.h),
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: (n) {
              final can = n.metrics.maxScrollExtent > 0;
              if (can != _canScroll) {
                setState(() => _canScroll = can);
              }
              return false;
            },
            child: CustomScrollView(
              physics: _canScroll
                  ? const BouncingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: SvgPicture.asset(
                          !isThemeLight.value
                              ? "assets/logo/logo_dark.svg"
                              : "assets/logo/logo_light.svg",
                          height: 103.h,
                          width: 98.71.w,
                        ),
                      ),
                      SizedBox(height: 44.h),
                      Text(
                        "register".tr(),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      SizedBox(height: 17.h),
                      Text(
                        "welcome".tr(),
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: !isThemeLight.value
                              ? const Color(0xffCDCDCD)
                              : Theme.of(context).colorScheme.onSecondary,
                        ),
                      ),
                      SizedBox(height: 11.h),
                      Row(
                        children: [
                          Text(
                            "already_registered".tr(),
                            style: Theme.of(context).textTheme.bodySmall!
                                .copyWith(
                                  color: !isThemeLight.value
                                      ? Theme.of(context).colorScheme.onTertiary
                                      : Theme.of(context)
                                            .colorScheme
                                            .onSecondary,
                                ),
                          ),
                          SizedBox(width: 6.w),
                          TextButton(
                            style: ButtonStyle(
                              minimumSize: WidgetStateProperty.all(Size.zero),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              padding: const WidgetStatePropertyAll(
                                EdgeInsets.zero,
                              ),
                            ),
                            onPressed: () {
                              goScreen(context: context, screen: LoginScreen());
                            },
                            child: Text(
                              "enter_to_account".tr(),
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 33.h),
                    ],
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
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
                          suffix: Icon(
                            Icons.email_outlined,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                          validator: (String? e) =>
                              (e == null || e.trim().isEmpty)
                              ? tr('required.email')
                              : null,
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Expanded(
                              child: CoreTextField(
                                controller: _firstNameController,
                                hint: "first_name".tr(),
                                errorText: _fieldErrors['first_name'],
                                onChanged: (v) {
                                  if (_fieldErrors.containsKey('first_name')) {
                                    setState(() => _fieldErrors.remove('first_name'));
                                  }
                                },
                                validator: (String? e) =>
                                    (e == null || e.trim().isEmpty)
                                    ? tr('required.first_name')
                                    : null,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: CoreTextField(
                                controller: _lastNameController,
                                hint: "last_name".tr(),
                                errorText: _fieldErrors['last_name'],
                                onChanged: (v) {
                                  if (_fieldErrors.containsKey('last_name')) {
                                    setState(() => _fieldErrors.remove('last_name'));
                                  }
                                },
                                validator: (String? e) =>
                                    (e == null || e.trim().isEmpty)
                                    ? tr('required.last_name')
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        CoreTextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                          hint: "phone_number".tr(),
                          errorText: _fieldErrors['phone_number'] ?? _fieldErrors['phone'],
                          onChanged: (v) {
                            if (_fieldErrors.containsKey('phone_number') || _fieldErrors.containsKey('phone')) {
                              setState(() {
                                _fieldErrors.remove('phone_number');
                                _fieldErrors.remove('phone');
                              });
                            }
                          },
                          suffix: SvgPicture.asset(
                            "assets/icons/call.svg",
                            width: 24.w,
                            height: 24.h,
                            colorFilter: ColorFilter.mode(
                              Theme.of(context).colorScheme.tertiary,
                              BlendMode.srcIn,
                            ),
                          ),
                          validator: (String? e) =>
                              (e == null || e.trim().isEmpty)
                              ? tr('required.phone')
                              : null,
                        ),
                        SizedBox(height: 12.h),
                        CoreTextField(
                          controller: _passController,
                          obscure: true,
                          hint: "password_hint".tr(),
                          errorText: _fieldErrors['password'],
                          onChanged: (v) {
                            if (_fieldErrors.containsKey('password')) {
                              setState(() => _fieldErrors.remove('password'));
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
                          validator: (String? e) =>
                              (e == null || e.trim().isEmpty)
                              ? tr('required.password')
                              : null,
                        ),
                        SizedBox(height: 12.h),
                        CoreTextField(
                          controller: _rePassController,
                          obscure: true,
                          hint: "rePassword_hint".tr(),
                          errorText: _fieldErrors['password_confirm'] ?? _fieldErrors['passwordConfirm'] ?? _fieldErrors['re_password'],
                          onChanged: (v) {
                            if (_fieldErrors.containsKey('password_confirm') || _fieldErrors.containsKey('passwordConfirm') || _fieldErrors.containsKey('re_password')) {
                              setState(() {
                                _fieldErrors.remove('password_confirm');
                                _fieldErrors.remove('passwordConfirm');
                                _fieldErrors.remove('re_password');
                              });
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
                          validator: (String? e) =>
                              (e == null || e.trim().isEmpty)
                              ? tr('required.re_password')
                              : null,
                        ),
                        SizedBox(height: 24.h),
                        const Spacer(),
                        SafeArea(
                          top: false,
                          minimum: EdgeInsets.only(bottom: 12.h),
                          child: BlocConsumer<AuthBloc, AuthState>(
                            buildWhen: (previous, current) {
                              if (current is RegisterLoading ||
                                  current is RegisterSuccess ||
                                  current is RegisterError) {
                                return true;
                              } else {
                                return false;
                              }
                            },
                            listener: (context, state) {
                              if (state is RegisterSuccess) {
                                showCustomSnackBar(
                                  context: context,
                                  title: 'success_title'.tr(),
                                  content: state.message,
                                  status: ToastificationType.success,
                                );
                                goScreen(
                                  context: context,
                                  screen: LoginScreen(),
                                );
                              }
                              if (state is RegisterError) {
                                if (state.fieldErrors != null && state.fieldErrors!.isNotEmpty) {
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
                              return Column(
                                children: [
                                  CustomElevatedButton(
                                    loading: state is RegisterLoading,
                                    onTap: () {
                                      if (_formKey.currentState!.validate()) {
                                        setState(() {
                                          _fieldErrors.clear();
                                        });
                                        if (_passController.text ==
                                            _rePassController.text) {
                                          BlocProvider.of<AuthBloc>(
                                            context,
                                          ).add(
                                            RegisterEvent(
                                              email: _emailController.text,
                                              firstName:
                                                  _firstNameController.text,
                                              lastName:
                                                  _lastNameController.text,
                                              phoneNumber:
                                                  _phoneController.text,
                                              password: _passController.text,
                                              passwordConfirm:
                                                  _rePassController.text,
                                            ),
                                          );
                                        } else {
                                          showCustomSnackBar(
                                            context: context,
                                            title: 'error_title'.tr(),
                                            content: 'pass_and_repass_error'
                                                .tr(),
                                            status: ToastificationType.error,
                                          );
                                        }
                                      }
                                    },
                                    text: "register".tr(),
                                  ),

                                  SizedBox(height: 12.h),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "sign_up_rules".tr() + " ",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall!
                                            .copyWith(
                                              color: !isThemeLight.value
                                                  ? Theme.of(context)
                                                        .colorScheme
                                                        .onTertiary
                                                  : Theme.of(context)
                                                        .colorScheme
                                                        .onSecondary,
                                            ),
                                      ),
                                      TextButton(
                                        style: ButtonStyle(
                                          minimumSize: WidgetStateProperty.all(
                                            Size.zero,
                                          ),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                          padding: const WidgetStatePropertyAll(
                                            EdgeInsets.zero,
                                          ),
                                        ),
                                        onPressed: () {},
                                        child: Text(
                                          "premium_rules".tr(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium,
                                        ),
                                      ),
                                      if (isRTL)
                                        Text(
                                          "${"is".tr()}.",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall!
                                              .copyWith(
                                                color: !isThemeLight.value
                                                    ? Theme.of(context)
                                                          .colorScheme
                                                          .onTertiary
                                                    : Theme.of(context)
                                                          .colorScheme
                                                          .onSecondary,
                                              ),
                                        ),
                                    ],
                                  ),
                                ],
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
    );
  }
}
