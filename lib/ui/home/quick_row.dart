import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/icons.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
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
        content: Text('${q.name} · ${money(q.amount, q.currency)} ${S.recorded}'),
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

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, size: 18, color: p.accent),
              const SizedBox(width: 4),
              Text(S.quick, style: context.tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              if (items.isNotEmpty)
                Expanded(
                  child: Text(S.quickHint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: p.muted, fontSize: 11.5)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 64,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: [
                for (final q in items)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: _QuickChip(
                      q: q,
                      cat: cats[q.categoryId],
                      onTap: () => _record(context, ref, q),
                      onLongPress: () => showQuickSheet(context, existing: q),
                    ),
                  ),
                _AddChip(
                  label: items.isEmpty ? S.quickFirst : S.add,
                  onTap: () => showQuickSheet(context),
                ),
              ],
            ),
          ),
        ],
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
    return SoftCard(
      radius: 18,
      onTap: onTap,
      onLongPress: onLongPress,
      padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleIcon(catIcon(cat?.icon ?? 'more'), color, size: 38),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(q.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              Text(money(q.amount, q.currency),
                  style: TextStyle(
                      color: q.kind == 'expense' ? p.muted : p.mint,
                      fontSize: 11.5,
                      fontFeatures: kTabular)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Material(
      color: p.accent.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: p.accent, size: 20),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: p.accent, fontWeight: FontWeight.w700)),
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
    final cats = all.where((c) => c.kind == kind && (!c.archived || c.id == categoryId)).toList();
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
