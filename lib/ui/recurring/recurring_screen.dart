import 'dart:math' as math;

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
import 'recurring_sheet.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.p;
    final s = ref.watch(settingsProvider);
    final recs = ref.watch(recurringsProvider);
    final paid = ref.watch(paidPeriodsProvider).valueOrNull ?? const <int, List<String>>{};
    final cats = ref.watch(categoryMapProvider);
    final month = ref.watch(selectedMonthProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            Row(
              children: [
                Text(S.recurring,
                    style: context.tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const Spacer(),
                const MonthPill(),
                const SizedBox(width: 8),
                RoundIconButton(Icons.add_rounded, onTap: () => showRecurringSheet(context)),
              ],
            ),
            const SizedBox(height: 6),
            Text(S.recurringHelp, style: TextStyle(color: p.muted, fontSize: 12.5)),
            const SizedBox(height: 18),
            recs.when(
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                    icon: Icons.event_repeat_rounded,
                    title: S.noRecurring,
                    subtitle: S.noRecurringHint,
                  );
                }
                final fixedExp = list
                    .where((r) => r.isExpense && r.coversMonth(month))
                    .fold(0.0, (a, r) => a + s.toBase(r.amount, r.currency));
                final fixedInc = list
                    .where((r) => !r.isExpense && r.coversMonth(month))
                    .fold(0.0, (a, r) => a + s.toBase(r.amount, r.currency));
                return Column(
                  children: [
                    _TotalsCard(fixedExp, fixedInc, s.baseCurrency),
                    const SizedBox(height: 16),
                    for (final r in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RecurringCard(
                          r: r,
                          cat: cats[r.categoryId],
                          paid: paid[r.id] ?? const [],
                          month: month,
                        ),
                      ),
                  ],
                );
              },
              loading: () => const SizedBox(height: 120),
              error: (e, _) => Text('$e'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final double exp, inc;
  final String cur;
  const _TotalsCard(this.exp, this.inc, this.cur);

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    Widget col(String label, double v, Color c) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: p.muted, fontSize: 12)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(money(v, cur),
                    style: TextStyle(
                        color: c, fontWeight: FontWeight.w800, fontSize: 17, fontFeatures: kTabular)),
              ),
            ],
          ),
        );
    return SoftCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          col('${S.expense} جێگیر · ${S.month}', exp, p.coral),
          Container(width: 1, height: 36, color: p.outline),
          const SizedBox(width: 16),
          col('${S.income} جێگیر · ${S.month}', inc, p.mint),
        ],
      ),
    );
  }
}

class _RecurringCard extends StatelessWidget {
  final Recurring r;
  final Category? cat;
  final List<String> paid;
  final String month;
  const _RecurringCard({required this.r, required this.cat, required this.paid, required this.month});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final color = Color(cat?.color ?? 0xFF8A93A3);
    final isPaid = paid.contains(month);
    final covers = r.coversMonth(month);
    final total = r.totalInstallments;
    final paidCount = paid.length;
    final remainingCount = total == null ? null : math.max(0, total - paidCount);

    return SoftCard(
      onTap: () => showRecurringSheet(context, existing: r),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleIcon(catIcon(cat?.icon ?? 'more'), color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      '${money(r.amount, r.currency)} · ${S.dayOfMonth} ${r.dayOfMonth}',
                      style: TextStyle(color: p.muted, fontSize: 12.5, fontFeatures: kTabular),
                    ),
                  ],
                ),
              ),
              if (covers)
                StatusChip(isPaid ? S.paid : S.due, isPaid ? p.mint : p.gold)
              else
                StatusChip(r.isExpense ? S.expense : S.income, p.muted),
            ],
          ),
          const SizedBox(height: 14),
          if (total != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : (paidCount / total).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: p.surface2,
                color: p.gold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('$paidCount / $total ${S.installment}',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, fontFeatures: kTabular)),
                const Spacer(),
                Text('${S.remaining}: ${money(remainingCount! * r.amount, r.currency)}',
                    style: TextStyle(color: p.muted, fontSize: 12.5, fontFeatures: kTabular)),
              ],
            ),
            const SizedBox(height: 4),
            Text('${monthLabel(r.startMonth)}  تا  ${monthLabel(r.endMonth!)}',
                style: TextStyle(color: p.muted, fontSize: 11.5)),
          ] else
            Row(
              children: [
                Icon(Icons.all_inclusive_rounded, size: 14, color: p.muted),
                const SizedBox(width: 6),
                Text('${S.ongoing} · لە ${monthLabel(r.startMonth)}',
                    style: TextStyle(color: p.muted, fontSize: 12)),
              ],
            ),
        ],
      ),
    );
  }
}
