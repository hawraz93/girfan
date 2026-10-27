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
  final MonthNames monthNames;

  /// When the last backup file was made (yyyy-MM-dd), or null.
  final String? lastBackup;

  /// Off (default): dinar and dollar are kept apart, never converted.
  /// On: everything is converted into [baseCurrency] at each entry's rate.
  final bool mergeCurrencies;

  const Settings({
    required this.baseCurrency,
    required this.usdRate,
    required this.themeMode,
    required this.pin,
    required this.userName,
    this.monthNames = MonthNames.kurdish,
    this.lastBackup,
    this.mergeCurrencies = false,
  });

  /// Whether an entry in [currency] belongs in totals shown in [view].
  bool inView(String currency, String view) => mergeCurrencies || currency == view;

  /// [amount] as it counts in [view]: converted when merging, as-is otherwise.
  double inViewAmount(double amount, String currency, String view, [double? rate]) =>
      mergeCurrencies ? toBase(amount, currency, rate) : amount;

  /// Totals per currency for [items] (or a single base total when merging).
  Map<String, double> split<T>(Iterable<T> items, double Function(T) amount,
      String Function(T) currency, [double? Function(T)? rate]) {
    final out = <String, double>{};
    for (final i in items) {
      final cur = mergeCurrencies ? baseCurrency : currency(i);
      final v = mergeCurrencies ? toBase(amount(i), currency(i), rate?.call(i)) : amount(i);
      out[cur] = (out[cur] ?? 0) + v;
    }
    return out;
  }

  /// Days since the last backup; null when there has never been one.
  int? get daysSinceBackup => lastBackup == null
      ? null
      : DateTime.now().difference(dateFromKey(lastBackup!)).inDays;

  String get otherCurrency => baseCurrency == 'IQD' ? 'USD' : 'IQD';

  /// Converts to the base currency, at [rate] (IQD per USD) when given,
  /// otherwise at today's rate.
  double toBase(double amount, String currency, [double? rate]) {
    if (currency == baseCurrency) return amount;
    final r = (rate == null || rate <= 0) ? usdRate : rate;
    if (baseCurrency == 'IQD') return amount * r; // USD -> IQD
    return r == 0 ? 0 : amount / r; // IQD -> USD
  }

  /// A transaction in base currency, at the rate it was recorded with.
  double txBase(Tx t) => toBase(t.amount, t.currency, t.rate);

  Settings copyWith({
    String? baseCurrency,
    double? usdRate,
    ThemeMode? themeMode,
    String? pin,
    bool clearPin = false,
    String? userName,
    MonthNames? monthNames,
    String? lastBackup,
    bool? mergeCurrencies,
  }) =>
      Settings(
        baseCurrency: baseCurrency ?? this.baseCurrency,
        usdRate: usdRate ?? this.usdRate,
        themeMode: themeMode ?? this.themeMode,
        pin: clearPin ? null : (pin ?? this.pin),
        userName: userName ?? this.userName,
        monthNames: monthNames ?? this.monthNames,
        lastBackup: lastBackup ?? this.lastBackup,
        mergeCurrencies: mergeCurrencies ?? this.mergeCurrencies,
      );
}

class SettingsNotifier extends Notifier<Settings> {
  SharedPreferences get _p => ref.read(prefsProvider);

  @override
  Settings build() {
    final mi = _p.getInt('monthNames') ?? MonthNames.kurdish.index;
    final names = MonthNames.values[mi.clamp(0, MonthNames.values.length - 1)];
    monthNames = names;
    return Settings(
      baseCurrency: _p.getString('base') ?? 'IQD',
      usdRate: _p.getDouble('usdRate') ?? 1500,
      themeMode: ThemeMode.values[_p.getInt('theme') ?? 0],
      pin: _p.getString('pin'),
      userName: _p.getString('name') ?? '',
      monthNames: names,
      lastBackup: _p.getString('lastBackup'),
      mergeCurrencies: _p.getBool('merge') ?? false,
    );
  }

  Future<void> setMerge(bool v) async {
    await _p.setBool('merge', v);
    state = state.copyWith(mergeCurrencies: v);
  }

