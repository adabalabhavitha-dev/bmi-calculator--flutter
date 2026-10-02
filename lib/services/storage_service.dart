import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/bmi_record.dart';
import '../models/user_profile.dart';

/// Local persistence for profiles and BMI history.
///
/// Everything lives in [SharedPreferences] so the app works across android,
/// ios, linux, macos and web without a native database plugin.
class StorageService {
  StorageService(this._prefs);

  static const String _profilesKey = 'bmi.profiles';
  static const String _recordsKey = 'bmi.records';
  static const String _activeIdKey = 'bmi.activeProfileId';

  /// Most recent records retained per profile.
  static const int historyLimit = 50;

  final SharedPreferences _prefs;

  static Future<StorageService> getInstance() async =>
      StorageService(await SharedPreferences.getInstance());

  List<UserProfile> _readProfiles() {
    final String? raw = _prefs.getString(_profilesKey);
    if (raw == null || raw.isEmpty) {
      return const <UserProfile>[];
    }
    final Object? decoded = _tryDecode(raw);
    if (decoded is! List) {
      return const <UserProfile>[];
    }
    return decoded
        .whereType<Map<Object?, Object?>>()
        .map((Map<Object?, Object?> row) => UserProfile.fromJson(_asStringMap(row)))
        .whereType<UserProfile>()
        .toList(growable: false);
  }

  List<BmiRecord> _readRecords() {
    final String? raw = _prefs.getString(_recordsKey);
    if (raw == null || raw.isEmpty) {
      return const <BmiRecord>[];
    }
    final Object? decoded = _tryDecode(raw);
    if (decoded is! List) {
      return const <BmiRecord>[];
    }
    return decoded
        .whereType<Map<Object?, Object?>>()
        .map((Map<Object?, Object?> row) => BmiRecord.fromJson(_asStringMap(row)))
        .whereType<BmiRecord>()
        .toList(growable: false);
  }

  Object? _tryDecode(String raw) {
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  /// Narrows a decoded JSON object to the string-keyed map the models expect.
  static Map<String, Object?> _asStringMap(Map<Object?, Object?> row) => <String, Object?>{
        for (final MapEntry<Object?, Object?> entry in row.entries)
          if (entry.key is String) entry.key! as String: entry.value,
      };

  Future<void> _writeProfiles(List<UserProfile> profiles) => _prefs.setString(
        _profilesKey,
        jsonEncode(profiles.map((UserProfile p) => p.toJson()).toList(growable: false)),
      );

  Future<void> _writeRecords(List<BmiRecord> records) => _prefs.setString(
        _recordsKey,
        jsonEncode(records.map((BmiRecord r) => r.toJson()).toList(growable: false)),
      );

  // ---------------------------------------------------------------- profiles

  Future<List<UserProfile>> loadProfiles() async => _readProfiles();

  String? get activeProfileId => _prefs.getString(_activeIdKey);

  Future<void> setActiveProfileId(String id) => _prefs.setString(_activeIdKey, id);

  /// Returns the persisted active profile, or falls back to the first one.
  UserProfile? loadActiveProfile() {
    final List<UserProfile> profiles = _readProfiles();
    if (profiles.isEmpty) {
      return null;
    }
    final String? id = activeProfileId;
    return profiles.firstWhere(
      (UserProfile p) => p.id == id,
      orElse: () => profiles.first,
    );
  }

  /// Creates a profile, or updates the one with the same [UserProfile.id].
  Future<UserProfile> saveProfile(UserProfile profile) async {
    final List<UserProfile> profiles = _readProfiles().toList(growable: true);
    final int index = profiles.indexWhere((UserProfile p) => p.id == profile.id);
    final UserProfile saved = profile.copyWith(updatedAt: DateTime.now());
    if (index == -1) {
      profiles.add(saved);
    } else {
      profiles[index] = saved;
    }
    await _writeProfiles(profiles);
    return saved;
  }

  // ----------------------------------------------------------------- records

  Future<List<BmiRecord>> loadRecords(String profileId) async {
    final List<BmiRecord> records = _readRecords()
        .where((BmiRecord r) => r.profileId == profileId)
        .toList(growable: false)
      ..sort((BmiRecord a, BmiRecord b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }

  /// Appends a record and trims the profile's history to [historyLimit].
  Future<void> addRecord(BmiRecord record) async {
    final List<BmiRecord> records = _readRecords().toList(growable: true);
    records.add(record);

    final List<BmiRecord> forProfile = records
        .where((BmiRecord r) => r.profileId == record.profileId)
        .toList(growable: false)
      ..sort((BmiRecord a, BmiRecord b) => b.createdAt.compareTo(a.createdAt));

    if (forProfile.length > historyLimit) {
      final Set<String> trimmed =
          forProfile.skip(historyLimit).map((BmiRecord r) => r.id).toSet();
      records.removeWhere((BmiRecord r) => trimmed.contains(r.id));
    }

    await _writeRecords(records);
  }

  Future<void> clearRecords(String profileId) async {
    final List<BmiRecord> records =
        _readRecords().where((BmiRecord r) => r.profileId != profileId).toList(growable: false);
    await _writeRecords(records);
  }
}
