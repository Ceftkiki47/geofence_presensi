import 'package:flutter/material.dart';
import '../../providers/AttendanceProvider.dart';
import '../../model/ModelTask.dart';
import '../task/TaskItemCard.dart';

class TaskBottomSheet extends StatefulWidget {
  final Future<void> Function(List<TaskItem>) onSubmit;

  const TaskBottomSheet({
    super.key,
    required this.onSubmit,
  });

  @override
  State<TaskBottomSheet> createState() => _TaskBottomSheetState();
}

class _TaskBottomSheetState extends State<TaskBottomSheet> {
  final List<TaskItem> tasks = [];
  bool isSubmitting = false;

  void _addTask() {
    setState(() {
      tasks.add(
        TaskItem(
          title: '',
          status: TaskStatus.inProgress,
        ),
      );
    });
  }

  Future<void> _submit() async {
    if (tasks.isEmpty || tasks.any((t) => t.title.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal 1 task harus diisi')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    await widget.onSubmit(tasks);

    if (mounted) {
      setState(() => isSubmitting = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      height: maxHeight,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          /// HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Task Hari Ini',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: _addTask,
                icon: const Icon(Icons.add),
              ),
            ],
          ),

          const SizedBox(height: 8),

          /// LIST
          Expanded(
            child: tasks.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada task\nTekan + untuk menambahkan',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      return TaskItemCard(
                        task: tasks[index],
                        onDelete: () {
                          setState(() {
                            tasks.removeAt(index);
                          });
                        },
                        onChanged: () => setState(() {}),
                      );
                    },
                  ),
          ),

          /// SUBMIT
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : _submit,
              child: isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Simpan & Pulang'),
            ),
          ),
        ],
      ),
    );
  }
}
