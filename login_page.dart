
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_page.dart';
import 'admin_dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController registerController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isStudent = true;
  bool isLoading = false;
  bool obscurePassword = true;

  static const Color gold = Color(0xFFD4AF37);
  static const Color background = Color(0xFF101010);

  @override
  void initState() {
    super.initState();
    restoreProfile();
  }

  Future<void> restoreProfile() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    nameController.text = prefs.getString('studentName') ?? '';
    emailController.text = prefs.getString('studentEmail') ?? '';
    registerController.text = prefs.getString('registerNumber') ?? '';
    mobileController.text = prefs.getString('studentMobile') ?? '';
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: gold,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> login() async {
    if (isLoading) return;

    if (!isStudent) {
      final email = emailController.text.trim();
      final password = passwordController.text;

      if (email.isEmpty || password.isEmpty) {
        showMessage('Enter admin email and password');
        return;
      }

      setState(() {
        isLoading = true;
      });

      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminDashboardPage(),
          ),
        );
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;

        if (e.code == 'invalid-credential' ||
            e.code == 'user-not-found' ||
            e.code == 'wrong-password' ||
            e.code == 'invalid-email') {
          showMessage('Invalid admin email or password');
        } else if (e.code == 'too-many-requests') {
          showMessage('Too many attempts. Try again later.');
        } else {
          showMessage(e.message ?? 'Admin login failed');
        }
      } catch (e) {
        if (mounted) {
          showMessage('Could not log in. Please try again.');
        }
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }

      return;
    }

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final registerNumber = registerController.text.trim().toUpperCase();
    final mobile = mobileController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        registerNumber.isEmpty ||
        mobile.isEmpty) {
      showMessage('Please fill in all student details');
      return;
    }

    if (!email.toLowerCase().endsWith('@svecw.edu.in')) {
      showMessage('Use your @svecw.edu.in email address');
      return;
    }

    if (!RegExp(r'^\d{2}B01A\d{4}$').hasMatch(registerNumber)) {
      showMessage('Enter a valid register number');
      return;
    }

    if (!RegExp(r'^\d{10}$').hasMatch(mobile)) {
      showMessage('Enter a valid 10-digit mobile number');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('studentName', name);
      await prefs.setString('studentEmail', email);
      await prefs.setString('registerNumber', registerNumber);
      await prefs.setString('studentMobile', mobile);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(
            studentName: name,
            registerNumber: registerNumber,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        showMessage('Unable to save student details');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    registerController.dispose();
    mobileController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Widget buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword && obscurePassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(icon, color: gold),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: gold,
                  ),
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFF1C1C1C),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: gold.withValues(alpha: 0.4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: gold, width: 1.5),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.movie_filter,
                    color: gold,
                    size: 72,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'CINEMATE',
                    style: TextStyle(
                      color: gold,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your Campus Movie Experience',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFF171717),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: gold.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Welcome Back!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Login to continue',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white60),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _modeButton(
                                  title: 'Student',
                                  selected: isStudent,
                                  onTap: () {
                                    setState(() {
                                      isStudent = true;
                                      passwordController.clear();
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: _modeButton(
                                  title: 'Admin',
                                  selected: !isStudent,
                                  onTap: () {
                                    setState(() {
                                      isStudent = false;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (isStudent) ...[
                          buildField(
                            controller: nameController,
                            label: 'Student Name',
                            icon: Icons.person_outline,
                          ),
                          buildField(
                            controller: emailController,
                            label: 'Student Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          buildField(
                            controller: registerController,
                            label: 'Register Number',
                            icon: Icons.badge_outlined,
                          ),
                          buildField(
                            controller: mobileController,
                            label: 'Mobile Number',
                            icon: Icons.phone_android,
                            keyboardType: TextInputType.phone,
                          ),
                        ] else ...[
                          buildField(
                            controller: emailController,
                            label: 'Admin Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          buildField(
                            controller: passwordController,
                            label: 'Password',
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                        ],
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: gold,
                              foregroundColor: Colors.black,
                              disabledBackgroundColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : Text(
                                    isStudent
                                        ? 'LOGIN AS STUDENT'
                                        : 'LOGIN AS ADMIN',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'CINEMATE • College Movie Booking',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? gold : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
