import 'package:bmi/models/bmi_record.dart';
import 'package:bmi/models/user_profile.dart';
import 'package:bmi/services/storage_service.dart';
import 'package:bmi/utils/bmi_calculator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

BmiRecord _record(String id, String profileId, DateTime created, double bmi) =>
    BmiRecord(
      id: id,
      profileId: profileId,
      bmi: bmi,
      weightKg: 70,
      heightCm: 170,
      classification: classifyBmi(bmi),
      createdAt: created,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService profiles', () {
    test('starts empty', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final StorageService storage = await StorageService.getInstance();
      expect(await storage.loadProfiles(), isEmpty);
      expect(storage.loadActiveProfile(), isNull);
    });

    test('save then load returns the profile', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final StorageService storage = await StorageService.getInstance();

      const UserProfile profile = UserProfile(
        id: 'u_1',
        name: 'Ana Duarte',
        age: 28,
        gender: ProfileGender.female,
      );
      await storage.saveProfile(profile);
      await storage.setActiveProfileId('u_1');

      final List<UserProfile> loaded = await storage.loadProfiles();
      expect(loaded, hasLength(1));
      expect(loaded.single.name, 'Ana Duarte');
      expect(loaded.single.age, 28);
      expect(storage.loadActiveProfile()?.id, 'u_1');
      expect(loaded.single.updatedAt, isNotNull);
    });

    test('saving twice with the same id updates rather than duplicates', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final StorageService storage = await StorageService.getInstance();

      await storage.saveProfile(
        const UserProfile(id: 'u_1', name: 'Ana Duarte', age: 28, gender: ProfileGender.female),
      );
      await storage.saveProfile(
        const UserProfile(id: 'u_1', name: 'Ana Duarte', age: 29, gender: ProfileGender.female),
      );

      final List<UserProfile> loaded = await storage.loadProfiles();
      expect(loaded, hasLength(1));
      expect(loaded.single.age, 29);
    });

    test('two users keep separate profiles', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final StorageService storage = await StorageService.getInstance();

      await storage.saveProfile(
        const UserProfile(id: 'u_1', name: 'Ana Duarte', age: 28, gender: ProfileGender.female),
      );
      await storage.saveProfile(
        const UserProfile(id: 'u_2', name: 'Ravi Menon', age: 41, gender: ProfileGender.male),
      );

      final List<UserProfile> loaded = await storage.loadProfiles();
      expect(loaded, hasLength(2));
      expect(loaded.map((UserProfile p) => p.name), containsAll(<String>['Ana Duarte', 'Ravi Menon']));
    });
  });

  group('StorageService history', () {
    test('records are scoped to their profile', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final StorageService storage = await StorageService.getInstance();

      await storage.addRecord(_record('r_1', 'u_1', DateTime(2026, 1, 1), 22.0));
      await storage.addRecord(_record('r_2', 'u_2', DateTime(2026, 1, 2), 26.0));

      expect(await storage.loadRecords('u_1'), hasLength(1));
      expect(await storage.loadRecords('u_2'), hasLength(1));
      expect((await storage.loadRecords('u_1')).single.bmi, 22.0);
    });

    test('history is returned newest first', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final StorageService storage = await StorageService.getInstance();

      await storage.addRecord(_record('r_old', 'u_1', DateTime(2026, 1, 1), 22.0));
      await storage.addRecord(_record('r_new', 'u_1', DateTime(2026, 6, 1), 23.0));
      await storage.addRecord(_record('r_mid', 'u_1', DateTime(2026, 3, 1), 21.0));

      final List<BmiRecord> records = await storage.loadRecords('u_1');
      expect(records.map((BmiRecord r) => r.id).toList(), <String>['r_new', 'r_mid', 'r_old']);
    });

    test('history is capped at ${StorageService.historyLimit} per profile', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final StorageService storage = await StorageService.getInstance();

      for (int i = 0; i < StorageService.historyLimit + 10; i++) {
        await storage.addRecord(
          _record('r_$i', 'u_1', DateTime(2026, 1, 1).add(Duration(minutes: i)), 20 + i * 0.1),
        );
      }

      final List<BmiRecord> records = await storage.loadRecords('u_1');
      expect(records, hasLength(StorageService.historyLimit));
      // The newest record survives the trim.
      expect(records.first.id, 'r_${StorageService.historyLimit + 9}');
    });

    test('clearRecords only empties the requested profile', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final StorageService storage = await StorageService.getInstance();

      await storage.addRecord(_record('r_1', 'u_1', DateTime(2026, 1, 1), 22.0));
      await storage.addRecord(_record('r_2', 'u_2', DateTime(2026, 1, 1), 26.0));
      await storage.clearRecords('u_1');

      expect(await storage.loadRecords('u_1'), isEmpty);
      expect(await storage.loadRecords('u_2'), hasLength(1));
    });
  });
}
