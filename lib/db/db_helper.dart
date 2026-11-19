// lib/db/db_helper.dart
// sqflite 数据库单例：建表 / CRUD / 迁移
// 规避 EX22：全部操作 await
// 规避 EX23：条件查询全用 whereArgs 参数化，绝不字符串拼接

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/record.dart';

class DbHelper {
  DbHelper._();
  static final DbHelper instance = DbHelper._();

  static Database? _db;

  /// 全局只 open 一次，避免重复连接
  Future<Database> get database async {
    if (_db != null) return _db!;
    // getDatabasesPath() 在 sqflite 2.x 里已废弃，用 path_provider 拿到文档目录自己拼
    final dir = await getApplicationDocumentsDirectory();
    _db = await openDatabase(
      p.join(dir.path, 'book.db'),
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE book_record(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type INTEGER NOT NULL,
        amount REAL NOT NULL,
        remark TEXT,
        createAt TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_record_createAt ON book_record(createAt DESC)',
    );
  }

  /// 版本迁移三件套（规避 EX24）
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // await db.execute('ALTER TABLE book_record ADD COLUMN category TEXT');
    }
  }

  // ---------- CRUD ----------

  /// 新增
  Future<int> insert(Record r) async =>
      await (await database).insert('book_record', r.toMap());

  /// 查询全部（时间倒序）
  Future<List<Record>> queryAll() async {
    final db = await database;
    final rows = await db.query('book_record', orderBy: 'createAt DESC');
    return rows.map(Record.fromMap).toList();
  }

  /// 关键词搜索 + 类型筛选（全部参数化，规避 EX23）
  Future<List<Record>> search({String keyword = '', int? type}) async {
    final db = await database;
    final List<String> whereClauses = [];
    final List<dynamic> args = [];

    if (keyword.isNotEmpty) {
      whereClauses.add('remark LIKE ?');
      args.add('%$keyword%');
    }
    if (type != null) {
      whereClauses.add('type = ?');
      args.add(type);
    }

    final rows = await db.query(
      'book_record',
      where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'createAt DESC',
    );
    return rows.map(Record.fromMap).toList();
  }

  /// 按 id 查单条
  Future<Record?> queryById(int id) async {
    final db = await database;
    final rows = await db.query(
      'book_record',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Record.fromMap(rows.first);
  }

  /// 更新
  Future<int> update(Record r) async {
    if (r.id == null) return 0;
    return await (await database).update(
      'book_record',
      r.toMap(),
      where: 'id = ?',
      whereArgs: [r.id],
    );
  }

  /// 删除
  Future<int> delete(int id) async =>
      await (await database).delete(
        'book_record',
        where: 'id = ?',
        whereArgs: [id],
      );

  /// 清空全部（个人中心「清空本地数据」入口）
  Future<void> clearAll() async =>
      await (await database).delete('book_record');

  /// 月度汇总：传 yyyy-MM（如 "2026-11"），返回 {expense, income}
  Future<(double expense, double income)> monthSum(String prefix) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT type, SUM(amount) AS total
      FROM book_record
      WHERE createAt LIKE ?
      GROUP BY type
      ''',
      ['$prefix%'],
    );
    double expense = 0, income = 0;
    for (final row in rows) {
      final t = row['type'] as int;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      t == 0 ? expense = total : income = total;
    }
    return (expense, income);
  }
}
