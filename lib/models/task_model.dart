class TaskModel {
  final String title;
  final String status;

  TaskModel({required this.title, required this.status});

  factory TaskModel.formJson(Map<String, dynamic> json) {
    return TaskModel(title: json['title'], status: json['status']);
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'status': status};
  }
}
