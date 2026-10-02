/// The four BMI tiers used across the app.
enum BmiClassification {
  underweight('Underweight', 'Below 18.5'),
  normal('Normal', '18.5 – 24.9'),
  overweight('Overweight', '25.0 – 29.9'),
  obesity('Obesity', '30.0 and above');

  const BmiClassification(this.label, this.range);

  /// Human-readable tier name shown on the result screen.
  final String label;

  /// The numeric band this tier covers, shown as a caption.
  final String range;
}

/// Parses a height typed in metres into centimetres.
///
/// Returns `null` when the value cannot be read as a positive number.
double? heightToCm(String raw, {required bool isMeters}) {
  final double? parsed = _parsePositive(raw);
  if (parsed == null) {
    return null;
  }
  final double cm = isMeters ? parsed * 100 : parsed;
  return cm > 0 ? cm : null;
}

/// Parses a weight typed in kilograms.
double? weightToKg(String raw) => _parsePositive(raw);

double? _parsePositive(String raw) {
  final String trimmed = raw.trim().replaceAll(',', '.');
  if (trimmed.isEmpty) {
    return null;
  }
  final double? value = double.tryParse(trimmed);
  if (value == null || value.isNaN || value.isInfinite || value <= 0) {
    return null;
  }
  return value;
}

/// Body mass index from kilograms and centimetres.
double calculateBmi({required double weightKg, required double heightCm}) {
  if (heightCm <= 0) {
    throw ArgumentError.value(heightCm, 'heightCm', 'must be greater than zero');
  }
  final double metres = heightCm / 100;
  return weightKg / (metres * metres);
}

/// Maps a BMI value onto one of the four tiers.
BmiClassification classifyBmi(double bmi) {
  if (bmi < 18.5) {
    return BmiClassification.underweight;
  }
  if (bmi < 25) {
    return BmiClassification.normal;
  }
  if (bmi < 30) {
    return BmiClassification.overweight;
  }
  return BmiClassification.obesity;
}

/// Formats a BMI for display, e.g. `22.4`.
String formatBmi(double bmi) => bmi.toStringAsFixed(1);

/// Human-readable sentence for the result screen.
String classificationMessage(BmiClassification classification) {
  switch (classification) {
    case BmiClassification.underweight:
      return 'This falls below the healthy range. Consider speaking with a clinician about nutrition.';
    case BmiClassification.normal:
      return 'This sits in the healthy range for adults. Keep the habits that are working.';
    case BmiClassification.overweight:
      return 'This sits above the healthy range. Small, sustained changes move it back.';
    case BmiClassification.obesity:
      return 'This sits well above the healthy range. A clinician can help plan the next step.';
  }
}
