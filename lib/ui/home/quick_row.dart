import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/icons.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../settings/category_sheet.dart';
import '../widgets/widgets.dart';

/// One-tap buttons on the home screen. Tap records the item for today
/// (with undo); long-press edits it; the last chip adds a new one.
class QuickRow extends ConsumerWidget {
  const QuickRow({super.key});

  Future<void> _record(BuildContext context, WidgetRef ref, QuickItem q) async {
    final s = ref.read(settingsProvider);
    final repo = ref.read(repoProvider);
    final id = await repo.insertTx(Tx(
      id: 0,
      kind: q.kind,
      amount: q.amount,
      currency: q.currency,
      categoryId: q.categoryId,
      date: dateKey(DateTime.now()),
      note: q.name,
      rate: s.usdRate,
    ));
    ref.bump();
    if (!context.mounted) return;
    final p = context.p;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${q.name} · ${money(q.amount, q.currency)} ${S.recorded}'),
            Text(S.quickHint, style: TextStyle(color: p.muted, fontSize: 11.5)),
          ],
        ),
        action: SnackBarAction(
          label: S.undo,
          textColor: p.accent,
          onPressed: () async {
            await repo.deleteTx(id);
            ref.bump();
          },
        ),
      ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.p;
    final items = ref.watch(quickProvider).valueOrNull ?? const <QuickItem>[];
    final cats = ref.watch(categoryMapProvider);

    // One slim row of pills: tap records, hold edits, + adds.
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: Icon(Icons.bolt_rounded, size: 20, color: p.accent),
            ),
            for (final q in items)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 6),
                child: _QuickChip(
                  q: q,
                  cat: cats[q.categoryId],
                  onTap: () => _record(context, ref, q),
                  onLongPress: () => showQuickSheet(context, existing: q),
                ),
              ),
            _AddChip(
              label: items.isEmpty ? S.quickFirst : null,
              onTap: () => showQuickSheet(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final QuickItem q;
  final Category? cat;
  final VoidCallback onTap, onLongPress;
  const _QuickChip({required this.q, required this.cat, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final color = Color(cat?.color ?? 0xFF8A93A3);
    return Material(
      color: p.surface,
      shape: StadiumBorder(side: BorderSide(color: p.outline)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(catIcon(cat?.icon ?? 'more'), color: color, size: 16),
              const SizedBox(width: 6),
              Text(q.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
              const SizedBox(width: 6),
              Text(moneyNumber(q.amount, q.currency),
                  style: TextStyle(
                      color: q.kind == 'expense' ? p.muted : p.mint,
                      fontSize: 12,
                      fontFeatures: kTabular)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  final String? label;
  final VoidCallback onTap;
  const _AddChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Material(
      color: p.accent.withValues(alpha: 0.12),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: label == null ? 9 : 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: p.accent, size: 20),
              if (label != null) ...[
                const SizedBox(width: 4),
                Text(label!, style: TextStyle(color: p.accent, fontWeight: FontWeight.w700, fontSize: 12.5)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showQuickSheet(BuildContext context, {QuickItem? existing}) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => QuickSheet(existing: existing),
    );

/// Create / edit / delete a quick button.
class QuickSheet extends ConsumerStatefulWidget {
  final QuickItem? existing;
  const QuickSheet({super.key, this.existing});

  @override
  ConsumerState<QuickSheet> createState() => _QuickSheetState();
}

class _QuickSheetState extends ConsumerState<QuickSheet> {
  final name = TextEditingController();
  final amount = TextEditingController();
  String kind = 'expense';
  late String currency;
  int? categoryId;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      name.text = e.name;
      amount.text = moneyNumber(e.amount, e.currency);
      kind = e.kind;
      currency = e.currency;
      categoryId = e.categoryId;
    } else {
      currency = ref.read(settingsProvider).baseCurrency;
    }
  }

  @override
  void dispose() {
    name.dispose();
    amount.dispose();
    super.dispose();
  }

  Future<void> _save(List<Category> cats) async {
    final a = parseAmount(amount.text);
    final catId = categoryId ?? (cats.isNotEmpty ? cats.first.id : null);
    if (name.text.trim().isEmpty) return snack(context, '${S.name} ${S.required}');
    if (a <= 0) return snack(context, '${S.amount} ${S.required}');
    if (catId == null) return snack(context, '${S.category} ${S.required}');
    final q = QuickItem(
      id: widget.existing?.id ?? 0,
      name: name.text.trim(),
      amount: a,
      currency: currency,
      categoryId: catId,
      kind: kind,
      sort: widget.existing?.sort ?? 0,
    );
    final repo = ref.read(repoProvider);
    if (widget.existing != null) {
      await repo.updateQuick(q);
    } else {
      await repo.insertQuick(q);
    }
    ref.bump();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    if (!await confirmDelete(context)) return;
    await ref.read(repoProvider).deleteQuick(widget.existing!.id);
    ref.bump();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final all = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final cats = byUsage(
        all.where((c) => c.kind == kind && (!c.archived || c.id == categoryId)).toList(),
        ref.watch(categoryUsageProvider).valueOrNull ?? const {});
    final effective = categoryId ?? (cats.isNotEmpty ? cats.first.id : null);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            Row(
              children: [
                Expanded(
                  child: Text(widget.existing != null ? S.editQuick : S.newQuick,
                      style: context.tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
                if (widget.existing != null)
                  IconButton(
                    onPressed: _delete,
                    icon: Icon(Icons.delete_outline_rounded, color: p.coral),
                  ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            KindToggle(
              value: kind,
              onChanged: (k) => setState(() {
                kind = k;
                categoryId = null;
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: name,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: S.name,
                hintText: S.quickNameHint,
                prefixIcon: Icon(Icons.label_outline_rounded, color: p.muted, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            AmountField(
              controller: amount,
              currency: currency,
              onToggleCurrency: () => setState(() {
                currency = currency == 'IQD' ? 'USD' : 'IQD';
                amount.text = '';
              }),
            ),
            const SizedBox(height: 16),
            Text(kind == 'expense' ? S.category : S.source,
                style: TextStyle(color: p.muted, fontSize: 12.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in cats)
                  Pill(
                    icon: catIcon(c.icon),
                    label: c.name,
                    selected: c.id == effective,
                    onTap: () => setState(() => categoryId = c.id),
                  ),
                Pill(
                  icon: Icons.add_rounded,
                  label: S.newCategoryShort,
                  onTap: () async {
                    final id = await showCategorySheet(context, kind: kind);
                    if (id != null && mounted) setState(() => categoryId = id);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => _save(cats),
              child: Text(widget.existing != null ? S.save : S.add),
            ),
          ],
        ),
      ),
    );
  }
}
