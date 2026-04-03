import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _studentId;
  String? _studentName;
  String? _studentEmail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
  }

  Future<void> _fetchStudentData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) { setState(() => _loading = false); return; }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!userDoc.exists) { setState(() => _loading = false); return; }

      final studentId = userDoc['studentId'] as String?;
      if (studentId == null) { setState(() => _loading = false); return; }

      final studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(studentId)
          .get();

      if (studentDoc.exists) {
        final data = studentDoc.data()!;
        setState(() {
          _studentId = studentId;
          _studentName = data['name'] ?? '';
          _studentEmail = data['email'] ?? '';
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => _loading = false);
    }
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _aboutUs(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'UniBus',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2026 UniBus Team',
      children: const [
        Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'UniBus is a smart university bus card system '
            'designed to manage student travel, payments, '
            'and digital bus passes efficiently.',
          ),
        )
      ],
    );
  }

  void _showComplaintSheet(BuildContext context) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    bool _submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F7F5),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text('Submit a Complaint',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black)),
                    const SizedBox(height: 4),
                    Text("We'll review it and get back to you.",
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 13, color: Colors.black38)),
                    const SizedBox(height: 20),

                    // Title field
                    Text('TITLE',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black38,
                            letterSpacing: 1)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.black.withOpacity(0.08)),
                      ),
                      child: TextField(
                        controller: titleController,
                        style: GoogleFonts.spaceGrotesk(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'e.g. No AC in the bus',
                          hintStyle: GoogleFonts.spaceGrotesk(
                              color: Colors.black26, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Message field
                    Text('MESSAGE',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black38,
                            letterSpacing: 1)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.black.withOpacity(0.08)),
                      ),
                      child: TextField(
                        controller: messageController,
                        maxLines: 4,
                        style: GoogleFonts.spaceGrotesk(fontSize: 14),
                        decoration: InputDecoration(
                          hintText:
                              'Describe your complaint in detail...',
                          hintStyle: GoogleFonts.spaceGrotesk(
                              color: Colors.black26, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting
                            ? null
                            : () async {
                                final title =
                                    titleController.text.trim();
                                final message =
                                    messageController.text.trim();

                                if (title.isEmpty || message.isEmpty) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Please fill in both fields.',
                                          style:
                                              GoogleFonts.spaceGrotesk()),
                                      backgroundColor:
                                          Colors.red.shade700,
                                    ),
                                  );
                                  return;
                                }

                                setSheetState(
                                    () => _submitting = true);

                                try {
                                  await FirebaseFirestore.instance
                                      .collection('complaint')
                                      .add({
                                    'title': title,
                                    'message': message,
                                    'studentId': _studentId ?? '',
                                    'studentName': _studentName ?? '',
                                    'timestamp': FieldValue.serverTimestamp(),
                                  });

                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Complaint submitted successfully.',
                                          style:
                                              GoogleFonts.spaceGrotesk()),
                                      backgroundColor:
                                          const Color(0xFF7FC014),
                                    ),
                                  );
                                } catch (e) {
                                  setSheetState(
                                      () => _submitting = false);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Failed to submit. Try again.',
                                          style:
                                              GoogleFonts.spaceGrotesk()),
                                      backgroundColor:
                                          Colors.red.shade700,
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white))
                            : Text('Submit Complaint',
                                style: GoogleFonts.spaceGrotesk(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text('Profile',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black)),
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(color: Color(0xFF7FC014)))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Avatar + info card ─────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7FC014),
                              borderRadius:
                                  BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.person_rounded,
                                color: Colors.white, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _studentName?.isNotEmpty == true
                                      ? _studentName!
                                      : 'Student',
                                  style: GoogleFonts.spaceGrotesk(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white),
                                ),
                                const SizedBox(height: 3),
                                // Show email if available, else SHC ID
                                Text(
                                  _studentEmail?.isNotEmpty == true
                                      ? _studentEmail!
                                      : (_studentId ?? '—'),
                                  style: GoogleFonts.spaceGrotesk(
                                      fontSize: 13,
                                      color: Colors.white54),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_studentId != null) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7FC014),
                                      borderRadius:
                                          BorderRadius.circular(100),
                                    ),
                                    child: Text(
                                      _studentId!,
                                      style: GoogleFonts.dmMono(
                                          fontSize: 11,
                                          color: Colors.white,
                                          fontWeight:
                                              FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text('OPTIONS',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black38,
                            letterSpacing: 1)),
                    const SizedBox(height: 10),

                    // ── Complaint tile ─────────────────
                    _ProfileTile(
                      icon: Icons.report_problem_rounded,
                      iconBg: const Color(0xFFFAEEDA),
                      iconColor: const Color(0xFFBA7517),
                      title: 'Submit a Complaint',
                      subtitle: 'Report an issue with the bus service',
                      onTap: () => _showComplaintSheet(context),
                    ),
                    const SizedBox(height: 10),

                    // ── About tile ─────────────────────
                    _ProfileTile(
                      icon: Icons.info_outline_rounded,
                      iconBg: const Color(0xFFE6F1FB),
                      iconColor: const Color(0xFF185FA5),
                      title: 'About UniBus',
                      subtitle: 'Version 1.0.0 · © 2026 UniBus Team',
                      onTap: () => _aboutUs(context),
                    ),
                    const SizedBox(height: 10),

                    // ── Logout tile ────────────────────
                    _ProfileTile(
                      icon: Icons.logout_rounded,
                      iconBg: const Color(0xFFFCEBEB),
                      iconColor: const Color(0xFFA32D2D),
                      title: 'Logout',
                      subtitle: 'Sign out of your account',
                      onTap: () => _logout(context),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ── Reusable profile tile ─────────────────────────────
class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, subtitle;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.07)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 12, color: Colors.black38)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.black26, size: 20),
          ],
        ),
      ),
    );
  }
}