import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reservation_chat_univercity_project/core/payments/zarinpal_pending_store.dart';
import 'package:reservation_chat_univercity_project/core/utils/navigator.dart';
import 'package:reservation_chat_univercity_project/features/splash/screens/splash_screen.dart';
import 'package:reservation_chat_univercity_project/core/utils/snakbar.dart';
import 'package:toastification/toastification.dart';

import '../constants/app_setting.dart';

class ZarinpalCallbackHandler {
  ZarinpalCallbackHandler._();

  static final ZarinpalCallbackHandler instance = ZarinpalCallbackHandler._();

  StreamSubscription<Uri>? _sub;
  bool _initialized = false;

  static const MethodChannel _channel = MethodChannel('deep_link');

  /// Call this once at app start
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Listen to Android onNewIntent
    if (!kIsWeb) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onNewIntent') {
          final uri = Uri.parse(call.arguments as String);
          await handleUri(uri);
        }
      });
    }

    // ---- WEB: handle current URL ----
    if (kIsWeb) {
      await handleUri(Uri.base);
    }

    final appLinks = AppLinks();

    // ---- Cold start ----
    try {
      final initial = await appLinks.getInitialLink();
      if (initial != null) {
        await handleUri(initial);
      }
    } catch (_) {}

    // ---- Runtime deep links ----
    _sub = appLinks.uriLinkStream.listen(
      (uri) async => await handleUri(uri),
      onError: (_) {},
    );
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _initialized = false;
  }

  /// Public handler to call from Android onNewIntent
  Future<void> handleUri(Uri uri) async {
    final bool isPayment =
        (uri.scheme == 'reservation_chat_univercity_project' &&
            uri.host == 'payment') ||
        (uri.path == '/payment');

    if (!isPayment) return;

    // normalize query parameter
    String? status =
        uri.queryParameters['status'] ?? uri.queryParameters['Status'];
    final String? refId = uri.queryParameters['ref_id'];

    if (status == null || refId == null) return;
    status = status.toLowerCase().trim();

    if (status != 'success' && status != 'failed' && status != 'ok') return;

    // check if this refId already handled
    final lastHandledRef = await ZarinpalPendingStore.readLastHandledRefId();
    if (lastHandledRef == refId) return; // already processed

    // mark this refId as handled
    await ZarinpalPendingStore.saveLastHandledRefId(refId);

    // Wait until navigator is ready
    final ctx = await _waitForNavigatorContext();
    if (ctx == null) return;

    // Clear pending
    await ZarinpalPendingStore.clear();

    // Handle success
    if (status == 'success' || status == 'ok') {
      goScreen(
        context: ctx,
        screen: const SplashScreen(),
        closeAllScreen: true,
      );
      return;
    }

    // Handle failed
    if (status == 'failed') {
      showCustomSnackBar(
        context: ctx,
        title: 'پرداخت',
        content: 'پرداخت ناموفق بود.',
        status: ToastificationType.error,
      );
    }
  }

  Future<BuildContext?> _waitForNavigatorContext() async {
    for (int i = 0; i < 40; i++) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) return ctx;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    return null;
  }
}
