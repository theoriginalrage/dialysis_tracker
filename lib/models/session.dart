class Session {
  final DateTime date;
  final double? preWeight;
  final DateTime? preWeightAt;
  final double? preBP;
  final DateTime? preBPAt;
  final double? postBP;
  final DateTime? postBPAt;
  final double? postWeight;
  final DateTime? postWeightAt;
  final String? notes;
  final DateTime? notesAt;

  Session({
    required this.date,
    this.preWeight,
    this.preWeightAt,
    this.preBP,
    this.preBPAt,
    this.postBP,
    this.postBPAt,
    this.postWeight,
    this.postWeightAt,
    this.notes,
    this.notesAt,
  });

  static String dateKey(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String();

  double? get fluidRemoved =>
      (preWeight != null && postWeight != null)
          ? preWeight! - postWeight!
          : null;

  String? get status {
    final f = fluidRemoved;
    if (f == null) return null;
    final af = f.abs();
    if (af >= 1.0 && af <= 3.0) return 'green';
    if ((af >= 0.5 && af < 1.0) || (af > 3.0 && af <= 3.5)) return 'yellow';
    return 'red';
  }

  Session merge(Session other) => Session(
        date: date,
        preWeight: other.preWeight ?? preWeight,
        preWeightAt:
            other.preWeight != null ? other.preWeightAt ?? DateTime.now() : preWeightAt,
        preBP: other.preBP ?? preBP,
        preBPAt: other.preBP != null ? other.preBPAt ?? DateTime.now() : preBPAt,
        postBP: other.postBP ?? postBP,
        postBPAt:
            other.postBP != null ? other.postBPAt ?? DateTime.now() : postBPAt,
        postWeight: other.postWeight ?? postWeight,
        postWeightAt: other.postWeight != null
            ? other.postWeightAt ?? DateTime.now()
            : postWeightAt,
        notes: other.notes ?? notes,
        notesAt: other.notes != null ? other.notesAt ?? DateTime.now() : notesAt,
      );

  Map<String, dynamic> toMap() => {
        'date': dateKey(date),
        'preWeight': preWeight,
        'preWeightAt': preWeightAt?.toIso8601String(),
        'preBP': preBP,
        'preBPAt': preBPAt?.toIso8601String(),
        'postBP': postBP,
        'postBPAt': postBPAt?.toIso8601String(),
        'postWeight': postWeight,
        'postWeightAt': postWeightAt?.toIso8601String(),
        'notes': notes,
        'notesAt': notesAt?.toIso8601String(),
      };

  factory Session.fromMap(Map<String, dynamic> map) => Session(
        date: DateTime.parse(map['date'] as String),
        preWeight: map['preWeight'] as double?,
        preWeightAt: map['preWeightAt'] != null
            ? DateTime.parse(map['preWeightAt'] as String)
            : null,
        preBP: map['preBP'] as double?,
        preBPAt:
            map['preBPAt'] != null ? DateTime.parse(map['preBPAt'] as String) : null,
        postBP: map['postBP'] as double?,
        postBPAt: map['postBPAt'] != null
            ? DateTime.parse(map['postBPAt'] as String)
            : null,
        postWeight: map['postWeight'] as double?,
        postWeightAt: map['postWeightAt'] != null
            ? DateTime.parse(map['postWeightAt'] as String)
            : null,
        notes: map['notes'] as String?,
        notesAt: map['notesAt'] != null
            ? DateTime.parse(map['notesAt'] as String)
            : null,
      );
}
