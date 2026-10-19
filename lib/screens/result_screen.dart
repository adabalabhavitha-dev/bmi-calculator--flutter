import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/bmi_calculator.dart';

/// Screen 3 — the readout and the classification.
class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    this.storage,
    required this.profile,
    required this.bmi,
    required this.classification,
    required this.weightKg,
    required this.heightCm,
    required this.createdAt,
  });

  final StorageService? storage;
  final UserProfile profile;
  final double bmi;
  final BmiClassification classification;
  final double weightKg;
  final double heightCm;
  final DateTime createdAt;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _valueScale;
  late final Animation<double> _valueOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.spring,
    );
    _valueScale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _valueOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BmiClassification tier = widget.classification;
    final Color tierColor = _tierColor(tier);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 24),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Result'),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.profile.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
                  ),
                  const SizedBox(height: AppSpace.md),
                  _ReadoutCard(
                    bmi: widget.bmi,
                    classification: tier,
                    tierColor: tierColor,
                    scale: _valueScale,
                    opacity: _valueOpacity,
                    weightKg: widget.weightKg,
                    heightCm: widget.heightCm,
                    createdAt: widget.createdAt,
                  ),
                  const SizedBox(height: AppSpace.lg),
                  _TierBar(classification: tier),
                  const SizedBox(height: AppSpace.md),
                  Text(
                    classificationMessage(tier),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Color _tierColor(BmiClassification tier) {
    switch (tier) {
      case BmiClassification.underweight:
        return AppColors.tierUnderweight;
      case BmiClassification.normal:
        return AppColors.tierNormal;
      case BmiClassification.overweight:
      case BmiClassification.obesity:
        return AppColors.tierOverweight;
    }
  }
}

class _ReadoutCard extends StatelessWidget {
  const _ReadoutCard({
    required this.bmi,
    required this.classification,
    required this.tierColor,
    required this.scale,
    required this.opacity,
    required this.weightKg,
    required this.heightCm,
    required this.createdAt,
  });

  final double bmi;
  final BmiClassification classification;
  final Color tierColor;
  final Animation<double> scale;
  final Animation<double> opacity;
  final double weightKg;
  final double heightCm;
  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(AppSpace.radiusCard)),
        border: Border.all(color: AppColors.whisper.withValues(alpha: 0.5), width: 1),
        boxShadow: cardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('BODY MASS INDEX', style: text.labelLarge),
          const SizedBox(height: AppSpace.xs),
          FadeTransition(
            opacity: opacity,
            child: ScaleTransition(
              scale: scale,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    formatBmi(bmi),
                    style: const TextStyle(
                      fontFamily: AppType.numeric,
                      fontSize: AppType.displaySize,
                      height: 48 / AppType.displaySize,
                      fontWeight: FontWeight.w600,
                      fontVariations: <FontVariation>[FontVariation('wght', 600)],
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('kg/m²', style: text.bodySmall),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: tierColor.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: tierColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  classification.label,
                  style: text.titleMedium?.copyWith(
                    color: tierColor,
                    fontVariations: const <FontVariation>[FontVariation('wght', 600)],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
          const Divider(),
          const SizedBox(height: AppSpace.md),
          _MetricRow(
            label: 'Weight',
            value: '${weightKg.toStringAsFixed(1)} kg',
          ),
          const SizedBox(height: AppSpace.sm),
          _MetricRow(
            label: 'Height',
            value: '${heightCm.toStringAsFixed(0)} cm',
          ),
          const SizedBox(height: AppSpace.sm),
          _MetricRow(
            label: 'Recorded',
            value: _formatWhen(createdAt),
          ),
        ],
      ),
    );
  }

  static String _formatWhen(DateTime when) {
    const List<String> months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final String date =
        '${when.day} ${months[when.month - 1]} ${when.year}';
    final String hh = when.hour.toString().padLeft(2, '0');
    final String mm = when.minute.toString().padLeft(2, '0');
    return '$date · $hh:$mm';
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.steel)),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.ink),
        ),
      ],
    );
  }
}

/// A single continuous four-segment track. Replaces a row of equal cards.
class _TierBar extends StatefulWidget {
  const _TierBar({required this.classification});

  final BmiClassification classification;

  @override
  State<_TierBar> createState() => _TierBarState();
}

class _TierBarState extends State<_TierBar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.barFill,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const List<double> _weights = <double>[0.25, 0.30, 0.25, 0.20];
  static const List<Color> _colors = <Color>[
    AppColors.tierUnderweight,
    AppColors.tierNormal,
    AppColors.tierOverweight,
    AppColors.tierObesity,
  ];

  @override
  Widget build(BuildContext context) {
    final int active = widget.classification.index;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: List<Widget>.generate(4, (int index) {
            final bool isActive = index == active;
            return Expanded(
              flex: (_weights[index] * 100).round(),
              child: Tooltip(
                message: BmiClassification.values[index].label,
                child: Semantics(
                  label: BmiClassification.values[index].label,
                  selected: isActive,
                  child: AnimatedContainer(
                    duration: motionDuration(context, AppMotion.barFill),
                    curve: motionCurve(context, Curves.easeOutCubic),
                    height: 12,
                    margin: EdgeInsets.only(right: index == 3 ? 0 : 3),
                    decoration: BoxDecoration(
                      color: isActive ? _colors[index] : AppColors.whisper,
                      borderRadius: const BorderRadius.all(Radius.circular(6)),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpace.xs),
        Row(
          children: List<Widget>.generate(4, (int index) {
            final bool isActive = index == active;
            return Expanded(
              flex: (_weights[index] * 100).round(),
              child: Text(
                BmiClassification.values[index].label,
                key: ValueKey<String>('tier-$index'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isActive ? _colors[index] : AppColors.steel,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      fontVariations: <FontVariation>[
                        FontVariation('wght', isActive ? 600 : 400),
                      ],
                    ),
              ),
            );
          }),
        ),
        const SizedBox(height: 2),
        Text(
          widget.classification.range,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
