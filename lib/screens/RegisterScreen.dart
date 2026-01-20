import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/AuthProvider.dart';
// import '../database/db_helper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        /// BACKGROUND GRADIENT
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0FA3D1),
              Color(0xFF8FD3F4),
              Colors.white,
            ],
          ),
        ),

        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 120),

              /// TITLE
              const Text(
                'Register',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Buat akun baru untuk melanjutkan',
                style: TextStyle(color: Colors.black54),
              ),

              const SizedBox(height: 32),

              /// FORM CARD
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    /// EMAIL
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'EMAIL',
                        suffixIcon: Icon(Icons.email_outlined),
                        border: UnderlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// PASSWORD
                    TextField(
                      controller: passCtrl,
                      obscureText: _obscurePass,
                      decoration: InputDecoration(
                        labelText: 'PASSWORD',
                        border: const UnderlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePass
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePass = !_obscurePass;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// CONFIRM PASSWORD
                    TextField(
                      controller: confirmCtrl,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'KONFIRMASI PASSWORD',
                        border: const UnderlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirm = !_obscureConfirm;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              /// REGISTER BUTTON
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.75,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5EC6E8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                onPressed: auth.isLoading
                    ? null
                    : () async {
                        if (passCtrl.text != confirmCtrl.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password tidak sama')),
                          );
                          return;
                        }

                        final result = await auth.register(
                          emailCtrl.text.trim(),
                          passCtrl.text.trim(),
                          confirmCtrl.text.trim(),
                        );

                        if (!context.mounted) return;

                        if (result == 'EMAIL_EXISTS') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Akun sudah terdaftar')),
                          );
                          return;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Registrasi berhasil, silakan login')),
                        );

                        Navigator.pop(context);
                      },

                  child: auth.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              /// BACK TO LOGIN
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Sudah punya akun? Login',
                  style: TextStyle(
                    color: Color(0xFF5EC6E8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
