import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/format.dart';
import 'models.dart';
import 'repo.dart';

/// Writes every transaction to a UTF-8 CSV (with BOM so Excel reads Kurdish)
/// and opens the system share sheet.
Future<void> exportCsv(Repo repo, Map<int, Category> cats) async {
  final txs = await repo.allTx();
  final sb = StringBuffer('﻿');
  sb.writeln('date,type,category,amount,currency,note');
  String esc(String s) => '"${s.replaceAll('"', '""')}"';
  for (final t in txs) {
    sb.writeln([
      t.date,
      t.kind,
      esc(cats[t.categoryId]?.name ?? ''),
      t.amount.toString(),
      t.currency,
      esc(t.note),
    ].join(','));
  }
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/masruf-${dateKey(DateTime.now())}.csv');
  await file.writeAsString(sb.toString());
  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path, mimeType: 'text/csv')], subject: 'Masruf export'),
  );
}
