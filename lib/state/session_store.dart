import 'package:flutter/foundation.dart';
import '../models/session.dart';

class SessionStore extends ChangeNotifier {
  final List<Session> _sessions = [];

  List<Session> get sessions =>
      List.unmodifiable(_sessions..sort((a, b) => b.date.compareTo(a.date)));

  void add(Session s) {
    _sessions.add(s);
    notifyListeners();
  }

  double get avgPreWeight {
    if (_sessions.isEmpty) return 0;
    return _sessions.map((s) => s.preWeight).reduce((a, b) => a + b) /
        _sessions.length;
  }

  double get avgBP {
    if (_sessions.isEmpty) return 0;
    return _sessions.map((s) => s.preBP).reduce((a, b) => a + b) /
        _sessions.length;
  }
}

