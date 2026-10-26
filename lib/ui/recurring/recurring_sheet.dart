import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/icons.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../widgets/month_picker.dart';
import '../widgets/widgets.dart';

Future<void> showRecurringSheet(BuildContext context, {Recurring? existing}) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => RecurringSheet(existing: existing),
    );

class RecurringSheet extends ConsumerStatefulWidget {
  final Recurring? existing;
  const RecurringSheet({super.key, this.existing});
  @override
  ConsumerState<RecurringSheet> createState() => _RecurringSheetState();
}

class _RecurringSheetState extends ConsumerState<RecurringSheet> {
  late String kind;
  late String currency;
  final name = TextEditingController();
  final amount = TextEditingController();
  final day = TextEditingController();
  final note = TextEditingController();
  int? categoryId;
  late String startMonth;
  bool hasEnd = false;
  late String endMonth;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    final e = widget.existing;
    if (e != null) {
      kind = e.kind;
      currency = e.currency;
      name.text = e.name;
      amount.text = moneyNumber(e.amount, e.currency).replaceAll(',', '');
      day.text = '${e.dayOfMonth}';
      note.text = e.note;
      categoryId = e.categoryId;
      startMonth = e.startMonth;
      hasEnd = e.endMonth != null;
      endMonth = e.endMonth ?? addMonths(e.startMonth, 11);
    } else {
      kind = 'expense';
      currency = s.baseCurrency;
      day.text = '1';
      startMonth = currentMonth();
      endMonth = addMonths(startMonth, 11);
    }
  }

  @override
  void dispose() {
    name.dispose();
    amount.dispose();
    day.dispose();
    note.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(amount.text.replaceAll(',', '')) ?? 0;

  Future<void> _save(List<Category> cats) async {
    final catId = categoryId ?? (cats.isNotEmpty ? cats.first.id : null);
    final d = int.tryParse(day.text) ?? 0;
    if (name.text.trim().isEmpty) return snack(context, '${S.name} ${S.required}');
    if (_amount <= 0) return snack(context, '${S.amount} ${S.required}');
    if (d < 1 || d > 31) return snack(context, '${S.dayOfMonth}: 1 - 31');
    if (catId == null) return snack(context, '${S.category} ${S.required}');
    if (hasEnd && endMonth.compareTo(startMonth) < 0) {
      return snack(context, '${S.endMonth} پێش ${S.startMonth} نابێت');
    }
    final r = Recurring(
      id: widget.existing?.id ?? 0,
      name: name.text.trim(),
      amount: _amount,
      currency: currency,
      categoryId: catId,
      kind: kind,
      dayOfMonth: d,
      startMonth: startMonth,
      endMonth: hasEnd ? endMonth : null,
      note: note.text.trim(),
    );
    final repo = ref.read(repoProvider);
    if (widget.existing != null) {
      await repo.updateRecurring(r);
    } else {
      await repo.insertRecurring(r);
    }
    ref.bump();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    if (!await confirmDelete(context)) return;
    await ref.read(repoProvider).deleteRecurring(widget.existing!.id);
    ref.bump();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final s = ref.watch(settingsProvider);
    final allCats = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final cats = allCats.where((c) => c.kind == kind && (!c.archived || c.id == categoryId)).toList();
    final effectiveCat = categoryId ?? (cats.isNotEmpty ? cats.first.id : null);
    final n = hasEnd ? monthsBetween(startMonth, endMonth) : 0;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            Row(
              children: [
                Expanded(
                  child: Text(widget.existing != null ? S.editRecurring : S.newRecurring,
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
            const SizedBox(height: 8),
            KindToggle(
              value: kind,
              onChanged: (k) => setState(() {
                kind = k;
                categoryId = null;
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: name,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: kind == 'expense' ? 'بۆ نموونە: کرێی خانوو' : 'بۆ نموونە: موچە',
                labelText: S.name,
                prefixIcon: Icon(Icons.label_outline_rounded, color: p.muted, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    style: const TextStyle(fontFeatures: kTabular, fontWeight: FontWeight.w700),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: S.amount,
                      suffixIcon: TextButton(
                        onPressed: () => setState(
                            () => currency = currency == 'IQD' ? 'USD' : 'IQD'),
                        child: Text(currency,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: day,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    style: const TextStyle(fontFeatures: kTabular, fontWeight: FontWeight.w700),
                    decoration: const InputDecoration(labelText: S.dayOfMonth),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(kind == 'expense' ? S.category : S.source,
                style: TextStyle(color: p.muted, fontSize: 12.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in cats)
                  _CatPill(
                    c,
                    selected: c.id == effectiveCat,
                    onTap: () => setState(() => categoryId = c.id),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _MonthField(
              label: S.startMonth,
              value: startMonth,
              onTap: () async {
                final r = await showMonthPicker(context, startMonth);
                if (r != null) setState(() => startMonth = r);
              },
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(16)),
              child: SwitchListTile(
                value: hasEnd,
                onChanged: (v) => setState(() => hasEnd = v),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text(S.hasEnd, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
            if (hasEnd) ...[
              const SizedBox(height: 12),
              _MonthField(
                label: S.endMonth,
                value: endMonth,
                onTap: () async {
                  final r = await showMonthPicker(context, endMonth);
                  if (r != null) setState(() => endMonth = r);
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: p.muted),
                  const SizedBox(width: 6),
                  Text(
                    '$n ${S.installment} · ${S.total} ${money(n * _amount, currency)}',
                    style: TextStyle(color: p.muted, fontSize: 12, fontFeatures: kTabular),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: note,
              decoration: InputDecoration(
                hintText: S.noteHint,
                prefixIcon: Icon(Icons.notes_rounded, color: p.muted, size: 20),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => _save(cats),
              child: Text(widget.existing != null ? S.save : S.add),
            ),
            if (currency != s.baseCurrency)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '≈ ${money(s.toBase(_amount, currency), s.baseCurrency)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.muted, fontSize: 12, fontFeatures: kTabular),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CatPill extends StatelessWidget {
  final Category c;
  final bool selected;
  final VoidCallback onTap;
  const _CatPill(this.c, {required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final color = Color(c.color);
    return Material(
      color: selected ? color : p.surface2,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(catIcon(c.icon), size: 16, color: selected ? const Color(0xFF14181F) : color),
              const SizedBox(width: 6),
              Text(c.name,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? const Color(0xFF14181F) : p.text,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthField extends StatelessWidget {
  final String label, value;
  final VoidCallback onTap;
  const _MonthField({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Material(
      color: p.surface2,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: p.accent, size: 20),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: p.muted, fontSize: 11)),
                  Text(monthLabel(value),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ],
              ),
              const Spacer(),
              Icon(Icons.expand_more_rounded, color: p.muted),
            ],
          ),
        ),
      ),
    );
  }
}
