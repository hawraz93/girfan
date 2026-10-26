import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import 'widgets.dart';

/// App-styled date picker (replaces Material's showDatePicker). Weeks start
/// on Saturday; month names follow the user's month style.
Future<DateTime?> showDayPicker(
  BuildContext context, {
  required DateTime initial,
  DateTime? first,
  DateTime? last,
}) =>
    showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DaySheet(
        initial: DateTime(initial.year, initial.month, initial.day),
        first: first ?? DateTime(2015),
        last: last ?? DateTime.now().add(const Duration(days: 365 * 10)),
      ),
    );

class _DaySheet extends StatefulWidget {
  final DateTime initial, first, last;
  const _DaySheet({required this.initial, required this.first, required this.last});

  @override
  State<_DaySheet> createState() => _DaySheetState();
}

class _DaySheetState extends State<_DaySheet> {
  late DateTime month = DateTime(widget.initial.year, widget.initial.month);

  // Saturday first. DateTime.weekday: Mon=1 ... Sun=7.
  static const _order = [6, 7, 1, 2, 3, 4, 5];
  static const _kurdish = {6: 'ش', 7: 'ی', 1: 'د', 2: 'س', 3: 'چ', 4: 'پ', 5: 'ه'};
  static const _arabic = {6: 'س', 7: 'ح', 1: 'ن', 2: 'ث', 3: 'ر', 4: 'خ', 5: 'ج'};
  static const _english = {6: 'Sa', 7: 'Su', 1: 'Mo', 2: 'Tu', 3: 'We', 4: 'Th', 5: 'Fr'};

  String _wd(int w) => switch (monthNames) {
        MonthNames.arabic => _arabic[w]!,
        MonthNames.english => _english[w]!,
        _ => _kurdish[w]!,
      };

  bool _inRange(DateTime d) =>
      !d.isBefore(DateTime(widget.first.year, widget.first.month, widget.first.day)) &&
      !d.isAfter(DateTime(widget.last.year, widget.last.month, widget.last.day));

  void _shift(int n) => setState(() => month = DateTime(month.year, month.month + n));

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysIn = DateTime(month.year, month.month + 1, 0).day;
    final lead = _order.indexOf(DateTime(month.year, month.month).weekday);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHandle(),
            Row(
              children: [
                IconButton(
                  // Chevrons mirror in RTL: this one points right (back).
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => _shift(-1),
                ),
                Expanded(
                  child: Center(
                    child: Text(monthLabel(monthKey(month)),
                        style: context.tt.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800, fontFeatures: kTabular)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () => _shift(1),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                for (final w in _order)
                  Expanded(
                    child: Center(
                      child: Text(_wd(w),
                          style: TextStyle(
                              color: w == 5 ? p.coral : p.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              children: [
                for (var i = 0; i < lead; i++) const SizedBox.shrink(),
                for (var d = 1; d <= daysIn; d++)
                  () {
                    final day = DateTime(month.year, month.month, d);
                    final selected = day == widget.initial;
                    final isToday = day == today;
                    final enabled = _inRange(day);
                    return Material(
                      color: selected ? p.accent : Colors.transparent,
                      shape: CircleBorder(
                        side: isToday && !selected
                            ? BorderSide(color: p.accent, width: 1.5)
                            : BorderSide.none,
                      ),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: enabled ? () => Navigator.pop(context, day) : null,
                        child: Center(
                          child: Text(
                            '$d',
                            style: TextStyle(
                              fontWeight: selected || isToday ? FontWeight.w800 : FontWeight.w500,
                              fontFeatures: kTabular,
                              color: !enabled
                                  ? p.muted.withValues(alpha: 0.4)
                                  : selected
                                      ? Palette.onAccent
                                      : p.text,
                            ),
                          ),
                        ),
                      ),
                    );
                  }(),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Pill(label: S.today, onTap: () => Navigator.pop(context, today)),
                const SizedBox(width: 8),
                Pill(
                  label: S.yesterday,
                  onTap: () => Navigator.pop(context, today.subtract(const Duration(days: 1))),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(S.cancel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
