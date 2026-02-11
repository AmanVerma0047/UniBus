import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});



  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _aboutUs(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: "UniBus",
      applicationVersion: "1.0.0",
      applicationLegalese: "© 2026 UniBus Team",
      children: const [
        Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            "UniBus is a smart university bus card system "
            "designed to manage student travel, payments, "
            "and digital bus passes efficiently.",
          ),
        )
      ],
    );
  }

  Widget _optionTile(
      {required IconData icon,
      required String title,
      required VoidCallback onTap,
      Color? color}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: color ?? Colors.green),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 16),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.green.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            CircleAvatar(
              radius: 45,
              backgroundColor: Colors.green.shade700,
              child: const Icon(Icons.person,
                  size: 50, color: Colors.white),
            ),

            const SizedBox(height: 12),

            Text(
              user?.email ?? "",
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 30),


            _optionTile(
              icon: Icons.info,
              title: "About Us",
              onTap: () => _aboutUs(context),
            ),

            const SizedBox(height: 12),

            _optionTile(
              icon: Icons.logout,
              title: "Logout",
              color: Colors.red,
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }
}
