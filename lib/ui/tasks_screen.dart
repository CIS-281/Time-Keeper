// Tobias Cash
// 09/30/2025
// Basic Navigation set-up
// This code can be a starting point for further dev.

// Suong Tran
// Tasks screen with Employee + Manager views.
// Updated 11/07/2025

import 'package:flutter/material.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Example employee data
  final Map<String, dynamic> employeeInfo = {
    'name': 'John Doe',
    'hoursWorked': 82,
    'payRate': 18.50,
    'taxStatus': 'W-2',
  };

  // Example payroll entries
  final List<Map<String, dynamic>> payrollHistory = [
    {'date': 'Nov 1, 2025', 'hours': 40, 'pay': 740.00},
    {'date': 'Oct 15, 2025', 'hours': 42, 'pay': 777.00},
  ];

  // Example manager data
  final List<Map<String, dynamic>> employees = [
    {'name': 'John Doe', 'payRate': 18.5, 'scheduled': 'Mon 9–5'},
    {'name': 'Lisa Tran', 'payRate': 20.0, 'scheduled': 'Wed 12–8'},
    {'name': 'Carlos Vega', 'payRate': 17.0, 'scheduled': 'Fri 10–4'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks & Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Employee View'),
            Tab(text: 'Manager View'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEmployeeView(),
          _buildManagerView(),
        ],
      ),
    );
  }

  // ===============================
  // EMPLOYEE VIEW
  // ===============================
  Widget _buildEmployeeView() {
    final payTotal =
        (employeeInfo['hoursWorked'] as int) * (employeeInfo['payRate'] as double);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Employee Summary
          Card(
            elevation: 2,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.account_circle, size: 40),
              title: Text(employeeInfo['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  'Tax Status: ${employeeInfo['taxStatus']}\nPay Rate: \$${employeeInfo['payRate']}/hr'),
              isThreeLine: true,
            ),
          ),
          const SizedBox(height: 16),

          // Payroll Info
          Card(
            elevation: 2,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payroll Summary',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  Text('Hours Worked: ${employeeInfo['hoursWorked']} hrs'),
                  Text('Total Pay (est): \$${payTotal.toStringAsFixed(2)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Payroll History
          const Text('Past Payroll Periods',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...payrollHistory.map(
                (entry) => Card(
              child: ListTile(
                leading: const Icon(Icons.history),
                title: Text(entry['date']),
                subtitle: Text(
                    '${entry['hours']} hrs — \$${entry['pay'].toStringAsFixed(2)}'),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Request Day Off Button (connect to calendar later)
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: const Text('Request Day Off'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Day-off request feature will open the Calendar screen soon.'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===============================
  // MANAGER VIEW
  // ===============================
  Widget _buildManagerView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.person_add),
            label: const Text('Add Employee'),
            onPressed: () => _showAddEmployeeDialog(context),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: employees.length,
              itemBuilder: (context, i) {
                final emp = employees[i];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: const Icon(Icons.badge),
                    title: Text(emp['name']),
                    subtitle: Text(
                        'Pay: \$${emp['payRate']}/hr\nSchedule: ${emp['scheduled']}'),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'Edit Pay Rate') {
                          _showEditPayDialog(context, emp);
                        } else if (value == 'Remove') {
                          setState(() => employees.removeAt(i));
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'Edit Pay Rate', child: Text('Edit Pay Rate')),
                        PopupMenuItem(value: 'Remove', child: Text('Remove Employee')),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Dialog to Add Employee
  void _showAddEmployeeDialog(BuildContext context) {
    final nameController = TextEditingController();
    final payController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Employee'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Employee Name'),
            ),
            TextField(
              controller: payController,
              decoration: const InputDecoration(labelText: 'Pay Rate (\$ / hr)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                employees.add({
                  'name': nameController.text,
                  'payRate': double.tryParse(payController.text) ?? 0.0,
                  'scheduled': 'Unassigned',
                });
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Dialog to Edit Pay Rate
  void _showEditPayDialog(BuildContext context, Map<String, dynamic> emp) {
    final payController =
    TextEditingController(text: emp['payRate'].toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Pay Rate — ${emp['name']}'),
        content: TextField(
          controller: payController,
          decoration: const InputDecoration(labelText: 'New Pay Rate (\$ / hr)'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                emp['payRate'] = double.tryParse(payController.text) ?? emp['payRate'];
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
