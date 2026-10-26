import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import 'analytics/analytics_screen.dart';
import 'home/home_screen.dart';
import 'recurring/recurring_screen.dart';
import 'settings/settings_screen.dart';
import 'tx/tx_sheet.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 0;

  static const _pages = [
    HomeScreen(),
    AnalyticsScreen(),
    RecurringScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _i, children: _pages),
      bottomNavigationBar: _NavBar(
        index: _i,
        onTap: (i) => setState(() => _i = i),
        onAdd: () => showTxSheet(context),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onAdd;
  const _NavBar({required this.index, required this.onTap, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: p.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.5 : 0.12),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _Item(
                icon: Icons.home_outlined,
                active: Icons.home_rounded,
                label: S.home,
                selected: index == 0,
                onTap: () => onTap(0),
              ),
            ),
            Expanded(
              child: _Item(
                icon: Icons.donut_large_outlined,
                active: Icons.donut_large_rounded,
                label: S.analytics,
                selected: index == 1,
                onTap: () => onTap(1),
              ),
            ),
            _AddButton(onTap: onAdd),
            Expanded(
              child: _Item(
                icon: Icons.event_repeat_outlined,
                active: Icons.event_repeat_rounded,
                label: S.recurring,
                selected: index == 2,
                onTap: () => onTap(2),
              ),
            ),
            Expanded(
              child: _Item(
                icon: Icons.tune_outlined,
                active: Icons.tune_rounded,
                label: S.settings,
                selected: index == 3,
                onTap: () => onTap(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon, active;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Item({
    required this.icon,
    required this.active,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final color = selected ? p.accent : p.muted;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: selected ? 1.08 : 1,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: Icon(selected ? active : icon, color: color, size: 24),
          ),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Palette.accentSoft, p.accent],
          ),
          boxShadow: [
            BoxShadow(
              color: p.accent.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Palette.onAccent, size: 30),
      ),
    );
  }
}
