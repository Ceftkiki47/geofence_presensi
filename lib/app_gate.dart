import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:geofence_presensi/screens/HomeScreen.dart';
import 'package:geofence_presensi/screens/LoginScreen.dart';
import 'package:geofence_presensi/screens/MainNavigatorScreen.dart';
import 'package:geofence_presensi/screens/SplashScreen.dart';
import 'package:geofence_presensi/screens/create_pin/CreatePinScreen.dart';
import 'package:geofence_presensi/screens/verify_pin/VerifyPinScreen.dart';
import 'package:provider/provider.dart';

import 'providers/AuthProvider.dart';

@RoutePage()
class AppGateScreen extends StatelessWidget {
  const AppGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // // 1️⃣ APP BELUM SIAP
    // if (!auth.isInitialized) {
    //   return const SplashScreen();
    // }

    // 2️⃣ BELUM LOGIN
    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }

    // 3️⃣ SUDAH LOGIN, BELUM PUNYA PIN
    if (!auth.hasPin) {
      return const CreatePinScreen();
    }

    // 4️⃣ SUDAH LOGIN & ADA PIN → HOME + BOTTOM NAV
    return const MainNavigationScreen();
  }
}
