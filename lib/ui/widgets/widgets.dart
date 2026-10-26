import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';

/// Flat card with a hairline border. The app's main surface.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double radius;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.onTap,
    this.onLongPress,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Material(
        color: color ?? p.surface,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: p.outline),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(title,
              style: context.tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const EmptyState({super.key, required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: p.surface2, shape: BoxShape.circle),
            child: Icon(icon, color: p.muted, size: 32),
          ),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(color: p.muted, fontSize: 12.5)),
          ],
        ],
      ),
    );
  }
}

/// Expense / income segmented switch with a sliding thumb.
class KindToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const KindToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final isExp = value == 'expense';
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(23)),
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth / 2;
        return Stack(
          children: [
            AnimatedPositionedDirectional(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              start: isExp ? 0 : w,
              top: 0,
              bottom: 0,
              width: w,
              child: Container(
                decoration: BoxDecoration(
                  color: isExp ? p.coral : p.mint,
                  borderRadius: BorderRadius.circular(19),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(child: _Seg(S.expense, isExp, () => onChanged('expense'))),
                Expanded(child: _Seg(S.income, !isExp, () => onChanged('income'))),
              ],
            ),
          ],
        );
      }),
    );
  }
}

class _Seg extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Seg(this.label, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: selected ? const Color(0xFF14181F) : context.p.muted,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

/// Custom numeric keypad. [third] is the bottom-left key ('000', '.' or '').
class Keypad extends StatelessWidget {
  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  final String third;
  const Keypad({super.key, required this.onKey, required this.onBackspace, this.third = '000'});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      [third, '0', '⌫'],
    ];
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final r in rows)
            Row(
              children: [
                for (final k in r)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: k.isEmpty ? const SizedBox(height: 54) : _Key(k, onKey, onBackspace),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  final String k;
  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  const _Key(this.k, this.onKey, this.onBackspace);

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final isBack = k == '⌫';
    return Material(
      color: isBack ? Colors.transparent : p.surface2,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isBack ? onBackspace : () => onKey(k),
        child: SizedBox(
          height: 54,
          child: Center(
            child: isBack
                ? Icon(Icons.backspace_outlined, size: 22, color: p.muted)
                : Text(k,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w600, fontFeatures: kTabular)),
          ),
        ),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  const Pill({super.key, required this.label, required this.onTap, this.selected = false, this.icon});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Material(
      color: selected ? p.accent : p.surface2,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: selected ? Palette.onAccent : p.muted),
                const SizedBox(width: 6),
              ],
              Text(label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Palette.onAccent : p.text,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class CircleIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final bool filled;
  const CircleIcon(this.icon, this.color, {super.key, this.size = 44, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? color : color.withValues(alpha: 0.18),
      ),
      child: Icon(icon, color: filled ? const Color(0xFF14181F) : color, size: size * 0.48),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const StatusChip(this.label, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
    );
  }
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 10, bottom: 6),
          decoration: BoxDecoration(
            color: context.p.outline,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  const RoundIconButton(this.icon, {super.key, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Material(
      color: color ?? p.surface,
      shape: CircleBorder(side: BorderSide(color: p.outline)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 42, height: 42, child: Icon(icon, size: 22)),
      ),
    );
  }
}

Future<bool> confirmDelete(BuildContext context) async {
  final p = context.p;
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text(S.confirmDelete),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(S.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: p.coral,
            foregroundColor: Colors.white,
            minimumSize: const Size(100, 44),
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text(S.delete),
        ),
      ],
    ),
  );
  return r ?? false;
}

void snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

/// Simple text prompt dialog. Returns null on cancel.
Future<String?> textPrompt(
  BuildContext context, {
  required String title,
  String initial = '',
  TextInputType keyboard = TextInputType.text,
  String? hint,
}) {
  final ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        keyboardType: keyboard,
        decoration: InputDecoration(hintText: hint),
        onSubmitted: (v) => Navigator.pop(ctx, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text(S.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(110, 44)),
          onPressed: () => Navigator.pop(ctx, ctrl.text),
          child: const Text(S.save),
        ),
      ],
    ),
  );
}
