import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/format.dart';
import '../data/models.dart';
import '../data/repo.dart';

// ---------------------------------------------------------------------------
// Infrastructure
// ---------------------------------------------------------------------------

final prefsProvider = Provider<SharedPreferences>((_) => throw UnimplementedError());
final repoProvider = Provider<Repo>((_) => Repo());

/// Bumped after every write so all data providers refresh.
final dbTick = StateProvider<int>((_) => 0);

extension RefreshX on WidgetRef {
  void bump() => read(dbTick.notifier).state++;
}

// ---------------------------------------------------------------------------
// Settings
// ---------------------------------------------------------------------------

class Settings {
  final String baseCurrency;
  final double usdRate; // IQD per 1 USD
  final ThemeMode themeMode;
  final String? pin;
  final String userName;

  const Settings({
    required this.baseCurrency,
    required this.usdRate,
    required this.themeMode,
    required this.pin,
    required this.userName,
  });

  String get otherCurrency => baseCurrency == 'IQD' ? 'USD' : 'IQD';

  double toBase(double amount, String currency) {
    if (currency == baseCurrency) return amount;
    if (baseCurrency == 'IQD') return amount * usdRate; // USD -> IQD
    return usdRate == 0 ? 0 : amount / usdRate; // IQD -> USD
  }

  Settings copyWith({
    String? baseCurrency,
    double? usdRate,
    ThemeMode? themeMode,
    String? pin,
    bool clearPin = false,
    String? userName,
  }) =>
      Settings(
        baseCurrency: baseCurrency ?? this.baseCurrency,
        usdRate: usdRate ?? this.usdRate,
        themeMode: themeMode ?? this.themeMode,
        pin: clearPin ? null : (pin ?? this.pin),
        userName: userName ?? this.userName,
      );
}

class SettingsNotifier extends Notifier<Settings> {
  SharedPreferences get _p => ref.read(prefsProvider);

  @override
  Settings build() => Settings(
        baseCurrency: _p.getString('base') ?? 'IQD',
        usdRate: _p.getDouble('usdRate') ?? 1500,
        themeMode: ThemeMode.values[_p.getInt('theme') ?? 0],
        pin: _p.getString('pin'),
        userName: _p.getString('name') ?? '',
      );

  Future<void> setBase(String c) async {
    await _p.setString('base', c);
    state = state.copyWith(baseCurrency: c);
  }

  Future<void> setUsdRate(double r) async {
    await _p.setDouble('usdRate', r);
    state = state.copyWith(usdRate: r);
  }

  Future<void> setTheme(ThemeMode m) async {
    await _p.setInt('theme', m.index);
    state = state.copyWith(themeMode: m);
  }

  Future<void> setPin(String? pin) async {
    if (pin == null) {
      await _p.remove('pin');
      state = state.copyWith(clearPin: true);
    } else {
      await _p.setString('pin', pin);
      state = state.copyWith(pin: pin);
    }
  }

  Future<void> setName(String n) async {
    await _p.setString('name', n);
    state = state.copyWith(userName: n);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);

/// True once the PIN was entered this session (or no PIN is set).
final unlockedProvider = StateProvider<bool>((_) => false);

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

final selectedMonthProvider = StateProvider<String>((_) => currentMonth());

final categoriesProvider = FutureProvider<List<Category>>((ref) {
  ref.watch(dbTick);
  return ref.read(repoProvider).categories(includeArchived: true);
});

/// id -> category, including archived ones so old entries still resolve.
final categoryMapProvider = Provider<Map<int, Category>>((ref) {
  final list = ref.watch(categoriesProvider).valueOrNull ?? const [];
  return {for (final c in list) c.id: c};
});

final monthTxProvider = FutureProvider<List<Tx>>((ref) {
  ref.watch(dbTick);
  final m = ref.watch(selectedMonthProvider);
  return ref.read(repoProvider).txForMonth(m);
});

final recurringsProvider = FutureProvider<List<Recurring>>((ref) {
  ref.watch(dbTick);
  return ref.read(repoProvider).recurrings();
});

final paidPeriodsProvider = FutureProvider<Map<int, List<String>>>((ref) {
  ref.watch(dbTick);
  return ref.read(repoProvider).paidPeriods();
});

// ---------------------------------------------------------------------------
// Derived
// ---------------------------------------------------------------------------

class CatTotal {
  final Category cat;
  final double total; // base currency
  const CatTotal(this.cat, this.total);
}

class MonthSummary {
  final String month;
  final double income;
  final double expense;
  final List<CatTotal> expenseByCat; // sorted desc
  final List<CatTotal> incomeByCat;

