import 'package:device_preview/device_preview.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:reservation_chat_univercity_project/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:reservation_chat_univercity_project/features/onboarding/services/onboarding_service.dart';

import 'core/constants/app_setting.dart';
import 'core/localization/locale_initializer.dart';
import 'core/payments/payment_gateway.dart';
import 'core/payments/zarinpal_callback_handler.dart';
import 'core/utils/voice_player_manager.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/service/auth_service.dart';
import 'features/blog/bloc/blog_bloc.dart';
import 'features/blog/service/blog_service.dart';

import 'features/home/bloc/home_bloc.dart';

import 'features/profile/bloc/profile_bloc.dart';
import 'features/profile/service/profile_service.dart';

import 'app.dart';
import 'core/notifications/messaging_service.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await ScreenUtil.ensureScreenSize();
  await initGlobalSettings();
  await VoicePlayerManager.instance.init();
  await ZarinpalCallbackHandler.instance.init();
  final Locale initialLocale = await determineInitialLocale();
  // ! map cache
  try {
    await messagingService.initialize();
  } catch (e) {
    debugPrint('Firebase messaging initialization failed: $e');
  }

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('fa'), Locale('en')],
      path: 'assets/translations',
      startLocale: initialLocale,
      fallbackLocale: const Locale('en'),
      saveLocale: true,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<BlogBloc>(create: (context) => BlogBloc(BlogServices())),
          BlocProvider<AuthBloc>(create: (context) => AuthBloc(AuthServices())),

          BlocProvider<ProfileBloc>(
            create: (context) => ProfileBloc(ProfileService()),
          ),
          BlocProvider<OnboardingBloc>(
            create: (context) => OnboardingBloc(OnboardingService()),
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          enableScaleText: () => !kIsWeb,
          enableScaleWH: () => !kIsWeb,
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, _) {
            return DevicePreview(
              enabled: false, // enabled: !kReleaseMode
              builder: (context) => const MyApp(),
            );
          },
        ),
      ),
    ),
  );
}
