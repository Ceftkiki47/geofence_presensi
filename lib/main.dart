import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'providers/AuthProvider.dart';
import 'providers/AttendanceProvider.dart';
import 'app_gate.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..checkLogin(),
        ),
        ChangeNotifierProvider(
          create: (_) => AttendanceProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

/// =======================
/// APP ROOT
/// =======================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Geofence Presensi',
      home: AppGateScreen(),
    );
  }
}

