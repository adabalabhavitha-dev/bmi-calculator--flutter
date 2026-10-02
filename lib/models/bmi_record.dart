import 'package:flutter/foundation.dart';

import '../utils/bmi_calculator.dart';

/// One saved measurement belonging to a single [UserProfile].
@immutable
class BmiRecord {
  const BmiRecord({
    required this.id,
    required this.profileId,
    required this.bmi,
    required this.weightKg,
    required this.heightCm,
    required this.classification,
    required this.createdAt,
  });

  final String id;
  final String profileId;
  final double bmi;
  final double weightKg;
  final double heightCm;
  final BmiClassification classification;
  final DateTime createdAt;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'profileId': profileId,
        'bmi': bmi,
        'weightKg': weightKg,
        'heightCm': heightCm,
        'classification': classification.name,
        'createdAt': createdAt.toIso8601String(),
      };

  static BmiRecord? fromJson(Map<String, Object?> json) {
    final Object? id = json['id'];
    final Object? profileId = json['profileId'];
    final Object? bmi = json['bmi'];
    final Object? createdAt = json['createdAt'];
    if (id is! String ||
        id.isEmpty ||
        profileId is! String ||
        profileId.isEmpty ||
        bmi is! num ||
        createdAt is! String) {
      return null;
    }

    final DateTime? created = DateTime.tryParse(createdAt);
    if (created == null) {
      return null;
    }

    final String rawClass = json['classification'] is String ? json['classification']! as String : '';
    final BmiClassification classification = BmiClassification.values.firstWhere(
      (BmiClassification value) => value.name == rawClass,
      orElse: () => classifyBmi(bmi.toDouble()),
    );

    return BmiRecord(
      id: id,
      profileId: profileId,
      bmi: bmi.toDouble(),
      weightKg: json['weightKg'] is num ? (json['weightKg']! as num).toDouble() : 0,
      heightCm: json['heightCm'] is num ? (json['heightCm']! as num).toDouble() : 0,
      classification: classification,
      createdAt: created,
    );
  }
}
