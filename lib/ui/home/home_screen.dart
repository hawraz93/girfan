import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/icons.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../tx/tx_sheet.dart';
import '../../data/backup.dart';
import '../update/update_sheet.dart';
import 'quick_row.dart';
import '../widgets/month_picker.dart';
import '../widgets/widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final month = ref.watch(selectedMonthProvider);
    final summary = ref.watch(monthSummaryProvider);
    final txs = ref.watch(monthTxProvider);
    final due = ref.watch(dueProvider);
    final cats = ref.watch(categoryMapProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            _Header(name: s.userName),
            const SizedBox(height: 18),
            const UpdateBanner(),
            const _BackupBanner(),
            summary.when(
              data: (sum) => HeroCard(sum: sum, settings: s)
                  .animate(key: ValueKey(sum.month))
                  .fadeIn(duration: 350.ms)
                  .slideY(begin: 0.04, curve: Curves.easeOutCubic),
              loading: () => const _HeroSkeleton(),
              error: (e, _) => Text('$e'),
            ),
            const QuickRow(),
            due.maybeWhen(
              data: (items) {
                final pending = items.where((d) => !d.paid).toList();
                if (pending.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: _DueSection(pending, month),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            SectionHeader(
              S.transactions,
              trailing: txs.maybeWhen(
                data: (l) => Text('${l.length}',
                    style: TextStyle(color: context.p.muted, fontFeatures: kTabular)),
                orElse: () => null,
              ),
            ),
            txs.when(
              data: (list) => list.isEmpty
                  ? const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: S.noTx,
                      subtitle: S.noTxHint,
                    )
                  : _TxGroups(list, cats),
              loading: () => const SizedBox(height: 80),
              error: (e, _) => Text('$e'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupBanner extends ConsumerWidget {
  const _BackupBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final due = ref.watch(backupDueProvider).valueOrNull ?? false;
    if (!due) return const SizedBox.shrink();
    final p = context.p;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SoftCard(
        color: p.coral.withValues(alpha: 0.10),
        onTap: () async {
          final n = ref.read(settingsProvider.notifier);
          try {
            if (await shareBackup(ref.read(repoProvider), n.exportable())) {
              await n.markBackedUp();
              if (context.mounted) snack(context, S.backupDone);
            }
          } catch (e) {
            if (context.mounted) snack(context, '$e');
          }
        },
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.cloud_upload_outlined, color: p.coral),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(S.backupDue, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            Text(S.backupNow, style: TextStyle(color: p.coral, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  const _Header({required this.name});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? S.greeting : '${S.greeting}، $name',
                style: TextStyle(color: p.muted, fontSize: 13),
              ),
              Text(S.appName,
                  style: context.tt.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            ],
          ),
        ),
        const CurrencySwitch(),
        const SizedBox(width: 6),
        const MonthPill(),
      ],
    );
  }
}

/// The always-dark balance card.
class HeroCard extends StatelessWidget {
  final MonthSummary sum;
  final Settings settings;
  const HeroCard({super.key, required this.sum, required this.settings});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final cur = sum.currency;
    final top = sum.expenseByCat.take(5).toList();
    final other = sum.expense - top.fold(0.0, (a, b) => a + b.total);
    final negative = sum.net < 0;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [p.heroA, p.heroB],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            end: -60,
            top: -70,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  Palette.heroAccent.withValues(alpha: 0.32),
                  Palette.heroAccent.withValues(alpha: 0),
                ]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${S.remainingOf} ${monthLabel(sum.month)}',
                    style: const TextStyle(color: Palette.heroMuted, fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          moneyNumber(sum.net, cur),
                          style: TextStyle(
                            color: negative ? Palette.heroCoral : Palette.heroText,
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.2,
                            height: 1.1,
                            fontFeatures: kTabular,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(currencySymbol(cur),
                        style: const TextStyle(
                            color: Palette.heroMuted, fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
                if (sum.income > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${(sum.expense / sum.income * 100).round()}٪ ${S.ofIncome} خەرج کراوە',
                      style: const TextStyle(color: Palette.heroMuted, fontSize: 12),
                    ),
                  ),
                if (sum.saved != 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.savings_rounded, size: 13, color: Palette.heroMint),
                        const SizedBox(width: 5),
                        Text('${S.saved}: ${money(sum.saved, cur)}',
                            style: const TextStyle(
                                color: Palette.heroMint, fontSize: 12, fontFeatures: kTabular)),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        icon: Icons.arrow_downward_rounded,
                        color: Palette.heroMint,
                        label: S.income,
                        value: money(sum.income, cur),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Stat(
                        icon: Icons.arrow_upward_rounded,
                        color: Palette.heroCoral,
                        label: S.expense,
                        value: money(sum.expense, cur),
                      ),
                    ),
                  ],
                ),
                if (sum.expense > 0) ...[
                  const SizedBox(height: 18),
                  _StripeBar(top: top, other: other, total: sum.expense),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      for (final e in top.take(3))
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: Color(e.cat.color), shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text(e.cat.name,
                                style: const TextStyle(color: Palette.heroMuted, fontSize: 11.5)),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.speed_rounded, size: 14, color: Palette.heroMuted),
                      const SizedBox(width: 6),
                      Text('${S.avgPerDay}: ${money(sum.avgPerDay, cur)}',
                          style: const TextStyle(
                              color: Palette.heroMuted, fontSize: 12, fontFeatures: kTabular)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  const _Stat({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.18), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Palette.heroMuted, fontSize: 11)),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Palette.heroText,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFeatures: kTabular,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StripeBar extends StatelessWidget {
  final List<CatTotal> top;
  final double other, total;
  const _StripeBar({required this.top, required this.other, required this.total});

  int _flex(double v) => math.max(1, (v * 1000 / total).round());

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            for (final e in top)
              Expanded(
                flex: _flex(e.total),
                child: Container(
                  margin: const EdgeInsetsDirectional.only(end: 2),
                  color: Color(e.cat.color),
                ),
              ),
            if (other > 0)
              Expanded(
                flex: _flex(other),
                child: Container(color: Palette.heroMuted.withValues(alpha: 0.5)),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();
  @override
  Widget build(BuildContext context) => Container(
        height: 240,
        decoration: BoxDecoration(
          color: context.p.surface2,
          borderRadius: BorderRadius.circular(28),
        ),
      );
}

class _DueSection extends StatelessWidget {
  final List<DueItem> items;
  final String month;
  const _DueSection(this.items, this.month);

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          S.dueThisMonth,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
            decoration: BoxDecoration(
              color: p.accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${items.length}',
                style: TextStyle(
                    color: p.accent, fontWeight: FontWeight.w800, fontSize: 12, fontFeatures: kTabular)),
          ),
        ),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _DueCard(items[i], month),
          ),
        ),
      ],
    );
  }
}

