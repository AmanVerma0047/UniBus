import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String? _studentId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudentId();
  }

  Future<void> _fetchStudentId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) { setState(() => _loading = false); return; }
      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).get();
      setState(() {
        _studentId = userDoc.exists ? userDoc['studentId'] : null;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => _loading = false);
    }
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F7F5),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF7FC014))),
      );
    }

    if (_studentId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F7F5),
        body: Center(
          child: Text('Student data not found.',
              style: GoogleFonts.spaceGrotesk(color: Colors.black45)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .doc(_studentId)
            .collection('transactions')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF7FC014)));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          final docs = snapshot.data?.docs ?? [];

          final total = docs.fold<num>(0, (sum, doc) {
            final data = doc.data() as Map<String, dynamic>;
            final amt = data['amount'];
            return sum + (amt is num ? amt : num.tryParse(amt.toString()) ?? 0);
          });

          // Group by month from timestamp
          final Map<String, List<QueryDocumentSnapshot>> grouped = {};
          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final ts = data['timestamp'];
            String month = 'Unknown';
            if (ts is Timestamp) {
              month = _monthName(ts.toDate().month);
            }
            grouped.putIfAbsent(month, () => []).add(doc);
          }

          return SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Header ──────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Transactions',
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 28, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text('Recent activity',
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 13, color: Colors.black45)),
                        const SizedBox(height: 16),

                        // Summary card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 18),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('TOTAL SPENT',
                                      style: GoogleFonts.spaceGrotesk(
                                          fontSize: 11,
                                          color: Colors.white54,
                                          letterSpacing: 0.6)),
                                  const SizedBox(height: 4),
                                  Text('₹$total',
                                      style: GoogleFonts.dmMono(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7FC014),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text('${docs.length} trips',
                                    style: GoogleFonts.spaceGrotesk(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Empty state ──────────────────────────
                if (docs.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_rounded,
                              size: 52, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('No transactions yet',
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14, color: Colors.black38)),
                        ],
                      ),
                    ),
                  ),

                // ── Grouped list ─────────────────────────
                for (final entry in grouped.entries) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                      child: Text(
                        entry.key.toUpperCase(),
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black38,
                            letterSpacing: 1),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final data =
                            entry.value[i].data() as Map<String, dynamic>;
                        final ts = data['timestamp'] as Timestamp?;
                        final dateObj = ts?.toDate();

                        String date = '';
                        String time = '';
                        if (dateObj != null) {
                          date = '${dateObj.day} ${_monthName(dateObj.month)}';
                          final h = dateObj.hour % 12 == 0 ? 12 : dateObj.hour % 12;
                          final m = dateObj.minute.toString().padLeft(2, '0');
                          final period = dateObj.hour >= 12 ? 'PM' : 'AM';
                          time = '$h:$m $period';
                        }

                        return _TransactionCard(
                          stop: data['stop'] ?? 'Unknown Stop',
                          date: date,
                          time: time,
                          duration: data['duration'] ?? '',
                          amount: '₹${data['amount']}',
                        );
                      },
                      childCount: entry.value.length,
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final String stop, date, time, duration, amount;

  const _TransactionCard({
    required this.stop,
    required this.date,
    required this.time,
    required this.duration,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3DE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_bus_rounded,
                color: Color(0xFF3B6D11), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stop,
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 15, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text('$date · $time · $duration',
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 12, color: Colors.black45)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(amount,
              style: GoogleFonts.dmMono(
                  fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}