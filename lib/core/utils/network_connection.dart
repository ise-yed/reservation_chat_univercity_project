import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

class NetworkManager {
  static final Connectivity _connectivity = Connectivity();

  static final StreamController<bool> _statusController =
      StreamController<bool>.broadcast();

  static StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  static bool? _lastStatus;

  static Future<bool> hasInternetConnection({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    try {
      final statusList = await _connectivity.checkConnectivity();
      if (statusList.isEmpty ||
          (statusList.length == 1 &&
              statusList.contains(ConnectivityResult.none))) {
        return false;
      }

      if (kIsWeb) return true;

      // Probe backend host first (especially important for local IP / offline LAN setups)
      try {
        final uri = Uri.tryParse(AppConstants.appBaseUrl);
        if (uri != null && uri.host.isNotEmpty) {
          final port = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
          final s = await Socket.connect(uri.host, port, timeout: timeout);
          s.destroy();
          return true;
        }
      } catch (_) {}

      // Fallback: probe public DNS
      Future<bool> probe(String host) async {
        try {
          final s = await Socket.connect(host, 53, timeout: timeout);
          s.destroy();
          return true;
        } catch (_) {
          return false;
        }
      }

      if (await probe('1.1.1.1')) return true;
      if (await probe('8.8.8.8')) return true;

      try {
        final lookup = await InternetAddress.lookup(
          'google.com',
        ).timeout(timeout);
        return lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  static void _startMonitoring() {
    if (_connectivitySub != null) return;

    _connectivitySub = _connectivity.onConnectivityChanged.listen((list) async {
      final isNone = list.isEmpty ||
          (list.length == 1 && list.contains(ConnectivityResult.none));

      final hasNet = isNone ? false : await hasInternetConnection();

      if (hasNet != _lastStatus) {
        _lastStatus = hasNet;
        _statusController.add(hasNet);
      }
    });

    hasInternetConnection().then((value) {
      _lastStatus = value;
      _statusController.add(value);
    });
  }

  static Stream<bool> get internetStatusStream async* {
    _startMonitoring();
    if (_lastStatus != null) {
      yield _lastStatus!;
    }
    yield* _statusController.stream;
  }

  static bool? get lastKnownStatus => _lastStatus;

  static Future<void> dispose() async {
    await _connectivitySub?.cancel();
    _connectivitySub = null;
    // await _statusController.close();
  }
}
