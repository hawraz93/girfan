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
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
          children: [
            _Header(name: s.userName),
            const SizedBox(height: 14),
            const UpdateBanner(),
            summary.when(
              data: (sum) => HeroCard(sum: sum, settings: s)
                  .animate(key: ValueKey('${sum.month}-${sum.currency}'))
                  .fadeIn(duration: 300.ms),
              loading: () => const _HeroSkeleton(),
              error: (e, _) => Text('$e'),
            ),
            const QuickRow(),
            due.maybeWhen(
              data: (items) {
                final pending = items.where((d) => !d.paid).toList();
                if (pending.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _DueSection(pending, month),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
            // Future ad slot (AdMob native ad) belongs here, between the
            // summary area and the transaction list.
            const SizedBox(height: 20),
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
                  ? EmptyState(
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

Future<void> _backup(BuildContext context, WidgetRef ref) async {
  final n = ref.read(settingsProvider.notifier);
  try {
    if (await shareBackup(ref.read(repoProvider), n.exportable())) {
      await n.markBackedUp();
      if (context.mounted) snack(context, S.backupDone);
    }
  } catch (e) {
    if (context.mounted) snack(context, '$e');
  }
}

class _Header extends ConsumerWidget {
  final String name;
  const _Header({required this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.p;
    final backupDue = ref.watch(backupDueProvider).valueOrNull ?? false;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? S.greeting : S.greetingName(name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: p.muted, fontSize: 12.5),
              ),
              Text(S.appName,
                  style: context.tt.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            ],
          ),
        ),
        // Backup reminder: a small cloud with a red dot instead of a banner.
        if (backupDue)
          Tooltip(
            message: S.backupDue,
            child: Material(
              color: p.coral.withValues(alpha: 0.12),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _backup(context, ref),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.cloud_upload_outlined, size: 21, color: p.coral),
                      PositionedDirectional(
                        top: 8,
                        end: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: p.coral, shape: BoxShape.circle),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(width: 6),
        const CurrencySwitch(),
        const SizedBox(width: 6),
        const MonthPill(),
      ],
    );
  }
}

/// The always-dark balance card: what is left, how much of income is spent,
/// and income / expense. Category detail lives in Analytics.
class HeroCard extends StatelessWidget {
  final MonthSummary sum;
  final Settings settings;
  const HeroCard({super.key, required this.sum, required this.settings});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final cur = sum.currency;
    final negative = sum.net < 0;
    final ratio = sum.income > 0 ? sum.expense / sum.income : 0.0;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [p.heroA, p.heroB],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            end: -50,
            top: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  Palette.heroAccent.withValues(alpha: 0.28),
                  Palette.heroAccent.withValues(alpha: 0),
                ]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('${S.remainingOf} ${monthLabel(sum.month)}',
                          style: const TextStyle(color: Palette.heroMuted, fontSize: 12.5)),
                    ),
                    if (sum.saved != 0) ...[
                      const Icon(Icons.savings_rounded, size: 13, color: Palette.heroMint),
                      const SizedBox(width: 4),
                      Text(money(sum.saved, cur),
                          style: const TextStyle(
                              color: Palette.heroMint, fontSize: 11.5, fontFeatures: kTabular)),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
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
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            height: 1.15,
                            fontFeatures: kTabular,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(currencySymbol(cur),
                        style: const TextStyle(
                            color: Palette.heroMuted, fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
                if (sum.income > 0) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratio.clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: Colors.white.withValues(alpha: 0.10),
                            color: ratio > 0.9 ? Palette.heroCoral : Palette.heroMint,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(S.spentOfIncome((ratio * 100).round()),
                          style: const TextStyle(color: Palette.heroMuted, fontSize: 11.5)),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
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
                    Container(
                      width: 1,
                      height: 28,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
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
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.18), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Palette.heroMuted, fontSize: 11)),
              // Scales down instead of cutting the number off.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(value,
                    style: const TextStyle(
                      color: Palette.heroText,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFeatures: kTabular,
                    )),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();
  @override
  Widget build(BuildContext context) => Container(
        height: 170,
        decoration: BoxDecoration(
          color: context.p.surface2,
          borderRadius: BorderRadius.circular(24),
        ),
      );
}

/// Fixed items still to pay this month, as a short list (3 shown, rest
/// behind "more").
class _DueSection extends StatefulWidget {
  final List<DueItem> items;
  final String month;
  const _DueSection(this.items, this.month);

  @override
  State<_DueSection> createState() => _DueSectionState();
}

class _DueSectionState extends State<_DueSection> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final items = widget.items;
    final shown = expanded ? items : items.take(3).toList();
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(S.dueThisMonth, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                decoration: BoxDecoration(
                  color: p.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${items.length}',
                    style: TextStyle(
                        color: p.accent, fontWeight: FontWeight.w800, fontSize: 12, fontFeatures: kTabular)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final d in shown) _DueRow(d, widget.month),
          if (items.length > 3)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => setState(() => expanded = !expanded),
                child: Text(expanded ? S.showLess : S.moreCount(items.length - 3)),
              ),
            ),
        ],
      ),
    );
  }
}

class _DueRow extends StatelessWidget {
  final DueItem d;
  final String month;
  const _DueRow(this.d, this.month);

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final r = d.recurring;
    final color = Color(d.category?.color ?? 0xFF8A93A3);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => showTxSheet(context, fromRecurring: r, period: month),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            CircleIcon(catIcon(d.category?.icon ?? 'more'), color, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  Text('${S.dayOfMonth} ${r.dayOfMonth}',
                      style: TextStyle(color: p.muted, fontSize: 11.5, fontFeatures: kTabular)),
                ],
              ),
            ),
            Text(money(r.amount, r.currency),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, fontFeatures: kTabular)),
            const SizedBox(width: 10),
            Material(
              color: p.accent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => showTxSheet(context, fromRecurring: r, period: month),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Text(S.record,
                      style: const TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.w800, color: Palette.onAccent)),
                ),
              ),
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
