import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/AuthProvider.dart';
import 'LoginScreen.dart';
import 'ChangePasswordScreen.dart';
import 'HelpCenterScreen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0FA3D1),
              Color(0xFF8FD3F4),
              Color(0xFFDFF6FD),
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 80),

            /// FOTO PROFILE
            GestureDetector(
              onTap: () async {
                final picker = ImagePicker();
                final image =
                    await picker.pickImage(source: ImageSource.gallery);

                if (image != null) {
                  context
                      .read<AuthProvider>()
                      .updateProfileImage(image.path);
                }
              },
              child: CircleAvatar(
                radius: 45,
                backgroundColor: Colors.white,
                backgroundImage: auth.profileImage != null
                    ? FileImage(File(auth.profileImage!))
                    : null,
                child: auth.profileImage == null
                    ? const Icon(
                        Icons.person,
                        size: 50,
                        color: Color(0xFF0FA3D1),
                      )
                    : null,
              ),
            ),

            const SizedBox(height: 12),

            /// EMAIL
            Text(
              auth.userEmail ?? '-',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 30),

            /// MENU
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    _menuItem(
                      icon: Icons.settings,
                      title: 'Pengaturan Akun',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const ChangePasswordScreen(),
                          ),
                        );
                      },
                    ),
                    _menuItem(
                      icon: Icons.help_outline,
                      title: 'Pusat Bantuan',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const HelpCenterScreen(),
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    _menuItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      isLogout: true,
                      onTap: () => _showLogoutDialog(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout ? Colors.red : const Color(0xFF0FA3D1),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.red : Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              await context.read<AuthProvider>().logout();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
                (_) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
