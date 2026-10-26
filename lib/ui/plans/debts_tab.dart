import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../state/providers.dart';
import '../widgets/widgets.dart';
import 'debt_sheet.dart';

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
            double owe = 0, lent = 0;
            for (final v in list) {
              final r = s.toBase(v.remaining, v.debt.currency);
              if (v.debt.iOwe) {
                owe += r;
              } else {
                lent += r;
              }
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SoftCard(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      _Total(S.iOwe, owe, s.baseCurrency, p.coral),
                      Container(width: 1, height: 36, color: p.outline),
                      const SizedBox(width: 16),
                      _Total(S.owedToMe, lent, s.baseCurrency, p.mint),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (final v in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DebtCard(v),
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
  final String label;
  final double value;
  final String cur;
  final Color color;
  const _Total(this.label, this.value, this.cur, this.color);

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
            child: Text(money(value, cur),
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w800, fontSize: 17, fontFeatures: kTabular)),
          ),
        ],
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  final DebtView v;
  const _DebtCard(this.v);

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final d = v.debt;
    final color = d.iOwe ? p.coral : p.mint;
    final overdue = !v.settled && d.dueDate != null && d.dueDate!.compareTo(dateKey(DateTime.now())) < 0;

    return Opacity(
      opacity: v.settled ? 0.6 : 1,
      child: SoftCard(
        onTap: () => showDebtDetail(context, d.id),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleIcon(d.iOwe ? Icons.call_made_rounded : Icons.call_received_rounded, color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.person, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(
                        d.iOwe ? S.iOweShort : S.lentShort,
                        style: TextStyle(color: p.muted, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(money(v.remaining, d.currency),
                        style: TextStyle(
                            color: v.settled ? p.muted : color,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            fontFeatures: kTabular)),
                    const SizedBox(height: 4),
                    if (v.settled)
                      StatusChip(S.settled, p.mint)
                    else if (overdue)
                      StatusChip(S.overdue, p.coral)
                    else if (d.dueDate != null)
                      Text(shortDate(d.dueDate!), style: TextStyle(color: p.muted, fontSize: 11.5)),
                  ],
                ),
              ],
            ),
            if (!v.settled && v.paid > 0) ...[
              const SizedBox(height: 12),
              ProgressLine(v.paid / d.amount, color),
            ],
          ],
        ),
      ),
    );
  }
}
