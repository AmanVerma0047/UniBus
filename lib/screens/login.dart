import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register.dart';
import 'homescreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _studentIdController =
      TextEditingController();
  final TextEditingController _passwordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final studentId =
          _studentIdController.text.trim().toLowerCase();
      final password = _passwordController.text.trim();

      await AuthService.login(
        studentId: studentId,
        password: password,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Successful")),
      );

      // Navigate to Home Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // Logo & Title
                  Column(
                    children: const [
                      Icon(Icons.directions_bus,
                          size: 80,
                          color: Colors.blue),
                      SizedBox(height: 16),
                      Text(
                        'UniBus',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Student Login',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Student ID
                  TextFormField(
                    controller: _studentIdController,
                    decoration: const InputDecoration(
                      labelText: 'Student ID',
                      prefixIcon:
                          Icon(Icons.badge),
                      border:
                          OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty) {
                        return 'Student ID is required';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText:
                        _obscurePassword,
                    decoration:
                        InputDecoration(
                      labelText: 'Password',
                      prefixIcon:
                          const Icon(Icons.lock),
                      border:
                          const OutlineInputBorder(),
                      suffixIcon:
                          IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons
                                  .visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword =
                                !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 30),

                  // Login Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          _isLoading
                              ? null
                              : _login,
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color:
                                  Colors.white,
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                  fontSize: 16),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Register link
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                    children: [
                      const Text(
                          "Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const RegisterScreen(),
                            ),
                          );
                        },
                        child:
                            const Text('Register'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
