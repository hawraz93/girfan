// Renders the real app with demo data and writes PNG screenshots to
// build/screenshots. Run with:
//   flutter test test/screenshots_test.dart --update-goldens
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masruf/app.dart';
import 'package:masruf/core/strings.dart';
import 'package:masruf/data/db.dart';
import 'package:masruf/data/demo.dart';
import 'package:masruf/data/repo.dart';
import 'package:masruf/state/providers.dart';
import 'package:masruf/ui/widgets/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _loadFonts() async {
  final vazir = FontLoader('Vazirmatn');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    vazir.addFont(rootBundle.load('assets/fonts/Vazirmatn-$w.ttf'));
  }
  await vazir.load();

  // Material icons live in the Flutter SDK cache, not in the app bundle.
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.path;
  final icons = File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons');
    loader.addFont(Future.value(ByteData.view(icons.readAsBytesSync().buffer)));
    await loader.load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  setUpAll(() async {
    tmp = Directory.systemTemp.createTempSync('masruf_shots');
    AppDb.directoryOverride = tmp.path;
    await _loadFonts();
    await seedDemo(Repo());
  });

  Future<void> shot(WidgetTester tester, String name) async {
    // Let the real SQLite futures complete, then settle animations.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../build/screenshots/$name.png'),
    );
  }

  testWidgets('screens', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({'name': 'هاوڕێ', 'theme': 2});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs)],
      child: const MasrufApp(),
    ));
    await tester.pumpAndSettle();
    await shot(tester, '01-home-dark');

    await tester.tap(find.text(S.analytics));
    await shot(tester, '02-analytics-dark');

    await tester.tap(find.text(S.recurring));
    await shot(tester, '03-recurring-dark');

    await tester.tap(find.text(S.settings));
    await shot(tester, '04-settings-dark');

    await tester.tap(find.text(S.home));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();
    Finder key(String k) =>
        find.descendant(of: find.byType(Keypad), matching: find.text(k));
    await tester.tap(key('4'));
    await tester.pump();
    await tester.tap(key('5'));
    await tester.pump();
    await tester.tap(key('000'));
    await tester.pump();
    await shot(tester, '05-add-expense-dark');
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // Light theme
    await tester.tap(find.text(S.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.themeLight));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.home));
    await shot(tester, '06-home-light');
    await tester.tap(find.text(S.analytics));
    await shot(tester, '07-analytics-light');
  });
}
