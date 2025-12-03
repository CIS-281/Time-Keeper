import 'subtask.dart';

class TaskModel {
  int? id;
  String title;
  String? category;
  String? clientJob;
  String? recurrence;
  List<SubTaskModel> subtasks;

  TaskModel({
    this.id,
    required this.title,
    this.category,
    this.clientJob,
    this.recurrence,
    List<SubTaskModel>? subtasks,
  }) : subtasks = subtasks ?? []; // <-- ensures a mutable list

  // Convert TaskModel to a Map for database insertion
  Map<String, dynamic> toDb() => {
    'title': title,
    'category': category,
    'client_job': clientJob,
    'recurrence': recurrence,
  };

  // Create a TaskModel from a database Map
  factory TaskModel.fromDb(Map<String, dynamic> json) => TaskModel(
    id: json['id'],
    title: json['title'],
    category: json['category'],
    clientJob: json['client_job'],
    recurrence: json['recurrence'],
    subtasks: [], // start empty, load separately from SubTask table
  );
}