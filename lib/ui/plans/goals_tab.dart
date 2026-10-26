import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/icons.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../state/providers.dart';
import '../widgets/widgets.dart';
import 'goal_sheet.dart';

class GoalsTab extends ConsumerWidget {
  const GoalsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.p;
    final s = ref.watch(settingsProvider);
    final goals = ref.watch(goalsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        goals.when(
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(
                icon: Icons.savings_outlined,
                title: S.noGoals,
                subtitle: S.noGoalsHint,
              );
            }
            final saved = list.fold(0.0, (a, v) => a + s.toBase(v.saved, v.goal.currency));
            final target = list.fold(0.0, (a, v) => a + s.toBase(v.goal.target, v.goal.currency));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SoftCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.savedSoFar, style: TextStyle(color: p.muted, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(money(saved, s.baseCurrency),
                          style: TextStyle(
                              color: p.accent,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              fontFeatures: kTabular)),
                      const SizedBox(height: 10),
                      ProgressLine(target <= 0 ? 0 : saved / target, p.accent),
                      const SizedBox(height: 6),
                      Text('${S.target}: ${money(target, s.baseCurrency)}',
                          style: TextStyle(color: p.muted, fontSize: 12, fontFeatures: kTabular)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (final v in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _GoalCard(v),
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

class _GoalCard extends StatelessWidget {
  final GoalView v;
  const _GoalCard(this.v);

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final g = v.goal;
    final color = Color(g.color);
    final perMonth = v.perMonthNeeded(currentMonth());

    return SoftCard(
      onTap: () => showGoalDetail(context, g.id),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleIcon(catIcon(g.icon), color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      '${money(v.saved, g.currency)} / ${money(g.target, g.currency)}',
                      style: TextStyle(color: p.muted, fontSize: 12.5, fontFeatures: kTabular),
                    ),
                  ],
                ),
              ),
              if (v.reached)
                StatusChip(S.reached, p.mint)
              else
                Text('${(v.progress * 100).round()}٪',
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.w800, fontSize: 15, fontFeatures: kTabular)),
            ],
          ),
          const SizedBox(height: 12),
          ProgressLine(v.progress, color),
          if (perMonth != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.flag_rounded, size: 14, color: p.muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${S.perMonth} ${money(perMonth, g.currency)} · تا ${monthLabel(g.deadline!)}',
                    style: TextStyle(color: p.muted, fontSize: 12, fontFeatures: kTabular),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
