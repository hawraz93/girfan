// Renders the launcher icon to assets/icon/icon.png (1024x1024) and the
// adaptive foreground. Run: flutter test test/icon_test.dart --update-goldens
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _loadFont() async {
  final l = FontLoader('Vazirmatn');
  l.addFont(rootBundle.load('assets/fonts/Vazirmatn-Bold.ttf'));
  await l.load();
}

Widget _icon({required bool background, double inset = 0}) {
  return Directionality(
    textDirection: TextDirection.rtl,
    child: Container(
      width: 1024,
      height: 1024,
      decoration: background
          ? const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1C2333), Color(0xFF0D1016)],
              ),
            )
          : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (background)
            Positioned(
              right: -180,
              top: -200,
              child: Container(
                width: 700,
                height: 700,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    const Color(0xFFE8B54D).withValues(alpha: 0.35),
                    const Color(0xFFE8B54D).withValues(alpha: 0),
                  ]),
                ),
              ),
            ),
          Container(
            width: 560 - inset,
            height: 560 - inset,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF3CE7E), Color(0xFFE8B54D)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE8B54D).withValues(alpha: 0.45),
                  blurRadius: 90,
                  offset: const Offset(0, 40),
                ),
              ],
            ),
            child: Center(
              // Isolated meem has a descender; nudge it to look optically centred.
              child: Transform.translate(
                offset: Offset(22 - inset / 10, -48 + inset / 8),
                child: Text(
                'م',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 330 - inset / 3,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1300),
                  height: 1,
                ),
              ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('icon', (tester) async {
    await _loadFont();
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_icon(background: true));
    await expectLater(find.byType(Directionality), matchesGoldenFile('../assets/icon/icon.png'));

    await tester.pumpWidget(_icon(background: false, inset: 120));
    await expectLater(find.byType(Directionality), matchesGoldenFile('../assets/icon/foreground.png'));
  });
}
