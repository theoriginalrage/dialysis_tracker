class Profile {
  final String name;
  final List<int> dialysisWeekdays; // 1=Mon … 7=Sun (DateTime.monday..sunday)
  final String units; // 'kg' for now; future: lbs, etc.

  const Profile({
    required this.name,
    required this.dialysisWeekdays,
    this.units = 'kg',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'days': dialysisWeekdays,
        'units': units,
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        name: j['name'] ?? '',
        dialysisWeekdays: (j['days'] as List).cast<int>(),
        units: j['units'] ?? 'kg',
      );
}

