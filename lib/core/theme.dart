import 'package:flutter/material.dart';

/// App palette. The hero card is always dark (a signature), so it has its own
/// colours that do not follow the theme.
class Palette extends ThemeExtension<Palette> {
  final Color bg, surface, surface2, outline, text, muted, gold, mint, coral;
  final Color heroA, heroB;

  const Palette({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.outline,
    required this.text,
    required this.muted,
    required this.gold,
    required this.mint,
    required this.coral,
    required this.heroA,
    required this.heroB,
  });

  static const dark = Palette(
    bg: Color(0xFF0D1016),
    surface: Color(0xFF151A22),
    surface2: Color(0xFF1D232D),
    outline: Color(0xFF262D38),
    text: Color(0xFFF2EFE6),
    muted: Color(0xFF8A93A3),
    gold: Color(0xFFE8B54D),
    mint: Color(0xFF5FD3A3),
    coral: Color(0xFFF17B73),
    heroA: Color(0xFF1C2333),
    heroB: Color(0xFF10141C),
  );

  static const light = Palette(
    bg: Color(0xFFF5F2EA),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF0ECE2),
    outline: Color(0xFFE6E1D5),
    text: Color(0xFF151920),
    muted: Color(0xFF6E7684),
    gold: Color(0xFFB9821F),
    mint: Color(0xFF1F9D6B),
    coral: Color(0xFFD9534B),
    heroA: Color(0xFF1C2333),
    heroB: Color(0xFF0F131A),
  );

  static const heroText = Color(0xFFF4F1E8);
  static const heroMuted = Color(0xFF9AA3B2);
  static const heroGold = Color(0xFFE8B54D);
  static const heroMint = Color(0xFF6FE0B1);
  static const heroCoral = Color(0xFFFF8D85);

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
      gold: l(gold, other.gold),
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
    primary: p.gold,
    onPrimary: const Color(0xFF1A1300),
    secondary: p.mint,
    onSecondary: const Color(0xFF062A1C),
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
        borderSide: BorderSide(color: p.gold, width: 1.4),
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
      style: TextButton.styleFrom(foregroundColor: p.gold),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? const Color(0xFF1A1300) : p.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.gold : p.surface2,
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
