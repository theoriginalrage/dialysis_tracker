import 'package:intl/intl.dart';

import '../services/unit_service.dart';

const double lbsPerKg = 2.20462262185;

double toDisplayFromKg(double kg, WeightUnit unit) =>
    unit == WeightUnit.kg ? kg : kg * lbsPerKg;

/// Parse a user-entered number (in the *selected* unit) and return kg.
double toKgFromInput(double valueInUnit, WeightUnit unit) =>
    unit == WeightUnit.kg ? valueInUnit : (valueInUnit / lbsPerKg);

String formatWeight(double kg, WeightUnit unit, {int decimals = 1}) {
  final value = toDisplayFromKg(kg, unit);
  final formatted = NumberFormat.decimalPattern()
      .format(double.parse(value.toStringAsFixed(decimals)));
  return '$formatted ${unit == WeightUnit.kg ? 'kg' : 'lbs'}';
}
