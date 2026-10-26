import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/strings.dart';
import 'core/theme.dart';
import 'state/providers.dart';
import 'ui/lock/lock_screen.dart';
import 'ui/shell.dart';

class MasrufApp extends ConsumerWidget {
  const MasrufApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    return MaterialApp(
      title: S.appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: s.themeMode,
      // Material has no Sorani locale; Arabic gives RTL widgets and digits
      // layout while all visible text comes from S.
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Keyed on the month style so every date label redraws when it changes.
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: KeyedSubtree(key: ValueKey(s.monthNames), child: child!),
      ),
      home: const _Gate(),
    );
  }
}

class _Gate extends ConsumerWidget {
  const _Gate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final unlocked = ref.watch(unlockedProvider);
    if (s.pin != null && !unlocked) return const LockScreen();
    return const Shell();
  }
}
