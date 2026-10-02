import 'package:flutter/foundation.dart';

/// The gender a person selects for their profile.
///
/// This value is display-only. It never influences the BMI calculation or the
/// classification shown on the result screen.
enum ProfileGender {
  female('Female'),
  male('Male'),
  nonBinary('Non-binary'),
  preferNotToSay('Prefer not to say');

  const ProfileGender(this.label);

  final String label;

  String get storageKey => name;
}

/// A single person using the app. Each profile owns its own BMI history.
@immutable
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    this.heightUnitCm = true,
    this.lastWeight = '',
    this.lastHeight = '',
    this.updatedAt,
  });

  final String id;
  final String name;
  final int age;
  final ProfileGender gender;

  /// Whether the calculator's height field should default to centimetres.
  final bool heightUnitCm;

  /// Most recent weight entry, in kilograms, kept as the raw typed string.
  final String lastWeight;

  /// Most recent height entry, kept in the unit the person typed it in.
  final String lastHeight;

  final DateTime? updatedAt;

  UserProfile copyWith({
    String? id,
    String? name,
    int? age,
    ProfileGender? gender,
    bool? heightUnitCm,
    String? lastWeight,
    String? lastHeight,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightUnitCm: heightUnitCm ?? this.heightUnitCm,
      lastWeight: lastWeight ?? this.lastWeight,
      lastHeight: lastHeight ?? this.lastHeight,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'age': age,
        'gender': gender.storageKey,
        'heightUnitCm': heightUnitCm,
        'lastWeight': lastWeight,
        'lastHeight': lastHeight,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  static UserProfile? fromJson(Map<String, Object?> json) {
    final Object? id = json['id'];
    final Object? name = json['name'];
    final Object? age = json['age'];
    if (id is! String || id.isEmpty || name is! String || name.isEmpty || age is! int) {
      return null;
    }

    final String rawGender = json['gender'] is String ? json['gender']! as String : '';
    final ProfileGender gender = ProfileGender.values.firstWhere(
      (ProfileGender value) => value.storageKey == rawGender,
      orElse: () => ProfileGender.preferNotToSay,
    );

    final Object? updatedRaw = json['updatedAt'];
    return UserProfile(
      id: id,
      name: name,
      age: age,
      gender: gender,
      heightUnitCm: json['heightUnitCm'] is bool ? json['heightUnitCm']! as bool : true,
      lastWeight: json['lastWeight'] is String ? json['lastWeight']! as String : '',
      lastHeight: json['lastHeight'] is String ? json['lastHeight']! as String : '',
      updatedAt: updatedRaw is String ? DateTime.tryParse(updatedRaw) : null,
    );
  }
}
