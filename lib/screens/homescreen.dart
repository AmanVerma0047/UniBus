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
import 'package:unibus/screens/profilescreen.dart';
import 'package:unibus/screens/transactions.dart';
import 'package:unibus/screens/login.dart';
import 'package:unibus/screens/schedulepage.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () => _onOptionSelected(3),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.green.shade700,
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: _pages[_currentIndex],
      floatingActionButton: FloatingActionButton.large(
        backgroundColor: Colors.green.shade700,
        shape: const CircleBorder(),
        onPressed: () => _onOptionSelected(4),
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

class _HomeContentState extends State<HomeContent> {
  final GlobalKey _cardKey = GlobalKey();

  // studentId is fetched once; stream does the rest
  String? _studentId;
  bool _loadingStudentId = true;

  @override
  void initState() {
    super.initState();
    _fetchStudentId();
  }

  /// Fetch studentId from users/{uid} once — everything else is streamed
  Future<void> _fetchStudentId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return;

      setState(() {
        _studentId = userDoc['studentId'];
        _loadingStudentId = false;
      });
    } catch (e) {
      debugPrint('Error fetching studentId: $e');
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
      await Share.shareXFiles(
        [XFile(file.path)],
        text: "Here's my UniBus card 🚌",
      );
    } catch (e) {
      debugPrint('Error sharing card: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingStudentId) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_studentId == null) {
      return const Center(child: Text('Student data not found.'));
    }

    /// Real-time stream — rebuilds automatically whenever Firestore changes
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .doc(_studentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('No student record found.'));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        final name       = data['name'] ?? '';
        final batch      = data['batch'] ?? '';
        final year       = data['year']?.toString() ?? '';
        String cardStatus = data['cardStatus'] ?? 'inactive';
        final validity   = data['validity'] ?? '';
        final schedule   = data['schedule'] ?? 'No schedule available';

        DateTime? expiryDate;
        final rawExpiry = data['expiryDate'];
        if (rawExpiry != null) {
          expiryDate = (rawExpiry as Timestamp).toDate();
          // Auto-deactivate locally if expired
          if (expiryDate.isBefore(DateTime.now()) && cardStatus == 'active') {
            cardStatus = 'inactive';
            // Push update to Firestore silently
            FirebaseFirestore.instance
                .collection('students')
                .doc(_studentId)
                .update({'cardStatus': 'inactive'});
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              RepaintBoundary(
                key: _cardKey,
                child: BusCard(
                  cardNumber: _studentId!,
                  holdername: name,
                  validity: cardStatus.toUpperCase(),
                  passValidity: validity,
                  expiryDate: expiryDate,
                  onOptionSelected: widget.onOptionSelected,
                ),
              ),
              const SizedBox(height: 32),
              OptionsRow(
                onOptionSelected: widget.onOptionSelected,
                onSendTap: _shareCard,
              ),
              const SizedBox(height: 32),
              MoreSection(onOptionSelected: widget.onOptionSelected),
              const SizedBox(height: 32),
              ScheduleTitle(
                schedule: schedule,
                onViewFull: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SchedulePage()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class BusCard extends StatelessWidget {
  final String cardNumber;
  final String validity;
  final String holdername;
  final String passValidity;
  final DateTime? expiryDate;
  final Function(int) onOptionSelected;

  const BusCard({
    super.key,
    required this.cardNumber,
    required this.holdername,
    required this.validity,
    required this.passValidity,
    required this.onOptionSelected,
    this.expiryDate,
  });

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}'; // used to create the date for the card
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = validity.toLowerCase() == 'active';

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
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      holdername,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isActive ? Icons.check_circle : Icons.cancel,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            validity,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Expiry date
                    Text(
                      expiryDate != null
                          ? isActive
                              ? 'Valid Until: ${_formatDate(expiryDate!)}'
                              : 'Expired: ${_formatDate(expiryDate!)}'
                          : 'No active pass',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white60,
                      ),
                    ),
                    // Pass validity / duration
                    if (passValidity.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Pass: $passValidity',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              QrImageView(
                data: '$cardNumber|$holdername|$validity',
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

  const OptionsRow({
    super.key,
    required this.onOptionSelected,
    this.onSendTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _option(Icons.share, 'Send', onSendTap),
        _option(Icons.receipt_long, 'Bills', () => onOptionSelected(1)),
        _option(Icons.account_balance_wallet, 'Topup',
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
          children: [Icon(icon), const SizedBox(height: 6), Text(label)],
        ),
      ),
    );
  }
}

class ScheduleTitle extends StatelessWidget {
  final String schedule;
  final VoidCallback onViewFull;

  const ScheduleTitle({
    super.key,
    required this.schedule,
    required this.onViewFull,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Schedule', style: GoogleFonts.righteous(fontSize: 20)),
            GestureDetector(
              onTap: onViewFull,
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF7FC014),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: Color(0xFF7FC014), size: 18),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onViewFull,
          child: Card(
            color: const Color(0xFF7FC014),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Row(
                children: [
                  const Icon(Icons.directions_bus_rounded,
                      color: Colors.white, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      schedule,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: Colors.white70, size: 22),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MoreSection extends StatelessWidget {
  final Function(int) onOptionSelected;

  const MoreSection({super.key, required this.onOptionSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _moreOption(
              Icons.notifications,
              'Notifications',
              () => onOptionSelected(3),
            ),
            _moreOption(
              Icons.credit_card,
              'E-Card',
              () => onOptionSelected(4),
            ),
            _moreOption(Icons.logout, 'Logout', () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _moreOption(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [Icon(icon), const SizedBox(height: 6), Text(label)],
        ),
      ),
    );
  }
}