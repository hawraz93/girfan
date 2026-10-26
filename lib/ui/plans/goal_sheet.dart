import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/icons.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../widgets/month_picker.dart';
import '../widgets/widgets.dart';

Future<void> showGoalSheet(BuildContext context, {Goal? existing}) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => GoalSheet(existing: existing),
    );

Future<void> showGoalDetail(BuildContext context, int goalId) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => GoalDetailSheet(goalId: goalId),
    );

/// Create or edit a saving goal.
class GoalSheet extends ConsumerStatefulWidget {
  final Goal? existing;
  const GoalSheet({super.key, this.existing});

  @override
  ConsumerState<GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends ConsumerState<GoalSheet> {
  final name = TextEditingController();
  final target = TextEditingController();
  final note = TextEditingController();
  late String currency;
  String icon = 'phone';
  int color = kCatColors[5];
  String? deadline;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      name.text = e.name;
      target.text = moneyNumber(e.target, e.currency);
      note.text = e.note;
      currency = e.currency;
      icon = e.icon;
      color = e.color;
      deadline = e.deadline;
    } else {
      currency = ref.read(settingsProvider).baseCurrency;
    }
  }

  @override
  void dispose() {
    name.dispose();
    target.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = parseAmount(target.text);
    if (name.text.trim().isEmpty) return snack(context, '${S.name} ${S.required}');
    if (t <= 0) return snack(context, '${S.target} ${S.required}');
    final g = Goal(
      id: widget.existing?.id ?? 0,
      name: name.text.trim(),
      icon: icon,
      color: color,
      target: t,
      currency: currency,
      deadline: deadline,
      note: note.text.trim(),
    );
    final repo = ref.read(repoProvider);
    if (widget.existing != null) {
      await repo.updateGoal(g);
    } else {
      await repo.insertGoal(g);
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
                  child: Text(widget.existing != null ? S.editGoal : S.newGoal,
                      style: context.tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(child: CircleIcon(catIcon(icon), Color(color), size: 64, filled: true)),
            const SizedBox(height: 16),
            TextField(
              controller: name,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: S.name,
                hintText: S.goalNameHint,
                prefixIcon: Icon(Icons.label_outline_rounded, color: p.muted, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            AmountField(
              controller: target,
              currency: currency,
              label: S.target,
              onToggleCurrency: () =>
                  setState(() => currency = currency == 'IQD' ? 'USD' : 'IQD'),
            ),
            const SizedBox(height: 12),
            PickerField(
              icon: Icons.flag_rounded,
              label: S.deadline,
              value: deadline == null ? S.noDeadline : monthLabel(deadline!),
              onTap: () async {
                final m = await showMonthPicker(context, deadline ?? addMonths(currentMonth(), 3));
                if (m != null) setState(() => deadline = m);
              },
              onClear: deadline == null ? null : () => setState(() => deadline = null),
            ),
            const SizedBox(height: 16),
            Text(S.icon, style: TextStyle(color: p.muted, fontSize: 12.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final k in kGoalIcons)
                  GestureDetector(
                    onTap: () => setState(() => icon = k),
                    child: CircleIcon(catIcon(k), k == icon ? Color(color) : p.muted,
                        size: 46, filled: k == icon),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(S.color, style: TextStyle(color: p.muted, fontSize: 12.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final c in kCatColors)
                  GestureDetector(
                    onTap: () => setState(() => color = c),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: c == color ? p.text : Colors.transparent, width: 2.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
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

/// One goal: progress, monthly plan, deposits and withdrawals.
class GoalDetailSheet extends ConsumerStatefulWidget {
  final int goalId;
  const GoalDetailSheet({super.key, required this.goalId});

  @override
  ConsumerState<GoalDetailSheet> createState() => _GoalDetailSheetState();
}

class _GoalDetailSheetState extends ConsumerState<GoalDetailSheet> {
  final amount = TextEditingController();
  bool withdraw = false;

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  Future<void> _add(GoalView v) async {
    var a = parseAmount(amount.text);
    if (a <= 0) return snack(context, '${S.amount} ${S.required}');
    if (withdraw && a > v.saved) a = v.saved;
    if (a <= 0) return;
    await ref.read(repoProvider).insertGoalDeposit(GoalDeposit(
          id: 0,
          goalId: v.goal.id,
          amount: withdraw ? -a : a,
          date: dateKey(DateTime.now()),
        ));
    amount.clear();
    if (mounted) FocusScope.of(context).unfocus();
    ref.bump();
  }

  Future<void> _delete(Goal g) async {
    if (!await confirmDelete(context)) return;
    await ref.read(repoProvider).deleteGoal(g.id);
    ref.bump();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final list = ref.watch(goalsProvider).valueOrNull ?? const <GoalView>[];
    final v = list.where((x) => x.goal.id == widget.goalId).firstOrNull;
    if (v == null) return const SizedBox(height: 200);
    final g = v.goal;
    final color = Color(g.color);
    final perMonth = v.perMonthNeeded(currentMonth());

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
                CircleIcon(catIcon(g.icon), color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(g.name,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                ),
                IconButton(
                  onPressed: () => showGoalSheet(context, existing: g),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  onPressed: () => _delete(g),
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
                  Text(S.savedSoFar, style: TextStyle(color: p.muted, fontSize: 12)),
                  Text(money(v.saved, g.currency),
                      style: TextStyle(
                          color: color, fontSize: 26, fontWeight: FontWeight.w800, fontFeatures: kTabular)),
                  const SizedBox(height: 10),
                  ProgressLine(v.progress, color),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('${(v.progress * 100).round()}٪',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: kTabular)),
                      const Spacer(),
                      Text('${S.target}: ${money(g.target, g.currency)}',
                          style: TextStyle(color: p.muted, fontSize: 12.5, fontFeatures: kTabular)),
                    ],
                  ),
                  if (v.reached) ...[
                    const SizedBox(height: 8),
                    Text(S.reached, style: TextStyle(color: p.mint, fontWeight: FontWeight.w700)),
                  ] else ...[
                    const SizedBox(height: 6),
                    Text('${S.remaining}: ${money(v.remaining, g.currency)}',
                        style: TextStyle(color: p.muted, fontSize: 12.5, fontFeatures: kTabular)),
                    if (perMonth != null)
                      Text(
                        '${S.perMonth}: ${money(perMonth, g.currency)} · تا ${monthLabel(g.deadline!)}',
                        style: TextStyle(color: p.accent, fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            SegmentTabs(
              labels: const [S.deposit, S.withdraw],
              index: withdraw ? 1 : 0,
              colors: [p.mint, p.coral],
              onChanged: (i) => setState(() => withdraw = i == 1),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AmountField(
                    controller: amount,
                    currency: g.currency,
                    onToggleCurrency: () {},
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size(90, 52)),
                    onPressed: () => _add(v),
                    child: const Text(S.add),
                  ),
                ),
              ],
            ),
            if (perMonth != null && !withdraw) ...[
              const SizedBox(height: 8),
              Wrap(
                children: [
                  Pill(
                    label: '${S.perMonth}: ${moneyNumber(perMonth, g.currency)}',
                    onTap: () => amount.text = moneyNumber(perMonth, g.currency),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(S.goalsAffectBalance, style: TextStyle(color: p.muted, fontSize: 11.5)),
            if (v.deposits.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(S.history, style: context.tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              for (final d in v.deposits)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    d.amount >= 0 ? Icons.add_circle_rounded : Icons.remove_circle_rounded,
                    color: d.amount >= 0 ? p.mint : p.coral,
                  ),
                  title: Text(money(d.amount.abs(), g.currency),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: kTabular)),
                  subtitle: Text(dateLabel(d.date)),
                  trailing: IconButton(
                    icon: Icon(Icons.close_rounded, color: p.muted, size: 20),
                    onPressed: () async {
                      if (!await confirmDelete(context)) return;
                      await ref.read(repoProvider).deleteGoalDeposit(d.id);
                      ref.bump();
                    },
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
