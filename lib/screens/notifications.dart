import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unibus/screens/homescreen.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // 🔹 Added Heading
          Padding(
            padding: const EdgeInsets.only(top: 5, bottom: 10),
            child: Text(
              'Notifications',
              style: GoogleFonts.righteous(
                color: Colors.black,
                fontSize: 24,
              ),
            ),
          ),

          // 🔹 Notification cards
          const NotificationCard(
            head: "ℹ Your Bus Schedule has got updated!",
            title: "Check your current bus schedule!",
          ),
          const NotificationCard(
            head: "ℹ Your Fees has got updated!",
            title: "Check your current bus card details!",
          ),
          const NotificationCard(
            head: "ℹ All the Buses are off today!",
            title: "Check your current bus schedule!",
          ),
        ],
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final String head;
  final String title;

  const NotificationCard({
    super.key,
    required this.head,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (context) => const HomeScreen()),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              head,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
