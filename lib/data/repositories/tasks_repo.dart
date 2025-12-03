import 'package:sqflite/sqflite.dart';
import '../app_db.dart';
import '../models/task.dart';
import '../models/subtask.dart';

class TasksRepository {
  // Get all tasks from the database along with their subtasks
  Future<List<TaskModel>> getAllTasks() async {
    final db = await AppDatabase.instance();
    final taskMaps = await db.query('task', orderBy: 'id DESC');

    final tasks = <TaskModel>[];
    for (var map in taskMaps) {
      final task = TaskModel.fromDb(map);
      task.subtasks = await getSubTasks(task.id!);
      tasks.add(task);
    }

    return tasks;
  }

  // Get all subtasks for a specific task
  Future<List<SubTaskModel>> getSubTasks(int taskId) async {
    final db = await AppDatabase.instance();
    final subtaskMaps = await db.query(
      'subtask',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'id ASC',
    );
    return subtaskMaps.map((map) => SubTaskModel.fromDb(map)).toList();
  }

  // Insert a new task and return its ID
  Future<int> insertTask(TaskModel task) async {
    final db = await AppDatabase.instance();
    return await db.insert('task', task.toDb());
  }

  // Update an existing task
  Future<void> updateTask(TaskModel task) async {
    final db = await AppDatabase.instance();
    await db.update(
      'task',
      task.toDb(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  // Delete a task and its subtasks
  Future<void> deleteTask(int taskId) async {
    final db = await AppDatabase.instance();
    await db.delete('subtask', where: 'task_id = ?', whereArgs: [taskId]);
    await db.delete('task', where: 'id = ?', whereArgs: [taskId]);
  }

  // Insert a new subtask and return its ID
  Future<int> insertSubTask(SubTaskModel subtask) async {
    final db = await AppDatabase.instance();
    return await db.insert('subtask', subtask.toDb());
  }

  // Update an existing subtask
  Future<void> updateSubTask(SubTaskModel subtask) async {
    final db = await AppDatabase.instance();
    await db.update(
      'subtask',
      subtask.toDb(),
      where: 'id = ?',
      whereArgs: [subtask.id],
    );
  }

  // Delete a subtask
  Future<void> deleteSubTask(int subtaskId) async {
    final db = await AppDatabase.instance();
    await db.delete('subtask', where: 'id = ?', whereArgs: [subtaskId]);
  }
}