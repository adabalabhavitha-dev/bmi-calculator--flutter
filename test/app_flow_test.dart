import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bmi/main.dart';
import 'package:bmi/models/bmi_record.dart';
import 'package:bmi/models/user_profile.dart';
import 'package:bmi/screens/calculator_screen.dart';
import 'package:bmi/screens/onboarding_screen.dart';
import 'package:bmi/screens/result_screen.dart';
import 'package:bmi/services/storage_service.dart';
import 'package:bmi/utils/bmi_calculator.dart';

Future<StorageService> _freshStorage() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  return StorageService.getInstance();
}

/// A profile that already has a stored height, so the calculator prefills.
Future<StorageService> _storageWithProfile({
  String id = 'u_1',
  String name = 'Ravi Menon',
  int age = 29,
  String lastWeight = '72.5',
  String lastHeight = '172',
  bool heightUnitCm = true,
}) async {
  final StorageService storage = await _freshStorage();
  await storage.saveProfile(
    UserProfile(
      id: id,
      name: name,
      age: age,
      gender: ProfileGender.male,
      heightUnitCm: heightUnitCm,
      lastWeight: lastWeight,
      lastHeight: lastHeight,
    ),
  );
  await storage.setActiveProfileId(id);
  return storage;
}

BmiRecord _record(
  String id,
  String profileId,
  DateTime created,
  double bmi,
) =>
    BmiRecord(
      id: id,
      profileId: profileId,
      bmi: bmi,
      weightKg: 72.5,
      heightCm: 172,
      classification: classifyBmi(bmi),
      createdAt: created,
    );

