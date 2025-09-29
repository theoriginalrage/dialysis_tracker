import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WeightUnit { kg, lb }

class UnitService {
  static const _key = 'profile.unit';
  static final UnitService instance = UnitService._();
  UnitService._();

  final ValueNotifier<WeightUnit> unit = ValueNotifier(WeightUnit.kg);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    switch (raw) {
      case 'lb':
        unit.value = WeightUnit.lb;
        break;
      case 'lbs':
        unit.value = WeightUnit.lb;
        await prefs.setString(_key, 'lb');
        break;
      default:
        unit.value = WeightUnit.kg;
    }
  }

  Future<void> set(WeightUnit u) async {
    if (unit.value == u) return;
    unit.value = u;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, u == WeightUnit.lb ? 'lb' : 'kg');
  }
}
