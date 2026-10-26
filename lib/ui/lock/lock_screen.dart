import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../state/providers.dart';
import '../widgets/widgets.dart';

/// PIN entry. In [setup] mode it asks twice and pops with the new PIN.
class LockScreen extends ConsumerStatefulWidget {
  final bool setup;
  const LockScreen({super.key, this.setup = false});
  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String entered = '';
  String? first;
  bool error = false;

  void _key(String k) {
    if (k.isEmpty || entered.length >= 4) return;
    setState(() {
      entered += k;
      error = false;
    });
    if (entered.length == 4) {
      Future.delayed(const Duration(milliseconds: 160), _complete);
    }
  }

  void _complete() {
    if (!mounted) return;
    if (widget.setup) {
      if (first == null) {
        setState(() {
          first = entered;
          entered = '';
        });
      } else if (first == entered) {
        Navigator.pop(context, entered);
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          error = true;
          first = null;
          entered = '';
        });
      }
      return;
    }
    if (entered == ref.read(settingsProvider).pin) {
      ref.read(unlockedProvider.notifier).state = true;
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        error = true;
        entered = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final title = widget.setup ? (first == null ? S.setPin : S.confirmPin) : S.enterPin;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [const Color(0xFFF3CE7E), p.gold]),
                boxShadow: [
                  BoxShadow(color: p.gold.withValues(alpha: 0.4), blurRadius: 26, offset: const Offset(0, 10)),
                ],
              ),
              child: const Center(
                child: Text('م',
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Color(0xFF1A1300), height: 1)),
              ),
            ),
            const SizedBox(height: 22),
            Text(S.appName, style: context.tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(title, style: TextStyle(color: p.muted, fontSize: 14)),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 4; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 7),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < entered.length ? p.gold : p.surface2,
                      border: Border.all(color: error ? p.coral : p.outline),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 20,
              child: error
                  ? Text(S.wrongPin, style: TextStyle(color: p.coral, fontSize: 12.5))
                  : null,
            ),
            const Spacer(flex: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Keypad(
                onKey: _key,
                onBackspace: () => setState(() {
                  if (entered.isNotEmpty) entered = entered.substring(0, entered.length - 1);
                }),
                third: '',
              ),
            ),
            if (widget.setup)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(S.cancel),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
