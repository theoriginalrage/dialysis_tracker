import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dialysis_tracker/state/session_store.dart';
import 'package:dialysis_tracker/models/session.dart';

class _FakePathProvider extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    final dir = await Directory.systemTemp.createTemp('db_test');
    return dir.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  PathProviderPlatform.instance = _FakePathProvider();
  SharedPreferences.setMockInitialValues({});

  test('persists session across reload', () async {
    final store = SessionStore();
    await store.load();
    final day = DateTime(2024, 1, 1);
    await store.upsertPartial(Session(date: day, preWeight: 70, preWeightAt: DateTime.now()));

    final store2 = SessionStore();
    await store2.load();
    expect(store2.sessions.any((s) => s.date.year == day.year && s.date.month == day.month && s.date.day == day.day && s.preWeight == 70), isTrue);
  });
}
