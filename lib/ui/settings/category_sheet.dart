import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../widgets/widgets.dart';

Future<void> showCategorySheet(BuildContext context, {required String kind, Category? existing}) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CategorySheet(kind: kind, existing: existing),
    );

class CategorySheet extends ConsumerStatefulWidget {
  final String kind;
  final Category? existing;
  const CategorySheet({super.key, required this.kind, this.existing});
  @override
  ConsumerState<CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends ConsumerState<CategorySheet> {
  final name = TextEditingController();
  final budget = TextEditingController();
  late String icon;
  late int color;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    icon = e?.icon ?? (widget.kind == 'expense' ? 'grocery' : 'salary');
    color = e?.color ?? kCatColors[4];
    name.text = e?.name ?? '';
    if (e?.budget != null) budget.text = e!.budget!.toStringAsFixed(0);
  }

  @override
  void dispose() {
    name.dispose();
    budget.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (name.text.trim().isEmpty) return snack(context, '${S.name} ${S.required}');
    final b = double.tryParse(budget.text.replaceAll(',', ''));
    final c = Category(
      id: widget.existing?.id ?? 0,
      name: name.text.trim(),
      icon: icon,
      color: color,
      kind: widget.kind,
      budget: widget.kind == 'expense' && b != null && b > 0 ? b : null,
      sort: widget.existing?.sort ?? 0,
    );
    final repo = ref.read(repoProvider);
    if (widget.existing != null) {
      await repo.updateCategory(c);
    } else {
      await repo.insertCategory(c);
    }
    ref.bump();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final s = ref.watch(settingsProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            Row(
              children: [
                Expanded(
                  child: Text(widget.existing != null ? S.editCategory : S.newCategory,
                      style: context.tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(color),
                  boxShadow: [
                    BoxShadow(
                        color: Color(color).withValues(alpha: 0.45),
                        blurRadius: 22,
                        offset: const Offset(0, 8)),
                  ],
                ),
                child: Icon(catIcon(icon), color: const Color(0xFF14181F), size: 34),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: name,
              autofocus: widget.existing == null,
              decoration: const InputDecoration(labelText: S.name),
            ),
            const SizedBox(height: 18),
            Text(S.color, style: TextStyle(color: p.muted, fontSize: 12.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final c in kCatColors)
                  GestureDetector(
                    onTap: () => setState(() => color = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(c),
                        border: Border.all(
                          color: c == color ? p.text : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: c == color
                          ? const Icon(Icons.check_rounded, size: 18, color: Color(0xFF14181F))
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(S.icon, style: TextStyle(color: p.muted, fontSize: 12.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final k in kCatIcons.keys)
                  GestureDetector(
                    onTap: () => setState(() => icon = k),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: k == icon ? Color(color).withValues(alpha: 0.22) : p.surface2,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: k == icon ? Color(color) : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(kCatIcons[k], size: 22, color: k == icon ? Color(color) : p.muted),
                    ),
                  ),
              ],
            ),
            if (widget.kind == 'expense') ...[
              const SizedBox(height: 18),
              TextField(
                controller: budget,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontFeatures: kTabular, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  labelText: S.budget,
                  hintText: S.budgetHint,
                  suffixText: s.baseCurrency,
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _save,
              child: Text(widget.existing != null ? S.save : S.add),
            ),
          ],
        ),
      ),
    );
  }
}
