enum TaskStatus { done, inProgress }

class TaskItem {
  String title;
  TaskStatus status;

  TaskItem({
    required this.title,
    required this.status,
  });
}
