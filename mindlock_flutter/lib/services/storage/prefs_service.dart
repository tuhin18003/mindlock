import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'prefs_service.g.dart';

@riverpod
Future<PrefsService> prefsService(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  return PrefsService(prefs);
}

class PrefsService {
  final SharedPreferences _prefs;

  PrefsService(this._prefs);

  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  String? getString(String key) => _prefs.getString(key);

  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  bool? getBool(String key) => _prefs.getBool(key);

  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);

  int? getInt(String key) => _prefs.getInt(key);

  Future<void> setJson(String key, Map<String, dynamic> json) =>
      _prefs.setString(key, jsonEncode(json));

  Map<String, dynamic>? getJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> setJsonList(String key, List<Map<String, dynamic>> list) =>
      _prefs.setString(key, jsonEncode(list));

  List<Map<String, dynamic>>? getJsonList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as List;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> remove(String key) => _prefs.remove(key);

  bool containsKey(String key) => _prefs.containsKey(key);

  Future<void> clear() => _prefs.clear();
}