  Future<void> markBackedUp() async {
    final today = dateKey(DateTime.now());
    await _p.setString('lastBackup', today);
    state = state.copyWith(lastBackup: today);
  }

  /// Settings worth carrying in a backup file (not the PIN).
  Map<String, Object?> exportable() => {
        'base': state.baseCurrency,
        'usdRate': state.usdRate,
        'name': state.userName,
        'monthNames': state.monthNames.index,
        'theme': state.themeMode.index,
        'merge': state.mergeCurrencies,
      };

  Future<void> importFrom(Map<String, dynamic> m) async {
    if (m['base'] is String) await _p.setString('base', m['base'] as String);
    if (m['usdRate'] is num) await _p.setDouble('usdRate', (m['usdRate'] as num).toDouble());
    if (m['name'] is String) await _p.setString('name', m['name'] as String);
    if (m['monthNames'] is int) await _p.setInt('monthNames', m['monthNames'] as int);
    if (m['theme'] is int) await _p.setInt('theme', m['theme'] as int);
    if (m['merge'] is bool) await _p.setBool('merge', m['merge'] as bool);
    ref.invalidateSelf();
  }

  Future<void> setMonthNames(MonthNames m) async {
    await _p.setInt('monthNames', m.index);
    monthNames = m;
    state = state.copyWith(monthNames: m);
  }

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

/// Bottom-nav tab, kept outside the widget so it survives a full rebuild.
final shellTabProvider = StateProvider<int>((_) => 0);

final categoryUsageProvider = FutureProvider<Map<int, int>>((ref) {
  ref.watch(dbTick);
  return ref.read(repoProvider).categoryUsage();
});

/// [cats] with the most used (last 90 days) first; ties keep their order.
List<Category> byUsage(List<Category> cats, Map<int, int> usage) {
  final indexed = [for (var i = 0; i < cats.length; i++) (i, cats[i])];
  indexed.sort((a, b) {
    final d = (usage[b.$2.id] ?? 0).compareTo(usage[a.$2.id] ?? 0);
    return d != 0 ? d : a.$1.compareTo(b.$1);
  });
  return [for (final e in indexed) e.$2];
}

final quickProvider = FutureProvider<List<QuickItem>>((ref) {
  ref.watch(dbTick);
  return ref.read(repoProvider).quickItems();
});

/// Whether to nudge for a backup: there is data and none in the last week.
final backupDueProvider = FutureProvider<bool>((ref) async {
  ref.watch(dbTick);
  final days = ref.watch(settingsProvider.select((s) => s.daysSinceBackup));
  if (days != null && days < 7) return false;
  return await ref.read(repoProvider).txCount() >= 5;
});

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

  /// Net amount moved into saving goals this month.
  final double saved;

  /// Currency every figure here is in.
  final String currency;

  const MonthSummary({
    required this.month,
    required this.currency,
    required this.income,
    required this.expense,
    required this.expenseByCat,
    required this.incomeByCat,
    this.saved = 0,
  });

  /// What is left to spend: income minus expenses minus money set aside.
  double get net => income - expense - saved;

  /// Average spend per elapsed day (whole month when it is in the past).
  double get avgPerDay {
    final now = DateTime.now();
    final days = month == monthKey(now) ? now.day : daysInMonth(month);
    return days == 0 ? 0 : expense / days;
  }
}

/// The currency the home and analytics screens show. Dinar and dollar are
/// separate unless merging is on, in which case it is always the base.
final viewCurrencyProvider = StateProvider<String?>((_) => null);

final effectiveViewProvider = Provider<String>((ref) {
  final s = ref.watch(settingsProvider);
  if (s.mergeCurrencies) return s.baseCurrency;
  return ref.watch(viewCurrencyProvider) ?? s.baseCurrency;
});

/// Currencies used this month (to decide whether to show the switch).
final monthCurrenciesProvider = FutureProvider<Set<String>>((ref) async {
  final txs = await ref.watch(monthTxProvider.future);
  return {for (final t in txs) t.currency};
});

