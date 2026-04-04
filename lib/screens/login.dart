import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'register.dart';
import 'homescreen.dart';
import '../services/busmanagerpage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ── Form state ────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String _role = 'student'; // 'student' | 'manager'

  // ── Computed helpers ──────────────────────
  bool get _isManager => _role == 'manager';

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Login logic ───────────────────────────
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // 1. Authenticate
      await AuthService.login(
        studentId: _idController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      // 2. Fetch role from Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Login failed. Please try again.');

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();
        throw Exception('User record not found. Contact support.');
      }

      final firestoreRole =
          (userDoc.data()?['role'] ?? 'student') as String;

      if (!mounted) return;

      // 3. Guard — UI role must match Firestore role
      if (_role == 'manager' && firestoreRole != 'manager') {
        await FirebaseAuth.instance.signOut();
        throw Exception('This ID does not belong to a manager account.');
      }
      if (_role == 'student' && firestoreRole == 'manager') {
        await FirebaseAuth.instance.signOut();
        throw Exception('Please select "Bus Manager" to login.');
      }

      // 4. Route
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => firestoreRole == 'manager'
              ? const BusManagerScreen()
              : const HomeScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Snackbar ──────────────────────────────
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.spaceGrotesk()),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      ),
    );
  }

  // ── UI ────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 52),
                _buildLogo(),
                const SizedBox(height: 40),
                _buildRoleSelector(),
                const SizedBox(height: 28),
                _buildIdField(),
                const SizedBox(height: 16),
                _buildPasswordField(),
                const SizedBox(height: 32),
                _buildLoginButton(),
                const SizedBox(height: 20),
                if (!_isManager) _buildRegisterLink(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Logo ──────────────────────────────────
  Widget _buildLogo() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              color: Color(0xFF7FC014),
              size: 38,
            ),
          ),
          const SizedBox(height: 16),
          Text('UniBus',
              style: GoogleFonts.righteous(
                  fontSize: 32, color: Colors.black)),
          const SizedBox(height: 4),
          Text('Smart University Bus System',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 13, color: Colors.black38)),
        ],
      ),
    );
  }

  // ── Role selector ─────────────────────────
  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('LOGIN AS'),
        const SizedBox(height: 10),
        Row(
          children: [
            _RoleChip(
              label: 'Student',
              icon: Icons.person_rounded,
              selected: !_isManager,
              onTap: () => setState(() => _role = 'student'),
            ),
            const SizedBox(width: 12),
            _RoleChip(
              label: 'Bus Manager',
              icon: Icons.manage_accounts_rounded,
              selected: _isManager,
              onTap: () => setState(() => _role = 'manager'),
            ),
          ],
        ),
      ],
    );
  }

  // ── ID field ──────────────────────────────
  Widget _buildIdField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(_isManager ? 'MANAGER ID' : 'STUDENT ID'),
        const SizedBox(height: 8),
        _InputField(
          controller: _idController,
          hint: _isManager ? 'e.g. MGR001' : 'e.g. SHC2304009',
          icon: _isManager
              ? Icons.badge_rounded
              : Icons.school_rounded,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? (_isManager
                  ? 'Manager ID is required'
                  : 'Student ID is required')
              : null,
        ),
      ],
    );
  }

  // ── Password field ────────────────────────
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('PASSWORD'),
        const SizedBox(height: 8),
        _InputField(
          controller: _passwordController,
          hint: '••••••••',
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
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: (v) => (v == null || v.length < 8)
              ? 'Password must be at least 8 characters'
              : null,
        ),
      ],
    );
  }

  // ── Login button ──────────────────────────
  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(
                _isManager ? 'Login as Manager' : 'Login as Student',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
      ),
    );
  }

  // ── Register link ─────────────────────────
  Widget _buildRegisterLink() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Don't have an account? ",
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 13, color: Colors.black45)),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const RegisterScreen()),
            ),
            child: Text('Register',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF7FC014))),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════

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

class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? Colors.black
                  : Colors.black.withOpacity(0.08),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected
                      ? const Color(0xFF7FC014)
                      : Colors.black38),
              const SizedBox(width: 8),
              Text(label,
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          selected ? Colors.white : Colors.black54)),
            ],
          ),
        ),
      ),
    );
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