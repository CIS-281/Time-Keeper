// Suong Tran 11/12/25
// Handles schedules and calendar events
Future<List<Shift>> getShiftsForEmployee(int employeeId, DateTime month);
Future<void> addShift(Shift s);
Future<void> removeShift(int shiftId);
Future<void> updateShift(Shift s);
