import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/bmi_record.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/bmi_calculator.dart';
import 'result_screen.dart';

/// Screen 2 — weight and height entry for the active profile.
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({
    super.key,
    required this.storage,
    required this.profiles,
    required this.activeProfile,
    required this.onProfilesChanged,
    required this.onAddUser,
    required this.onEditProfile,
  });

  final StorageService storage;
  final List<UserProfile> profiles;
  final UserProfile activeProfile;
  final ValueChanged<UserProfile> onProfilesChanged;
  final VoidCallback onAddUser;
  final VoidCallback onEditProfile;

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late bool _useMeters;
  String? _weightError;
  String? _heightError;
  bool _calculating = false;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController();
    _heightController = TextEditingController();
    _weightController.addListener(_onChanged);
    _heightController.addListener(_onChanged);
    _hydrate();
  }

  @override
  void didUpdateWidget(CalculatorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeProfile.id != widget.activeProfile.id) {
      _hydrate();
    }
  }

  void _hydrate() {
    final UserProfile profile = widget.activeProfile;
    _weightError = null;
    _heightError = null;
    _useMeters = !profile.heightUnitCm;
    _weightController.text = profile.lastWeight;
    _heightController.text = profile.lastHeight;
  }

  @override
  void dispose() {
    _weightController.removeListener(_onChanged);
    _heightController.removeListener(_onChanged);
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  bool get _canCalculate =>
      _weightController.text.trim().isNotEmpty && _heightController.text.trim().isNotEmpty;

  /// Switches the height unit, converting whatever is already typed so the
  /// value stays meaningful instead of silently becoming 175 m.
  void _setUnit(bool useMeters) {
    if (useMeters == _useMeters) {
      return;
    }
    setState(() {
      final double? cm = heightToCm(_heightController.text, isMeters: _useMeters);
      _useMeters = useMeters;
      if (cm != null) {
        _heightController.text = useMeters
            ? (cm / 100).toStringAsFixed(2)
            : cm.toStringAsFixed(0);
      }
    });
  }

  /// Clears the field errors and rebuilds so `_canCalculate` tracks the text.
  void _onChanged() {
    _weightError = null;
    _heightError = null;
    setState(() {});
  }

  Future<void> _calculate() async {
    if (_calculating) {
      return;
    }

    final double? weightKg = weightToKg(_weightController.text);
    final double? heightCm = heightToCm(_heightController.text, isMeters: _useMeters);

    String? weightError;
    String? heightError;
    if (weightKg == null) {
      weightError = 'Enter a weight above 0 kg';
    } else if (weightKg > 500) {
      weightError = 'Enter a weight under 500 kg';
    }
    if (heightCm == null) {
      heightError = _useMeters ? 'Enter a height above 0 m' : 'Enter a height above 0 cm';
    } else if (heightCm < 50 || heightCm > 260) {
      heightError = _useMeters ? 'Enter a height between 0.5 m and 2.6 m' : 'Enter a height between 50 cm and 260 cm';
    }

    if (weightError != null || heightError != null) {
      setState(() {
        _weightError = weightError;
        _heightError = heightError;
      });
      return;
    }

    setState(() {
      _calculating = true;
      _pressed = true;
    });

    final double bmi = calculateBmi(weightKg: weightKg!, heightCm: heightCm!);
    final BmiClassification classification = classifyBmi(bmi);

    final UserProfile saved = await widget.storage.saveProfile(
      widget.activeProfile.copyWith(
        lastWeight: _weightController.text.trim(),
        lastHeight: _heightController.text.trim(),
        heightUnitCm: !_useMeters,
      ),
    );

    final String recordId =
        'r_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
    await widget.storage.addRecord(
      BmiRecord(
        id: recordId,
        profileId: saved.id,
        bmi: bmi,
        weightKg: weightKg,
        heightCm: heightCm,
        classification: classification,
        createdAt: DateTime.now(),
      ),
    );

    widget.onProfilesChanged(saved);

    if (!mounted) {
      return;
    }

    // Let the press state read before the route change.
    await Future<void>.delayed(motionDuration(context, AppMotion.quick));
    if (!mounted) {
      return;
    }

    setState(() {
      _calculating = false;
      _pressed = false;
    });

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ResultScreen(
          storage: widget.storage,
          profile: saved,
          bmi: bmi,
          classification: classification,
          weightKg: weightKg,
          heightCm: heightCm,
          createdAt: DateTime.now(),
        ),
      ),
    );

    if (!mounted) {
      return;
    }
    // Pull the saved weight/height strings back in case anything changed upstream.
    setState(_hydrate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.gutter,
                AppSpace.md,
                AppSpace.gutter,
                AppSpace.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _Header(
                    profile: widget.activeProfile,
                    profiles: widget.profiles,
                    onSwitch: widget.onProfilesChanged,
                    onAddUser: widget.onAddUser,
                    onEditProfile: widget.onEditProfile,
                  ),
                  const SizedBox(height: AppSpace.lg),
                  _FieldLabel(text: 'Weight'),
                  const SizedBox(height: AppSpace.xs),
                  TextField(
                    controller: _weightController,
                    onChanged: (_) => _onChanged(),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      LengthLimitingTextInputFormatter(6),
                    ],
                    onSubmitted: (_) => _calculate(),
                    style: const TextStyle(
                      fontFamily: AppType.numeric,
                      fontSize: AppType.numericInputSize,
                      height: 40 / AppType.numericInputSize,
                      fontWeight: FontWeight.w500,
                      fontVariations: <FontVariation>[FontVariation('wght', 500)],
                      color: AppColors.ink,
                    ),
                    decoration: InputDecoration(
                      hintText: '72.5',
                      suffixText: 'kg',
                      suffixStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
                      errorText: _weightError,
                      errorMaxLines: 2,
                    ),
                  ),
                  const SizedBox(height: AppSpace.fieldGap),
                  _FieldLabel(text: 'Height'),
                  const SizedBox(height: AppSpace.xs),
                  TextField(
                    controller: _heightController,
                    onChanged: (_) => _onChanged(),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      LengthLimitingTextInputFormatter(6),
                    ],
                    onSubmitted: (_) => _calculate(),
                    style: const TextStyle(
                      fontFamily: AppType.numeric,
                      fontSize: AppType.numericInputSize,
                      height: 40 / AppType.numericInputSize,
                      fontWeight: FontWeight.w500,
                      fontVariations: <FontVariation>[FontVariation('wght', 500)],
                      color: AppColors.ink,
                    ),
                    decoration: InputDecoration(
                      hintText: _useMeters ? '1.72' : '172',
                      suffixText: _useMeters ? 'm' : 'cm',
                      suffixStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
                      errorText: _heightError,
                      errorMaxLines: 2,
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _UnitSegmented(
                      useMeters: _useMeters,
                      onChanged: _setUnit,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),
                  AnimatedScale(
                    scale: _pressed ? 0.985 : 1,
                    duration: motionDuration(context, AppMotion.quick),
                    curve: motionCurve(context, Curves.easeOut),
                    child: FilledButton(
                      onPressed: _canCalculate && !_calculating ? _calculate : null,
                      child: _calculating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Calculate'),
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Center(
                    child: Text(
                      'BMI is a screening measure, not a diagnosis.',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: Theme.of(context).textTheme.labelLarge);
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.profile,
    required this.profiles,
    required this.onSwitch,
    required this.onAddUser,
    required this.onEditProfile,
  });

  final UserProfile profile;
  final List<UserProfile> profiles;
  final ValueChanged<UserProfile> onSwitch;
  final VoidCallback onAddUser;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Measure', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 2),
                  Text(
                    'Enter weight and height for ${profile.name}.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
                  ),
                ],
              ),
            ),
            Semantics(
              button: true,
              label: 'Edit profile for ${profile.name}',
              child: Ink(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: onEditProfile,
                  icon: const Icon(Icons.person_outline, size: 24),
                  color: AppColors.ink,
                  tooltip: 'Edit profile',
                  constraints: const BoxConstraints(
                    minWidth: AppSpace.touchTarget,
                    minHeight: AppSpace.touchTarget,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        // Wraps rather than scrolls sideways: adding a user never needs a
        // horizontal gesture.
        Wrap(
          spacing: AppSpace.xs,
          runSpacing: AppSpace.xs,
          children: <Widget>[
            for (final UserProfile candidate in profiles)
              _UserChip(
                label: candidate.name,
                icon: null,
                selected: candidate.id == profile.id,
                onTap: () => onSwitch(candidate),
              ),
            _UserChip(
              label: 'Add user',
              icon: Icons.add,
              selected: false,
              onTap: onAddUser,
            ),
          ],
        ),
      ],
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: icon == null ? 'Switch to $label' : label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.all(Radius.circular(AppSpace.touchTarget)),
          child: AnimatedContainer(
            duration: motionDuration(context, AppMotion.quick),
            curve: motionCurve(context, Curves.easeOut),
            constraints: const BoxConstraints(minHeight: AppSpace.touchTarget),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: selected ? AppColors.accentTint : AppColors.surface,
              borderRadius: const BorderRadius.all(Radius.circular(AppSpace.touchTarget)),
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.whisper,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: 18, color: selected ? AppColors.accent : AppColors.ink),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: selected ? AppColors.accent : AppColors.ink,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        fontVariations: <FontVariation>[
                          FontVariation('wght', selected ? 600 : 400),
                        ],
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Two-segment control switching the height field between centimetres and metres.
class _UnitSegmented extends StatelessWidget {
  const _UnitSegmented({required this.useMeters, required this.onChanged});

  final bool useMeters;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Height unit',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.all(Radius.circular(AppSpace.touchTarget)),
          border: Border.all(color: AppColors.whisper, width: 1),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _Segment(
              label: 'cm',
              selected: !useMeters,
              onTap: () => onChanged(false),
            ),
            const SizedBox(width: 4),
            _Segment(label: 'm', selected: useMeters, onTap: () => onChanged(true)),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label == 'cm' ? 'Centimetres' : 'Metres',
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        child: AnimatedContainer(
          duration: motionDuration(context, AppMotion.quick),
          curve: motionCurve(context, Curves.easeOut),
          constraints: const BoxConstraints(minHeight: 36, minWidth: 56),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentTint : Colors.transparent,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: selected ? AppColors.accent : AppColors.steel,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  fontVariations: <FontVariation>[
                    FontVariation('wght', selected ? 600 : 400),
                  ],
                ),
          ),
        ),
      ),
    );
  }
}
