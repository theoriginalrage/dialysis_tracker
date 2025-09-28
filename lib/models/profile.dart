enum WeightUnit { kg, lb }

extension WeightUnitLabel on WeightUnit {
  String get storageKey => this == WeightUnit.lb ? 'lb' : 'kg';

  String get displayLabel => this == WeightUnit.lb ? 'lbs' : 'kg';
}

WeightUnit weightUnitFromStorage(String? value) {
  return value == 'lb' ? WeightUnit.lb : WeightUnit.kg;
}

class UserProfile {
  final String name;
  final String? photoPath;
  final double startWeight;
  final WeightUnit unit;

  const UserProfile({
    required this.name,
    required this.startWeight,
    required this.unit,
    this.photoPath,
  });

  UserProfile copyWith({
    String? name,
    String? photoPath,
    double? startWeight,
    WeightUnit? unit,
  }) {
    return UserProfile(
      name: name ?? this.name,
      photoPath: photoPath ?? this.photoPath,
      startWeight: startWeight ?? this.startWeight,
      unit: unit ?? this.unit,
    );
  }
}
