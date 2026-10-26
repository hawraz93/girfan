import 'dart:math';

import '../core/format.dart';
import 'models.dart';
import 'repo.dart';

/// Fills an empty database with sample data for screenshots / previews.
/// Only runs when the app is built with `--dart-define=DEMO=true`.
Future<void> seedDemo(Repo repo) async {
  if ((await repo.allTx()).isNotEmpty) return;
  final cats = await repo.categories();
  int id(String name, String kind) =>
      cats.firstWhere((c) => c.name == name && c.kind == kind).id;

  final now = DateTime.now();
  final thisMonth = monthKey(now);

  // Recurring items
  final salaryId = await repo.insertRecurring(Recurring(
    id: 0,
    name: 'موچە',
    amount: 1650000,
    currency: 'IQD',
    categoryId: id('موچە', 'income'),
    kind: 'income',
    dayOfMonth: 1,
    startMonth: addMonths(thisMonth, -12),
  ));
  final rentId = await repo.insertRecurring(Recurring(
    id: 0,
    name: 'کرێی خانوو',
    amount: 450000,
    currency: 'IQD',
    categoryId: id('خانوو', 'expense'),
    kind: 'expense',
    dayOfMonth: 5,
    startMonth: addMonths(thisMonth, -12),
  ));
  final loanId = await repo.insertRecurring(Recurring(
    id: 0,
    name: 'سلفەی ئۆتۆمبێل',
    amount: 250,
    currency: 'USD',
    categoryId: id('سەیارە', 'expense'),
    kind: 'expense',
    dayOfMonth: 15,
    startMonth: addMonths(thisMonth, -5),
    endMonth: addMonths(thisMonth, 6),
  ));
  await repo.insertRecurring(Recurring(
    id: 0,
    name: 'ئینتەرنێت',
    amount: 45000,
    currency: 'IQD',
    categoryId: id('مۆبایل و ئینتەرنێت', 'expense'),
    kind: 'expense',
    dayOfMonth: 10,
    startMonth: addMonths(thisMonth, -12),
  ));

  final rnd = Random(7);
  final expenseCats = <String, List<int>>{
    'خواردن': [8000, 35000],
    'بازاڕ': [25000, 120000],
    'مناڵ': [10000, 60000],
    'سەیارە': [20000, 50000],
    'تەندروستی': [15000, 80000],
    'جل و بەرگ': [40000, 150000],
    'کات بەسەربردن': [10000, 45000],
  };
  final notes = <String, List<String>>{
    'خواردن': ['نانی نیوەڕۆ', 'قاوە', 'شام لەگەڵ خێزان', ''],
    'بازاڕ': ['بازاڕی هەفتانە', 'سەوزە و میوە', ''],
    'مناڵ': ['کتێب و قەڵەم', 'شیر', 'یاری', ''],
    'سەیارە': ['بەنزین', 'شوشتن', ''],
    'تەندروستی': ['دەرمانخانە', 'پزیشک', ''],
    'جل و بەرگ': ['پێڵاو', 'کراس', ''],
    'کات بەسەربردن': ['سینەما', 'کافێ', ''],
  };

  // Past 5 months + this month
  for (var back = 5; back >= 0; back--) {
    final m = addMonths(thisMonth, -back);
    final d = monthFromKey(m);
    final lastDay = back == 0 ? now.day : daysInMonth(m);

    // Fixed items for the month
    await repo.insertTx(Tx(
      id: 0,
      kind: 'income',
      amount: 1650000,
      currency: 'IQD',
      categoryId: id('موچە', 'income'),
      date: dateKey(DateTime(d.year, d.month, 1)),
      note: 'موچە',
      recurringId: salaryId,
      period: m,
    ));
    await repo.insertTx(Tx(
      id: 0,
      kind: 'expense',
      amount: 450000,
      currency: 'IQD',
      categoryId: id('خانوو', 'expense'),
      date: dateKey(DateTime(d.year, d.month, min(5, lastDay))),
      note: 'کرێی خانوو',
      recurringId: rentId,
      period: m,
    ));
    if (back > 0) {
      await repo.insertTx(Tx(
        id: 0,
        kind: 'expense',
        amount: 250,
        currency: 'USD',
        categoryId: id('سەیارە', 'expense'),
        date: dateKey(DateTime(d.year, d.month, 15)),
        note: 'سلفەی ئۆتۆمبێل',
        recurringId: loanId,
        period: m,
      ));
    }
    if (back == 2) {
      await repo.insertTx(Tx(
        id: 0,
        kind: 'income',
        amount: 300,
        currency: 'USD',
        categoryId: id('کاری سەربەخۆ', 'income'),
        date: dateKey(DateTime(d.year, d.month, 20)),
        note: 'پڕۆژەی وێبسایت',
      ));
    }

    // Daily spending
    final count = back == 0 ? 14 : 18 + rnd.nextInt(8);
    for (var i = 0; i < count; i++) {
      final cat = expenseCats.keys.elementAt(rnd.nextInt(expenseCats.length));
      final range = expenseCats[cat]!;
      final amount = (range[0] + rnd.nextInt(range[1] - range[0])) ~/ 500 * 500;
      final day = 1 + rnd.nextInt(lastDay);
      final ns = notes[cat]!;
      await repo.insertTx(Tx(
        id: 0,
        kind: 'expense',
        amount: amount.toDouble(),
        currency: 'IQD',
        categoryId: id(cat, 'expense'),
        date: dateKey(DateTime(d.year, d.month, day)),
        note: ns[rnd.nextInt(ns.length)],
      ));
    }
  }
}
