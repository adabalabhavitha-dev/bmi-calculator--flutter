import 'package:bmi/models/bmi_record.dart';
import 'package:bmi/models/user_profile.dart';
import 'package:bmi/utils/bmi_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calculateBmi', () {
    test('72.5 kg at 172 cm is 24.5', () {
      final double bmi = calculateBmi(weightKg: 72.5, heightCm: 172);
      expect(bmi, closeTo(24.51, 0.01));
      expect(formatBmi(bmi), '24.5');
    });

    test('60 kg at 160 cm is 23.4', () {
      final double bmi = calculateBmi(weightKg: 60, heightCm: 160);
      expect(bmi, closeTo(23.44, 0.01));
    });

    test('rejects a zero height', () {
      expect(
        () => calculateBmi(weightKg: 70, heightCm: 0),
        throwsArgumentError,
      );
    });
  });

  group('classifyBmi — four tiers at their boundaries', () {
    test('17.0 is underweight', () {
      expect(classifyBmi(17.0), BmiClassification.underweight);
    });

    test('18.49 is underweight, 18.5 is normal', () {
      expect(classifyBmi(18.49), BmiClassification.underweight);
      expect(classifyBmi(18.5), BmiClassification.normal);
    });

    test('24.9 is normal, 25 is overweight', () {
      expect(classifyBmi(24.9), BmiClassification.normal);
      expect(classifyBmi(25.0), BmiClassification.overweight);
    });

    test('29.9 is overweight, 30 is obesity', () {
      expect(classifyBmi(29.9), BmiClassification.overweight);
      expect(classifyBmi(30.0), BmiClassification.obesity);
    });

    test('40 is obesity', () {
      expect(classifyBmi(40.0), BmiClassification.obesity);
    });
  });

  group('height unit conversion', () {
    test('172 in centimetres is 172', () {
      expect(heightToCm('172', isMeters: false), 172);
    });

    test('1.72 in metres is 172', () {
      expect(heightToCm('1.72', isMeters: true), closeTo(172, 0.001));
    });

    test('accepts a comma decimal separator', () {
      expect(heightToCm('1,72', isMeters: true), closeTo(172, 0.001));
      expect(weightToKg('72,5'), closeTo(72.5, 0.001));
    });

    test('rejects empty, zero and non-numeric input', () {
      expect(heightToCm('', isMeters: false), isNull);
      expect(heightToCm('0', isMeters: false), isNull);
      expect(heightToCm('-5', isMeters: false), isNull);
      expect(heightToCm('tall', isMeters: false), isNull);
      expect(weightToKg(''), isNull);
      expect(weightToKg('0'), isNull);
      expect(weightToKg('heavy'), isNull);
    });
  });

  group('formatBmi', () {
    test('one decimal place', () {
      expect(formatBmi(22.444), '22.4');
      expect(formatBmi(18.499), '18.5');
      expect(formatBmi(30), '30.0');
    });
  });

  group('BmiClassification labels', () {
    test('every tier has a non-empty name and range', () {
      for (final BmiClassification tier in BmiClassification.values) {
        expect(tier.label, isNotEmpty);
        expect(tier.range, isNotEmpty);
      }
    });
  });

  group('serialization round trips', () {
    test('UserProfile survives toJson / fromJson', () {
      const UserProfile original = UserProfile(
        id: 'u_abc',
        name: 'Priya Raman',
        age: 34,
        gender: ProfileGender.female,
        heightUnitCm: false,
        lastWeight: '72.5',
        lastHeight: '1.72',
      );
      final UserProfile? restored = UserProfile.fromJson(original.toJson());
      expect(restored, isNotNull);
      expect(restored!.id, original.id);
      expect(restored.name, original.name);
      expect(restored.age, original.age);
      expect(restored.gender, original.gender);
      expect(restored.heightUnitCm, original.heightUnitCm);
      expect(restored.lastWeight, original.lastWeight);
      expect(restored.lastHeight, original.lastHeight);
    });

    test('BmiRecord survives toJson / fromJson', () {
      final DateTime created = DateTime(2026, 3, 14, 9, 26);
      final BmiRecord original = BmiRecord(
        id: 'r_1',
        profileId: 'u_abc',
        bmi: 24.46,
        weightKg: 72.5,
        heightCm: 172,
        classification: BmiClassification.normal,
        createdAt: created,
      );
      final BmiRecord? restored = BmiRecord.fromJson(original.toJson());
      expect(restored, isNotNull);
      expect(restored!.id, original.id);
      expect(restored.profileId, original.profileId);
      expect(restored.bmi, original.bmi);
      expect(restored.weightKg, original.weightKg);
      expect(restored.heightCm, original.heightCm);
      expect(restored.classification, original.classification);
      expect(restored.createdAt, created);
    });

    test('malformed profile JSON is rejected, not thrown', () {
      expect(UserProfile.fromJson(<String, Object?>{}), isNull);
      expect(UserProfile.fromJson(<String, Object?>{'id': '', 'name': 'A', 'age': 2}), isNull);
      expect(BmiRecord.fromJson(<String, Object?>{}), isNull);
    });
  });
}
