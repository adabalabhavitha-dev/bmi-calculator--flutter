import 'package:flutter/material.dart';

import 'models/user_profile.dart';
import 'screens/calculator_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final StorageService storage = await StorageService.getInstance();
  runApp(BMIApp(storage: storage));
}

/// Application root: theme, loading gate, and the first-run decision.
class BMIApp extends StatelessWidget {
  const BMIApp({super.key, required this.storage});

  final StorageService storage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BMI',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: RootNav(storage: storage),
    );
  }
}

/// Decides between first-run onboarding and the calculator, then hosts the
/// active profile.
class RootNav extends StatefulWidget {
  const RootNav({super.key, required this.storage});

  final StorageService storage;

  @override
  State<RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<RootNav> {
  bool _ready = false;
  UserProfile? _active;
  List<UserProfile> _profiles = const <UserProfile>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<UserProfile> profiles = await widget.storage.loadProfiles();
    final UserProfile? active = widget.storage.loadActiveProfile();
    if (!mounted) {
      return;
    }
    setState(() {
      _profiles = profiles;
      _active = active;
      _ready = true;
    });
  }

  Future<void> _openOnboarding({UserProfile? existing}) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => OnboardingScreen(
          storage: widget.storage,
          existing: existing,
          allowCancel: true,
          onSaved: _handleSaved,
        ),
      ),
    );
  }

  void _handleSaved(UserProfile profile) {
    widget.storage.loadProfiles().then((List<UserProfile> profiles) {
      if (!mounted) {
        return;
      }
      setState(() {
        _profiles = profiles;
        _active = profile;
      });
    });
  }

  void _onProfilesChanged(UserProfile profile) {
    final int index = _profiles.indexWhere((UserProfile p) => p.id == profile.id);
    final List<UserProfile> next = _profiles.toList(growable: true);
    if (index == -1) {
      next.add(profile);
    } else {
      next[index] = profile;
    }
    widget.storage.setActiveProfileId(profile.id);
    setState(() {
      _profiles = next;
      _active = profile;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final UserProfile? active = _active;
    if (active == null) {
      return OnboardingScreen(storage: widget.storage, onSaved: _handleSaved);
    }

    return CalculatorScreen(
      key: ValueKey<String>(active.id),
      storage: widget.storage,
      profiles: _profiles,
      activeProfile: active,
      onProfilesChanged: _onProfilesChanged,
      onAddUser: () => _openOnboarding(),
      onEditProfile: () => _openOnboarding(existing: active),
    );
  }
}
