import 'package:flutter/material.dart';
import 'package:time_keeper/data/models/task.dart';
import 'package:time_keeper/data/models/subtask.dart';
import 'package:time_keeper/data/repositories/tasks_repo.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _repo = TasksRepository();
  List<TaskModel> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await _repo.getAllTasks();
    setState(() {
      _tasks = tasks;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tasks.isEmpty
          ? const Center(
        child: Text('No tasks yet!', style: TextStyle(fontSize: 18)),
      )
          : ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return ExpansionTile(
            key: Key(task.title),
            title: Text(task.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.category != null && task.category!.isNotEmpty)
                  Text('Category: ${task.category}'),
                if (task.clientJob != null && task.clientJob!.isNotEmpty)
                  Text('Client/Job: ${task.clientJob}'),
                if (task.recurrence != null && task.recurrence!.isNotEmpty)
                  Text('Recurrence: ${task.recurrence}'),
                if (task.subtasks.isNotEmpty)
                  Text(
                      'Subtasks: ${task.subtasks.map((s) => s.title).join(', ')}'),
              ],
            ),
            children: [
              for (var subtask in task.subtasks)
                ListTile(
                  leading: Checkbox(
                    value: subtask.completed,
                    onChanged: (val) async {
                      subtask.completed = val ?? false;
                      try {
                        await _repo.updateSubTask(subtask);
                      } catch (e) {
                        print('Error updating subtask: $e');
                      }
                      setState(() {});
                    },
                  ),
                  title: Text(subtask.title),
                ),
              OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => _addSubtask(task),
                    child: const Text('Add Subtask'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editTask(task),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteTask(task),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addTask() => _showTaskDialog();

  void _editTask(TaskModel task) => _showTaskDialog(task: task);

  Future<void> _deleteTask(TaskModel task) async {
    try {
      await _repo.deleteTask(task.id!);
      setState(() {
        _tasks.remove(task);
      });
    } catch (e) {
      print('Error deleting task: $e');
    }
  }

  void _addSubtask(TaskModel task) {
    if (task.id == null) return; // Safety check
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Subtask'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Subtask Title'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;

              try {
                final subtask = SubTaskModel(
                  taskId: task.id!,
                  title: controller.text,
                );
                final id = await _repo.insertSubTask(subtask);
                subtask.id = id;

                setState(() {
                  task.subtasks.add(subtask);
                });
                Navigator.pop(context);
              } catch (e) {
                print('Error adding subtask: $e');
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showTaskDialog({TaskModel? task}) {
    final titleController = TextEditingController(text: task?.title ?? '');
    final categoryController =
    TextEditingController(text: task?.category ?? '');
    final clientController =
    TextEditingController(text: task?.clientJob ?? '');
    final recurrenceController =
    TextEditingController(text: task?.recurrence ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(task == null ? 'Add Task' : 'Edit Task'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Task Title')),
              TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Category')),
              TextField(
                  controller: clientController,
                  decoration:
                  const InputDecoration(labelText: 'Client/Job')),
              TextField(
                  controller: recurrenceController,
                  decoration:
                  const InputDecoration(labelText: 'Recurrence')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty) return;

              try {
                if (task == null) {
                  final newTask = TaskModel(
                    title: titleController.text,
                    category: categoryController.text,
                    clientJob: clientController.text,
                    recurrence: recurrenceController.text,
                  );
                  final id = await _repo.insertTask(newTask);
                  newTask.id = id;
                  setState(() => _tasks.add(newTask));
                } else {
                  task.title = titleController.text;
                  task.category = categoryController.text;
                  task.clientJob = clientController.text;
                  task.recurrence = recurrenceController.text;
                  await _repo.updateTask(task);
                  setState(() {});
                }

                Navigator.pop(context);
              } catch (e) {
                print('Error saving task: $e');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}