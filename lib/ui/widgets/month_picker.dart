import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../state/providers.dart';
import 'widgets.dart';

Future<String?> showMonthPicker(BuildContext context, String current) =>
    showModalBottomSheet<String>(
      context: context,
      builder: (_) => _MonthSheet(current),
    );

class _MonthSheet extends StatefulWidget {
  final String current;
  const _MonthSheet(this.current);
  @override
  State<_MonthSheet> createState() => _MonthSheetState();
}

class _MonthSheetState extends State<_MonthSheet> {
  late int year = monthFromKey(widget.current).year;

  @override
  Widget build(BuildContext context) {
    final cur = monthFromKey(widget.current);
    final now = DateTime.now();
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + MediaQuery.paddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => setState(() => year--),
              ),
              Expanded(
                child: Center(
                  child: Text('$year',
                      style: context.tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800, fontFeatures: kTabular)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                onPressed: () => setState(() => year++),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              for (var m = 1; m <= 12; m++)
                _MonthCell(
                  label: monthNames == MonthNames.number ? '$m' : '$m · ${monthNameShort(m)}',
                  selected: cur.year == year && cur.month == m,
                  isNow: now.year == year && now.month == m,
                  onTap: () => Navigator.pop(context, '$year-${two(m)}'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthCell extends StatelessWidget {
  final String label;
  final bool selected, isNow;
  final VoidCallback onTap;
  const _MonthCell({required this.label, required this.selected, required this.isNow, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Material(
      color: selected ? p.accent : p.surface2,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: isNow && !selected ? Border.all(color: p.accent, width: 1.2) : null,
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? Palette.onAccent : p.text,
              )),
        ),
      ),
    );
  }
}

/// Pill showing the selected month; tap to change it.
class MonthPill extends ConsumerWidget {
  const MonthPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = ref.watch(selectedMonthProvider);
    final p = context.p;
    return Material(
      color: p.surface,
      shape: StadiumBorder(side: BorderSide(color: p.outline)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () async {
          final r = await showMonthPicker(context, m);
          if (r != null) ref.read(selectedMonthProvider.notifier).state = r;
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_month_rounded, size: 18, color: p.accent),
              const SizedBox(width: 8),
              Text(monthLabel(m),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              const SizedBox(width: 2),
              Icon(Icons.expand_more_rounded, size: 18, color: p.muted),
            ],
          ),
        ),
      ),
    );
  }
}
