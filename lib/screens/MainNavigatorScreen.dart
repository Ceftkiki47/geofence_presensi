import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/AttendanceProvider.dart';
import '../providers/AuthProvider.dart';

import 'HomeScreen.dart';
import 'HistoryScreen.dart';
import 'ProfileScreen.dart';
import '../widgets/CustomButtonNav.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late PageController _pageController;
  int _currentIndex = 1; // default Home

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attendance = context.watch<AttendanceProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Stack(
        children: [
          /// PAGE VIEW (SWIPE)
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            children: const [
              HistoryScreen(),
              HomeScreen(),
              ProfileScreen(),
            ],
          ),

          /// GLOBAL LOADING (ABSENSI)
          if (attendance.isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),

      /// BOTTOM NAV (REUSABLE)
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
      ),
    );
  }
}
