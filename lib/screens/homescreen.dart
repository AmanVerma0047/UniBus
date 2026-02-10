import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
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

  late final List<Widget> _pages = [
    HomeContent(onOptionSelected: _onOptionSelected),
    const TransactionsPage(),
    const Topup(),
    const NotificationsPage(),
    const ECard(),
  ];

  void _onOptionSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {
              _onOptionSelected(3);
            },
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage('assets/avatar.png'),
            ),
          ),
        ],
      ),
      body: _pages[_currentIndex],
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
              onPressed: () {
                setState(() {
                  _currentIndex = 0;
                });
              },
            ),
            const SizedBox(width: 40),
            IconButton(
              icon: Icon(
                Icons.receipt_long,
                color: _currentIndex == 1
                    ? Colors.green.shade700
                    : Colors.black54,
              ),
              onPressed: () {
                setState(() {
                  _currentIndex = 1;
                });
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.large(
        backgroundColor: Colors.green.shade700,
        shape: const CircleBorder(),
        onPressed: () {
          setState(() {
            _currentIndex = 4;
          });
        },
        child: const Icon(Icons.qr_code_scanner,color: Colors.white,size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class HomeContent extends StatelessWidget {
  final Function(int) onOptionSelected;
  final GlobalKey _cardKey = GlobalKey(); // ✅ Added key for screenshot

  HomeContent({super.key, required this.onOptionSelected});

  ///  Capture BusCard widget as image and share it
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

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Here’s my UniBus card 🚌');
    } catch (e) {
      debugPrint("Error sharing card: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          RepaintBoundary(
            key: _cardKey, // ✅ Wrap card for capture
            child: BusCard(
              cardNumber: "2304009",
              holdername: "Aman Verma",
              validity: "12/2025",
              onOptionSelected: onOptionSelected,
            ),
          ),
          const SizedBox(height: 32),
          OptionsRow(
            onOptionSelected: onOptionSelected,
            onSendTap: _shareCard, // ✅ Share handler
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
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2.5,
      child: InkWell(
        onTap: () => onOptionSelected(4),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: const DecorationImage(
              image: AssetImage('assets/card_bg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Expanded column for text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // allows expansion
                  children: [
                    Text(
                      cardNumber,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      holdername,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      validity,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color.fromARGB(179, 255, 255, 255),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),
              // QR code stays fixed size
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: QrImageView(
                  data: cardNumber +"|"+ holdername+"|"+validity,
                  size:128,
                  backgroundColor: Colors.white,
                ),
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
  final VoidCallback? onSendTap; // ✅ added

  const OptionsRow({super.key, required this.onOptionSelected, this.onSendTap});

  Widget _option(
    BuildContext context,
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color.fromARGB(255, 146, 146, 146)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _option(context, Icons.share, "Send", onTap: onSendTap), // ✅ share card
        _option(
          context,
          Icons.credit_card,
          "Bills",
          onTap: () => onOptionSelected(1),
        ),
        _option(
          context,
          Icons.account_balance_wallet_outlined, // ✅ safer icon
          "Topup",
          onTap: () => onOptionSelected(2),
        ),
        _option(context, Icons.more_horiz, "More"),
      ],
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
          style: GoogleFonts.righteous(color: Colors.black, fontSize: 20),
        ),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2.5,
          color: const Color(0xFF7FC014),
          child: Container(
            padding: const EdgeInsets.all(35),
            child: Text(
              '8:27 AM | Sainik Gate',
              style: GoogleFonts.righteous(color: Colors.white, fontSize: 20),
            ),
          ),
        ),
      ],
    );
  }
}
