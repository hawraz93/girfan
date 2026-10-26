import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/export.dart';
import '../../state/providers.dart';
import '../lock/lock_screen.dart';
import '../widgets/widgets.dart';
import 'categories_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.p;
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            Text(S.settings, style: context.tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            _Group(S.profile, [
              _Tile(
                icon: Icons.person_outline_rounded,
                title: S.yourName,
                value: s.userName.isEmpty ? '—' : s.userName,
                onTap: () async {
                  final v = await textPrompt(context, title: S.yourName, initial: s.userName);
                  if (v != null) n.setName(v.trim());
                },
              ),
            ]),
            _Group(S.currency, [
              _Tile(
                icon: Icons.payments_outlined,
                title: S.baseCurrency,
                trailing: _Segmented(
                  options: const ['IQD', 'USD'],
                  labels: const ['دینار', 'دۆلار'],
                  value: s.baseCurrency,
                  onChanged: n.setBase,
                ),
              ),
              _Tile(
                icon: Icons.currency_exchange_rounded,
                title: S.usdRate,
                value: moneyNumber(s.usdRate, 'IQD'),
                onTap: () async {
                  final v = await textPrompt(
                    context,
                    title: S.usdRate,
                    initial: s.usdRate.toStringAsFixed(0),
                    keyboard: TextInputType.number,
                  );
                  final r = double.tryParse((v ?? '').replaceAll(',', ''));
                  if (r != null && r > 0) n.setUsdRate(r);
                },
              ),
            ]),
            _Group('${S.category} و ${S.source}', [
              _Tile(
                icon: Icons.grid_view_rounded,
                title: S.categories,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoriesScreen(kind: 'expense')),
                ),
              ),
              _Tile(
                icon: Icons.account_balance_wallet_outlined,
                title: S.incomeSources,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoriesScreen(kind: 'income')),
                ),
              ),
            ]),
            _Group(S.security, [
              _Tile(
                icon: Icons.lock_outline_rounded,
                title: S.pinLock,
                trailing: Switch(
                  value: s.pin != null,
                  onChanged: (v) async {
                    if (!v) {
                      n.setPin(null);
                      return;
                    }
                    final pin = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(builder: (_) => const LockScreen(setup: true)),
                    );
                    if (pin != null) n.setPin(pin);
                  },
                ),
              ),
            ]),
            _Group(S.appearance, [
              Padding(
                padding: const EdgeInsets.all(12),
                child: _Segmented(
                  options: const ['system', 'light', 'dark'],
                  labels: const [S.themeSystem, S.themeLight, S.themeDark],
                  value: s.themeMode.name,
                  expand: true,
                  onChanged: (v) => n.setTheme(ThemeMode.values.byName(v)),
                ),
              ),
            ]),
            _Group(S.data, [
              _Tile(
                icon: Icons.ios_share_rounded,
                title: S.exportCsv,
                subtitle: S.exportHint,
                onTap: () async {
                  try {
                    await exportCsv(ref.read(repoProvider), ref.read(categoryMapProvider));
                  } catch (e) {
                    if (context.mounted) snack(context, '$e');
                  }
                },
              ),
            ]),
            const SizedBox(height: 12),
            Center(
              child: Text('${S.appName} · 1.0.0', style: TextStyle(color: p.muted, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Group(this.title, this.children);

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 6, bottom: 8),
            child: Text(title,
                style: TextStyle(color: p.muted, fontSize: 12.5, fontWeight: FontWeight.w700)),
          ),
          SoftCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) Divider(height: 1, indent: 66, color: p.outline),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle, value;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: p.surface2, shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: p.gold),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  if (subtitle != null)
                    Text(subtitle!, style: TextStyle(color: p.muted, fontSize: 12)),
                ],
              ),
            ),
            if (value != null)
              Text(value!, style: TextStyle(color: p.muted, fontSize: 13, fontFeatures: kTabular)),
            if (trailing != null)
              trailing!
            else if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: p.muted),
            ],
          ],
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  final List<String> options, labels;
  final String value;
  final ValueChanged<String> onChanged;
  final bool expand;
  const _Segmented({
    required this.options,
    required this.labels,
    required this.value,
    required this.onChanged,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          for (var i = 0; i < options.length; i++)
            () {
              final selected = options[i] == value;
              final child = GestureDetector(
                onTap: () => onChanged(options[i]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? p.gold : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(labels[i],
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: selected ? const Color(0xFF1A1300) : p.muted,
                      )),
                ),
              );
              return expand ? Expanded(child: child) : child;
            }(),
        ],
      ),
    );
  }
}
