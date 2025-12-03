import 'package:sqflite/sqflite.dart';
import '../app_db.dart';

class SubTaskDao {
  Future<List<Map<String, dynamic>>> getSubtasks(int taskId) async {
    final db = await AppDb.instance();
    return db.query('subtask', where: 'task_id = ?', whereArgs: [taskId]);
  }

  Future<int> insertSubtask(Map<String, dynamic> data) async {
    final db = await AppDb.instance();
    return db.insert('subtask', data);
  }

  Future<int> updateSubtask(int id, Map<String, dynamic> data) async {
    final db = await AppDb.instance();
    return db.update('subtask', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteSubtask(int id) async {
    final db = await AppDb.instance();
    return db.delete('subtask', where: 'id = ?', whereArgs: [id]);
  }
}