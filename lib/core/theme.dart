import 'package:flutter/material.dart';

/// App palette: deep navy surfaces with an emerald accent. The hero card is
/// always navy (a signature), so it has its own colours that do not follow the
/// theme.
class Palette extends ThemeExtension<Palette> {
  final Color bg, surface, surface2, outline, text, muted, accent, mint, coral;
  final Color heroA, heroB;

  const Palette({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.outline,
    required this.text,
    required this.muted,
    required this.accent,
    required this.mint,
    required this.coral,
    required this.heroA,
    required this.heroB,
  });

  static const dark = Palette(
    bg: Color(0xFF0A1120),
    surface: Color(0xFF111B2E),
    surface2: Color(0xFF18243A),
    outline: Color(0xFF223149),
    text: Color(0xFFEAF0F8),
    muted: Color(0xFF8495B0),
    accent: Color(0xFF34D399),
    mint: Color(0xFF34D399),
    coral: Color(0xFFF87171),
    heroA: Color(0xFF16305E),
    heroB: Color(0xFF0B1833),
  );

  static const light = Palette(
    bg: Color(0xFFF3F6FB),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFEAF0F7),
    outline: Color(0xFFDCE4EF),
    text: Color(0xFF0F1B2D),
    muted: Color(0xFF5F6F86),
    accent: Color(0xFF059669),
    mint: Color(0xFF059669),
    coral: Color(0xFFDC4B4B),
    heroA: Color(0xFF173A73),
    heroB: Color(0xFF0C1F44),
  );

  /// Ink used on top of accent-filled surfaces (buttons, selected chips).
  static const onAccent = Color(0xFF032619);

  /// Lighter partner of the accent for gradients (FAB, lock badge).
  static const accentSoft = Color(0xFF6EE7B7);

  static const heroText = Color(0xFFF1F5FB);
  static const heroMuted = Color(0xFF9FB2D0);
  static const heroAccent = Color(0xFF34D399);
  static const heroMint = Color(0xFF6EE7B7);
  static const heroCoral = Color(0xFFFF9C9C);

  @override
  Palette copyWith() => this;

  @override
  Palette lerp(ThemeExtension<Palette>? other, double t) {
    if (other is! Palette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return Palette(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surface2: l(surface2, other.surface2),
      outline: l(outline, other.outline),
      text: l(text, other.text),
      muted: l(muted, other.muted),
      accent: l(accent, other.accent),
      mint: l(mint, other.mint),
      coral: l(coral, other.coral),
      heroA: l(heroA, other.heroA),
      heroB: l(heroB, other.heroB),
    );
  }
}

extension PaletteX on BuildContext {
  Palette get p => Theme.of(this).extension<Palette>()!;
  TextTheme get tt => Theme.of(this).textTheme;
}

const kTabular = [FontFeature.tabularFigures()];

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final p = dark ? Palette.dark : Palette.light;
  final scheme = ColorScheme(
    brightness: b,
    primary: p.accent,
    onPrimary: Palette.onAccent,
    secondary: p.mint,
    onSecondary: Palette.onAccent,
    error: p.coral,
    onError: Colors.white,
    surface: p.surface,
    onSurface: p.text,
    surfaceContainerHighest: p.surface2,
    onSurfaceVariant: p.muted,
    outline: p.outline,
    outlineVariant: p.outline,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: scheme,
    fontFamily: 'Vazirmatn',
    scaffoldBackgroundColor: p.bg,
  );
  final text = base.textTheme
      .apply(bodyColor: p.text, displayColor: p.text, fontFamily: 'Vazirmatn');
  return base.copyWith(
    extensions: [p],
    textTheme: text,
    splashFactory: InkSparkle.splashFactory,
    dividerColor: p.outline,
    iconTheme: IconThemeData(color: p.text),
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      foregroundColor: p.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface2,
      hintStyle: TextStyle(color: p.muted),
      labelStyle: TextStyle(color: p.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.accent, width: 1.4),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(
          fontFamily: 'Vazirmatn',
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: p.accent),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Palette.onAccent : p.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.accent : p.surface2,
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.surface2,
      contentTextStyle: TextStyle(color: p.text, fontFamily: 'Vazirmatn'),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
