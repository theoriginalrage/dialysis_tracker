import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/session.dart';
import '../data/session_repository.dart';

class SessionStore extends ChangeNotifier {
  final List<Session> _sessions = [];
  final SessionRepository _repo = SessionRepository();

  List<Session> get sessions =>
      List.unmodifiable(_sessions..sort((a, b) => b.date.compareTo(a.date)));

  Session? sessionForDay(DateTime d) {
    for (final s in _sessions) {
      if (_sameDay(s.date, d)) return s;
    }
    return null;
  }

  Future<void> load() async {
    // ignore: avoid_print
    print('SessionStore: loading sessions');
    await _migrateLegacy();
    _sessions
      ..clear()
      ..addAll(await _repo.fetchAllSessions());
    // ignore: avoid_print
    print('SessionStore: loaded ${_sessions.length} sessions');
    notifyListeners();
  }

  Future<void> _migrateLegacy() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('sessions_v1');
    if (data == null) return;
    // ignore: avoid_print
    print('SessionStore: migrating legacy sessions');
    try {
      final list = jsonDecode(data) as List;
      for (final m in list) {
        final s = Session(
          date: DateTime.parse(m['date'] as String),
          preWeight: (m['preWeight'] as num?)?.toDouble(),
          preWeightAt: DateTime.now(),
          preBP: (m['preBP'] as num?)?.toDouble(),
          preBPAt: DateTime.now(),
          postBP: (m['postBP'] as num?)?.toDouble(),
          postBPAt: DateTime.now(),
          postWeight: (m['postWeight'] as num?)?.toDouble(),
          postWeightAt: DateTime.now(),
          notes: m['notes'] as String?,
          notesAt: DateTime.now(),
        );
        await _repo.upsertSession(s);
      }
      await prefs.remove('sessions_v1');
    } catch (e) {
      // ignore: avoid_print
      print('SessionStore: legacy migration failed: $e');
    }
  }

  Future<void> upsertPartial(Session patch) async {
    final existing = sessionForDay(patch.date);
    if (existing != null) {
      final merged = existing.merge(patch);
      _sessions[_sessions.indexOf(existing)] = merged;
      await _repo.upsertSession(merged);
    } else {
      await _repo.upsertSession(patch);
      _sessions.add(patch);
    }
    // ignore: avoid_print
    print('SessionStore: saved session for ${patch.date}');
    notifyListeners();
  }

  double get avgPreWeight {
    final vals =
        _sessions.map((s) => s.preWeight).whereType<double>().toList();
    if (vals.isEmpty) return 0;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  double get avgBP {
    final vals = _sessions.map((s) => s.preBP).whereType<double>().toList();
    if (vals.isEmpty) return 0;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
