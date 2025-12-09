import 'package:sqflite/sqflite.dart';
import '../app_db.dart';
import '../models/task.dart';
import '../models/subtask.dart';

class TasksRepository {
  // -------------------------------------------------------------
  // LOAD ALL TASKS (including subtasks + assigned employees)
  // -------------------------------------------------------------
  Future<List<TaskModel>> getAllTasks() async {
    final db = await AppDatabase.instance();
    final taskMaps = await db.query('task', orderBy: 'id DESC');

    final tasks = <TaskModel>[];

    for (var map in taskMaps) {
      final task = TaskModel.fromDb(map);

      // Load subtasks
      task.subtasks = await getSubTasks(task.id!);

      // Load assigned employees
      task.assignedEmployees = await getEmployeesForTask(task.id!);

      tasks.add(task);
    }

    return tasks;
  }

  // -------------------------------------------------------------
  // SUBTASKS
  // -------------------------------------------------------------
  Future<List<SubTaskModel>> getSubTasks(int taskId) async {
    final db = await AppDatabase.instance();
    final rows = await db.query(
      'subtask',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'id ASC',
    );

    return rows.map((m) => SubTaskModel.fromDb(m)).toList();
  }
  // -------------------------------------------------------------
  // SUBTASK INSERT + UPDATE (needed by UI)
  // -------------------------------------------------------------
  Future<int> insertSubTask(SubTaskModel sub) async {
    final db = await AppDatabase.instance();
    return await db.insert('subtask', {
      'task_id': sub.taskId,
      'title': sub.title,
      'completed': sub.completed ? 1 : 0,
    });
  }

  Future<void> updateSubTask(SubTaskModel sub) async {
    final db = await AppDatabase.instance();
    await db.update(
      'subtask',
      {
        'title': sub.title,
        'completed': sub.completed ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [sub.id],
    );
  }

  // -------------------------------------------------------------
  // INSERT / UPDATE / DELETE TASK
  // -------------------------------------------------------------
  Future<int> insertTask(TaskModel task) async {
    final db = await AppDatabase.instance();
    return await db.insert('task', task.toDb());
  }

  Future<void> updateTask(TaskModel task) async {
    final db = await AppDatabase.instance();
    await db.update(
      'task',
      task.toDb(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(int taskId) async {
    final db = await AppDatabase.instance();

    // Delete subtasks
    await db.delete('subtask', where: 'task_id = ?', whereArgs: [taskId]);

    // Delete assigned employees
    await db.delete('task_employee', where: 'task_id = ?', whereArgs: [taskId]);

    // Delete task
    await db.delete('task', where: 'id = ?', whereArgs: [taskId]);
  }

  // -------------------------------------------------------------
  // MULTI-EMPLOYEE ASSIGNMENT LOGIC
  // -------------------------------------------------------------

  /// Returns: [{employee_id: 3, full_name: "John"}, ...]
  Future<List<Map<String, dynamic>>> getEmployeesForTask(int taskId) async {
    final db = await AppDatabase.instance();

    final rows = await db.rawQuery('''
      SELECT e.id AS employee_id, e.full_name
      FROM task_employee te
      JOIN employee e ON e.id = te.employee_id
      WHERE te.task_id = ?
    ''', [taskId]);

    return rows;
  }

  /// Assign a list of employee IDs to a task
  Future<void> assignEmployees(int taskId, List<int> employeeIds) async {
    final db = await AppDatabase.instance();

    // Remove old assignments
    await db.delete('task_employee', where: 'task_id = ?', whereArgs: [taskId]);

    // Insert new mappings
    for (int empId in employeeIds) {
      await db.insert('task_employee', {
        'task_id': taskId,
        'employee_id': empId,
      });
    }
  }

  /// Returns tasks assigned to one employee (for employee calendar)
  Future<List<TaskModel>> getTasksForEmployee(int employeeId) async {
    final db = await AppDatabase.instance();

    final rows = await db.rawQuery('''
      SELECT t.*
      FROM task t
      JOIN task_employee te ON te.task_id = t.id
      WHERE te.employee_id = ?
    ''', [employeeId]);

    List<TaskModel> tasks = [];

    for (var map in rows) {
      final task = TaskModel.fromDb(map);
      task.subtasks = await getSubTasks(task.id!);
      task.assignedEmployees = await getEmployeesForTask(task.id!);
      tasks.add(task);
    }

    return tasks;
  }
}
