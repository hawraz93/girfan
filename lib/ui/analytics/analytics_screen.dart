import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
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

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String kind = 'expense';

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final cur = ref.watch(effectiveViewProvider);
    final showBudget = s.mergeCurrencies || cur == s.baseCurrency;
    final summary = ref.watch(monthSummaryProvider);
    final series = ref.watch(monthlySeriesProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            Row(
              children: [
                Text(S.analytics,
                    style: context.tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const Spacer(),
                const CurrencySwitch(),
                const SizedBox(width: 6),
                const MonthPill(),
              ],
            ),
            const SizedBox(height: 18),
            KindToggle(value: kind, onChanged: (k) => setState(() => kind = k)),
            const SizedBox(height: 18),
            summary.when(
              data: (sum) {
                final items = kind == 'expense' ? sum.expenseByCat : sum.incomeByCat;
                final total = kind == 'expense' ? sum.expense : sum.income;
                if (items.isEmpty) {
                  return const SoftCard(
                    child: EmptyState(icon: Icons.pie_chart_outline_rounded, title: S.nothingHere),
                  );
                }
                return _Breakdown(
                    items: items, total: total, cur: cur, isExpense: kind == 'expense' && showBudget);
              },
              loading: () => const SizedBox(height: 240),
              error: (e, _) => Text('$e'),
            ),
            const SizedBox(height: 24),
            const SectionHeader(S.last6),
            series.when(
              data: (list) => _BarsCard(list, cur),
              loading: () => const SizedBox(height: 220),
              error: (e, _) => Text('$e'),
            ),
            const SizedBox(height: 16),
            summary.maybeWhen(
              data: (sum) => _NetRow(sum, cur),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Breakdown extends StatelessWidget {
  final List<CatTotal> items;
  final double total;
  final String cur;
  final bool isExpense;
  const _Breakdown({required this.items, required this.total, required this.cur, required this.isExpense});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return SoftCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 50,
                        startDegreeOffset: -90,
                        sections: [
                          for (final e in items)
                            PieChartSectionData(
                              value: e.total,
                              color: Color(e.cat.color),
                              radius: 22,
                              showTitle: false,
                            ),
                        ],
                      ),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(S.total, style: TextStyle(color: p.muted, fontSize: 11)),
                          Text(moneyNumber(total, cur),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15, fontFeatures: kTabular)),
                          Text(currencySymbol(cur), style: TextStyle(color: p.muted, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final e in items.take(5))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(color: Color(e.cat.color), shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(e.cat.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                            ),
                            Text('${(e.total / total * 100).round()}٪',
                                style: TextStyle(color: p.muted, fontSize: 12, fontFeatures: kTabular)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Divider(height: 1, color: p.outline),
          const SizedBox(height: 6),
          for (final e in items) _CatRow(e, total, cur, isExpense),
        ],
      ),
    );
  }
}

class _CatRow extends StatelessWidget {
  final CatTotal e;
  final double total;
  final String cur;
  final bool isExpense;
  const _CatRow(this.e, this.total, this.cur, this.isExpense);

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final color = Color(e.cat.color);
    final budget = isExpense ? e.cat.budget : null;
    final pct = total == 0 ? 0.0 : e.total / total;
    final over = budget != null && e.total > budget;
    final progress = budget != null ? (e.total / budget).clamp(0.0, 1.0) : pct;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              CircleIcon(catIcon(e.cat.icon), color, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.cat.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    if (budget != null)
                      Text(
                        over
                            ? '${S.overBudget} (${money(budget, cur)})'
                            : '${S.ofBudget} ${money(budget, cur)}',
                        style: TextStyle(
                            color: over ? p.coral : p.muted, fontSize: 11.5, fontFeatures: kTabular),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(money(e.total, cur),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14, fontFeatures: kTabular)),
                  Text('${(pct * 100).round()}٪',
                      style: TextStyle(color: p.muted, fontSize: 11.5, fontFeatures: kTabular)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: p.surface2,
              color: over ? p.coral : color,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarsCard extends StatelessWidget {
  final List<MonthTotal> list;
  final String cur;
  const _BarsCard(this.list, this.cur);

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    var maxY = list.fold(0.0, (m, e) => math.max(m, math.max(e.income, e.expense)));
    if (maxY == 0) maxY = 1;
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              _Legend(p.mint, S.income),
              const SizedBox(width: 16),
              _Legend(p.coral, S.expense),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 180,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY * 1.15,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (_) => FlLine(color: p.outline, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (v, meta) {
                          final i = v.toInt();
                          if (i < 0 || i >= list.length) return const SizedBox.shrink();
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(monthShort(list[i].month),
                                style: TextStyle(color: p.muted, fontSize: 10, fontWeight: FontWeight.w600)),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => p.surface2,
                      getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                        money(rod.toY, cur),
                        TextStyle(
                          color: p.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < list.length; i++)
                      BarChartGroupData(
                        x: i,
                        barsSpace: 4,
                        barRods: [
                          BarChartRodData(
                            toY: list[i].income,
                            color: p.mint,
                            width: 10,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          BarChartRodData(
                            toY: list[i].expense,
                            color: p.coral,
                            width: 10,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                  ],
                ),
                duration: const Duration(milliseconds: 400),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend(this.color, this.label);
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: context.p.muted, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      );
}

class _NetRow extends StatelessWidget {
  final MonthSummary sum;
  final String cur;
  const _NetRow(this.sum, this.cur);

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    Widget cell(String label, double v, Color color) => Expanded(
          child: SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: p.muted, fontSize: 11.5)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(money(v, cur),
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.w800, fontSize: 14, fontFeatures: kTabular)),
                ),
              ],
            ),
          ),
        );
    return Row(
      children: [
        cell(S.income, sum.income, p.mint),
        const SizedBox(width: 10),
        cell(S.expense, sum.expense, p.coral),
        const SizedBox(width: 10),
        cell(S.net, sum.net, sum.net < 0 ? p.coral : p.accent),
      ],
    );
  }
}
