// lib/ui/tasks_screen.dart
import 'package:flutter/material.dart';
import 'package:time_keeper/data/models/task.dart';
import 'package:time_keeper/data/models/subtask.dart';
import 'package:time_keeper/data/repositories/tasks_repo.dart';
import 'package:time_keeper/data/app_db.dart';
import 'package:time_keeper/data/dao/task_employee_dao.dart';
import 'package:time_keeper/services/org_service.dart';
import 'package:time_keeper/services/manager_mode_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _repo = TasksRepository();
  final _org = OrgService();
  final _taskEmployeeDao = TaskEmployeeDao();

  String? _companyId;
  bool _isManagerMode = false;
  List<Map<String, dynamic>> _employees = [];

  List<TaskModel> _tasks = [];

  static const List<String> _recurrenceOptions = <String>[
    'None',
    'Daily',
    'Weekly',
    'Bi-weekly',
    'Monthly',
  ];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final companyId = await _org.activeCompanyId();
    if (companyId == null) return;

    _companyId = companyId;

    final mgr = ManagerModeService(companyId);
    _isManagerMode = await mgr.isEnabled();

    // Load employees for this company
    final db = await AppDatabase.instance();
    _employees = await db.query(
      'employee',
      where: 'company_id = ?',
      whereArgs: [companyId],
      orderBy: 'full_name ASC',
    );

    // Load tasks (with subtasks and assignedEmployees via repository)
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
        child: Text(
          'No tasks yet!',
          style: TextStyle(fontSize: 18),
        ),
      )
          : ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];

          final clientLabel =
          (task.clientJob == null || task.clientJob!.isEmpty)
              ? 'No client'
              : 'Client: ${task.clientJob}';

          final employeeSummary = _buildEmployeeSummary(task);

          return Card(
            margin:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ExpansionTile(
              key: Key('task_${task.id ?? index}'),
              title: Text(
                task.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '$clientLabel • $employeeSummary',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              children: [
                // DETAILS
                ExpansionTile(
                  title: const Text('Details'),
                  children: [
                    _detailRow('Category', task.category),
                    _detailRow(
                      'Recurrence',
                      task.recurrence == null ||
                          task.recurrence!.isEmpty
                          ? 'None'
                          : task.recurrence,
                    ),
                    _detailRow(
                      'Employees',
                      _employeeNamesForDetails(task),
                    ),
                    _detailRow(
                      'Start',
                      _formatDateTime(task.startUtc),
                    ),
                    _detailRow(
                      'End',
                      _formatDateTime(task.endUtc),
                    ),
                    if (task.jobSiteId != null)
                      _detailRow(
                        'Job Site ID',
                        task.jobSiteId.toString(),
                      ),
                  ],
                ),

                // SUBTASKS
                ExpansionTile(
                  title: const Text('Subtasks'),
                  children: [
                    if (task.subtasks.isEmpty)
                      const ListTile(
                        title: Text('No subtasks yet'),
                      ),
                    for (final subtask in task.subtasks)
                      CheckboxListTile(
                        value: subtask.completed,
                        onChanged: (val) async {
                          subtask.completed = val ?? false;
                          await _repo.updateSubTask(subtask);
                          setState(() {});
                        },
                        title: Text(subtask.title),
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _addSubtask(task),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Subtask'),
                      ),
                    ),
                  ],
                ),

                // ACTIONS
                ButtonBar(
                  alignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _showTaskDialog(task: task),
                      child: const Text('Edit'),
                    ),
                    TextButton(
                      onPressed: () => _deleteTask(task),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Display helpers
  // ---------------------------------------------------------------------------

  Widget _detailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return ListTile(
      dense: true,
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(value),
    );
  }

  String _buildEmployeeSummary(TaskModel task) {
    final emps = task.assignedEmployees;
    if (emps.isEmpty) return 'No employees assigned';

    if (emps.length == 1) {
      return 'Employee: ${emps.first['full_name'] ?? 'Unknown'}';
    }
    if (emps.length == 2) {
      final names = emps
          .map((e) => (e['full_name'] as String?) ?? 'Unknown')
          .take(2)
          .join(', ');
      return 'Employees: $names';
    }

    final firstTwo = emps
        .map((e) => (e['full_name'] as String?) ?? 'Unknown')
        .take(2)
        .join(', ');
    final remaining = emps.length - 2;
    return 'Employees: $firstTwo + $remaining more';
  }

  String _employeeNamesForDetails(TaskModel task) {
    if (task.assignedEmployees.isEmpty) return 'None';
    return task.assignedEmployees
        .map((e) => (e['full_name'] as String?) ?? 'Unknown')
        .join(', ');
  }

  String _formatDateTime(int? millis) {
    if (millis == null) return 'Not set';
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.month}/${dt.day}/${dt.year} $h:$m';
  }

  // ---------------------------------------------------------------------------
  // Subtasks
  // ---------------------------------------------------------------------------

  Future<void> _deleteTask(TaskModel task) async {
    if (task.id == null) return;
    await _repo.deleteTask(task.id!);
    setState(() => _tasks.remove(task));
  }

  void _addSubtask(TaskModel task) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Subtask'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Subtask title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty || task.id == null) return;

              final sub = SubTaskModel(
                taskId: task.id!,
                title: controller.text,
              );
              sub.id = await _repo.insertSubTask(sub);
              task.subtasks.add(sub);

              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Task creation / editing dialog
  // ---------------------------------------------------------------------------

  void _showTaskDialog({TaskModel? task}) {
    final titleCtrl = TextEditingController(text: task?.title ?? '');
    final categoryCtrl = TextEditingController(text: task?.category ?? '');
    final clientCtrl = TextEditingController(text: task?.clientJob ?? '');

    String recurrenceValue = task?.recurrence != null &&
        _recurrenceOptions.contains(task!.recurrence!)
        ? task.recurrence!
        : 'None';

    DateTime? selectedDate;
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    if (task?.startUtc != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(task!.startUtc!);
      selectedDate = DateTime(dt.year, dt.month, dt.day);
      startTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    }
    if (task?.endUtc != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(task!.endUtc!);
      selectedDate ??= DateTime(dt.year, dt.month, dt.day);
      endTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    }

    // Multi-employee selection – defensively ignore bad/missing IDs
    List<int> selectedEmployeeIds = (task?.assignedEmployees ?? [])
        .map((e) => e['id'])
        .whereType<int>()
        .toList();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) {
          String employeeButtonLabel;
          if (selectedEmployeeIds.isEmpty) {
            employeeButtonLabel = 'Assign employees';
          } else if (selectedEmployeeIds.length == 1) {
            final emp = _employees.firstWhere(
                  (e) => e['id'] == selectedEmployeeIds.first,
              orElse: () => {'full_name': 'Selected'},
            );
            employeeButtonLabel = (emp['full_name'] as String?) ?? 'Selected';
          } else {
            employeeButtonLabel =
            '${selectedEmployeeIds.length} employees selected';
          }

          final bool showTimeWarning =
              _isManagerMode && selectedDate != null && startTime == null;

          return AlertDialog(
            title: Text(task == null ? 'Add Task' : 'Edit Task'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration:
                    const InputDecoration(labelText: 'Task title'),
                  ),
                  TextField(
                    controller: categoryCtrl,
                    decoration:
                    const InputDecoration(labelText: 'Category'),
                  ),
                  TextField(
                    controller: clientCtrl,
                    decoration:
                    const InputDecoration(labelText: 'Client / Job'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: recurrenceValue,
                    items: _recurrenceOptions
                        .map(
                          (opt) => DropdownMenuItem<String>(
                        value: opt,
                        child: Text(opt),
                      ),
                    )
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() {
                        recurrenceValue = val;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Recurrence'),
                  ),
                  const SizedBox(height: 12),

                  // Manager-only: employees + schedule
                  if (_isManagerMode) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Assigned employees',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.group),
                      label: Text(employeeButtonLabel),
                      onPressed: _employees.isEmpty
                          ? null
                          : () async {
                        final updated =
                        await _pickEmployees(selectedEmployeeIds);
                        setState(() {
                          selectedEmployeeIds = updated;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        selectedDate == null
                            ? 'Pick date'
                            : 'Date: ${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}',
                      ),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2030),
                        );
                        if (d != null) {
                          setState(() => selectedDate = d);
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        startTime == null
                            ? 'Pick start time (optional)'
                            : 'Start: ${startTime!.format(context)}',
                      ),
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: startTime ?? TimeOfDay.now(),
                        );
                        if (t != null) {
                          setState(() => startTime = t);
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        endTime == null
                            ? 'Pick end time (optional)'
                            : 'End: ${endTime!.format(context)}',
                      ),
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: endTime ?? TimeOfDay.now(),
                        );
                        if (t != null) {
                          setState(() => endTime = t);
                        }
                      },
                    ),
                    if (showTimeWarning)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'No start time selected. The task will still be saved for this date and shown on the calendar.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) {
                      // Title is required
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Title is required'),
                        ),
                      );
                      return;
                    }

                    int? startUtc;
                    int? endUtc;

                    if (_isManagerMode) {
                      // In manager mode, date is required for scheduling
                      if (selectedDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a date for this task.'),
                          ),
                        );
                        return;
                      }

                      // If no startTime, treat as all-day starting at midnight
                      final baseDate = DateTime(
                        selectedDate!.year,
                        selectedDate!.month,
                        selectedDate!.day,
                      );

                      if (startTime != null) {
                        startUtc = DateTime(
                          selectedDate!.year,
                          selectedDate!.month,
                          selectedDate!.day,
                          startTime!.hour,
                          startTime!.minute,
                        ).millisecondsSinceEpoch;
                      } else {
                        startUtc = baseDate.millisecondsSinceEpoch;
                      }

                      if (endTime != null) {
                        endUtc = DateTime(
                          selectedDate!.year,
                          selectedDate!.month,
                          selectedDate!.day,
                          endTime!.hour,
                          endTime!.minute,
                        ).millisecondsSinceEpoch;
                      } else {
                        endUtc = null;
                      }
                    }

                    final recurrenceToSave =
                    recurrenceValue == 'None' ? null : recurrenceValue;

                    final assignedEmployees =
                    _buildAssignedEmployeesFromIds(selectedEmployeeIds);

                    if (task == null) {
                      // New task
                      final newTask = TaskModel(
                        title: title,
                        category: categoryCtrl.text.trim().isEmpty
                            ? null
                            : categoryCtrl.text.trim(),
                        clientJob: clientCtrl.text.trim().isEmpty
                            ? null
                            : clientCtrl.text.trim(),
                        recurrence: recurrenceToSave,
                        companyId: _companyId,
                        startUtc: startUtc,
                        endUtc: endUtc,
                        assignedEmployees: assignedEmployees,
                      );

                      final newId = await _repo.insertTask(newTask);
                      newTask.id = newId;

                      await _taskEmployeeDao.clearEmployees(newId);
                      for (final empId in selectedEmployeeIds) {
                        await _taskEmployeeDao.assignEmployee(newId, empId);
                      }
                    } else {
                      // Update existing task
                      task.title = title;
                      task.category = categoryCtrl.text.trim().isEmpty
                          ? null
                          : categoryCtrl.text.trim();
                      task.clientJob = clientCtrl.text.trim().isEmpty
                          ? null
                          : clientCtrl.text.trim();
                      task.recurrence = recurrenceToSave;
                      task.companyId = _companyId;
                      task.startUtc = startUtc;
                      task.endUtc = endUtc;
                      task.assignedEmployees = assignedEmployees;

                      await _repo.updateTask(task);

                      if (task.id != null) {
                        await _taskEmployeeDao.clearEmployees(task.id!);
                        for (final empId in selectedEmployeeIds) {
                          await _taskEmployeeDao.assignEmployee(
                              task.id!, empId);
                        }
                      }
                    }

                    await _loadTasks();
                    Navigator.pop(ctx);
                  } catch (e, stack) {
                    // Keep logging plain and simple
                    // ignore: avoid_print
                    print('Error saving task: $e');
                    // ignore: avoid_print
                    print(stack);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Employee picker bottom sheet
  // ---------------------------------------------------------------------------

  Future<List<int>> _pickEmployees(List<int> initial) async {
    final selected = List<int>.from(initial);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(sheetCtx).size.height * 0.7,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text(
                        'Assign employees',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _employees.isEmpty
                          ? const Center(
                        child:
                        Text('No employees found for this company'),
                      )
                          : ListView.builder(
                        itemCount: _employees.length,
                        itemBuilder: (ctx, index) {
                          final emp = _employees[index];
                          final id = emp['id'] as int;
                          final name =
                              (emp['full_name'] as String?) ?? 'Unknown';
                          final isSelected = selected.contains(id);

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (val) {
                              setSheetState(() {
                                if (val == true) {
                                  if (!selected.contains(id)) {
                                    selected.add(id);
                                  }
                                } else {
                                  selected.remove(id);
                                }
                              });
                            },
                            secondary: CircleAvatar(
                              child: Text(
                                name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : '?',
                              ),
                            ),
                            title: Text(name),
                            subtitle: const Text('Employee'),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    return selected;
  }

  List<Map<String, dynamic>> _buildAssignedEmployeesFromIds(
      List<int> ids,
      ) {
    final result = <Map<String, dynamic>>[];
    for (final id in ids) {
      final emp = _employees.firstWhere(
            (e) => e['id'] == id,
        orElse: () => {'id': id, 'full_name': 'Employee $id'},
      );
      result.add({
        'id': emp['id'],
        'full_name': emp['full_name'],
      });
    }
    return result;
  }
}
