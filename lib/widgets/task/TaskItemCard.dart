import 'package:flutter/material.dart';
import '../../providers/AttendanceProvider.dart';
import '../../models/ModelTask.dart';
import '../task/TaskDialog.dart';

class TaskItemCard extends StatelessWidget {
  final TaskItem task;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const TaskItemCard({
    super.key,
    required this.task,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TASK NAME
            TextField(
              decoration: const InputDecoration(
                labelText: 'Nama Task',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                task.title = val;
                onChanged();
              },
            ),

            const SizedBox(height: 8),

            /// STATUS + DELETE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<TaskStatus>(
                  value: task.status,
                  items: const [
                    DropdownMenuItem(
                      value: TaskStatus.done,
                      child: Text('DONE'),
                    ),
                    DropdownMenuItem(
                      value: TaskStatus.inProgress,
                      child: Text('IN PROGRESS'),
                    ),
                  ],
                  onChanged: (val) {
                    task.status = val!;
                    onChanged();
                  },
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
