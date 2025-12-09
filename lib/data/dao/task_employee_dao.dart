import 'package:sqflite/sqflite.dart';
import '../app_db.dart';

class TaskEmployeeDao {
  Future<List<Map<String, dynamic>>> getEmployeesForTask(int taskId) async {
    final db = await AppDatabase.instance();

    return db.rawQuery('''
      SELECT e.id, e.full_name
      FROM task_employee te
      JOIN employee e ON e.id = te.employee_id
      WHERE te.task_id = ?
    ''', [taskId]);
  }

  Future<void> assignEmployee(int taskId, int employeeId) async {
    final db = await AppDatabase.instance();
    await db.insert(
      'task_employee',
      {'task_id': taskId, 'employee_id': employeeId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> unassignEmployee(int taskId, int employeeId) async {
    final db = await AppDatabase.instance();
    await db.delete(
      'task_employee',
      where: 'task_id = ? AND employee_id = ?',
      whereArgs: [taskId, employeeId],
    );
  }

  Future<void> clearEmployees(int taskId) async {
    final db = await AppDatabase.instance();
    await db.delete('task_employee', where: 'task_id = ?', whereArgs: [taskId]);
  }
}