final monthSummaryProvider = FutureProvider<MonthSummary>((ref) async {
  final month = ref.watch(selectedMonthProvider);
  final settings = ref.watch(settingsProvider);
  final view = ref.watch(effectiveViewProvider);
  final txs = (await ref.watch(monthTxProvider.future))
      .where((t) => settings.inView(t.currency, view));
  final cats = await ref.watch(categoriesProvider.future);
  final savedRows = await ref.watch(_monthSavedRowsProvider.future);
  final byId = {for (final c in cats) c.id: c};
  final saved = savedRows
      .where((r) => settings.inView(r['currency'] as String, view))
      .fold(0.0, (a, r) =>
          a + settings.inViewAmount((r['s'] as num).toDouble(), r['currency'] as String, view));

  double income = 0, expense = 0;
  final exp = <int, double>{}, inc = <int, double>{};
  for (final t in txs) {
    final v = settings.inViewAmount(t.amount, t.currency, view, t.rate);
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
    currency: view,
    income: income,
    expense: expense,
    expenseByCat: build(exp),
    incomeByCat: build(inc),
    saved: saved,
  );
});

final _monthSavedRowsProvider = FutureProvider<List<Map<String, Object?>>>((ref) {
  ref.watch(dbTick);
  final m = ref.watch(selectedMonthProvider);
  return ref.read(repoProvider).rawMonthlySaved(m, m);
});

// ---------------------------------------------------------------------------
// Debts & goals
// ---------------------------------------------------------------------------

class DebtView {
  final Debt debt;
  final List<DebtPayment> payments;
  const DebtView(this.debt, this.payments);

  double get paid => payments.fold(0.0, (a, p) => a + p.amount);
  double get remaining => (debt.amount - paid).clamp(0, double.infinity).toDouble();
  bool get settled => remaining <= 0.0001;
}

final debtsProvider = FutureProvider<List<DebtView>>((ref) async {
  ref.watch(dbTick);
  final repo = ref.read(repoProvider);
  final debts = await repo.debts();
  final pays = await repo.debtPayments();
  final byDebt = <int, List<DebtPayment>>{};
  for (final p in pays) {
    byDebt.putIfAbsent(p.debtId, () => []).add(p);
  }
  final list = [for (final d in debts) DebtView(d, byDebt[d.id] ?? const [])];
  // Open debts first, then settled ones.
  list.sort((a, b) => a.settled == b.settled ? 0 : (a.settled ? 1 : -1));
  return list;
});

class GoalView {
  final Goal goal;
  final List<GoalDeposit> deposits;
  const GoalView(this.goal, this.deposits);

  double get saved => deposits.fold(0.0, (a, d) => a + d.amount);
  double get remaining => (goal.target - saved).clamp(0, double.infinity).toDouble();
  double get progress => goal.target <= 0 ? 0 : (saved / goal.target).clamp(0.0, 1.0);
  bool get reached => saved >= goal.target;

  /// Amount to put aside each month to reach the target by the deadline.
  double? perMonthNeeded(String fromMonth) {
    final d = goal.deadline;
    if (d == null || reached) return null;
    final months = monthsBetween(fromMonth, d);
    return months <= 0 ? remaining : remaining / months;
  }
}

final goalsProvider = FutureProvider<List<GoalView>>((ref) async {
  ref.watch(dbTick);
  final repo = ref.read(repoProvider);
  final goals = await repo.goals();
  final deps = await repo.goalDeposits();
  final byGoal = <int, List<GoalDeposit>>{};
  for (final d in deps) {
    byGoal.putIfAbsent(d.goalId, () => []).add(d);
  }
  return [for (final g in goals) GoalView(g, byGoal[g.id] ?? const [])];
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
  final view = ref.watch(effectiveViewProvider);
  final from = addMonths(month, -5);
  final rows = await ref.read(repoProvider).rawMonthlySums(from, month);
  final inc = <String, double>{}, exp = <String, double>{};
  for (final r in rows) {
    final m = r['m'] as String;
    final cur = r['currency'] as String;
    if (!settings.inView(cur, view)) continue;
    final v = settings.inViewAmount(
        (r['s'] as num).toDouble(), cur, view, (r['rate'] as num?)?.toDouble());
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
