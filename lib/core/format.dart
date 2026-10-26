import 'package:intl/intl.dart';

const kurdishMonths = [
  'کانوونی دووەم', 'شوبات', 'ئازار', 'نیسان', 'ئایار', 'حوزەیران',
  'تەممووز', 'ئاب', 'ئەیلوول', 'تشرینی یەکەم', 'تشرینی دووەم', 'کانوونی یەکەم',
];

const kurdishMonthsShort = [
  'ک.دووەم', 'شوبات', 'ئازار', 'نیسان', 'ئایار', 'حوزەیران',
  'تەممووز', 'ئاب', 'ئەیلوول', 'ت.یەکەم', 'ت.دووەم', 'ک.یەکەم',
];

/// DateTime.weekday: 1 = Monday ... 7 = Sunday
const kurdishWeekdays = [
  'دووشەممە', 'سێشەممە', 'چوارشەممە', 'پێنجشەممە', 'هەینی', 'شەممە', 'یەکشەممە',
];

String two(int n) => n.toString().padLeft(2, '0');

/// yyyy-MM
String monthKey(DateTime d) => '${d.year}-${two(d.month)}';

DateTime monthFromKey(String key) {
  final p = key.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]));
}

String monthLabel(String key) {
  final d = monthFromKey(key);
  return '${kurdishMonths[d.month - 1]} ${d.year}';
}

String monthShort(String key) => kurdishMonthsShort[monthFromKey(key).month - 1];

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
  final year = d.year == now.year ? '' : ' ${d.year}';
  return '${kurdishWeekdays[d.weekday - 1]}، ${d.day} ${kurdishMonths[d.month - 1]}$year';
}

String shortDate(String key) {
  final d = dateFromKey(key);
  return '${d.day} ${kurdishMonthsShort[d.month - 1]}';
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
