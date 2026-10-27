import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../state/providers.dart';
import '../widgets/widgets.dart';
import 'debt_sheet.dart';

/// All loans with one person, added up. Positive balance = I owe them.
class PersonDebts {
  final String person;
  final List<DebtView> debts;
  const PersonDebts(this.person, this.debts);

  /// What is still open, per currency: I owe (+) minus they owe me (−).
  Map<String, double> get balance {
    final out = <String, double>{};
    for (final v in debts) {
      final sign = v.debt.iOwe ? 1 : -1;
      out[v.debt.currency] = (out[v.debt.currency] ?? 0) + sign * v.remaining;
    }
    out.removeWhere((_, v) => v.abs() < 0.005);
    return out;
  }

  bool get settled => debts.every((v) => v.settled);

  String? get nextDue {
    final dues = [
      for (final v in debts)
        if (!v.settled && v.debt.dueDate != null) v.debt.dueDate!
    ]..sort();
    return dues.isEmpty ? null : dues.first;
  }
}

List<PersonDebts> groupByPerson(List<DebtView> list) {
  final groups = <String, List<DebtView>>{};
  final names = <String, String>{};
  for (final v in list) {
    final key = v.debt.person.trim().toLowerCase();
    names.putIfAbsent(key, () => v.debt.person.trim());
    groups.putIfAbsent(key, () => []).add(v);
  }
  final out = [for (final e in groups.entries) PersonDebts(names[e.key]!, e.value)];
  out.sort((a, b) => a.settled == b.settled ? 0 : (a.settled ? 1 : -1));
  return out;
}

class DebtsTab extends ConsumerWidget {
  const DebtsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.p;
    final s = ref.watch(settingsProvider);
    final debts = ref.watch(debtsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        debts.when(
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(
                icon: Icons.handshake_outlined,
                title: S.noDebts,
                subtitle: S.noDebtsHint,
              );
            }
            final people = groupByPerson(list);
            // Totals across people use each person's net balance, so a
            // person I both owe and lent to is counted once, on one side.
            final owe = <String, double>{}, lent = <String, double>{};
            for (final pd in people) {
              for (final e in pd.balance.entries) {
                final cur = s.mergeCurrencies ? s.baseCurrency : e.key;
                final v = s.mergeCurrencies ? s.toBase(e.value, e.key) : e.value;
                if (v > 0) {
                  owe[cur] = (owe[cur] ?? 0) + v;
                } else {
                  lent[cur] = (lent[cur] ?? 0) - v;
                }
              }
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SoftCard(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      _Total(S.iOwe, moneyMulti(owe, fallback: s.baseCurrency), p.coral),
                      Container(width: 1, height: 36, color: p.outline),
                      const SizedBox(width: 16),
                      _Total(S.owedToMe, moneyMulti(lent, fallback: s.baseCurrency), p.mint),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (final pd in people)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PersonCard(pd),
                  ),
              ],
            );
          },
          loading: () => const SizedBox(height: 120),
          error: (e, _) => Text('$e'),
        ),
      ],
    );
  }
}

class _Total extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Total(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: context.p.muted, fontSize: 12)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(value,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w800, fontSize: 17, fontFeatures: kTabular)),
          ),
        ],
      ),
    );
  }
}

/// "I owe 300,000 د.ع" / "owes me $150" / "settled" for a balance map.
Widget balanceText(BuildContext context, Map<String, double> bal, {double size = 15}) {
  final p = context.p;
  if (bal.isEmpty) {
    return Text(S.even, style: TextStyle(color: p.mint, fontWeight: FontWeight.w800, fontSize: size));
  }
  final iOwe = {for (final e in bal.entries) if (e.value > 0) e.key: e.value};
  final theyOwe = {for (final e in bal.entries) if (e.value < 0) e.key: -e.value};
  return Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      if (iOwe.isNotEmpty)
        Text('${S.iOweThem} ${moneyMulti(iOwe)}',
            style: TextStyle(
                color: p.coral, fontWeight: FontWeight.w800, fontSize: size, fontFeatures: kTabular)),
      if (theyOwe.isNotEmpty)
        Text('${S.theyOweMe} ${moneyMulti(theyOwe)}',
            style: TextStyle(
                color: p.mint, fontWeight: FontWeight.w800, fontSize: size, fontFeatures: kTabular)),
    ],
  );
}

