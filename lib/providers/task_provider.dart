import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/task.dart';
 
class TaskProvider extends ChangeNotifier {
  static const table = 'tasks';
  Database? _db;
  List<Task> _items = [];
  bool _busy = false;
  bool _disposed = false;
  String? _error;
  List<Task> get items => List.unmodifiable(_items);
  bool get busy => _busy;
  String? get error => _error;
 
  void _notify() {
    if (!_disposed) notifyListeners();
  }
  Future<Database> _database() async {
    if (_db != null) return _db!;
    final file = join(await getDatabasesPath(), 'task_quiz.db');
    _db = await openDatabase(
      file,
      version: 1,
      onCreate: (db, version) => db.execute(
        'CREATE TABLE $table ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT, '
        'title TEXT NOT NULL, '
        'dueDate TEXT NOT NULL, '
        'isDone INTEGER NOT NULL CHECK (isDone IN (0, '
        '1))'
        ')',
      ),
    );
    return _db!;
  }
 
  Future<void> _readAll() async {
    final db = await _database();
    final rows = await db.query(table, orderBy: 'id DESC');
    _items = rows.map((m) => Task.fromMap(m)).toList();
  }
 
  Future<bool> _run(Future<void> Function() action) async {
    if (_busy) return false;
    _busy = true;
    _error = null;
    _notify();
    try {
      await action();
      return true;
    } catch (e) {
      _error = 'Database error: $e';
      return false;
    } finally {
      _busy = false;
      _notify();
    }
  }
  Future<bool> load() => _run(_readAll);
 
  Future<bool> save(Task item) => _run(() async {
        final db = await _database();
        final values = item.toMap()..remove('id');
        if (item.id == null) {
          await db.insert(table, values);
        } else {
          final count = await db
              .update(table, values, where: 'id = ?', whereArgs: [item.id]);
          if (count != 1) throw StateError('Record not found');
        }
        await _readAll();
      });
 
  Future<bool> delete(int id) => _run(() async {
        final db = await _database();
        final count = await db.delete(table, where: 'id = ?', whereArgs: [id]);
        if (count != 1) throw StateError('Record not found');
        await _readAll();
      });
 
  @override
  void dispose() {
    _disposed = true;
    // Keep DB open for this app session and pending writes.
    super.dispose();
  }
}