Future<void> _fillOnboarding(WidgetTester tester, String name) async {
  await tester.enterText(find.byType(TextFormField).at(0), name);
  await tester.enterText(find.byType(TextFormField).at(1), '34');
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('first launch', () {
    testWidgets('onboarding -> calculator -> result', (WidgetTester tester) async {
      final StorageService storage = await _freshStorage();

      await tester.pumpWidget(BMIApp(storage: storage));
      await tester.pumpAndSettle();

      // Screen 1: onboarding, not the calculator.
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(CalculatorScreen), findsNothing);
      expect(find.text('Set up your profile'), findsOneWidget);

      // Empty name shows the inline validator, not a dialog.
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a name'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);

      await _fillOnboarding(tester, 'Nadia Okoye');
      await tester.tap(find.text('Female'));
      await tester.pump();
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Screen 2, reached automatically after the profile is saved.
      expect(find.byType(CalculatorScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.textContaining('Nadia'), findsWidgets);

      // Nothing typed yet, so Calculate is disabled.
      final Finder calculate = find.widgetWithText(FilledButton, 'Calculate');
      expect(tester.widget<FilledButton>(calculate).onPressed, isNull);

      // Invalid height: inline error, no navigation, no record written.
      await tester.enterText(find.byType(TextField).at(0), '72.5');
      await tester.enterText(find.byType(TextField).at(1), '0');
      await tester.pump();
      expect(tester.widget<FilledButton>(calculate).onPressed, isNotNull);

      await tester.ensureVisible(calculate);
      await tester.tap(calculate);
      await tester.pumpAndSettle();

      expect(find.byType(ResultScreen), findsNothing);
      expect(find.text('Enter a height above 0 cm'), findsOneWidget);

      final List<UserProfile> profiles = await storage.loadProfiles();
      expect(profiles, hasLength(1));
      expect(await storage.loadRecords(profiles.single.id), isEmpty);

      // A valid height lands on screen 3.
      await tester.enterText(find.byType(TextField).at(1), '172');
      await tester.pump();
      await tester.ensureVisible(calculate);
      await tester.tap(calculate);
      await tester.pumpAndSettle();

      expect(find.byType(ResultScreen), findsOneWidget);
      expect(find.text('24.5'), findsOneWidget);
      // Chip plus the tier-bar legend.
      expect(find.text('Normal'), findsNWidgets(2));

      expect(await storage.loadRecords(profiles.single.id), hasLength(1));
    });

    testWidgets('a saved profile skips onboarding', (WidgetTester tester) async {
      final StorageService storage = await _storageWithProfile();

      await tester.pumpWidget(BMIApp(storage: storage));
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.textContaining('Ravi'), findsWidgets);
    });
  });

  group('height unit', () {
    testWidgets('switching to metres converts the entered height',
        (WidgetTester tester) async {
      final StorageService storage = await _storageWithProfile(
        lastWeight: '70',
        lastHeight: '175',
      );

      await tester.pumpWidget(BMIApp(storage: storage));
      await tester.pumpAndSettle();

      // Centimetres is the stored default.
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
        '175',
      );

      final Finder metres = find.widgetWithText(InkWell, 'm');
      await tester.ensureVisible(metres);
      await tester.tap(metres);
      await tester.pumpAndSettle();

      // 175 cm is carried over as 1.75 m, not left as 175 m.
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
        '1.75',
      );

      final Finder calculate = find.widgetWithText(FilledButton, 'Calculate');
      await tester.ensureVisible(calculate);
      await tester.tap(calculate);
      await tester.pumpAndSettle();

      expect(find.byType(ResultScreen), findsOneWidget);
      expect(find.text('22.9'), findsOneWidget);

      // The metre choice is remembered for next launch.
      final List<UserProfile> profiles = await storage.loadProfiles();
      expect(profiles.single.heightUnitCm, isFalse);
      expect(profiles.single.lastHeight, '1.75');
    });
  });

  group('history', () {
    testWidgets('the history panel lists past readings for the profile',
        (WidgetTester tester) async {
      final StorageService storage = await _storageWithProfile();
      await storage.addRecord(
        _record('r_1', 'u_1', DateTime(2026, 9, 1, 10), 24.5),
      );
      await storage.addRecord(
        _record('r_2', 'u_1', DateTime(2026, 9, 14, 8, 30), 26.1),
      );

      await tester.pumpWidget(BMIApp(storage: storage));
      await tester.pumpAndSettle();

      final Finder calculate = find.widgetWithText(FilledButton, 'Calculate');
      await tester.ensureVisible(calculate);
      await tester.tap(calculate);
      await tester.pumpAndSettle();

      expect(find.byType(ResultScreen), findsOneWidget);

      final Finder history = find.byTooltip('Past readings');
      await tester.ensureVisible(history);
      await tester.tap(history);
      await tester.pumpAndSettle();

      expect(find.text('PAST READINGS'), findsOneWidget);
      expect(find.text('26.1'), findsOneWidget);
      expect(find.text('Overweight'), findsNWidgets(2)); // legend + row
      expect(await storage.loadRecords('u_1'), hasLength(3));

      // And the panel closes again.
      await tester.tap(find.byTooltip('Past readings'));
      await tester.pumpAndSettle();
      expect(find.text('PAST READINGS'), findsNothing);
    });

    testWidgets('history is scoped to the active profile',
        (WidgetTester tester) async {
      final StorageService storage = await _storageWithProfile();
      await storage.saveProfile(
        const UserProfile(
          id: 'u_2',
          name: 'Meera Shah',
          age: 31,
          gender: ProfileGender.female,
          lastWeight: '64',
          lastHeight: '160',
        ),
      );
      await storage.addRecord(
        _record('r_2', 'u_2', DateTime(2026, 9, 2), 29.4),
      );

      await tester.pumpWidget(BMIApp(storage: storage));
      await tester.pumpAndSettle();

      final Finder calculate = find.widgetWithText(FilledButton, 'Calculate');
      await tester.ensureVisible(calculate);
      await tester.tap(calculate);
      await tester.pumpAndSettle();

      // Ravi is the active profile here, so the readout is his own 72.5 / 172.
      expect(find.text('24.5'), findsOneWidget);
      expect(find.text('29.4'), findsNothing);

      await tester.tap(find.byTooltip('Past readings'));
      await tester.pumpAndSettle();
      expect(find.text('PAST READINGS'), findsOneWidget);
      // Meera's reading stays in her own history.
      expect(find.text('29.4'), findsNothing);
      expect(await storage.loadRecords('u_1'), hasLength(1));
      expect(await storage.loadRecords('u_2'), hasLength(1));
    });
  });

  group('multiple users', () {
    testWidgets('add user opens onboarding and switches the active profile',
        (WidgetTester tester) async {
      final StorageService storage = await _storageWithProfile();

      await tester.pumpWidget(BMIApp(storage: storage));
      await tester.pumpAndSettle();

      expect(find.textContaining('Ravi'), findsWidgets);

      final Finder addUser = find.text('Add user');
      await tester.ensureVisible(addUser);
      await tester.tap(addUser);
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('Set up your profile'), findsOneWidget);

      await _fillOnboarding(tester, 'Meera Shah');
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Back on the calculator, now owned by the new profile.
      expect(find.byType(CalculatorScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.text('Enter weight and height for Meera Shah.'), findsOneWidget);

      // Both profiles are listed, each with an empty history.
      final List<UserProfile> profiles = await storage.loadProfiles();
      expect(profiles, hasLength(2));
      for (final UserProfile profile in profiles) {
        expect(await storage.loadRecords(profile.id), isEmpty);
      }
      expect(storage.activeProfileId, profiles.last.id);
    });

    testWidgets('switching profiles keeps histories separate',
        (WidgetTester tester) async {
      final StorageService storage = await _storageWithProfile();
      await storage.saveProfile(
        const UserProfile(
          id: 'u_2',
          name: 'Meera Shah',
          age: 31,
          gender: ProfileGender.female,
          lastWeight: '64',
          lastHeight: '160',
        ),
      );
      await storage.addRecord(
        _record('r_2', 'u_2', DateTime(2026, 9, 2), 29.4),
      );

      await tester.pumpWidget(BMIApp(storage: storage));
      await tester.pumpAndSettle();

      expect(find.text('Enter weight and height for Ravi Menon.'), findsOneWidget);

      final Finder meera = find.text('Meera Shah');
      await tester.ensureVisible(meera);
      await tester.tap(meera);
      await tester.pumpAndSettle();

      expect(find.text('Enter weight and height for Meera Shah.'), findsOneWidget);

      final Finder calculate = find.widgetWithText(FilledButton, 'Calculate');
      await tester.ensureVisible(calculate);
      await tester.tap(calculate);
      await tester.pumpAndSettle();

      // Meera's own reading is recorded on top of the one already there.
      expect(await storage.loadRecords('u_1'), isEmpty);
      expect(await storage.loadRecords('u_2'), hasLength(2));
    });
  });
}