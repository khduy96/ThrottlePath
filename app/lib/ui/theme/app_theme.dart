import 'package:flutter/material.dart';

import '../../domain/plans.dart';
import '../../recorder/protocol.dart';

/// Brand accent: a warm "throttle" orange.
const _seed = Color(0xFFF26B1D);

/// Spacing scale and radii shared by every screen.
abstract final class Gap {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class Radii {
  static const sm = 12.0;
  static const md = 20.0;
  static const lg = 28.0;
}

/// Digits that do not jump around while a timer ticks.
const tabular = [FontFeature.tabularFigures()];

/// Colours for recorder phases and plans, light and dark aware.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.idle,
    required this.waiting,
    required this.recording,
    required this.success,
    required this.warning,
    required this.morning,
    required this.evening1,
    required this.evening2,
    required this.unknownPlan,
  });

  final Color idle;
  final Color waiting;
  final Color recording;
  final Color success;
  final Color warning;
  final Color morning;
  final Color evening1;
  final Color evening2;
  final Color unknownPlan;

  static const light = AppColors(
    idle: Color(0xFF475569),
    waiting: Color(0xFFD97706),
    recording: Color(0xFFDC2626),
    success: Color(0xFF059669),
    warning: Color(0xFFD97706),
    morning: Color(0xFFEA580C),
    evening1: Color(0xFF2563EB),
    evening2: Color(0xFF7C3AED),
    unknownPlan: Color(0xFF64748B),
  );

  static const dark = AppColors(
    idle: Color(0xFF94A3B8),
    waiting: Color(0xFFFBBF24),
    recording: Color(0xFFF87171),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    morning: Color(0xFFFB923C),
    evening1: Color(0xFF60A5FA),
    evening2: Color(0xFFA78BFA),
    unknownPlan: Color(0xFF94A3B8),
  );

  Color phase(RecorderPhase p) => switch (p) {
        RecorderPhase.off => idle,
        RecorderPhase.waiting => waiting,
        RecorderPhase.recording => recording,
      };

  Color plan(PlanId? p) => switch (p) {
        PlanId.morning => morning,
        PlanId.evening1 => evening1,
        PlanId.evening2 => evening2,
        null => unknownPlan,
      };

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      idle: l(idle, other.idle),
      waiting: l(waiting, other.waiting),
      recording: l(recording, other.recording),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      morning: l(morning, other.morning),
      evening1: l(evening1, other.evening1),
      evening2: l(evening2, other.evening2),
      unknownPlan: l(unknownPlan, other.unknownPlan),
    );
  }
}

extension AppThemeX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  ColorScheme get cs => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  var cs = ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
  );
  // Neutral, slightly cool surfaces so the orange accent stands out.
  // Keep the accent a saturated orange in both modes (the tonal palette
  // turns it pastel in dark mode, which looks washed out on the big button).
  cs = dark
      ? cs.copyWith(
          primary: const Color(0xFFFF7A2E),
          onPrimary: const Color(0xFF1F0A00),
          surface: const Color(0xFF0F1216),
          surfaceContainerLowest: const Color(0xFF0A0C0F),
          surfaceContainerLow: const Color(0xFF151920),
          surfaceContainer: const Color(0xFF1A1F27),
          surfaceContainerHigh: const Color(0xFF222832),
          surfaceContainerHighest: const Color(0xFF2B323D),
          onSurface: const Color(0xFFE8ECF1),
          onSurfaceVariant: const Color(0xFFA3ADBB),
          outlineVariant: const Color(0xFF2E3541),
        )
      : cs.copyWith(
          primary: const Color(0xFFEA5A0C),
          onPrimary: Colors.white,
          surface: const Color(0xFFF6F7F9),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: Colors.white,
          surfaceContainer: const Color(0xFFF0F2F5),
          surfaceContainerHigh: const Color(0xFFE9ECF0),
          surfaceContainerHighest: const Color(0xFFE2E6EB),
          onSurface: const Color(0xFF111827),
          onSurfaceVariant: const Color(0xFF5B6472),
          outlineVariant: const Color(0xFFE1E5EA),
        );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    fontFamily: 'BeVietnamPro',
    scaffoldBackgroundColor: cs.surface,
    extensions: [dark ? AppColors.dark : AppColors.light],
  );
  final t = base.textTheme;
  final text = t.copyWith(
    displayLarge: t.displayLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1.5),
    displayMedium: t.displayMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1),
    displaySmall: t.displaySmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
    headlineLarge: t.headlineLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
    headlineMedium: t.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
    headlineSmall: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
    titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    titleSmall: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.2),
    bodyMedium: t.bodyMedium?.copyWith(height: 1.45),
    bodyLarge: t.bodyLarge?.copyWith(height: 1.45),
  );

  const big = Size.fromHeight(56);
  final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md));
  return base.copyWith(
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge?.copyWith(color: cs.onSurface),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: big, shape: buttonShape, textStyle: text.labelLarge?.copyWith(fontSize: 16)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: big,
        shape: buttonShape,
        side: BorderSide(color: cs.outlineVariant, width: 1.5),
        textStyle: text.labelLarge?.copyWith(fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(minimumSize: const Size(56, 48))),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cs.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.lg),
    ),
    listTileTheme: const ListTileThemeData(minVerticalPadding: 12),
    dividerTheme: DividerThemeData(color: cs.outlineVariant, space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.sm)),
    ),
    dialogTheme: DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg))),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
    ),
  );
}
