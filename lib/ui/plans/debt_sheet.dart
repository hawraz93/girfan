import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../widgets/day_picker.dart';
import '../widgets/widgets.dart';

Future<void> showDebtSheet(BuildContext context,
        {Debt? existing, String? person, String? direction}) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DebtSheet(existing: existing, person: person, direction: direction),
    );

Future<void> showDebtDetail(BuildContext context, int debtId) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DebtDetailSheet(debtId: debtId),
    );

Future<DateTime?> _pickDay(BuildContext context, DateTime initial) =>
    showDayPicker(context, initial: initial);

/// Create or edit a debt.
class DebtSheet extends ConsumerStatefulWidget {
  final Debt? existing;

  /// Pre-filled when adding another loan for someone already in the list.
  final String? person;
  final String? direction;
  const DebtSheet({super.key, this.existing, this.person, this.direction});

  @override
  ConsumerState<DebtSheet> createState() => _DebtSheetState();
}

class _DebtSheetState extends ConsumerState<DebtSheet> {
  final person = TextEditingController();
  final amount = TextEditingController();
  final note = TextEditingController();
  String direction = 'owe';
  late String currency;
  late DateTime date;
  DateTime? due;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      person.text = e.person;
      amount.text = moneyNumber(e.amount, e.currency);
      note.text = e.note;
      direction = e.direction;
      currency = e.currency;
      date = dateFromKey(e.date);
      due = e.dueDate == null ? null : dateFromKey(e.dueDate!);
    } else {
      currency = ref.read(settingsProvider).baseCurrency;
      date = DateTime.now();
      person.text = widget.person ?? '';
      direction = widget.direction ?? 'owe';
    }
  }

  @override
  void dispose() {
    person.dispose();
    amount.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final a = parseAmount(amount.text);
    if (person.text.trim().isEmpty) return snack(context, '${S.person} ${S.required}');
    if (a <= 0) return snack(context, '${S.amount} ${S.required}');
    final d = Debt(
      id: widget.existing?.id ?? 0,
      person: person.text.trim(),
      direction: direction,
      amount: a,
      currency: currency,
      date: dateKey(date),
      dueDate: due == null ? null : dateKey(due!),
      note: note.text.trim(),
    );
    final repo = ref.read(repoProvider);
    if (widget.existing != null) {
      await repo.updateDebt(d);
    } else {
      await repo.insertDebt(d);
    }
    ref.bump();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            Row(
              children: [
                Expanded(
                  child: Text(widget.existing != null ? S.editDebt : S.newDebt,
                      style: context.tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SegmentTabs(
              labels: const [S.iOweShort, S.lentShort],
              index: direction == 'owe' ? 0 : 1,
              colors: [p.coral, p.mint],
              onChanged: (i) => setState(() => direction = i == 0 ? 'owe' : 'lent'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: person,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: S.person,
                hintText: S.personHint,
                prefixIcon: Icon(Icons.person_outline_rounded, color: p.muted, size: 20),
              ),
            ),
            // Names already used, so the same person is spelled the same way
            // and their loans add up together.
            Builder(builder: (_) {
              final typed = person.text.trim();
              final names = {
                for (final v in ref.watch(debtsProvider).valueOrNull ?? const <DebtView>[])
                  v.debt.person.trim()
              }.where((n) => n != typed && (typed.isEmpty || n.contains(typed))).take(6).toList();
              if (names.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final n in names)
                      Pill(
                        icon: Icons.person_rounded,
                        label: n,
                        onTap: () => setState(() => person.text = n),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            AmountField(
              controller: amount,
              currency: currency,
              onToggleCurrency: () =>
                  setState(() => currency = currency == 'IQD' ? 'USD' : 'IQD'),
            ),
            const SizedBox(height: 12),
            PickerField(
              icon: Icons.event_rounded,
              label: S.date,
              value: dateLabel(dateKey(date)),
              onTap: () async {
                final d = await _pickDay(context, date);
                if (d != null) setState(() => date = d);
              },
            ),
            const SizedBox(height: 12),
            PickerField(
              icon: Icons.alarm_rounded,
              label: S.dueDate,
              value: due == null ? S.noDueDate : dateLabel(dateKey(due!)),
              onTap: () async {
                final d = await _pickDay(context, due ?? DateTime.now().add(const Duration(days: 30)));
                if (d != null) setState(() => due = d);
              },
              onClear: due == null ? null : () => setState(() => due = null),
            ),
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
              onPressed: _save,
              child: Text(widget.existing != null ? S.save : S.add),
            ),
          ],
        ),
      ),
    );
  }
}

/// One debt: what is left, its repayments, and a quick way to add one.
class DebtDetailSheet extends ConsumerStatefulWidget {
  final int debtId;
  const DebtDetailSheet({super.key, required this.debtId});

  @override
  ConsumerState<DebtDetailSheet> createState() => _DebtDetailSheetState();
}

class _DebtDetailSheetState extends ConsumerState<DebtDetailSheet> {
  final amount = TextEditingController();

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  Future<void> _addPayment(DebtView v) async {
    final a = parseAmount(amount.text);
    if (a <= 0) return snack(context, '${S.amount} ${S.required}');
    await ref.read(repoProvider).insertDebtPayment(DebtPayment(
          id: 0,
          debtId: v.debt.id,
          amount: a > v.remaining ? v.remaining : a,
          date: dateKey(DateTime.now()),
        ));
    amount.clear();
    if (mounted) FocusScope.of(context).unfocus();
    ref.bump();
  }

  Future<void> _delete(Debt d) async {
    if (!await confirmDelete(context)) return;
    await ref.read(repoProvider).deleteDebt(d.id);
    ref.bump();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final list = ref.watch(debtsProvider).valueOrNull ?? const <DebtView>[];
    final v = list.where((x) => x.debt.id == widget.debtId).firstOrNull;
    if (v == null) return const SizedBox(height: 200);
    final d = v.debt;
    final color = d.iOwe ? p.coral : p.mint;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            Row(
              children: [
                CircleIcon(d.iOwe ? Icons.call_made_rounded : Icons.call_received_rounded, color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.person,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                      Text(d.iOwe ? S.iOwe : S.owedToMe,
                          style: TextStyle(color: p.muted, fontSize: 12.5)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => showDebtSheet(context, existing: d),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  onPressed: () => _delete(d),
                  icon: Icon(Icons.delete_outline_rounded, color: p.coral),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SoftCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(S.remaining, style: TextStyle(color: p.muted, fontSize: 12)),
                  Text(money(v.remaining, d.currency),
                      style: TextStyle(
                          color: v.settled ? p.mint : color,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          fontFeatures: kTabular)),
                  const SizedBox(height: 10),
                  ProgressLine(d.amount <= 0 ? 0 : v.paid / d.amount, p.mint),
                  const SizedBox(height: 8),
                  Text(
                    '${money(v.paid, d.currency)} / ${money(d.amount, d.currency)}',
                    style: TextStyle(color: p.muted, fontSize: 12.5, fontFeatures: kTabular),
                  ),
                  if (d.dueDate != null) ...[
                    const SizedBox(height: 4),
                    Text('${S.dueDate}: ${dateLabel(d.dueDate!)}',
                        style: TextStyle(color: p.muted, fontSize: 12.5)),
                  ],
                  if (d.note.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(d.note, style: TextStyle(color: p.muted, fontSize: 12.5)),
                  ],
                ],
              ),
            ),
            if (!v.settled) ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AmountField(
                      controller: amount,
                      currency: d.currency,
                      label: d.iOwe ? S.payBack : S.receivePayment,
                      onToggleCurrency: () {},
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size(90, 52)),
                      onPressed: () => _addPayment(v),
                      child: const Text(S.add),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Pill(
                    label: '${S.total}: ${moneyNumber(v.remaining, d.currency)}',
                    onTap: () => amount.text = moneyNumber(v.remaining, d.currency),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            if (v.payments.isNotEmpty) ...[
              Text(S.payments,
                  style: context.tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final pay in v.payments)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.check_circle_rounded, color: p.mint),
                  title: Text(money(pay.amount, d.currency),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: kTabular)),
                  subtitle: Text(dateLabel(pay.date)),
                  trailing: IconButton(
                    icon: Icon(Icons.close_rounded, color: p.muted, size: 20),
                    onPressed: () async {
                      if (!await confirmDelete(context)) return;
                      await ref.read(repoProvider).deleteDebtPayment(pay.id);
                      ref.bump();
                    },
                  ),
                ),
            ],
            const SizedBox(height: 8),
            Text(S.debtsSeparate, style: TextStyle(color: p.muted, fontSize: 11.5)),
          ],
        ),
      ),
    );
  }
}