class _PersonCard extends StatelessWidget {
  final PersonDebts pd;
  const _PersonCard(this.pd);

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final bal = pd.balance;
    final iOweMore = bal.values.fold(0.0, (a, b) => a + b) > 0;
    final color = bal.isEmpty ? p.mint : (iOweMore ? p.coral : p.mint);
    final due = pd.nextDue;
    final overdue = due != null && due.compareTo(dateKey(DateTime.now())) < 0;
    final initial = pd.person.isEmpty ? '?' : pd.person.characters.first;

    return Opacity(
      opacity: pd.settled ? 0.6 : 1,
      child: SoftCard(
        onTap: () => pd.debts.length == 1
            ? showDebtDetail(context, pd.debts.first.debt.id)
            : showPersonDebts(context, pd.person),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.16), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(initial,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pd.person, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(S.loansCount(pd.debts.length),
                          style: TextStyle(color: p.muted, fontSize: 12.5)),
                      if (overdue) ...[
                        const SizedBox(width: 6),
                        StatusChip(S.overdue, p.coral),
                      ] else if (due != null && !pd.settled) ...[
                        const SizedBox(width: 6),
                        Text('· ${shortDate(due)}', style: TextStyle(color: p.muted, fontSize: 12)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (pd.settled) StatusChip(S.settled, p.mint) else balanceText(context, bal, size: 14),
          ],
        ),
      ),
    );
  }
}

Future<void> showPersonDebts(BuildContext context, String person) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _PersonSheet(person: person),
    );

/// Every loan with one person, their net balance, and shortcuts to add more.
class _PersonSheet extends ConsumerWidget {
  final String person;
  const _PersonSheet({required this.person});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.p;
    final list = ref.watch(debtsProvider).valueOrNull ?? const <DebtView>[];
    final pd = groupByPerson(list)
        .where((x) => x.person.toLowerCase() == person.trim().toLowerCase())
        .firstOrNull;
    if (pd == null) return const SizedBox(height: 200);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHandle(),
          Row(
            children: [
              Expanded(
                child: Text(pd.person,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SoftCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(S.net, style: TextStyle(color: p.muted, fontSize: 13)),
                const Spacer(),
                balanceText(context, pd.balance, size: 17),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showDebtSheet(context, person: pd.person, direction: 'owe'),
                  icon: Icon(Icons.call_made_rounded, color: p.coral, size: 18),
                  label: Text(S.borrowAgain, style: TextStyle(color: p.text)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showDebtSheet(context, person: pd.person, direction: 'lent'),
                  icon: Icon(Icons.call_received_rounded, color: p.mint, size: 18),
                  label: Text(S.lendAgain, style: TextStyle(color: p.text)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final v in pd.debts)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LoanRow(v),
            ),
        ],
      ),
    );
  }
}

class _LoanRow extends StatelessWidget {
  final DebtView v;
  const _LoanRow(this.v);

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final d = v.debt;
    final color = d.iOwe ? p.coral : p.mint;
    return Opacity(
      opacity: v.settled ? 0.6 : 1,
      child: SoftCard(
        onTap: () => showDebtDetail(context, d.id),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleIcon(d.iOwe ? Icons.call_made_rounded : Icons.call_received_rounded, color,
                    size: 38),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${d.iOwe ? S.iOweShort : S.lentShort} · ${money(d.amount, d.currency)}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                      Text(dateLabel(d.date) + (d.note.isEmpty ? '' : ' · ${d.note}'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: p.muted, fontSize: 12)),
                    ],
                  ),
                ),
                if (v.settled)
                  StatusChip(S.settled, p.mint)
                else
                  Text(money(v.remaining, d.currency),
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.w800, fontFeatures: kTabular)),
              ],
            ),
            if (!v.settled && v.paid > 0) ...[
              const SizedBox(height: 10),
              ProgressLine(v.paid / d.amount, color),
            ],
          ],
        ),
      ),
    );
  }
}
