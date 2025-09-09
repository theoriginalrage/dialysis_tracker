class Session {
  final DateTime date;
  final double preWeight;
  final double preBP;   // systolic for MVP; expand later if you want s/ d
  final double postBP;
  final double postWeight;
  final String? notes;

  Session({
    required this.date,
    required this.preWeight,
    required this.preBP,
    required this.postBP,
    required this.postWeight,
    this.notes,
  });

  double get fluidRemoved => preWeight - postWeight;

  /// Very simple status for MVP:
  ///  - Green: fluid 1.0–3.0 kg
  ///  - Yellow: 0.5–1.0 or 3.0–3.5
  ///  - Red: <0.5 or >3.5
  String get status {
    final f = fluidRemoved.abs();
    if (f >= 1.0 && f <= 3.0) return 'green';
    if ((f >= 0.5 && f < 1.0) || (f > 3.0 && f <= 3.5)) return 'yellow';
    return 'red';
  }
}

