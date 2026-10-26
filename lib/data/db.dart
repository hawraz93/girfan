import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDb {
  static Database? _db;

  static bool get _desktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  /// Tests set this to a temp folder so no platform plugin is needed.
  static String? directoryOverride;

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    final String dir;
    if (directoryOverride != null) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      dir = directoryOverride!;
    } else if (_desktop) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      dir = (await getApplicationSupportDirectory()).path;
    } else {
      dir = await getDatabasesPath();
    }
    _db = await openDatabase(
      join(dir, 'masruf.db'),
      version: 1,
      onCreate: _create,
    );
    return _db!;
  }

  static Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL,
        kind TEXT NOT NULL,
        budget REAL,
        sort INTEGER NOT NULL DEFAULT 0,
        archived INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kind TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        recurring_id INTEGER,
        period TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');
    await db.execute('CREATE INDEX idx_tx_date ON transactions(date)');
    await db.execute(
        'CREATE INDEX idx_tx_recurring ON transactions(recurring_id, period)');
    await db.execute('''
      CREATE TABLE recurrings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        kind TEXT NOT NULL,
        day_of_month INTEGER NOT NULL,
        start_month TEXT NOT NULL,
        end_month TEXT,
        note TEXT NOT NULL DEFAULT '',
        active INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await _seed(db);
  }

  static Future<void> _seed(Database db) async {
    const expense = [
      ['خواردن', 'restaurant', 0xFFF4A259],
      ['بازاڕ', 'grocery', 0xFFA3D977],
      ['مناڵ', 'child', 0xFFFF7BB3],
      ['سەیارە', 'car', 0xFF4FC3F7],
      ['خانوو', 'home', 0xFF6C8CFF],
      ['تەندروستی', 'health', 0xFFF17B73],
      ['جل و بەرگ', 'clothes', 0xFF9B7BFF],
      ['کات بەسەربردن', 'fun', 0xFFD67BFF],
      ['مۆبایل و ئینتەرنێت', 'phone', 0xFF5FD3A3],
      ['پەروەردە', 'school', 0xFFE8B54D],
      ['هیتر', 'more', 0xFF8A93A3],
    ];
    const income = [
      ['موچە', 'salary', 0xFF5FD3A3],
      ['کاری سەربەخۆ', 'work', 0xFF4FC3F7],
      ['دیاری', 'gift', 0xFFE8B54D],
      ['هیتر', 'more', 0xFF8A93A3],
    ];
    final batch = db.batch();
    for (var i = 0; i < expense.length; i++) {
      batch.insert('categories', {
        'name': expense[i][0],
        'icon': expense[i][1],
        'color': expense[i][2],
        'kind': 'expense',
        'sort': i,
      });
    }
    for (var i = 0; i < income.length; i++) {
      batch.insert('categories', {
        'name': income[i][0],
        'icon': income[i][1],
        'color': income[i][2],
        'kind': 'income',
        'sort': i,
      });
    }
    await batch.commit(noResult: true);
  }
}
