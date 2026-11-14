import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:reservation_chat_univercity_project/core/constants/app_constants.dart';
import 'package:reservation_chat_univercity_project/core/constants/app_setting.dart';
import 'package:reservation_chat_univercity_project/core/themes/app_colors.dart';
import 'package:reservation_chat_univercity_project/core/notifications/messaging_service.dart';
import 'package:reservation_chat_univercity_project/core/utils/app_error.dart';
import 'package:reservation_chat_univercity_project/core/utils/navigator.dart';
import 'package:reservation_chat_univercity_project/core/utils/network_connection.dart';
import 'package:reservation_chat_univercity_project/features/auth/screens/login.dart';
import 'package:reservation_chat_univercity_project/features/auth/service/auth_service.dart';
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
  static const Duration _minSplash = Duration(seconds: 3);
  bool _showError = false;
  String _retryTextKey = 'no_internet_retry';
  DateTime? _startedAt;
  bool _userReady = false;
  bool _navigated = false;
  bool _forceUpdateChecked = false;

  @override
  void initState() {
    super.initState();
    _startFlow();
  }

  Future<void> _startFlow() async {
    _startedAt = DateTime.now();
    _navigated = false;
    _userReady = false;
    if (mounted) {
      setState(() => _showError = false);
    }

    final token = prefs.getString(AppConstants.userToken);
    final refreshToken = prefs.getString(AppConstants.userRefreshToken);

    // ── Case 1: No credentials at all → onboarding or login ──────────────
    if ((token == null || token.isEmpty) &&
        (refreshToken == null || refreshToken.isEmpty)) {
      await _ensureMinSplash();
      if (!mounted) return;
      _goLogin();
      return;
    }

    // ── Case 2: Credentials exist → check internet connectivity first ────
    final hasNet = await NetworkManager.hasInternetConnection();
    if (!hasNet) {
      await _ensureMinSplash();
      if (!mounted) return;
      setState(() {
        _retryTextKey = 'no_internet_retry';
        _showError = true;
      });
      return;
    }

    // ── Case 3: Token is missing but refresh token exists ─────────────────
    if ((token == null || token.isEmpty) &&
        (refreshToken != null && refreshToken.isNotEmpty)) {
      final authService = AuthServices();
      final refreshed = await authService.refreshTokenOnStartup();
      if (!mounted) return;

      if (!refreshed) {
        final stillHasRefresh = prefs.getString(AppConstants.userRefreshToken);
        if (stillHasRefresh == null || stillHasRefresh.isEmpty) {
          await _ensureMinSplash();
          if (!mounted) return;
          _goLogin();
        } else {
          setState(() {
            _retryTextKey = 'no_internet_retry';
            _showError = true;
          });
        }
        return;
      }
    }

    // ── Case 4: Verify session & fetch user data via ProfileBloc ──────────
    if (!mounted) return;
    context.read<ProfileBloc>().add(GetCurrentUserEvent());
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
    if (!_userReady) return;

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
      _goRoot();
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
      return false;
    }
  }

  void _goLogin() {
    if (_navigated || !mounted) return;
    _navigated = true;
    final seenOnboarding = prefs.getBool(AppConstants.isOnboardingSeen) == true;
    goScreen(
      context: context,
      screen: seenOnboarding ? const LoginScreen() : const OnboardingsScreen(),
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
              current is GetCurrentUserError,
          listener: (context, state) async {
            if (state is GetCurrentUserLoading) {
              if (!mounted) return;
              setState(() => _showError = false);
            }

            if (state is GetCurrentUserSuccess) {
              currentUserModel = state.user;
              isLogin.value = true;

              final id = currentUserModel.id;
              if (id != null && id.isNotEmpty) {
                MessagingService.instance.onLogin(id);
              }

              _userReady = true;
              await _maybeProceed();
              return;
            }

            if (state is GetCurrentUserError) {
              await _ensureMinSplash();
              if (!mounted) return;

              if (state.errorCode == AppErrorCode.unauthorized) {
                _goLogin();
              } else {
                setState(() {
                  _retryTextKey = (state.errorCode == AppErrorCode.noInternet ||
                          state.errorCode == AppErrorCode.timeout ||
                          state.errorCode == AppErrorCode.dnsError ||
                          state.errorCode == AppErrorCode.gatewayError)
                      ? 'no_internet_retry'
                      : 'fetch_user_retry';
                  _showError = true;
                });
              }
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
