import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/demo.dart';
import 'data/repo.dart';
import 'state/providers.dart';

/// `flutter run --dart-define=DEMO=true` fills an empty DB with sample data.
const _demo = bool.fromEnvironment('DEMO');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final prefs = await SharedPreferences.getInstance();
  if (_demo) await seedDemo(Repo());
  // Older rows have no stored rate; pin them to today's so a later rate
  // change does not rewrite past months.
  await Repo().freezeMissingRates(prefs.getDouble('usdRate') ?? 1500);
  runApp(
    ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs)],
      child: const MasrufApp(),
    ),
  );
}
