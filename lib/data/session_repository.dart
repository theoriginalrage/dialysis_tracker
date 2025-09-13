import 'package:sqflite/sqflite.dart';
import '../models/session.dart';
import 'db.dart';

class SessionRepository {
  Future<List<Session>> fetchAllSessions() async {
    final db = await AppDb.instance;
    // ignore: avoid_print
    print('SessionRepository: fetchAllSessions');
    final rows = await db.query('sessions', orderBy: 'date DESC');
    return rows.map((r) => Session.fromMap(r)).toList();
  }

  Future<void> upsertSession(Session s) async {
    final db = await AppDb.instance;
    // ignore: avoid_print
    print('SessionRepository: upsertSession for ${s.date}');
    await db.insert(
      'sessions',
      s.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Session?> getSessionForDay(DateTime d) async {
    final db = await AppDb.instance;
    final key = Session.dateKey(d);
    final rows = await db.query('sessions', where: 'date = ?', whereArgs: [key], limit: 1);
    return rows.isEmpty ? null : Session.fromMap(rows.first);
  }
}
