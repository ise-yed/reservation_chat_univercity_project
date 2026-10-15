import 'dart:async';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:reservation_chat_univercity_project/features/auth/screens/change_password.dart';

import 'package:reservation_chat_univercity_project/core/utils/navigator.dart';
import 'package:reservation_chat_univercity_project/core/widgets/main_button.dart';
import 'package:reservation_chat_univercity_project/features/auth/widgets/otp_pinput.dart';

import '../widgets/back_button.dart';

class VerifyCodeScreen extends StatefulWidget {
  const VerifyCodeScreen({
    super.key,
    this.email,
    this.isRegister = false,
    this.isChangePassword = false,
  });

  final String? email;
  final bool isRegister;
  final bool isChangePassword;

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController otpController = TextEditingController();
  final ValueNotifier<int> _secsLeft = ValueNotifier<int>(120);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      final v = _secsLeft.value;
      if (v <= 1) {
        _secsLeft.value = 0;
        t.cancel();
        if (mounted) Navigator.pop(context);
      } else {
        _secsLeft.value = v - 1;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _secsLeft.dispose();
    otpController.dispose();
    super.dispose();
  }

  String _fmt(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final code = otpController.text.trim();

    _timer?.cancel();
    goScreen(
      context: context,
      screen: ChangePasswordScreen(
        isReset: widget.isChangePassword ? false : !widget.isRegister,
        email: widget.email,
        code: code,
      ),
      closeScreen: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: EdgeInsets.only(
              left: 24.w,
              right: 24.w,
              bottom: 28.h,
              top: 26.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AuthBackButton(onPressed: () => Navigator.pop(context)),
                SizedBox(height: 82.h),
                Text(
                  "verify_code".tr(),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                SizedBox(height: 17.h),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "${"enter_code_part1".tr()} ",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      TextSpan(
                        text: widget.email ?? "",
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: " ${"enter_code_part2".tr()}",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 34.h),
                Directionality(
                  textDirection: ui.TextDirection.ltr,
                  child: Form(
                    key: _formKey,
                    child: OtpPinPut(
                      controller: otpController,
                      onCompleted: (_) => _submit(),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  height: 18.h,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        style: ButtonStyle(
                          minimumSize: WidgetStateProperty.all(Size.zero),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          padding: const WidgetStatePropertyAll(
                            EdgeInsets.zero,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 24.w,
                              height: 24.h,
                              child: SvgPicture.asset(
                                "assets/icons/edit.svg",
                                colorFilter: ColorFilter.mode(
                                  Theme.of(context).colorScheme.onSecondary,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              "edit_number".tr(), // maybe need to change to edit email in translations
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      ValueListenableBuilder<int>(
                        valueListenable: _secsLeft,
                        builder: (_, v, __) => Text(
                          _fmt(v),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                CustomElevatedButton(
                  loading: false,
                  onTap: _submit,
                  text: "submit_code".tr(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
