import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:reservation_chat_univercity_project/core/constants/app_constants.dart';
import 'package:reservation_chat_univercity_project/core/constants/app_setting.dart';
import 'package:reservation_chat_univercity_project/core/themes/app_colors.dart';
import 'package:reservation_chat_univercity_project/core/utils/navigator.dart';
import 'package:reservation_chat_univercity_project/core/utils/network_connection.dart';
import 'package:reservation_chat_univercity_project/features/auth/screens/login.dart';
import 'package:reservation_chat_univercity_project/features/auth/screens/register_screen.dart';
import 'package:reservation_chat_univercity_project/features/onboarding/screens/onboarding_screen.dart';
import 'package:reservation_chat_univercity_project/features/profile/bloc/profile_bloc.dart';
import 'package:reservation_chat_univercity_project/features/profile/screens/edit_profile_screen.dart';
import 'package:reservation_chat_univercity_project/features/profile/screens/update_screen.dart';
import 'package:reservation_chat_univercity_project/features/root/root_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Duration _minSplash = Duration(seconds: 4);
  bool _showError = false;
  String _retryTextKey = 'no_internet_retry';
  DateTime? _startedAt;
  bool _userReady = false;
  bool _constReady = false;
  bool _navigated = false;

  bool _forceUpdateChecked = false;

  @override
  void initState() {
    super.initState();
    _startFlow();
  }

  Future<void> _startFlow() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    goScreen(
      context: context,
      screen: const LoginScreen(),
      closeAllScreen: true,
    );
  }

  Future<void> _ensureMinSplash() async {
    final start = _startedAt ?? DateTime.now();
    final elapsed = DateTime.now().difference(start);
    final remain = _minSplash - elapsed;
    if (remain > Duration.zero) {
      await Future.delayed(remain);
    }
  }

  Future<void> _maybeProceed() async {
    if (_navigated || !mounted) return;
    if (!(_userReady && _constReady)) return;

    if (!_forceUpdateChecked) {
      final updated = await _checkForForcedUpdate();
      if (updated) {
        return;
      }
    }

    await _ensureMinSplash();
    if (!mounted) return;

    final startedBefore = prefs.getBool(AppConstants.isAppStarted) == true;
    _navigated = true;

    if (startedBefore) {
      try {
        final hasSub = true;
        if (!mounted) return;

        if (hasSub) {
          _goRoot();
        } else {}
      } catch (e) {
        //debugPrint('Subscription check error: $e');
        _goRoot();
      }
    } else {
      _goEditProfile();
    }
  }

  Future<bool> _checkForForcedUpdate() async {
    _forceUpdateChecked = true;
    try {
      final minVer = appConstSetting.minVersion;
      if (minVer == null) {
        return false;
      }
      if ((int.tryParse(appBuildVersion) ?? 0) <
          (appConstSetting.minVersion ?? 0)) {
        if (!mounted) return true;
        _goForceUpdate();
        return true;
      }
      return false;
    } catch (e) {
      //debugPrint('Version check error: $e');
      return false;
    }
  }

  void _goOnboarding() {
    goScreen(
      context: context,
      screen: const OnboardingsScreen(),
      closeAllScreen: true,
    );
  }

  void _goAuth() {
    goScreen(
      context: context,
      screen: const RegisterScreen(),
      closeAllScreen: true,
    );
  }

  void _goRoot() {
    goScreen(
      context: context,
      screen: const RootScreen(),
      closeAllScreen: true,
    );
  }

  void _goEditProfile() {
    goScreen(
      context: context,
      screen: const EditProfileScreen(isEdit: false),
      closeAllScreen: true,
    );
  }

  void _goForceUpdate() {
    goScreen(
      context: context,
      screen: UpdateScreen(hasUpdate: true, showBack: false),
      closeAllScreen: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppColors.primary500,
      body: SafeArea(
        child: BlocListener<ProfileBloc, ProfileState>(
          listenWhen: (previous, current) =>
              current is GetCurrentUserLoading ||
              current is GetCurrentUserSuccess ||
              current is GetCurrentUserError ||
              current is AppConstSettingLoading ||
              current is AppConstSettingSuccess ||
              current is AppConstSettingError,
          listener: (context, state) async {
            if (state is GetCurrentUserLoading ||
                state is AppConstSettingLoading) {
              if (!mounted) return;
              setState(() => _showError = false);
            }

            if (state is AppConstSettingSuccess) {
              appConstSetting = state.appConstSetting;
              final forced = await _checkForForcedUpdate();
              if (forced) {
                return;
              }

              _constReady = true;
              await _maybeProceed();
              return;
            }

            if (state is GetCurrentUserSuccess) {
              currentUserModel = state.user;
              try {
                // unawaited(
                //   MessagingService.instance.syncTokenToServer(
                //     promptOnWeb: kIsWeb,
                //   ),
                // );
              } catch (_) {}

              final id = currentUserModel.id;
              if (id != null && id.isNotEmpty) {
                // MessagingService.instance.onLogin(id);
              }

              _userReady = true;
              await _maybeProceed();
              return;
            }

            if (state is GetCurrentUserError) {
              await _ensureMinSplash();
              if (!mounted) return;
              setState(() {
                _retryTextKey = 'fetch_user_retry';
                _showError = true;
              });
              return;
            }

            if (state is AppConstSettingError) {
              await _ensureMinSplash();
              if (!mounted) return;
              setState(() {
                _retryTextKey = 'fetch_user_retry';
                _showError = true;
              });
              return;
            }
          },
          child: SizedBox(
            width: width,
            child: Stack(
              children: [
                Center(child: SvgPicture.asset('assets/logo/splash_logo.svg')),
                Positioned(
                  bottom: 20,
                  right: 16,
                  left: 16,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _showError
                        ? _RetryBar(
                            key: const ValueKey('retry'),
                            textKey: _retryTextKey,
                            onTap: _startFlow,
                          )
                        : const SizedBox.shrink(key: ValueKey('idle')),
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

class _RetryBar extends StatelessWidget {
  const _RetryBar({
    super.key,
    required this.onTap,
    this.textKey = 'no_internet_retry',
  });

  final VoidCallback onTap;
  final String textKey;

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final bgColor = onPrimary.withOpacity(0.12);
    final border = onPrimary.withOpacity(0.32);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.refresh, size: 16.sp, color: onPrimary),
              SizedBox(width: 4.w),
              Flexible(
                child: Text(
                  textKey.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: onPrimary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
