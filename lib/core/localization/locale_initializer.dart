import 'dart:ui' show Locale, PlatformDispatcher;
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../constants/app_setting.dart';
import '../utils/api_provider.dart';

Future<Locale> determineInitialLocale() async {
  // If we already decided once, never call the IP service again.
  final bool alreadyInitialized =
      (prefs.getBool(AppConstants.isLocaleInitialized) ?? false);

  if (alreadyInitialized) {
    final int code =
        prefs.getInt(AppConstants.selectedLanguageCode) ?? AppLanguages.codeEn;
    return AppLanguages.localeFromCode(code);
  }

  Locale decidedLocale;

  try {
    final Response response = await apiProvider.get('setting/ip');

    final int statusCode = response.statusCode ?? 0;
    final dynamic data = response.data;
    final bool? status = (data is Map) ? data['status'] as bool? : null;

    // Primary rules based on your backend behavior.
    if (statusCode == 200 && status == true) {
      decidedLocale = AppLanguages.fa;
    } else if (statusCode == 403 && status == false) {
      decidedLocale = AppLanguages.en;
    } else {
      // Defensive: if backend changes behavior or returns unexpected payload.
      decidedLocale = AppLanguages.fa;
    }
  } catch (_) {
    // Network/timeout/interceptor errors.
    decidedLocale = AppLanguages.fa;
  }

  // Persist the decision so this won't happen again.
  await _persistLocaleDecision(decidedLocale);
  return decidedLocale;
}

Locale _fallbackLocale() {
  // If device language is Persian, default to fa, else en.
  final String code = PlatformDispatcher.instance.locale.languageCode;
  return (code.toLowerCase().startsWith('fa'))
      ? AppLanguages.fa
      : AppLanguages.en;
}

Future<void> _persistLocaleDecision(Locale locale) async {
  final int code = (locale.languageCode == AppLanguages.fa.languageCode)
      ? AppLanguages.codeFa
      : AppLanguages.codeEn;

  await prefs.setBool(AppConstants.isLocaleInitialized, true);
  await prefs.setInt(AppConstants.selectedLanguageCode, code);
}

/// Call this whenever user changes language manually.
Future<void> persistUserSelectedLocale(Locale locale) async {
  await _persistLocaleDecision(locale);
}
