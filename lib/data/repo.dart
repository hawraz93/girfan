import 'package:sqflite/sqflite.dart';

import 'db.dart';
import 'models.dart';

class Repo {
  Future<Database> get _db => AppDb.instance;

  // ---------- categories ----------

  Future<List<Category>> categories({bool includeArchived = false}) async {
    final db = await _db;
    final rows = await db.query(
      'categories',
      where: includeArchived ? null : 'archived = 0',
      orderBy: 'kind DESC, sort ASC, id ASC',
    );
    return rows.map(Category.fromMap).toList();
  }

  Future<int> insertCategory(Category c) async {
    final db = await _db;
    final max = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT MAX(sort) FROM categories WHERE kind = ?', [c.kind])) ??
        0;
    return db.insert('categories', {...c.toMap(), 'sort': max + 1});
  }

  Future<void> updateCategory(Category c) async {
    final db = await _db;
    await db.update('categories', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
  }

  /// Deletes when unused, otherwise archives. Returns true if archived.
  Future<bool> deleteCategory(int id) async {
    final db = await _db;
    final used = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM transactions WHERE category_id = ?', [id])) ??
        0;
    final usedRec = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM recurrings WHERE category_id = ?', [id])) ??
        0;
    if (used + usedRec > 0) {
      await db.update('categories', {'archived': 1},
          where: 'id = ?', whereArgs: [id]);
      return true;
    }
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
    return false;
  }

  // ---------- transactions ----------

  Future<List<Tx>> txForMonth(String month) async {
    final db = await _db;
    final rows = await db.query(
      'transactions',
      where: 'substr(date, 1, 7) = ?',
      whereArgs: [month],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(Tx.fromMap).toList();
  }

  Future<List<Tx>> allTx() async {
    final db = await _db;
    final rows = await db.query('transactions', orderBy: 'date DESC, id DESC');
    return rows.map(Tx.fromMap).toList();
  }

  Future<int> insertTx(Tx t) async => (await _db).insert('transactions', t.toMap());

  Future<void> updateTx(Tx t) async {
    final db = await _db;
    await db.update('transactions', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  }

  Future<void> deleteTx(int id) async {
    final db = await _db;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  /// Raw sums grouped by month/kind/currency for [from]..[to] inclusive.
  /// Conversion to base currency happens in the caller.
  Future<List<Map<String, Object?>>> rawMonthlySums(String from, String to) async {
    final db = await _db;
    return db.rawQuery('''
      SELECT substr(date, 1, 7) AS m, kind, currency, rate, SUM(amount) AS s
      FROM transactions
      WHERE substr(date, 1, 7) BETWEEN ? AND ?
      GROUP BY m, kind, currency, rate
    ''', [from, to]);
  }

  // ---------- recurrings ----------

  Future<List<Recurring>> recurrings() async {
    final db = await _db;
    final rows = await db.query('recurrings',
        where: 'active = 1', orderBy: 'day_of_month ASC, id ASC');
    return rows.map(Recurring.fromMap).toList();
  }

  Future<int> insertRecurring(Recurring r) async =>
      (await _db).insert('recurrings', r.toMap());

  Future<void> updateRecurring(Recurring r) async {
    final db = await _db;
    await db.update('recurrings', r.toMap(), where: 'id = ?', whereArgs: [r.id]);
  }

  /// Removes the recurring definition; past payments stay as transactions.
  Future<void> deleteRecurring(int id) async {
    final db = await _db;
    await db.delete('recurrings', where: 'id = ?', whereArgs: [id]);
    await db.update('transactions', {'recurring_id': null},
        where: 'recurring_id = ?', whereArgs: [id]);
  }

  /// recurring_id -> list of paid periods (yyyy-MM).
  Future<Map<int, List<String>>> paidPeriods() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT recurring_id, period FROM transactions
      WHERE recurring_id IS NOT NULL AND period IS NOT NULL
    ''');
    final out = <int, List<String>>{};
    for (final r in rows) {
      out.putIfAbsent(r['recurring_id'] as int, () => []).add(r['period'] as String);
    }
    return out;
  }

  // ---------- debts ----------

  Future<List<Debt>> debts() async {
    final db = await _db;
    final rows = await db.query('debts', orderBy: 'date DESC, id DESC');
    return rows.map(Debt.fromMap).toList();
  }

  Future<int> insertDebt(Debt d) async => (await _db).insert('debts', d.toMap());

  Future<void> updateDebt(Debt d) async {
    final db = await _db;
    await db.update('debts', d.toMap(), where: 'id = ?', whereArgs: [d.id]);
  }

  Future<void> deleteDebt(int id) async {
    final db = await _db;
    await db.delete('debt_payments', where: 'debt_id = ?', whereArgs: [id]);
    await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<DebtPayment>> debtPayments() async {
    final db = await _db;
    final rows = await db.query('debt_payments', orderBy: 'date DESC, id DESC');
    return rows.map(DebtPayment.fromMap).toList();
  }

  Future<int> insertDebtPayment(DebtPayment p) async =>
      (await _db).insert('debt_payments', p.toMap());

  Future<void> deleteDebtPayment(int id) async {
    final db = await _db;
    await db.delete('debt_payments', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- goals ----------

  Future<List<Goal>> goals() async {
    final db = await _db;
    final rows = await db.query('goals', orderBy: 'id ASC');
    return rows.map(Goal.fromMap).toList();
  }

  Future<int> insertGoal(Goal g) async => (await _db).insert('goals', g.toMap());

  Future<void> updateGoal(Goal g) async {
    final db = await _db;
    await db.update('goals', g.toMap(), where: 'id = ?', whereArgs: [g.id]);
  }

  Future<void> deleteGoal(int id) async {
    final db = await _db;
    await db.delete('goal_deposits', where: 'goal_id = ?', whereArgs: [id]);
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<GoalDeposit>> goalDeposits() async {
    final db = await _db;
    final rows = await db.query('goal_deposits', orderBy: 'date DESC, id DESC');
    return rows.map(GoalDeposit.fromMap).toList();
  }

  Future<int> insertGoalDeposit(GoalDeposit d) async =>
      (await _db).insert('goal_deposits', d.toMap());

  Future<void> deleteGoalDeposit(int id) async {
    final db = await _db;
    await db.delete('goal_deposits', where: 'id = ?', whereArgs: [id]);
  }

  /// Net amount put into goals per month and currency, for [from]..[to].
  Future<List<Map<String, Object?>>> rawMonthlySaved(String from, String to) async {
    final db = await _db;
    return db.rawQuery('''
      SELECT substr(d.date, 1, 7) AS m, g.currency AS currency, SUM(d.amount) AS s
      FROM goal_deposits d JOIN goals g ON g.id = d.goal_id
      WHERE substr(d.date, 1, 7) BETWEEN ? AND ?
      GROUP BY m, g.currency
    ''', [from, to]);
  }

  /// Gives rows recorded before rates were stored the rate in use now, so
  /// changing the rate later leaves them as they are.
  Future<void> freezeMissingRates(double rate) async {
    final db = await _db;
    await db.update('transactions', {'rate': rate}, where: 'rate IS NULL');
  }

  /// category_id -> number of entries in the last 90 days (most used first).
  Future<Map<int, int>> categoryUsage() async {
    final db = await _db;
    final since = DateTime.now().subtract(const Duration(days: 90));
    final key = '${since.year}-${since.month.toString().padLeft(2, '0')}-${since.day.toString().padLeft(2, '0')}';
    final rows = await db.rawQuery(
        'SELECT category_id AS c, COUNT(*) AS n FROM transactions WHERE date >= ? GROUP BY category_id',
        [key]);
    return {for (final r in rows) r['c'] as int: r['n'] as int};
  }

  Future<int> txCount() async {
    final db = await _db;
    final r = await db.rawQuery('SELECT COUNT(*) AS n FROM transactions');
    return (r.first['n'] as int?) ?? 0;
  }

  // ---------- quick buttons ----------

  Future<List<QuickItem>> quickItems() async {
    final db = await _db;
    final rows = await db.query('quick', orderBy: 'sort ASC, id ASC');
    return rows.map(QuickItem.fromMap).toList();
  }

  Future<int> insertQuick(QuickItem q) async {
    final db = await _db;
    final r = await db.rawQuery('SELECT MAX(sort) AS m FROM quick');
    final max = (r.first['m'] as int?) ?? 0;
    return db.insert('quick', {...q.toMap(), 'sort': max + 1});
  }

  Future<void> updateQuick(QuickItem q) async {
    final db = await _db;
    await db.update('quick', q.toMap(), where: 'id = ?', whereArgs: [q.id]);
  }

  Future<void> deleteQuick(int id) async {
    final db = await _db;
    await db.delete('quick', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- backup ----------

  /// Every row of every table, for a backup file.
  Future<Map<String, List<Map<String, Object?>>>> dumpAll() async {
    final db = await _db;
    return {for (final t in AppDb.tables) t: await db.query(t)};
  }

  /// Replaces all data with [tables] from a backup. Columns the current
  /// schema does not know are dropped; missing ones take their defaults.
  Future<void> restoreAll(Map<String, dynamic> tables) async {
    final db = await _db;
    await db.transaction((txn) async {
      for (final t in AppDb.tables) {
        final cols = {
          for (final c in await txn.rawQuery('PRAGMA table_info($t)')) c['name'] as String
        };
        await txn.delete(t);
        final rows = (tables[t] as List?) ?? const [];
        for (final r in rows) {
          final row = <String, Object?>{
            for (final e in (r as Map).entries)
              if (cols.contains(e.key)) e.key as String: e.value as Object?
          };
          if (row.isNotEmpty) await txn.insert(t, row);
        }
      }
    });
  }
}
