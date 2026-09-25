import 'package:flutter/material.dart';
import 'package:reservation_chat_univercity_project/features/profile/model/app_const_setting_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/models/user_model.dart';
import '../utils/unfocus_on_route_change.dart';
import 'app_constants.dart';

// ------------------------------------------------
late final SharedPreferences prefs;
ValueNotifier<bool> isLogin = ValueNotifier(false);
ValueNotifier<bool> isThemeLight = ValueNotifier(false);
final navigatorKey = GlobalKey<NavigatorState>();
final unfocusObserver = UnfocusOnRouteChange();

// ------------------------------------------------
final String appVersion = '1.0.0';
final String appBuildVersion = '1';
// ------------------------------------------------
UserModel currentUserModel = UserModel();
AppConstSettingModel appConstSetting = AppConstSettingModel();
// ------------------------------------------------
Future<void> initGlobalSettings() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeSharedPreferences();
  await loadUserInformation();
  isThemeLight.value = (prefs.getBool(AppConstants.isThemeLight)) == null
      ? true
      : (prefs.getBool(AppConstants.isThemeLight)) == true;
  // isThemeLight.value = false;
}

Future<void> initializeSharedPreferences() async {
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('Error initializing SharedPreferences: $e');
  }
}

Future<void> loadUserInformation() async {
  isLogin.value = prefs.getString(AppConstants.userToken) != null;
}

// ------------------------------------------------
class AppLanguages {
  static const int codeFa = 0;
  static const int codeEn = 1;

  static const Locale fa = Locale('fa');
  static const Locale en = Locale('en');

  static const List<Locale> supportedLocales = [fa, en];

  static Locale localeFromCode(int code) {
    return code == codeFa ? fa : en;
  }
}
