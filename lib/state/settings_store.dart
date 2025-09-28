import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile.dart';

class SettingsStore extends ChangeNotifier {
  static const _kName = 'profile.name';
  static const _kPhotoPath = 'profile.photoPath';
  static const _kStartWeight = 'profile.startWeight';
  static const _kUnit = 'profile.unit';

  bool _loaded = false;
  UserProfile? _profile;

  bool get loaded => _loaded;
  bool get onboarded => _profile != null;
  UserProfile? get profile => _profile;

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final name = sp.getString(_kName)?.trim();
    final startWeightRaw = sp.getString(_kStartWeight);
    final unitRaw = sp.getString(_kUnit);
    final photoPath = sp.getString(_kPhotoPath);
    final startWeight = startWeightRaw != null ? double.tryParse(startWeightRaw) : null;

    if (name != null && name.isNotEmpty && startWeight != null && startWeight > 0) {
      _profile = UserProfile(
        name: name,
        photoPath: photoPath?.isNotEmpty == true ? photoPath : null,
        startWeight: startWeight,
        unit: weightUnitFromStorage(unitRaw),
      );
    } else {
      _profile = null;
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> saveProfile(UserProfile profile) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kName, profile.name.trim());
    await sp.setString(_kStartWeight, profile.startWeight.toString());
    await sp.setString(_kUnit, profile.unit.storageKey);
    final photoPath = profile.photoPath;
    if (photoPath != null && photoPath.isNotEmpty) {
      await sp.setString(_kPhotoPath, photoPath);
    } else {
      await sp.remove(_kPhotoPath);
    }

    _profile = profile;
    _loaded = true;
    notifyListeners();
  }
}
