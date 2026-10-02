import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/user_profile.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

/// First-run profile capture and the "add user" / "edit profile" flow.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.storage,
    this.onSaved,
    this.existing,
    this.allowCancel = false,
  });

  final StorageService storage;

  /// Called with the saved profile. Also used when this screen is the root
  /// route and therefore cannot be popped.
  final ValueChanged<UserProfile>? onSaved;

  final UserProfile? existing;

  /// When true a back affordance is offered (used for edits, not first run).
  final bool allowCancel;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  ProfileGender _gender = ProfileGender.preferNotToSay;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final UserProfile? existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _ageController = TextEditingController(
      text: existing == null ? '' : existing.age.toString(),
    );
    _gender = existing?.gender ?? ProfileGender.preferNotToSay;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) {
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _saving = true);

    final UserProfile profile = UserProfile(
      id: widget.existing?.id ?? _newId(),
      name: _nameController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      gender: _gender,
      heightUnitCm: widget.existing?.heightUnitCm ?? true,
      lastWeight: widget.existing?.lastWeight ?? '',
      lastHeight: widget.existing?.lastHeight ?? '',
    );

    await widget.storage.saveProfile(profile);
    await widget.storage.setActiveProfileId(profile.id);

    if (!mounted) {
      return;
    }
    widget.onSaved?.call(profile);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  String _newId() {
    final String stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return 'u_$stamp';
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.existing != null;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: widget.allowCancel
            ? IconButton(
                icon: const Icon(Icons.close, size: 24),
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: Text(isEdit ? 'Edit profile' : 'Your profile'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.gutter,
                AppSpace.md,
                AppSpace.gutter,
                AppSpace.xl,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      isEdit ? 'Update your details' : 'Set up your profile',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      'Used to label your measurements and keep your history separate.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    _FieldLabel(text: 'Name'),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.name],
                      decoration: const InputDecoration(hintText: 'e.g. Priya Raman'),
                      validator: (String? value) {
                        final String trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty) {
                          return 'Enter a name';
                        }
                        if (trimmed.length > 40) {
                          return 'Keep it under 40 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpace.fieldGap),
                    _FieldLabel(text: 'Age'),
                    TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(
                        fontFamily: AppType.numeric,
                        fontVariations: <FontVariation>[FontVariation('wght', 500)],
                      ),
                      decoration: const InputDecoration(hintText: 'e.g. 34'),
                      validator: (String? value) {
                        final String trimmed = value?.trim() ?? '';
                        final int? age = int.tryParse(trimmed);
                        if (age == null || age < 1 || age > 120) {
                          return 'Enter an age between 1 and 120';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpace.fieldGap),
                    _FieldLabel(text: 'Gender'),
                    const SizedBox(height: AppSpace.xs),
                    _GenderSelector(
                      selected: _gender,
                      onChanged: (ProfileGender value) => setState(() => _gender = value),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      'Recorded for your profile only. It does not change your BMI.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpace.xl),
                    FilledButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isEdit ? 'Save profile' : 'Continue'),
                    ),
                  ],
                ),
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

/// Four gender options as a wrapping row of pills — not a grid of equal cards.
class _GenderSelector extends StatelessWidget {
  const _GenderSelector({required this.selected, required this.onChanged});

  final ProfileGender selected;
  final ValueChanged<ProfileGender> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpace.xs,
      runSpacing: AppSpace.xs,
      children: ProfileGender.values.map((ProfileGender value) {
        final bool isSelected = value == selected;
        return Semantics(
          button: true,
          selected: isSelected,
          label: value.label,
          child: InkWell(
            onTap: () => onChanged(value),
            borderRadius: const BorderRadius.all(Radius.circular(AppSpace.touchTarget)),
            child: AnimatedContainer(
              duration: motionDuration(context, AppMotion.quick),
              curve: motionCurve(context, Curves.easeOut),
              constraints: const BoxConstraints(minHeight: AppSpace.touchTarget),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentTint : AppColors.surface,
                borderRadius: const BorderRadius.all(Radius.circular(AppSpace.touchTarget)),
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.whisper,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Text(
                value.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected ? AppColors.accent : AppColors.ink,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      fontVariations: <FontVariation>[
                        FontVariation('wght', isSelected ? 600 : 400),
                      ],
                    ),
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}
