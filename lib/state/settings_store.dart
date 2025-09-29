import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/profile_prefs.dart';

class SettingsStore extends ChangeNotifier {
  bool _loaded = false;
  bool _onboarded = false;
  String _name = '';
  double? _startWeight;
  String _unit = 'kg';
  Uint8List? _photoBytes;
  ThemeMode _themeMode = ThemeMode.light;
  List<int> _dialysisWeekdays = <int>[];

  bool get loaded => _loaded;
  bool get onboarded => _onboarded;
  String get name => _name;
  double? get startWeight => _startWeight;
  String get unit => _unit;
  Uint8List? get photoBytes => _photoBytes;
  ThemeMode get themeMode => _themeMode;
  bool get darkMode => _themeMode == ThemeMode.dark;
  List<int> get dialysisWeekdays => List.unmodifiable(_dialysisWeekdays);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    await migrateOldPhotoIfNeeded(prefs);

    _dialysisWeekdays = <int>[];
    String? legacyName;
    String? legacyUnit;
    final legacyProfileJson = prefs.getString(kLegacyProfileJsonKey);
    if (legacyProfileJson != null) {
      try {
        final Map<String, dynamic> legacy = jsonDecode(legacyProfileJson) as Map<String, dynamic>;
        final days = legacy['days'];
        if (days is List) {
          _dialysisWeekdays = days.whereType<int>().toList();
        }
        final name = legacy['name'];
        if (name is String && name.trim().isNotEmpty) {
          legacyName = name.trim();
        }
        final units = legacy['units'];
        if (units is String && units.isNotEmpty) {
          legacyUnit = units;
        }
      } catch (_) {
        _dialysisWeekdays = <int>[];
      }
    }

    _name = prefs.getString(kProfileNameKey) ?? legacyName ?? '';
    _unit = prefs.getString(kProfileUnitKey) ?? legacyUnit ?? 'kg';
    _startWeight = prefs.getDouble(kProfileStartWeightKey);
    _photoBytes = decodePhotoBase64(prefs.getString(kProfilePhotoBase64Key));

    final storedTheme = prefs.getString(kPrefsThemeModeKey);
    _themeMode = parseThemeMode(storedTheme);
    if (storedTheme == null) {
      final legacyDark = prefs.getBool(kLegacyDarkModeKey);
      if (legacyDark != null) {
        _themeMode = legacyDark ? ThemeMode.dark : ThemeMode.light;
        await prefs.setString(kPrefsThemeModeKey, encodeThemeMode(_themeMode));
      }
    }

    _onboarded = prefs.getBool(kProfileOnboardedKey) ?? (_name.isNotEmpty && _startWeight != null);
    _loaded = true;
    notifyListeners();
  }

  Future<void> saveProfile({
    required String name,
    required double startWeight,
    required String unit,
    Uint8List? photoBytes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kProfileNameKey, name);
    await prefs.setDouble(kProfileStartWeightKey, startWeight);
    await prefs.setString(kProfileUnitKey, unit);
    if (photoBytes != null && photoBytes.isNotEmpty) {
      await prefs.setString(kProfilePhotoBase64Key, base64Encode(photoBytes));
    } else {
      await prefs.remove(kProfilePhotoBase64Key);
    }
    await prefs.setBool(kProfileOnboardedKey, true);

    _name = name;
    _startWeight = startWeight;
    _unit = unit;
    _photoBytes = photoBytes;
    _onboarded = true;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    await setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefsThemeModeKey, encodeThemeMode(mode));
    _themeMode = mode;
    notifyListeners();
  }
}

