import 'package:shared_preferences/shared_preferences.dart';

class ZarinpalPendingStore {
  static const _keyLastHandledRefId = 'last_handled_ref_id';

  static Future<String?> readLastHandledRefId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastHandledRefId);
  }

  static Future<void> saveLastHandledRefId(String refId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastHandledRefId, refId);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastHandledRefId);
  }
}