class _DueCard extends StatelessWidget {
  final DueItem d;
  final String month;
  const _DueCard(this.d, this.month);

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final r = d.recurring;
    final color = Color(d.category?.color ?? 0xFF8A93A3);
    return SizedBox(
      width: 196,
      child: SoftCard(
        padding: const EdgeInsets.all(14),
        onTap: () => showTxSheet(context, fromRecurring: r, period: month),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleIcon(catIcon(d.category?.icon ?? 'more'), color, size: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(r.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ],
            ),
            const Spacer(),
            Text(money(r.amount, r.currency),
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16.5, fontFeatures: kTabular)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('${S.dayOfMonth} ${r.dayOfMonth}',
                    style: TextStyle(color: p.muted, fontSize: 12, fontFeatures: kTabular)),
                const Spacer(),
                Material(
                  color: p.accent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => showTxSheet(context, fromRecurring: r, period: month),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Text(S.record,
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w800, color: Palette.onAccent)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TxGroups extends ConsumerWidget {
  final List<Tx> list;
  final Map<int, Category> cats;
  const _TxGroups(this.list, this.cats);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.p;
    final s = ref.watch(settingsProvider);
    final groups = <String, List<Tx>>{};
    for (final t in list) {
      groups.putIfAbsent(t.date, () => []).add(t);
    }
    return Column(
      children: [
        for (final e in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
            child: Row(
              children: [
                Text(dateLabel(e.key),
                    style: TextStyle(color: p.muted, fontWeight: FontWeight.w700, fontSize: 12.5)),
                const Spacer(),
                Builder(builder: (_) {
                  final exp = s.split(e.value.where((t) => t.isExpense), (t) => t.amount,
                      (t) => t.currency, (t) => t.rate);
                  return exp.values.every((v) => v == 0)
                      ? const SizedBox.shrink()
                      : Text('−${moneyMulti(exp, fallback: s.baseCurrency)}',
                          style: TextStyle(color: p.muted, fontSize: 12, fontFeatures: kTabular));
                }),
              ],
            ),
          ),
          SoftCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < e.value.length; i++) ...[
                  if (i > 0) Divider(height: 1, indent: 70, color: p.outline),
                  TxTile(e.value[i], cats[e.value[i].categoryId]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class TxTile extends ConsumerWidget {
  final Tx t;
  final Category? cat;
  const TxTile(this.t, this.cat, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.p;
    final color = Color(cat?.color ?? 0xFF8A93A3);
    final sub = t.note.isNotEmpty ? t.note : (t.recurringId != null ? S.recurring : null);
    return InkWell(
      onTap: () => showTxSheet(context, existing: t),
      onLongPress: () async {
        if (await confirmDelete(context)) {
          await ref.read(repoProvider).deleteTx(t.id);
          ref.bump();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleIcon(catIcon(cat?.icon ?? 'more'), color, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat?.name ?? '—',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                  if (sub != null)
                    Text(sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: p.muted, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${t.isExpense ? '−' : '+'}${money(t.amount, t.currency)}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
                fontFeatures: kTabular,
                color: t.isExpense ? p.text : p.mint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
