import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:unibus/screens/Topup.dart';
import 'package:unibus/screens/ecard.dart';
import 'package:unibus/screens/notifications.dart';
import 'package:unibus/screens/transactions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _onOptionSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  late final List<Widget> _pages = [
    HomeContent(onOptionSelected: _onOptionSelected),
    const TransactionsPage(),
    const Topup(),
    const NotificationsPage(),
    const ECard(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'UniBus',
          style: GoogleFonts.righteous(color: Colors.black, fontSize: 24),
        ),
      ),
      body: _pages[_currentIndex],
      floatingActionButton: FloatingActionButton.large(
        backgroundColor: Colors.green.shade700,
        shape: const CircleBorder(),
        onPressed: () {
          _onOptionSelected(4);
        },
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(
                Icons.home,
                color: _currentIndex == 0
                    ? Colors.green.shade700
                    : Colors.black54,
              ),
              onPressed: () => _onOptionSelected(0),
            ),
            const SizedBox(width: 40),
            IconButton(
              icon: Icon(
                Icons.receipt_long,
                color: _currentIndex == 1
                    ? Colors.green.shade700
                    : Colors.black54,
              ),
              onPressed: () => _onOptionSelected(1),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  final Function(int) onOptionSelected;

  const HomeContent({super.key, required this.onOptionSelected});

  @override
  State<HomeContent> createState() => _HomeContentState();
}
//accessing the data from firebase
class _HomeContentState extends State<HomeContent> {
  final GlobalKey _cardKey = GlobalKey();

  bool isLoading = true;

  String studentId = "";
  String name = "";
  String batch = "";
  String year = "";
  String cardStatus = "";

  @override
  void initState() {
    super.initState();
    fetchStudentData();
  }

  Future<void> fetchStudentData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1 Get studentId from users collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return;

      final fetchedStudentId = userDoc['studentId'];

      // 2 Fetch full student data
      final studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(fetchedStudentId)
          .get();

      if (!studentDoc.exists) return;

      final data = studentDoc.data()!;

      setState(() {
        studentId = fetchedStudentId;
        name = data['name'] ?? "";
        batch = data['batch'] ?? "";
        year = data['year'].toString();
        cardStatus = data['cardStatus'] ?? "";
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching student data: $e");
    }
  }

  Future<void> _shareCard() async {
    try {
      final boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/unibus_card.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([XFile(file.path)],
          text: 'Here’s my UniBus card 🚌');
    } catch (e) {
      debugPrint("Error sharing card: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          RepaintBoundary(
            key: _cardKey,
            child: BusCard(
              cardNumber: studentId,
              holdername: name,
              validity: cardStatus.toUpperCase(),
              onOptionSelected: widget.onOptionSelected,
            ),
          ),
          const SizedBox(height: 32),
          OptionsRow(
            onOptionSelected: widget.onOptionSelected,
            onSendTap: _shareCard,
          ),
          const SizedBox(height: 32),
          const ScheduleTitle(),
        ],
      ),
    );
  }
}

class BusCard extends StatelessWidget {
  final String cardNumber;
  final String validity;
  final String holdername;
  final Function(int) onOptionSelected;

  const BusCard({
    super.key,
    required this.cardNumber,
    required this.holdername,
    required this.validity,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = validity.toLowerCase() == "active";

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: InkWell(
        onTap: () => onOptionSelected(4),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isActive ? Colors.green.shade700 : Colors.red.shade700,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cardNumber,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      holdername,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      validity,
                      style: const TextStyle(
                          fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              QrImageView(
                data: "$cardNumber|$holdername|$validity",
                size: 110,
                backgroundColor: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OptionsRow extends StatelessWidget {
  final Function(int) onOptionSelected;
  final VoidCallback? onSendTap;

  const OptionsRow(
      {super.key, required this.onOptionSelected, this.onSendTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _option(Icons.share, "Send", onSendTap),
        _option(Icons.receipt_long, "Bills",
            () => onOptionSelected(1)),
        _option(Icons.account_balance_wallet, "Topup",
            () => onOptionSelected(2)),
      ],
    );
  }

  Widget _option(IconData icon, String label, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon),
            const SizedBox(height: 6),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class ScheduleTitle extends StatelessWidget {
  const ScheduleTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Schedule',
          style: GoogleFonts.righteous(fontSize: 20),
        ),
        const SizedBox(height: 16),
        Card(
          color: const Color(0xFF7FC014),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Padding(
            padding: EdgeInsets.all(30),
            child: Text(
              '8:27 AM | Sainik Gate',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        )
      ],
    );
  }
}
