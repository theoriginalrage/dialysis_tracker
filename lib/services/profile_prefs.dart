import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'photo_loader.dart';

const String kProfileNameKey = 'profile.name';
const String kProfilePhotoBase64Key = 'profile.photoBase64';
const String kProfileStartWeightKey = 'profile.startWeight';
const String kProfileUnitKey = 'profile.unit';
const String kProfileOnboardedKey = 'onboarded';
const String kLegacyProfileJsonKey = 'profile';
const String kLegacyProfilePhotoPathKey = 'profile.photoPath';
const String kLegacyDarkModeKey = 'darkMode';
const String kPrefsThemeModeKey = 'prefs.themeMode';

Future<void> migrateOldPhotoIfNeeded(SharedPreferences prefs) async {
  final oldPath = prefs.getString(kLegacyProfilePhotoPathKey);
  final hasNew = prefs.getString(kProfilePhotoBase64Key) != null;
  if (oldPath != null && !hasNew) {
    final bytes = await tryLoadBytesFromPath(oldPath);
    if (bytes != null) {
      await prefs.setString(kProfilePhotoBase64Key, base64Encode(bytes));
    }
    await prefs.remove(kLegacyProfilePhotoPathKey);
  }
}

Uint8List? decodePhotoBase64(String? b64) {
  if (b64 == null || b64.isEmpty) return null;
  try {
    return base64Decode(b64);
  } catch (_) {
    return null;
  }
}

String encodeThemeMode(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.light:
      return 'light';
    case ThemeMode.system:
      return 'system';
  }
}

ThemeMode parseThemeMode(String? value, {ThemeMode fallback = ThemeMode.light}) {
  switch (value) {
    case 'dark':
      return ThemeMode.dark;
    case 'system':
      return ThemeMode.system;
    case 'light':
      return ThemeMode.light;
    default:
      return fallback;
  }
}
