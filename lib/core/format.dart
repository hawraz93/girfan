import 'package:intl/intl.dart';

/// How months are written across the app. Set from Settings at start-up and
/// whenever the user changes it (the app tree is rebuilt on change).
enum MonthNames { number, kurdish, arabic, english }

MonthNames monthNames = MonthNames.kurdish;

const kurdishMonths = [
  'کانوونی دووەم', 'شوبات', 'ئازار', 'نیسان', 'ئایار', 'حوزەیران',
  'تەممووز', 'ئاب', 'ئەیلوول', 'تشرینی یەکەم', 'تشرینی دووەم', 'کانوونی یەکەم',
];

const kurdishMonthsShort = [
  'ک.دووەم', 'شوبات', 'ئازار', 'نیسان', 'ئایار', 'حوزەیران',
  'تەممووز', 'ئاب', 'ئەیلوول', 'ت.یەکەم', 'ت.دووەم', 'ک.یەکەم',
];

const arabicMonths = [
  'كانون الثاني', 'شباط', 'آذار', 'نيسان', 'أيار', 'حزيران',
  'تموز', 'آب', 'أيلول', 'تشرين الأول', 'تشرين الثاني', 'كانون الأول',
];

const arabicMonthsShort = [
  'ك.الثاني', 'شباط', 'آذار', 'نيسان', 'أيار', 'حزيران',
  'تموز', 'آب', 'أيلول', 'ت.الأول', 'ت.الثاني', 'ك.الأول',
];

const englishMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const englishMonthsShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// DateTime.weekday: 1 = Monday ... 7 = Sunday
const kurdishWeekdays = [
  'دووشەممە', 'سێشەممە', 'چوارشەممە', 'پێنجشەممە', 'هەینی', 'شەممە', 'یەکشەممە',
];
const arabicWeekdays = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
const englishWeekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

/// Full month name in the chosen style ("تشرینی یەکەم", "October"...),
/// or the number itself in number style.
String monthName(int m) => switch (monthNames) {
      MonthNames.number => '$m',
      MonthNames.kurdish => kurdishMonths[m - 1],
      MonthNames.arabic => arabicMonths[m - 1],
      MonthNames.english => englishMonths[m - 1],
    };

String monthNameShort(int m) => switch (monthNames) {
      MonthNames.number => '$m',
      MonthNames.kurdish => kurdishMonthsShort[m - 1],
      MonthNames.arabic => arabicMonthsShort[m - 1],
      MonthNames.english => englishMonthsShort[m - 1],
    };

String weekdayName(int weekday) => switch (monthNames) {
      MonthNames.arabic => arabicWeekdays[weekday - 1],
      MonthNames.english => englishWeekdays[weekday - 1],
      _ => kurdishWeekdays[weekday - 1],
    };

String two(int n) => n.toString().padLeft(2, '0');

/// yyyy-MM
String monthKey(DateTime d) => '${d.year}-${two(d.month)}';

DateTime monthFromKey(String key) {
  final p = key.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]));
}

/// "10 · تشرینی یەکەم 2026", or "10 / 2026" in number style.
String monthLabel(String key) {
  final d = monthFromKey(key);
  if (monthNames == MonthNames.number) return '${d.month} / ${d.year}';
  return '${d.month} · ${monthName(d.month)} ${d.year}';
}

String monthShort(String key) {
  final m = monthFromKey(key).month;
  return monthNames == MonthNames.number ? '$m' : monthNameShort(m);
}

String addMonths(String key, int n) {
  final d = monthFromKey(key);
  return monthKey(DateTime(d.year, d.month + n));
}

/// Inclusive count of months from [a] to [b]. Returns 0 if b < a.
int monthsBetween(String a, String b) {
  final da = monthFromKey(a), db = monthFromKey(b);
  final n = (db.year - da.year) * 12 + (db.month - da.month) + 1;
  return n < 0 ? 0 : n;
}

/// Payments from [a] to [b] inclusive when one falls every [interval] months.
int installmentsBetween(String a, String b, int interval) {
  final n = monthsBetween(a, b);
  return n <= 0 ? 0 : (n - 1) ~/ interval + 1;
}

int daysInMonth(String key) {
  final d = monthFromKey(key);
  return DateTime(d.year, d.month + 1, 0).day;
}

String currentMonth() => monthKey(DateTime.now());

/// yyyy-MM-dd
String dateKey(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

DateTime dateFromKey(String key) => DateTime.parse(key);

String dateLabel(String key) {
  final d = dateFromKey(key);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(DateTime(d.year, d.month, d.day)).inDays;
  if (diff == 0) return 'ئەمڕۆ';
  if (diff == 1) return 'دوێنێ';
  final year = d.year == now.year ? '' : (monthNames == MonthNames.number ? '/${d.year}' : ' ${d.year}');
  if (monthNames == MonthNames.number) {
    return '${weekdayName(d.weekday)}، ${d.day}/${d.month}$year';
  }
  return '${weekdayName(d.weekday)}، ${d.day} ${monthName(d.month)}$year';
}

String shortDate(String key) {
  final d = dateFromKey(key);
  if (monthNames == MonthNames.number) return '${d.day}/${d.month}';
  return '${d.day} ${monthNameShort(d.month)}';
}

final _n0 = NumberFormat('#,##0', 'en');
final _n2 = NumberFormat('#,##0.##', 'en');

String currencySymbol(String cur) => cur == 'USD' ? r'$' : 'د.ع';

/// 450,000 د.ع  /  $120.5
String money(double v, String cur) {
  // LRM keeps "$1,750" in reading order inside RTL sentences.
  if (cur == 'USD') return '‎\$${_n2.format(v)}‎';
  return '${_n0.format(v)} د.ع';
}

/// Number only, without the currency suffix.
String moneyNumber(double v, String cur) =>
    cur == 'USD' ? _n2.format(v) : _n0.format(v);
