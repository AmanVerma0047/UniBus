import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _studentIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await AuthService.register(
        studentId: _studentIdController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account created successfully!',
              style: GoogleFonts.spaceGrotesk()),
          backgroundColor: const Color(0xFF7FC014),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: GoogleFonts.spaceGrotesk()),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text('Create Account',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // ── Header ──────────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF3DE),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.person_add_rounded,
                          color: Color(0xFF3B6D11),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Join UniBus',
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 22,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                          'Register with your student ID\nto get started',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 13, color: Colors.black38)),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Student ID ───────────────────────
                _Label('STUDENT ID'),
                const SizedBox(height: 8),
                _InputField(
                  controller: _studentIdController,
                  hint: 'e.g. SHC2304009',
                  icon: Icons.school_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Student ID is required'
                          : null,
                ),

                const SizedBox(height: 16),

                // ── Password ─────────────────────────
                _Label('PASSWORD'),
                const SizedBox(height: 8),
                _InputField(
                  controller: _passwordController,
                  hint: 'Min. 8 characters',
                  icon: Icons.lock_rounded,
                  obscure: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: Colors.black38,
                      size: 20,
                    ),
                    onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) => (v == null || v.length < 8)
                      ? 'Minimum 8 characters required'
                      : null,
                ),

                const SizedBox(height: 16),

                // ── Confirm Password ─────────────────
                _Label('CONFIRM PASSWORD'),
                const SizedBox(height: 8),
                _InputField(
                  controller: _confirmPasswordController,
                  hint: 'Re-enter password',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscureConfirm,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: Colors.black38,
                      size: 20,
                    ),
                    onPressed: () => setState(
                        () => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) =>
                      v != _passwordController.text
                          ? 'Passwords do not match'
                          : null,
                ),

                const SizedBox(height: 32),

                // ── Register button ──────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white),
                          )
                        : Text('Create Account',
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black38,
            letterSpacing: 1));
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.spaceGrotesk(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.spaceGrotesk(
              color: Colors.black26, fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.black38, size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }
}