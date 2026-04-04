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

  void _onOptionSelected(int index) =>
      setState(() => _currentIndex = index);

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
      backgroundColor: const Color(0xFFF7F7F5),
      body: _pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        shape: const CircleBorder(),
        onPressed: () => _onOptionSelected(4),
        child: const Icon(Icons.qr_code_scanner_rounded,
            color: Colors.white, size: 26),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomBar(
        currentIndex: _currentIndex,
        onTap: _onOptionSelected,
      ),
    );
  }
}

// ── Bottom Bar ────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _BottomBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 72,
      color: Colors.white,
      elevation: 8,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            active: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.receipt_long_rounded,
            label: 'Bills',
            active: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          const SizedBox(width: 56),
          _NavItem(
            icon: Icons.notifications_rounded,
            label: 'Alerts',
            active: currentIndex == 3,
            onTap: () => onTap(3),
          ),
          _NavItem(
            icon: Icons.person_rounded,
            label: 'Profile',
            active: false,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF7FC014) : Colors.black26;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 3),
          Text(label,
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: color)),
        ],
      ),
    );
  }
}

// ── Home Content ──────────────────────────────────────
class HomeContent extends StatefulWidget {
  final Function(int) onOptionSelected;
  const HomeContent({super.key, required this.onOptionSelected});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final GlobalKey _cardKey = GlobalKey();
  String? _studentId;
  bool _loadingStudentId = true;

  // Fetched from latest transaction
  String? _latestStop;
  String? _latestBus;

  // Schedule data: sorted list of {stop, time}
  List<Map<String, String>> _scheduleStops = [];
  bool _loadingSchedule = false;

  @override
  void initState() {
    super.initState();
    _fetchStudentId();
  }