  const MonthSummary({
    required this.month,
    required this.income,
    required this.expense,
    required this.expenseByCat,
    required this.incomeByCat,
  });

  double get net => income - expense;

  /// Average spend per elapsed day (whole month when it is in the past).
  double get avgPerDay {
    final now = DateTime.now();
    final days = month == monthKey(now) ? now.day : daysInMonth(month);
    return days == 0 ? 0 : expense / days;
  }
}

final monthSummaryProvider = FutureProvider<MonthSummary>((ref) async {
  final month = ref.watch(selectedMonthProvider);
  final settings = ref.watch(settingsProvider);
  final txs = await ref.watch(monthTxProvider.future);
  final cats = await ref.watch(categoriesProvider.future);
  final byId = {for (final c in cats) c.id: c};

  double income = 0, expense = 0;
  final exp = <int, double>{}, inc = <int, double>{};
  for (final t in txs) {
    final v = settings.toBase(t.amount, t.currency);
    if (t.isExpense) {
      expense += v;
      exp[t.categoryId] = (exp[t.categoryId] ?? 0) + v;
    } else {
      income += v;
      inc[t.categoryId] = (inc[t.categoryId] ?? 0) + v;
    }
  }
  List<CatTotal> build(Map<int, double> m) {
    final list = [
      for (final e in m.entries)
        if (byId[e.key] != null) CatTotal(byId[e.key]!, e.value)
    ];
    list.sort((a, b) => b.total.compareTo(a.total));
    return list;
  }

  return MonthSummary(
    month: month,
    income: income,
    expense: expense,
    expenseByCat: build(exp),
    incomeByCat: build(inc),
  );
});

class DueItem {
  final Recurring recurring;
  final Category? category;
  final bool paid;
  const DueItem(this.recurring, this.category, this.paid);
}

/// Recurring items that apply to the selected month, with paid status.
final dueProvider = FutureProvider<List<DueItem>>((ref) async {
  final month = ref.watch(selectedMonthProvider);
  final recs = await ref.watch(recurringsProvider.future);
  final paid = await ref.watch(paidPeriodsProvider.future);
  final cats = await ref.watch(categoriesProvider.future);
  final byId = {for (final c in cats) c.id: c};
  return [
    for (final r in recs)
      if (r.coversMonth(month))
        DueItem(r, byId[r.categoryId], (paid[r.id] ?? const []).contains(month)),
  ];
});

/// Six months ending at the selected month, totals in base currency.
final monthlySeriesProvider = FutureProvider<List<MonthTotal>>((ref) async {
  ref.watch(dbTick);
  final month = ref.watch(selectedMonthProvider);
  final settings = ref.watch(settingsProvider);
  final from = addMonths(month, -5);
  final rows = await ref.read(repoProvider).rawMonthlySums(from, month);
  final inc = <String, double>{}, exp = <String, double>{};
  for (final r in rows) {
    final m = r['m'] as String;
    final v = settings.toBase((r['s'] as num).toDouble(), r['currency'] as String);
    if (r['kind'] == 'expense') {
      exp[m] = (exp[m] ?? 0) + v;
    } else {
      inc[m] = (inc[m] ?? 0) + v;
    }
  }
  return [
    for (var i = 0; i < 6; i++)
      () {
        final m = addMonths(from, i);
        return MonthTotal(m, inc[m] ?? 0, exp[m] ?? 0);
      }(),
  ];
});
