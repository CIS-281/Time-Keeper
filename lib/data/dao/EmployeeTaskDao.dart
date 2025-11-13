// Suong Tran - 11/12/25
// Handles tasks assigned to employees

Future<List<EmployeeTask>> getTasksForEmployee(int employeeId);
Future<void> addTask(EmployeeTask task);
Future<void> updateTask(EmployeeTask task);
Future<void> removeTask(int taskId);
