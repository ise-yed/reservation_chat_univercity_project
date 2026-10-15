import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' as ui;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:reservation_chat_univercity_project/core/constants/app_setting.dart';
import 'package:reservation_chat_univercity_project/core/notifications/messaging_service.dart';
import 'package:reservation_chat_univercity_project/core/utils/navigator.dart';
import 'package:reservation_chat_univercity_project/core/widgets/main_button.dart';
import 'package:reservation_chat_univercity_project/core/widgets/main_textfield.dart';
import 'package:reservation_chat_univercity_project/features/auth/screens/forgot_password.dart';
import 'package:reservation_chat_univercity_project/features/auth/screens/register_screen.dart';
import 'package:reservation_chat_univercity_project/features/root/root_screen.dart';
import 'package:toastification/toastification.dart';

import '../../../core/constants/app_constants.dart';
// import '../../../core/notifications/messaging_service.dart';
import '../../../core/utils/snakbar.dart';

import '../bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _canScroll = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
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
                      SizedBox(height: 44.43.h),
                      Text(
                        "login".tr(),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      SizedBox(height: 17.h),
                      Row(
                        spacing: 6.w,
                        children: [
                          Text(
                            "dont_have_account".tr(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          TextButton(
                            style: ButtonStyle(
                              minimumSize: WidgetStateProperty.all(Size.zero),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              padding: const WidgetStatePropertyAll(
                                EdgeInsets.all(0),
                              ),
                            ),
                            onPressed: () {
                              goScreen(
                                context: context,
                                screen: RegisterScreen(),
                                closeAllScreen: true,
                              );
                            },
                            child: Text(
                              "sign_up".tr(),
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
                        Column(
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
                            CoreTextField(
                              controller: _passController,
                              obscure: true,
                              hint: "password_hint".tr(),
                              errorText: _fieldErrors['password'],
                              onChanged: (v) {
                                if (_fieldErrors.containsKey('password')) {
                                  setState(
                                    () => _fieldErrors.remove('password'),
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
                              validator: (String? e) =>
                                  (e == null || e.trim().isEmpty)
                                  ? tr('required.password')
                                  : null,
                            ),
                          ],
                        ),
                        SizedBox(height: 14.h),
                        Row(
                          spacing: 6.w,
                          children: [
                            Text(
                              "forgot_password_question".tr(),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            TextButton(
                              style: ButtonStyle(
                                minimumSize: WidgetStateProperty.all(Size.zero),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                padding: const WidgetStatePropertyAll(
                                  EdgeInsets.all(0),
                                ),
                              ),
                              onPressed: () {
                                goScreen(
                                  context: context,
                                  screen: ForgotPasswordScreen(),
                                );
                              },
                              child: Text(
                                "forgot_password".tr(),
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 24.h),
                        const Spacer(),
                        SafeArea(
                          top: false,
                          minimum: EdgeInsets.only(bottom: 12.h),
                          child: BlocConsumer<AuthBloc, AuthState>(
                            buildWhen: (previous, current) {
                              if (current is LoginLoading ||
                                  current is LoginSuccess ||
                                  current is LoginError) {
                                return true;
                              } else {
                                return false;
                              }
                            },
                            listener: (context, state) async {
                              if (state is LoginSuccess) {
                                currentUserModel = state.user;
                                prefs.setBool(AppConstants.isAppStarted, true);

                                final uid = currentUserModel.id;
                                if (uid != null && uid.isNotEmpty) {
                                  MessagingService.instance.onLogin(uid);
                                }

                                final hasSub = true;
                                if (hasSub) {
                                  goScreen(
                                    context: context,
                                    screen: RootScreen(),
                                  );
                                }
                              }

                              if (state is LoginError) {
                                if (state.fieldErrors != null &&
                                    state.fieldErrors!.isNotEmpty) {
                                  setState(() {
                                    state.fieldErrors!.forEach((key, value) {
                                      if (value is List && value.isNotEmpty) {
                                        _fieldErrors[key] = value.first
                                            .toString();
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
                                    loading: state is LoginLoading,
                                    onTap: () {
                                      if (_formKey.currentState!.validate()) {
                                        setState(() {
                                          _fieldErrors.clear();
                                        });
                                        BlocProvider.of<AuthBloc>(context).add(
                                          LoginEvent(
                                            email: _emailController.text,
                                            password: _passController.text,
                                          ),
                                        );
                                      }
                                    },
                                    text: "login".tr(),
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
