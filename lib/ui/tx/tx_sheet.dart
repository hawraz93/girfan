import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../core/icons.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../widgets/widgets.dart';

/// Opens the add / edit sheet. Pass [fromRecurring] + [period] to record a
/// fixed monthly item for that month.
Future<void> showTxSheet(
  BuildContext context, {
  Tx? existing,
  Recurring? fromRecurring,
  String? period,
}) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TxSheet(existing: existing, fromRecurring: fromRecurring, period: period),
    );

class TxSheet extends ConsumerStatefulWidget {
  final Tx? existing;
  final Recurring? fromRecurring;
  final String? period;
  const TxSheet({super.key, this.existing, this.fromRecurring, this.period});

  @override
  ConsumerState<TxSheet> createState() => _TxSheetState();
}

class _TxSheetState extends ConsumerState<TxSheet> {
  late String kind;
  late String currency;
  String raw = '';
  int? categoryId;
  late DateTime date;
  final note = TextEditingController();
  final noteFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    final e = widget.existing;
    final r = widget.fromRecurring;
    if (e != null) {
      kind = e.kind;
      currency = e.currency;
      raw = _rawFrom(e.amount, e.currency);
      categoryId = e.categoryId;
      date = dateFromKey(e.date);
      note.text = e.note;
    } else if (r != null) {
      kind = r.kind;
      currency = r.currency;
      raw = _rawFrom(r.amount, r.currency);
      categoryId = r.categoryId;
      date = _dateForPeriod(widget.period ?? currentMonth(), r.dayOfMonth);
      note.text = r.name;
    } else {
      kind = 'expense';
      currency = s.baseCurrency;
      date = DateTime.now();
    }
    noteFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    note.dispose();
    noteFocus.dispose();
    super.dispose();
  }

  static String _rawFrom(double a, String cur) {
    if (cur == 'USD') return a == a.roundToDouble() ? a.toInt().toString() : a.toString();
    return a.round().toString();
  }

  static DateTime _dateForPeriod(String period, int day) {
    final now = DateTime.now();
    if (period == monthKey(now)) return now;
    final d = monthFromKey(period);
    return DateTime(d.year, d.month, math.min(day, daysInMonth(period)));
  }

  double get amount => double.tryParse(raw) ?? 0;

  void _key(String k) {
    setState(() {
      if (k == '.') {
        if (currency != 'USD' || raw.contains('.')) return;
        raw = raw.isEmpty ? '0.' : '$raw.';
        return;
      }
      if (raw.replaceAll('.', '').length >= 12) return;
      if (currency == 'USD' && raw.contains('.') && raw.split('.')[1].length >= 2) return;
      if (raw == '0') {
        raw = k == '000' ? '0' : k;
      } else if (raw.isEmpty && k == '000') {
        return;
      } else {
        raw += k;
      }
    });
  }

  void _backspace() => setState(() {
        if (raw.isNotEmpty) raw = raw.substring(0, raw.length - 1);
      });

  void _toggleCurrency() => setState(() {
        currency = currency == 'IQD' ? 'USD' : 'IQD';
        if (currency == 'IQD' && raw.contains('.')) raw = raw.split('.')[0];
      });

  String get _display {
    if (raw.isEmpty) return '0';
    final parts = raw.split('.');
    final intPart = NumberFormat('#,##0', 'en').format(int.tryParse(parts[0]) ?? 0);
    return parts.length > 1 ? '$intPart.${parts[1]}' : intPart;
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => date = d);
  }

  Future<void> _save(List<Category> cats) async {
    final catId = categoryId ?? (cats.isNotEmpty ? cats.first.id : null);
    if (amount <= 0) {
      snack(context, '${S.amount} ${S.required}');
      return;
    }
    if (catId == null) {
      snack(context, '${S.category} ${S.required}');
      return;
    }
    final repo = ref.read(repoProvider);
    final e = widget.existing;
    final tx = Tx(
      id: e?.id ?? 0,
      kind: kind,
      amount: amount,
      currency: currency,
      categoryId: catId,
      date: dateKey(date),
      note: note.text.trim(),
      recurringId: e?.recurringId ?? widget.fromRecurring?.id,
      period: e?.period ?? widget.period,
    );
    if (e != null) {
      await repo.updateTx(tx);
    } else {
      await repo.insertTx(tx);
    }
    ref.bump();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    if (!await confirmDelete(context)) return;
    await ref.read(repoProvider).deleteTx(widget.existing!.id);
    ref.bump();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final isExp = kind == 'expense';
    final allCats = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final cats = allCats
        .where((c) => c.kind == kind && (!c.archived || c.id == categoryId))
        .toList();
    final effectiveCat = categoryId ?? (cats.isNotEmpty ? cats.first.id : null);

    final h = MediaQuery.sizeOf(context).height;
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final height = (h * 0.92 - inset).clamp(320.0, h);
    final showKeypad = !noteFocus.hasFocus;

    final title = widget.existing != null
        ? S.editTx
        : widget.fromRecurring != null
            ? widget.fromRecurring!.name
            : (isExp ? S.newExpense : S.newIncome);

    final today = dateKey(DateTime.now());
    final yesterday = dateKey(DateTime.now().subtract(const Duration(days: 1)));
    final dk = dateKey(date);
    final isOther = dk != today && dk != yesterday;

    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            const SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  if (widget.existing != null)
                    IconButton(
                      onPressed: _delete,
                      icon: Icon(Icons.delete_outline_rounded, color: p.coral),
                    ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.fromRecurring == null && widget.existing == null)
                      KindToggle(
                        value: kind,
                        onChanged: (k) => setState(() {
                          kind = k;
                          categoryId = null;
                        }),
                      ),
                    const SizedBox(height: 22),
                    // Amount
                    GestureDetector(
                      onTap: _toggleCurrency,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _display,
                                style: TextStyle(
                                  fontSize: 46,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.5,
                                  height: 1.1,
                                  fontFeatures: kTabular,
                                  color: raw.isEmpty ? p.muted : (isExp ? p.text : p.mint),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: p.surface2,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: p.outline),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(currency,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                const SizedBox(width: 4),
                                Icon(Icons.swap_horiz_rounded, size: 16, color: p.muted),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(isExp ? S.category : S.source,
                        style: TextStyle(color: p.muted, fontSize: 12.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 88,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: cats.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (_, i) => _CatChip(
                          cats[i],
                          selected: cats[i].id == effectiveCat,
                          onTap: () => setState(() => categoryId = cats[i].id),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Pill(
                          label: S.today,
                          selected: dk == today,
                          onTap: () => setState(() => date = DateTime.now()),
                        ),
                        const SizedBox(width: 8),
                        Pill(
                          label: S.yesterday,
                          selected: dk == yesterday,
                          onTap: () => setState(
                              () => date = DateTime.now().subtract(const Duration(days: 1))),
                        ),
                        const SizedBox(width: 8),
                        Pill(
                          label: isOther ? shortDate(dk) : S.pickDate,
                          icon: Icons.calendar_today_rounded,
                          selected: isOther,
                          onTap: _pickDate,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: note,
                      focusNode: noteFocus,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: S.noteHint,
                        prefixIcon: Icon(Icons.notes_rounded, color: p.muted, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (showKeypad)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Keypad(
                  onKey: _key,
                  onBackspace: _backspace,
                  third: currency == 'USD' ? '.' : '000',
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: FilledButton(
                onPressed: () => _save(cats),
                child: Text(widget.existing != null
                    ? S.save
                    : widget.fromRecurring != null
                        ? S.record
                        : S.add),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final Category c;
  final bool selected;
  final VoidCallback onTap;
  const _CatChip(this.c, {required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final color = Color(c.color);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? color : color.withValues(alpha: 0.14),
                boxShadow: selected
                    ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 5))]
                    : null,
              ),
              child: Icon(catIcon(c.icon), color: selected ? const Color(0xFF14181F) : color, size: 23),
            ),
            const SizedBox(height: 6),
            Text(
              c.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: selected ? p.text : p.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
