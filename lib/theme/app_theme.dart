import 'package:flutter/material.dart';

/// Design tokens and the app-wide [ThemeData].
///
/// See `DESIGN.md` for the rationale behind every value here.
abstract final class AppColors {
  static const Color canvas = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF18181B);
  static const Color steel = Color(0xFF71717A);
  static const Color whisper = Color(0xFFE2E8F0);

  /// Single interaction accent. Saturation stays below 80%.
  static const Color accent = Color(0xFF3D5A3D);
  static const Color accentTint = Color(0x143D5A3D);
  static const Color accentPressed = Color(0xFF324B32);

  /// Semantic BMI tier signals — never used on interactive controls.
  static const Color tierUnderweight = Color(0xFFA1A1AA);
  static const Color tierNormal = Color(0xFF2F6F4E);
  static const Color tierOverweight = Color(0xFFB45309);
  static const Color tierObesity = Color(0xFFB45309);
}

abstract final class AppType {
  static const String display = 'Outfit';
  static const String body = 'Outfit';
  static const String numeric = 'JetBrainsMono';

  static const double displaySize = 44;
  static const double titleSize = 28;
  static const double headingSize = 20;
  static const double bodySize = 16;
  static const double labelSize = 13;
  static const double captionSize = 12;
  static const double numericInputSize = 32;
  static const double numericDataSize = 15;
}

abstract final class AppSpace {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double gutter = 24;
  static const double fieldGap = 20;
  static const double radiusCard = 20;
  static const double radiusField = 14;

  /// Minimum hit area for anything tappable.
  static const double touchTarget = 44;

  static const double inputHeight = 56;
  static const double buttonHeight = 56;
}

abstract final class AppMotion {
  static const Duration spring = Duration(milliseconds: 420);
  static const Duration transition = Duration(milliseconds: 300);
  static const Duration quick = Duration(milliseconds: 180);
  static const Duration barFill = Duration(milliseconds: 500);
  static const Duration stagger = Duration(milliseconds: 40);

  /// Spring used for presses and value entrances.
  static const Curve springCurve = Curves.easeOutBack;

  /// Applied when the platform reports reduced motion.
  static const Duration reduced = Duration(milliseconds: 1);
}

/// Springs and durations that collapse to a near-instant step under reduced motion.
Duration motionDuration(BuildContext context, Duration normal) =>
    MediaQuery.disableAnimationsOf(context) ? AppMotion.reduced : normal;

Curve motionCurve(BuildContext context, Curve normal) =>
    MediaQuery.disableAnimationsOf(context) ? Curves.linear : normal;

/// A variable-font text style. Both `fontWeight` and `fontVariations` are set
/// because Flutter honours one or the other depending on the platform.
TextStyle vf(
  String family, {
  required double size,
  required double lineHeight,
  required FontWeight weight,
}) {
  return TextStyle(
    fontFamily: family,
    fontSize: size,
    height: lineHeight / size,
    fontWeight: weight,
    fontVariations: <FontVariation>[FontVariation('wght', weight.value.toDouble())],
    leadingDistribution: TextLeadingDistribution.even,
  );
}

ThemeData buildAppTheme() {
  const OutlineInputBorder enabledBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppSpace.radiusField)),
    borderSide: BorderSide(color: AppColors.whisper, width: 1),
  );

  const OutlineInputBorder focusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppSpace.radiusField)),
    borderSide: BorderSide(color: AppColors.accent, width: 1.5),
  );

  final ThemeData base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.canvas,
    colorScheme: const ColorScheme.light(
      primary: AppColors.accent,
      onPrimary: AppColors.surface,
      secondary: AppColors.accent,
      onSecondary: AppColors.surface,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      error: AppColors.tierOverweight,
      onError: AppColors.surface,
      outline: AppColors.whisper,
      outlineVariant: AppColors.whisper,
    ),
  );

  return base.copyWith(
    splashFactory: InkSparkle.splashFactory,
    textTheme: base.textTheme.copyWith(
      displayLarge: vf(AppType.display, size: AppType.displaySize, lineHeight: 48, weight: FontWeight.w600)
          .copyWith(color: AppColors.ink),
      headlineMedium: vf(AppType.display, size: AppType.titleSize, lineHeight: 34, weight: FontWeight.w600)
          .copyWith(color: AppColors.ink),
      titleLarge: vf(AppType.display, size: AppType.headingSize, lineHeight: 26, weight: FontWeight.w600)
          .copyWith(color: AppColors.ink),
      titleMedium: vf(AppType.body, size: AppType.bodySize, lineHeight: 24, weight: FontWeight.w600)
          .copyWith(color: AppColors.ink),
      bodyLarge: vf(AppType.body, size: AppType.bodySize, lineHeight: 24, weight: FontWeight.w400)
          .copyWith(color: AppColors.ink),
      bodyMedium: vf(AppType.body, size: AppType.bodySize, lineHeight: 24, weight: FontWeight.w400)
          .copyWith(color: AppColors.ink),
      labelLarge: vf(AppType.body, size: AppType.labelSize, lineHeight: 18, weight: FontWeight.w600)
          .copyWith(color: AppColors.steel, letterSpacing: 0.78),
      bodySmall: vf(AppType.body, size: AppType.captionSize, lineHeight: 16, weight: FontWeight.w400)
          .copyWith(color: AppColors.steel),
      labelSmall: vf(AppType.numeric, size: AppType.numericDataSize, lineHeight: 20, weight: FontWeight.w500)
          .copyWith(color: AppColors.ink),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.canvas,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: AppType.display,
        fontSize: AppType.headingSize,
        height: 26 / AppType.headingSize,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        fontVariations: <FontVariation>[FontVariation('wght', 600)],
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: enabledBorder,
      focusedBorder: focusedBorder,
      errorBorder: enabledBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.tierOverweight, width: 1),
      ),
      focusedErrorBorder: focusedBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.tierOverweight, width: 1.5),
      ),
      hintStyle: vf(AppType.body, size: AppType.bodySize, lineHeight: 24, weight: FontWeight.w400)
          .copyWith(color: AppColors.steel),
      errorStyle: vf(AppType.body, size: AppType.captionSize, lineHeight: 16, weight: FontWeight.w400)
          .copyWith(color: AppColors.tierOverweight),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.surface,
        disabledBackgroundColor: AppColors.whisper,
        disabledForegroundColor: AppColors.steel,
        minimumSize: const Size.fromHeight(AppSpace.buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpace.radiusField)),
        ),
        textStyle: vf(AppType.body, size: AppType.bodySize, lineHeight: 24, weight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accent,
        minimumSize: const Size(AppSpace.touchTarget, AppSpace.touchTarget),
        side: const BorderSide(color: AppColors.accent, width: 1),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpace.radiusField)),
        ),
        textStyle: vf(AppType.body, size: AppType.bodySize, lineHeight: 24, weight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        minimumSize: const Size(AppSpace.touchTarget, AppSpace.touchTarget),
        textStyle: vf(AppType.body, size: AppType.bodySize, lineHeight: 24, weight: FontWeight.w600),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.whisper,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.ink,
      contentTextStyle: vf(AppType.body, size: AppType.bodySize, lineHeight: 24, weight: FontWeight.w400)
          .copyWith(color: AppColors.surface),
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSpace.radiusField)),
      ),
    ),
  );
}

/// The diffused card shadow specified in `DESIGN.md`.
List<BoxShadow> cardShadow() => const <BoxShadow>[
      BoxShadow(
        color: Color(0x0A18181B),
        blurRadius: 24,
        offset: Offset(0, 4),
      ),
    ];
