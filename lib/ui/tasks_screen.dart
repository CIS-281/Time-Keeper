import 'package:flutter/material.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  // In-memory task list
  final List<Task> _tasks = [];

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
                  Text('Subtasks: ${task.subtasks.map((s) => s.title).join(', ')}'),
              ],
            ),
            children: [
              for (var subtask in task.subtasks)
                ListTile(
                  leading: Checkbox(
                    value: subtask.completed,
                    onChanged: (val) {
                      setState(() => subtask.completed = val ?? false);
                    },
                  ),
                  title: Text(subtask.title),
                ),
              OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: 8, // optional spacing between buttons
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

  void _editTask(Task task) => _showTaskDialog(task: task);

  void _deleteTask(Task task) {
    setState(() {
      _tasks.remove(task);
    });
  }

  void _addSubtask(Task task) {
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isEmpty) return;
              setState(() {
                task.subtasks.add(SubTask(title: controller.text));
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showTaskDialog({Task? task}) {
    final titleController = TextEditingController(text: task?.title ?? '');
    final categoryController = TextEditingController(text: task?.category ?? '');
    final clientController = TextEditingController(text: task?.clientJob ?? '');
    final recurrenceController = TextEditingController(text: task?.recurrence ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(task == null ? 'Add Task' : 'Edit Task'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Task Title')),
              TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category')),
              TextField(controller: clientController, decoration: const InputDecoration(labelText: 'Client/Job')),
              TextField(controller: recurrenceController, decoration: const InputDecoration(labelText: 'Recurrence')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isEmpty) return;
              setState(() {
                if (task == null) {
                  _tasks.add(Task(
                    title: titleController.text,
                    category: categoryController.text,
                    clientJob: clientController.text,
                    recurrence: recurrenceController.text,
                  ));
                } else {
                  task.title = titleController.text;
                  task.category = categoryController.text;
                  task.clientJob = clientController.text;
                  task.recurrence = recurrenceController.text;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// Models
class Task {
  String title;
  String? category;
  List<SubTask> subtasks = [];
  String? clientJob;
  String? recurrence;

  Task({required this.title, this.category, this.clientJob, this.recurrence});
}

class SubTask {
  String title;
  bool completed = false;

  SubTask({required this.title});
}
