import 'subtask.dart';

class TaskModel {
  int? id;
  String title;
  String? category;
  String? clientJob;
  String? recurrence;

  // Multiple-assigned employees
  List<Map<String, dynamic>> assignedEmployees;

  // Company & scheduling
  String? companyId;
  int? startUtc;
  int? endUtc;

  int? jobSiteId; // keep your teammate's field

  List<SubTaskModel> subtasks;

  TaskModel({
    this.id,
    required this.title,
    this.category,
    this.clientJob,
    this.recurrence,
    this.companyId,
    this.startUtc,
    this.endUtc,
    this.jobSiteId,
    this.assignedEmployees = const [],  // NEW
    List<SubTaskModel>? subtasks,
  }) : subtasks = subtasks ?? [];

  // Convert to DB map
  Map<String, dynamic> toDb() => {
    'title': title,
    'category': category,
    'client_job': clientJob,
    'recurrence': recurrence,
    'company_id': companyId,
    'start_utc': startUtc,
    'end_utc': endUtc,
    'job_site_id': jobSiteId,
    // assignedEmployees NOT stored directly in task table
  };

  // Create model from DB
  factory TaskModel.fromDb(Map<String, dynamic> json) => TaskModel(
    id: json['id'],
    title: json['title'],
    category: json['category'],
    clientJob: json['client_job'],
    recurrence: json['recurrence'],
    companyId: json['company_id'],
    startUtc: json['start_utc'],
    endUtc: json['end_utc'],
    jobSiteId: json['job_site_id'],
    assignedEmployees: [], // will populate separately
    subtasks: [],
  );
}
