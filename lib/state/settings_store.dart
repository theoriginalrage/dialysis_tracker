import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile.dart';

class SettingsStore extends ChangeNotifier {
  static const _kOnboarded = 'onboarded';
  static const _kProfile = 'profile';

  bool _loaded = false;          // 👈 NEW
  bool _onboarded = false;
  Profile? _profile;

  bool get loaded => _loaded;    // 👈 NEW
  bool get onboarded => _onboarded;
  Profile? get profile => _profile;

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    _onboarded = sp.getBool(_kOnboarded) ?? false;
    final p = sp.getString(_kProfile);
    if (p != null) {
      _profile = Profile.fromJson(jsonDecode(p));
    }
    _loaded = true;              // 👈 mark done
    notifyListeners();
  }

  Future<void> saveProfile(Profile p) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kProfile, jsonEncode(p.toJson()));
    await sp.setBool(_kOnboarded, true);
    _profile = p;
    _onboarded = true;
    _loaded = true;
    notifyListeners();
  }
}

