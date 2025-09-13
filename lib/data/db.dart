import 'dart:convert';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDb {
  static Database? _db;

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'dialysis.db');
    // Log DB open so it's visible in logcat
    // ignore: avoid_print
    print('AppDb: opening database at ' + path);
    _db = await openDatabase(path, version: 1, onCreate: _onCreate);
    // Ensure sessions table exists for upgrades
    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS sessions(
        date TEXT PRIMARY KEY,
        preWeight REAL, preWeightAt TEXT,
        preBP REAL, preBPAt TEXT,
        postBP REAL, postBPAt TEXT,
        postWeight REAL, postWeightAt TEXT,
        notes TEXT, notesAt TEXT
      );
    ''');
    return _db!;
  }

  static Future _onCreate(Database db, int v) async {
    await db.execute('''
      CREATE TABLE profile(
        id INTEGER PRIMARY KEY,
        name TEXT, dob TEXT, photoPath TEXT,
        startWeightKg REAL,
        fluidTargetMlPerDay INTEGER,
        scheduleDays TEXT,   -- JSON "[1,3,5]"
        scheduleTime TEXT    -- "08:00"
      );
    ''');

    await db.execute('''
      CREATE TABLE treatments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT, start TEXT, durationMin INTEGER,
        location TEXT, ufMl INTEGER,
        preWeightKg REAL, postWeightKg REAL,
        notes TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE vitals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT, phase TEXT, -- 'pre' or 'post'
        weightKg REAL, sys INTEGER, dia INTEGER, pulse INTEGER, tempC REAL
      );
    ''');

    await db.execute('''
      CREATE TABLE fluids(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT, amountMl INTEGER
      );
    ''');

    await db.execute('''
      CREATE TABLE meds(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT, strength TEXT, instructions TEXT,
        timesJson TEXT, daysJson TEXT,
        startDate TEXT, endDate TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE dose_log(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medId INTEGER, timestamp TEXT, taken INTEGER
      );
    ''');

    await db.execute('''
      CREATE TABLE sessions(
        date TEXT PRIMARY KEY,
        preWeight REAL, preWeightAt TEXT,
        preBP REAL, preBPAt TEXT,
        postBP REAL, postBPAt TEXT,
        postWeight REAL, postWeightAt TEXT,
        notes TEXT, notesAt TEXT
      );
    ''');
  }

  // -------- Profile helpers --------

  /// Returns the single profile row (id=1) or null.
  static Future<Map<String, dynamic>?> getProfile() async {
    final db = await instance;
    final rows = await db.query('profile', where: 'id = 1', limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  /// Upsert (insert or replace) the profile row at id=1.
  static Future<void> saveProfile({
    required String name,
    String? dobIso,
    String? photoPath,
    double? startWeightKg,
    int? fluidTargetMlPerDay,
    required List<int> scheduleDays, // 1..7
    required String scheduleTime,    // "HH:MM"
  }) async {
    final db = await instance;
    await db.insert(
      'profile',
      {
        'id': 1,
        'name': name,
        'dob': dobIso,
        'photoPath': photoPath,
        'startWeightKg': startWeightKg,
        'fluidTargetMlPerDay': fluidTargetMlPerDay,
        'scheduleDays': jsonEncode(scheduleDays),
        'scheduleTime': scheduleTime,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

