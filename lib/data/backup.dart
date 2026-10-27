import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/format.dart';
import 'repo.dart';

const _app = 'girfan';
const _format = 1;

/// Writes every table plus [settings] to a JSON file and opens the share
/// sheet (Google Drive, WhatsApp, Files...). Returns false if the user
/// closed the sheet without sharing.
Future<bool> shareBackup(Repo repo, Map<String, Object?> settings) async {
  final data = {
    'app': _app,
    'format': _format,
    'created': DateTime.now().toIso8601String(),
    'settings': settings,
    'tables': await repo.dumpAll(),
  };
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/girfan-backup-${dateKey(DateTime.now())}.json');
  await file.writeAsString(jsonEncode(data));
  final r = await SharePlus.instance.share(ShareParams(
    files: [XFile(file.path, mimeType: 'application/json')],
    subject: 'Girfan backup',
  ));
  return r.status != ShareResultStatus.dismissed;
}

class BackupFile {
  final Map<String, dynamic> settings;
  final Map<String, dynamic> tables;
  final String created;
  final int txCount;
  const BackupFile(this.settings, this.tables, this.created, this.txCount);
}

/// Lets the user pick a backup file. Returns null when cancelled; throws
/// [FormatException] when the file is not a Girfan backup.
Future<BackupFile?> pickBackup() async {
  final res = await FilePicker.platform.pickFiles(type: FileType.any, withData: true);
  if (res == null || res.files.isEmpty) return null;
  final f = res.files.single;
  final bytes = f.bytes ?? (f.path != null ? await File(f.path!).readAsBytes() : null);
  if (bytes == null) throw const FormatException('empty');
  final Object? json;
  try {
    json = jsonDecode(utf8.decode(bytes));
  } catch (_) {
    throw const FormatException('not json');
  }
  if (json is! Map<String, dynamic> || json['app'] != _app || json['tables'] is! Map) {
    throw const FormatException('not a girfan backup');
  }
  final tables = json['tables'] as Map<String, dynamic>;
  return BackupFile(
    (json['settings'] as Map<String, dynamic>?) ?? const {},
    tables,
    (json['created'] as String?) ?? '',
    ((tables['transactions'] as List?) ?? const []).length,
  );
}
