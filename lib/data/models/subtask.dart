class SubTaskModel {
  int? id;
  int taskId;
  String title;
  bool completed;

  SubTaskModel({
    this.id,
    required this.taskId,
    required this.title,
    this.completed = false,
  });

  // Convert SubTaskModel to a Map for database insertion
  Map<String, dynamic> toDb() => {
    'task_id': taskId,
    'title': title,
    'completed': completed ? 1 : 0,
  };

  // Create a SubTaskModel from a database Map
  factory SubTaskModel.fromDb(Map<String, dynamic> json) => SubTaskModel(
    id: json['id'],
    taskId: json['task_id'],
    title: json['title'],
    completed: json['completed'] == 1,
  );
}