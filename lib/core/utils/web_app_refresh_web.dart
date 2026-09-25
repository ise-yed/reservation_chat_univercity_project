import 'package:web/web.dart' as web;
import 'dart:js_interop';

Future<void> refreshWebAppSafely() async {
  // update SW + clear caches + reload
  try {
    final jsRegs = await web.window.navigator.serviceWorker
        .getRegistrations()
        .toDart;
    if (!jsRegs.isNull) {
      final regs = jsRegs.toDart.cast<web.ServiceWorkerRegistration>();
      for (final reg in regs) {
        try {
          await reg.update().toDart;
        } catch (_) {}
      }
    }
  } catch (_) {}

  try {
    final jsKeys = await web.window.caches.keys().toDart;
    if (jsKeys != null) {
      final keys = jsKeys.toDart.cast<String>();
      for (final key in keys) {
        try {
          await web.window.caches.delete(key).toDart;
        } catch (_) {}
      }
    }
  } catch (_) {}

  web.window.location.reload();
}
