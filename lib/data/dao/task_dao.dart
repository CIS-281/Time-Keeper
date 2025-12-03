import 'package:sqflite/sqflite.dart';
import '../app_db.dart';

class TaskDao {
  Future<List<Map<String, dynamic>>> getAllTasks() async {
    final db = await AppDb.instance();
    return db.query('task');
  }

  Future<int> insertTask(Map<String, dynamic> data) async {
    final db = await AppDb.instance();
    return db.insert('task', data);
  }

  Future<int> updateTask(int id, Map<String, dynamic> data) async {
    final db = await AppDb.instance();
    return db.update('task', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTask(int id) async {
    final db = await AppDb.instance();
    return db.delete('task', where: 'id = ?', whereArgs: [id]);
  }
}