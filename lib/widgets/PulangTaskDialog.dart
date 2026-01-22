// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:geofence_presensi/providers/AuthProvider.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:image_picker/image_picker.dart';

// import '../providers/AttendanceProvider.dart';

// class PulangTaskDialog extends StatefulWidget {
//   const PulangTaskDialog({super.key});

//   @override
//   State<PulangTaskDialog> createState() => _PulangTaskDialogState();
// }

// class _PulangTaskDialogState extends State<PulangTaskDialog> {
//   final List<TextEditingController> _taskControllers = [];
//   final List<String> _statuses = [];

//   @override
//   void initState() {
//     super.initState();
//     _addTask();
//   }

//   void _addTask() {
//     setState(() {
//       _taskControllers.add(TextEditingController());
//       _statuses.add('Done');
//     });
//   }

//   @override
//   void dispose() {
//     for (var c in _taskControllers) {
//       c.dispose();
//     }
//     super.dispose();
//   }

//   void _submit() {
//     final tasks = [];

//     for (int i = 0; i < _taskControllers.length; i++) {
//       if (_taskControllers[i].text.trim().isNotEmpty) {
//         tasks.add({
//           'task': _taskControllers[i].text.trim(),
//           'status': _statuses[i],
//         });
//       }
//     }

//     context.read<AttendanceProvider>().submitPulang(tasks);

//     Navigator.pop(context);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: const Text('Laporan Task Hari Ini'),
//       content: SizedBox(
//         width: double.maxFinite,
//         child: SingleChildScrollView(
//           child: Column(
//             children: List.generate(_taskControllers.length, (i) {
//               return Padding(
//                 padding: const EdgeInsets.only(bottom: 12),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: TextField(
//                         controller: _taskControllers[i],
//                         decoration: const InputDecoration(
//                           labelText: 'Task',
//                           border: OutlineInputBorder(),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     DropdownButton<String>(
//                       value: _statuses[i],
//                       items: const [
//                         DropdownMenuItem(
//                           value: 'Done',
//                           child: Text('Done'),
//                         ),
//                         DropdownMenuItem(
//                           value: 'In Progress',
//                           child: Text('In Progress'),
//                         ),
//                       ],
//                       onChanged: (v) {
//                         setState(() {
//                           _statuses[i] = v!;
//                         });
//                       },
//                     ),
//                   ],
//                 ),
//               );
//             }),
//           ),
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: _addTask,
//           child: const Text('+ Task'),
//         ),
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text('Batal'),
//         ),
//         ElevatedButton(
//           onPressed: _submit,
//           child: const Text('Kirim'),
//         ),
//       ],
//     );
//   }
// }
