import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/icons.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../widgets/widgets.dart';
import 'category_sheet.dart';

class CategoriesScreen extends ConsumerWidget {
  final String kind;
  const CategoriesScreen({super.key, required this.kind});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.p;
    final s = ref.watch(settingsProvider);
    final cats = (ref.watch(categoriesProvider).valueOrNull ?? const <Category>[])
        .where((c) => c.kind == kind && !c.archived)
        .toList();
    final isExpense = kind == 'expense';

    return Scaffold(
      appBar: AppBar(
        title: Text(isExpense ? S.categories : S.incomeSources),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: RoundIconButton(Icons.add_rounded,
                onTap: () => showCategorySheet(context, kind: kind)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          if (cats.isEmpty)
            const EmptyState(icon: Icons.category_outlined, title: S.nothingHere)
          else
            SoftCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < cats.length; i++) ...[
                    if (i > 0) Divider(height: 1, indent: 68, color: p.outline),
                    _CatTile(cats[i], s.baseCurrency),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 14),
          Text(
            'دابگرە بۆ دەستکاری · درێژ دابگرە بۆ سڕینەوە',
            textAlign: TextAlign.center,
            style: TextStyle(color: p.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CatTile extends ConsumerWidget {
  final Category c;
  final String cur;
  const _CatTile(this.c, this.cur);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.p;
    return InkWell(
      onTap: () => showCategorySheet(context, kind: c.kind, existing: c),
      onLongPress: () async {
        if (!await confirmDelete(context)) return;
        final archived = await ref.read(repoProvider).deleteCategory(c.id);
        ref.bump();
        if (archived && context.mounted) snack(context, S.categoryHidden);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleIcon(catIcon(c.icon), Color(c.color), size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
            ),
            if (c.budget != null)
              Text(money(c.budget!, cur),
                  style: TextStyle(color: p.muted, fontSize: 12, fontFeatures: kTabular)),
            const SizedBox(width: 10),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: p.muted),
          ],
        ),
      ),
    );
  }
}
