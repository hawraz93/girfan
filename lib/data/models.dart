import '../core/format.dart';

/// A category of spending, or a source of income (kind == 'income').
class Category {
  final int id;
  final String name;
  final String icon;
  final int color;
  final String kind; // 'expense' | 'income'
  final double? budget; // monthly limit in base currency (expense only)
  final int sort;
  final bool archived;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.kind,
    this.budget,
    this.sort = 0,
    this.archived = false,
  });

  bool get isExpense => kind == 'expense';

  factory Category.fromMap(Map<String, Object?> m) => Category(
        id: m['id'] as int,
        name: m['name'] as String,
        icon: m['icon'] as String,
        color: m['color'] as int,
        kind: m['kind'] as String,
        budget: (m['budget'] as num?)?.toDouble(),
        sort: (m['sort'] as int?) ?? 0,
        archived: ((m['archived'] as int?) ?? 0) == 1,
      );

  Map<String, Object?> toMap() => {
        'name': name,
        'icon': icon,
        'color': color,
        'kind': kind,
        'budget': budget,
        'sort': sort,
        'archived': archived ? 1 : 0,
      };

  Category copyWith({
    String? name,
    String? icon,
    int? color,
    double? budget,
    bool clearBudget = false,
    int? sort,
    bool? archived,
  }) =>
      Category(
        id: id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        kind: kind,
        budget: clearBudget ? null : (budget ?? this.budget),
        sort: sort ?? this.sort,
        archived: archived ?? this.archived,
      );
}

/// One expense or income entry.
class Tx {
  final int id;
  final String kind; // 'expense' | 'income'
  final double amount;
  final String currency; // 'IQD' | 'USD'
  final int categoryId;
  final String date; // yyyy-MM-dd
  final String note;
  final int? recurringId;
  final String? period; // yyyy-MM when generated from a recurring item

  const Tx({
    required this.id,
    required this.kind,
    required this.amount,
    required this.currency,
    required this.categoryId,
    required this.date,
    this.note = '',
    this.recurringId,
    this.period,
  });

  bool get isExpense => kind == 'expense';
  String get month => date.substring(0, 7);

  factory Tx.fromMap(Map<String, Object?> m) => Tx(
        id: m['id'] as int,
        kind: m['kind'] as String,
        amount: (m['amount'] as num).toDouble(),
        currency: m['currency'] as String,
        categoryId: m['category_id'] as int,
        date: m['date'] as String,
        note: (m['note'] as String?) ?? '',
        recurringId: m['recurring_id'] as int?,
        period: m['period'] as String?,
      );

  Map<String, Object?> toMap() => {
        'kind': kind,
        'amount': amount,
        'currency': currency,
        'category_id': categoryId,
        'date': date,
        'note': note,
        'recurring_id': recurringId,
        'period': period,
      };
}

/// A fixed monthly item: rent, a loan installment, salary...
class Recurring {
  final int id;
  final String name;
  final double amount;
  final String currency;
  final int categoryId;
  final String kind;
  final int dayOfMonth;
  final String startMonth; // yyyy-MM
  final String? endMonth; // yyyy-MM, null = open-ended
  final String note;
  final bool active;

  const Recurring({
    required this.id,
    required this.name,
    required this.amount,
    required this.currency,
    required this.categoryId,
    required this.kind,
    required this.dayOfMonth,
    required this.startMonth,
    this.endMonth,
    this.note = '',
    this.active = true,
  });

  bool get isExpense => kind == 'expense';
  bool get hasEnd => endMonth != null;

  bool coversMonth(String m) =>
      startMonth.compareTo(m) <= 0 &&
      (endMonth == null || endMonth!.compareTo(m) >= 0);

  /// Total number of installments when the item has an end month.
  int? get totalInstallments =>
      endMonth == null ? null : monthsBetween(startMonth, endMonth!);

  factory Recurring.fromMap(Map<String, Object?> m) => Recurring(
        id: m['id'] as int,
        name: m['name'] as String,
        amount: (m['amount'] as num).toDouble(),
        currency: m['currency'] as String,
        categoryId: m['category_id'] as int,
        kind: m['kind'] as String,
        dayOfMonth: m['day_of_month'] as int,
        startMonth: m['start_month'] as String,
        endMonth: m['end_month'] as String?,
        note: (m['note'] as String?) ?? '',
        active: ((m['active'] as int?) ?? 1) == 1,
      );

  Map<String, Object?> toMap() => {
        'name': name,
        'amount': amount,
        'currency': currency,
        'category_id': categoryId,
        'kind': kind,
        'day_of_month': dayOfMonth,
        'start_month': startMonth,
        'end_month': endMonth,
        'note': note,
        'active': active ? 1 : 0,
      };
}

/// Aggregated totals for one month (already converted to base currency).
class MonthTotal {
  final String month;
  final double income;
  final double expense;
  const MonthTotal(this.month, this.income, this.expense);
  double get net => income - expense;
}