  Future<void> _fetchStudentId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!userDoc.exists) return;

      final id = userDoc['studentId'] as String?;
      setState(() {
        _studentId = id;
        _loadingStudentId = false;
      });

      if (id != null) await _fetchLatestTransaction(id);
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => _loadingStudentId = false);
    }
  }

  Future<void> _fetchLatestTransaction(String studentId) async {
    try {
      final txSnap = await FirebaseFirestore.instance
          .collection('students')
          .doc(studentId)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (txSnap.docs.isEmpty) return;

      final txData = txSnap.docs.first.data();
      final stop = txData['stop'] as String?;
      if (stop == null) return;

      setState(() => _latestStop = stop);

      await _findBusAndLoadSchedule(stop);
    } catch (e) {
      debugPrint('Error fetching transaction: $e');
    }
  }

  Future<void> _findBusAndLoadSchedule(String stop) async {
    setState(() => _loadingSchedule = true);
    try {
      // Check each bus document to find which one contains this stop
      final schedSnap = await FirebaseFirestore.instance
          .collection('schedule')
          .get();

      for (final doc in schedSnap.docs) {
        final fields = doc.data();
        // Check if this bus has the student's stop
        final hasStop = fields.keys.any((key) =>
            key.toLowerCase() == stop.toLowerCase());

        if (hasStop) {
          _latestBus = doc.id;

          // Build sorted stop list
          final List<Map<String, String>> stops = fields.entries
              .map((e) => {
                    'stop': e.key,
                    'time': e.value.toString(),
                  })
              .toList();

          stops.sort((a, b) =>
              _parseTime(a['time']!).compareTo(_parseTime(b['time']!)));

          setState(() {
            _scheduleStops = stops;
            _loadingSchedule = false;
          });
          return;
        }
      }
      setState(() => _loadingSchedule = false);
    } catch (e) {
      debugPrint('Error loading schedule: $e');
      setState(() => _loadingSchedule = false);
    }
  }

  int _parseTime(String t) {
    final clean = t.replaceAll(RegExp(r'[APMapm\s]'), '');
    final parts = clean.split(':');
    if (parts.length < 2) return 0;
    int h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    if (t.toUpperCase().contains('PM') && h < 12) h += 12;
    return h * 60 + m;
  }

  String _formatTime(String t) {
    if (t.toUpperCase().contains('AM') || t.toUpperCase().contains('PM')) {
      return t;
    }
    final parts = t.split(':');
    if (parts.length < 2) return t;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final period = h >= 12 ? 'PM' : 'AM';
    final dh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$dh:${m.toString().padLeft(2, '0')} $period';
  }

  String _studentPickupTime() {
    if (_latestStop == null) return '';
    for (final s in _scheduleStops) {
      if (s['stop']!.toLowerCase() == _latestStop!.toLowerCase()) {
        return _formatTime(s['time']!);
      }
    }
    return '';
  }

  Future<void> _shareCard() async {
    try {
      final boundary = _cardKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/unibus_card.png');
      await file.writeAsBytes(pngBytes);
      await Share.shareXFiles([XFile(file.path)],
          text: "Here's my UniBus card 🚌");
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingStudentId) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF7FC014)));
    }

    if (_studentId == null) {
      return Center(
          child: Text('Student data not found.',
              style: GoogleFonts.spaceGrotesk(color: Colors.black45)));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .doc(_studentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child:
                  CircularProgressIndicator(color: Color(0xFF7FC014)));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
              child: Text('No student record found.',
                  style:
                      GoogleFonts.spaceGrotesk(color: Colors.black45)));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final name = data['name'] ?? '';
        String cardStatus = data['cardStatus'] ?? 'inactive';
        final validity = data['validity'] ?? '';

        DateTime? expiryDate;
        final rawExpiry = data['expiryDate'];
        if (rawExpiry != null) {
          expiryDate = (rawExpiry as Timestamp).toDate().toLocal();
          if (expiryDate.isBefore(DateTime.now()) &&
              cardStatus == 'active') {
            cardStatus = 'inactive';
            FirebaseFirestore.instance
                .collection('students')
                .doc(_studentId)
                .update({'cardStatus': 'inactive'});
          }
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top bar ──────────────────────────
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('UniBus',
                          style: GoogleFonts.righteous(
                              fontSize: 24, color: Colors.black)),
                      Row(
                        children: [
                          _IconCircle(
                            onTap: () => widget.onOptionSelected(3),
                            child: const Icon(
                                Icons.notifications_none_rounded,
                                color: Colors.black54,
                                size: 20),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ProfileScreen()),
                            ),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.green.shade700,
                              child: const Icon(Icons.person,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Greeting ─────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Good morning,',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 13, color: Colors.black38)),
                    const SizedBox(height: 2),
                    Text(name,
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.black)),
                  ],
                ),
              ),

              // ── Bus Card (original — untouched) ───
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: RepaintBoundary(
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
              ),

              // ── Quick Actions ─────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick Actions',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _QuickBtn(
                          icon: Icons.share_rounded,
                          label: 'Share\nCard',
                          iconBg: const Color(0xFFEAF3DE),
                          iconColor: const Color(0xFF3B6D11),
                          onTap: _shareCard,
                        ),
                        const SizedBox(width: 10),
                        _QuickBtn(
                          icon: Icons.account_balance_wallet_rounded,
                          label: 'Top Up',
                          iconBg: Colors.black,
                          iconColor: Colors.white,
                          onTap: () => widget.onOptionSelected(2),
                        ),
                        const SizedBox(width: 10),
                        _QuickBtn(
                          icon: Icons.receipt_long_rounded,
                          label: 'Bills',
                          iconBg: const Color(0xFFF1EFE8),
                          iconColor: Colors.black54,
                          onTap: () => widget.onOptionSelected(1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── More ─────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('More',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _QuickBtn(
                          icon: Icons.notifications_rounded,
                          label: 'Alerts',
                          iconBg: const Color(0xFFF1EFE8),
                          iconColor: Colors.black54,
                          onTap: () => widget.onOptionSelected(3),
                        ),
                        const SizedBox(width: 10),
                        _QuickBtn(
                          icon: Icons.credit_card_rounded,
                          label: 'E-Card',
                          iconBg: const Color(0xFFEAF3DE),
                          iconColor: const Color(0xFF3B6D11),
                          onTap: () => widget.onOptionSelected(4),
                        ),
                        const SizedBox(width: 10),
                        _QuickBtn(
                          icon: Icons.logout_rounded,
                          label: 'Logout',
                          iconBg: const Color(0xFFFCEBEB),
                          iconColor: const Color(0xFFA32D2D),
                          onTap: () async {
                            await FirebaseAuth.instance.signOut();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Schedule section ──────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Schedule',
                                style: GoogleFonts.spaceGrotesk(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                            if (_latestBus != null)
                              Text(_latestBus!,
                                  style: GoogleFonts.spaceGrotesk(
                                      fontSize: 11,
                                      color: Colors.black38)),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SchedulePage()),
                          ),
                          child: Text('View all →',
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF7FC014))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_loadingSchedule)
                      const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF7FC014)))
                    else if (_scheduleStops.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.black.withOpacity(0.07)),
                        ),
                        child: Text('No schedule found.',
                            style: GoogleFonts.spaceGrotesk(
                                color: Colors.black38, fontSize: 13)),
                      )
                    else
                      Column(
                        children: [
                          // ── Boarding stop banner ──
                          if (_latestStop != null &&
                              _studentPickupTime().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7FC014),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                        Icons.place_rounded,
                                        color: Colors.white,
                                        size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Your Boarding Stop',
                                            style:
                                                GoogleFonts.spaceGrotesk(
                                                    fontSize: 11,
                                                    color:
                                                        Colors.white38)),
                                        Text(
                                          _latestStop!,
                                          style: GoogleFonts.spaceGrotesk(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _studentPickupTime(),
                                        style: GoogleFonts.dmMono(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white),
                                      ),
                                      Text('Pickup',
                                          style: GoogleFonts.spaceGrotesk(
                                              fontSize: 10,
                                              color: Colors.white38)),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                          // ── Mini timeline (next 4 stops
                          //    from student's stop onward) ──
                          Builder(builder: (context) {
                            // Find student stop index
                            int startIdx = 0;
                            for (int i = 0;
                                i < _scheduleStops.length;
                                i++) {
                              if (_scheduleStops[i]['stop']!
                                      .toLowerCase() ==
                                  (_latestStop?.toLowerCase() ?? '')) {
                                startIdx = i;
                                break;
                              }
                            }

                            // Show from student stop to end, max 4
                            final visible = _scheduleStops
                                .sublist(startIdx)
                                .take(4)
                                .toList();
                            final hasMore =
                                _scheduleStops.length - startIdx > 4;

                            return Column(
                              children: [
                                ...visible.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final stop = entry.value;
                                  final isStudent = idx == 0;
                                  final isLast = idx ==
                                      _scheduleStops.length - 1 -
                                          startIdx;

                                  return IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // Timeline column
                                        SizedBox(
                                          width: 32,
                                          child: Column(
                                            children: [
                                              Container(
                                                width: 2,
                                                height: 16,
                                                color: idx == 0
                                                    ? Colors.transparent
                                                    : const Color(
                                                        0xFF7FC014),
                                              ),
                                              Container(
                                                width: isStudent ? 16 : 10,
                                                height:
                                                    isStudent ? 16 : 10,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: isStudent
                                                      ? const Color(
                                                          0xFF7FC014)
                                                      : Colors.white,
                                                  border: Border.all(
                                                    color: const Color(
                                                        0xFF7FC014),
                                                    width: 2,
                                                  ),
                                                ),
                                                child: isStudent
                                                    ? const Icon(
                                                        Icons
                                                            .person_rounded,
                                                        color: Colors.white,
                                                        size: 8)
                                                    : null,
                                              ),
                                              Expanded(
                                                child: Container(
                                                  width: 2,
                                                  color: isLast
                                                      ? Colors.transparent
                                                      : const Color(
                                                          0xFFD0E8B0),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(width: 10),

                                        // Stop card
                                        Expanded(
                                          child: Container(
                                            margin:
                                                const EdgeInsets.symmetric(
                                                    vertical: 4),
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 10),
                                            decoration: BoxDecoration(
                                              color: isStudent
                                                  ? const Color(0xFFEAF3DE)
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isStudent
                                                    ? const Color(
                                                        0xFF7FC014)
                                                    : Colors.black
                                                        .withOpacity(0.06),
                                                width: isStudent ? 1.5 : 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      stop['stop']!,
                                                      style: GoogleFonts
                                                          .spaceGrotesk(
                                                        fontSize: 13,
                                                        fontWeight: isStudent
                                                            ? FontWeight.w600
                                                            : FontWeight.w400,
                                                        color: isStudent
                                                            ? const Color(
                                                                0xFF3B6D11)
                                                            : Colors.black87,
                                                      ),
                                                    ),
                                                    if (isStudent) ...[
                                                      const SizedBox(
                                                          width: 6),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 7,
                                                                vertical: 2),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: const Color(
                                                              0xFF7FC014),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      20),
                                                        ),
                                                        child: Text('You',
                                                            style: GoogleFonts
                                                                .spaceGrotesk(
                                                                    fontSize:
                                                                        9,
                                                                    color: Colors
                                                                        .white,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600)),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                Text(
                                                  _formatTime(
                                                      stop['time']!),
                                                  style: GoogleFonts.dmMono(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w500,
                                                    color: isStudent
                                                        ? const Color(
                                                            0xFF7FC014)
                                                        : Colors.black38,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),

                                // ── View all link ──
                                if (hasMore)
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const SchedulePage()),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          top: 8, left: 42),
                                      child: Row(
                                        children: [
                                          Text(
                                            '${_scheduleStops.length - startIdx - 4} more stops',
                                            style: GoogleFonts.spaceGrotesk(
                                                fontSize: 12,
                                                color: Colors.black38),
                                          ),
                                          const SizedBox(width: 4),
                                          Text('View all →',
                                              style:
                                                  GoogleFonts.spaceGrotesk(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: const Color(
                                                          0xFF7FC014))),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          }),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Reusable Quick Button ─────────────────────────────
class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickBtn({
    required this.icon,
    required this.label,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border:
                Border.all(color: Colors.black.withOpacity(0.07)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Icon Circle Button ────────────────────────────────
class _IconCircle extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _IconCircle({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
              color: Colors.black.withOpacity(0.08)),
        ),
        child: child,
      ),
    );
  }
}

// ── Original Bus Card (unchanged) ─────────────────────
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = validity.toLowerCase() == 'active';

    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: InkWell(
        onTap: () => onOptionSelected(4),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isActive
                ? Colors.green.shade700
                : Colors.red.shade700,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cardNumber,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 6),
                    Text(holdername,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 6),
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
                            isActive
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(validity,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      expiryDate != null
                          ? isActive
                              ? 'Valid Until: ${_formatDate(expiryDate!)}'
                              : 'Expired: ${_formatDate(expiryDate!)}'
                          : 'No active pass',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white60),
                    ),
                    if (passValidity.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Pass: $passValidity',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white60)),
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