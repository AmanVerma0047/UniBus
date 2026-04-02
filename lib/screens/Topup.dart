import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unibus/screens/paymentpage.dart';

class Topup extends StatefulWidget {
  const Topup({super.key});

  @override
  State<Topup> createState() => _TopupState();
}

class _TopupState extends State<Topup> {
  String? selectedStop;
  String? selectedDuration;

  // Fetched from Firestore
  String? _studentId;
  String? _studentName;
  String? _studentBatch;
  String? _studentEmail;
  bool _loading = true;

  final List<String> stops = [
    "Sainik Gate", "Hydel", "Scooter India", "Krishna Nagar", "Gomti Nagar"
  ];

  final Map<String, int> durationPrices = {
    "1 Month": 500,
    "3 Months": 1400,
    "6 Months": 2700,
  };

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
  }

  Future<void> _fetchStudentData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) { setState(() => _loading = false); return; }

      // 1. Get studentId from users collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) { setState(() => _loading = false); return; }

      final studentId = userDoc['studentId'] as String?;

      // 2. Get student details from students collection
      if (studentId != null) {
        final studentDoc = await FirebaseFirestore.instance
            .collection('students')
            .doc(studentId)
            .get();

        if (studentDoc.exists) {
          final data = studentDoc.data()!;
          setState(() {
            _studentId = studentId;
            _studentName = data['name'] ?? '';
            _studentBatch = data['batch'] ?? '';
            _studentEmail = data['email'] ?? '';
            // Pre-select stop from their saved stop
            selectedStop = data['stop'] ?? null;
            _loading = false;
          });
          return;
        }
      }

      setState(() => _loading = false);
    } catch (e) {
      debugPrint('Error fetching student data: $e');
      setState(() => _loading = false);
    }
  }

  int getAmount() => durationPrices[selectedDuration] ?? 500;

  void _showErrorSnack(String message) {
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16, right: 16,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(message,
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.white, fontSize: 13)),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(entry);
    Future.delayed(const Duration(seconds: 2)).then((_) => entry.remove());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F7F5),
        body: Center(
            child: CircularProgressIndicator(color: Color(0xFF7FC014))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header ──────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Top Up',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 28, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text('Select stop & duration',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 13, color: Colors.black38)),
                  ],
                ),
              ),

              // ── Bus Stop selector ────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BUS STOP',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black38,
                            letterSpacing: 1)),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 3.2,
                      ),
                      itemCount: stops.length,
                      itemBuilder: (context, i) {
                        final isActive = selectedStop == stops[i];
                        return GestureDetector(
                          onTap: () =>
                              setState(() => selectedStop = stops[i]),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color:
                                  isActive ? Colors.black : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isActive
                                    ? Colors.black
                                    : Colors.black.withOpacity(0.08),
                              ),
                            ),
                            alignment: Alignment.centerLeft,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(stops[i],
                                style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isActive
                                        ? Colors.white
                                        : Colors.black54)),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ── Duration selector ────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DURATION',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black38,
                            letterSpacing: 1)),
                    const SizedBox(height: 10),
                    Row(
                      children:
                          durationPrices.entries.map((entry) {
                        final isActive = selectedDuration == entry.key;
                        final isLast = entry.key == '6 Months';
                        return Expanded(
                          child: Padding(
                            padding:
                                EdgeInsets.only(right: isLast ? 0 : 8),
                            child: GestureDetector(
                              onTap: () => setState(
                                  () => selectedDuration = entry.key),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.black
                                      : Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isActive
                                        ? Colors.black
                                        : Colors.black
                                            .withOpacity(0.08),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(entry.key,
                                        style: GoogleFonts.spaceGrotesk(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: isActive
                                                ? Colors.white
                                                : Colors.black54)),
                                    const SizedBox(height: 2),
                                    Text('₹${entry.value}',
                                        style: GoogleFonts.dmMono(
                                            fontSize: 11,
                                            color: isActive
                                                ? Colors.white60
                                                : Colors.black38)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // ── Invoice card ─────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        color: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text('FEE INVOICE',
                                style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white54,
                                    letterSpacing: 1)),
                            Text(
                              _studentId ?? '—',
                              style: GoogleFonts.dmMono(
                                  fontSize: 12, color: Colors.white38),
                            ),
                          ],
                        ),
                      ),
                      // Rows — now pulled from Firestore
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 4),
                        child: Column(
                          children: [
                            _InvRow(
                                label: 'Name',
                                value: _studentName ?? '—'),
                            _InvRow(
                                label: 'Batch',
                                value: _studentBatch ?? '—'),
                            _InvRow(
                                label: 'Email',
                                value: _studentEmail ?? '—'),
                            _InvRow(
                                label: 'Stop',
                                value: selectedStop ?? '—'),
                            _InvRow(
                                label: 'Duration',
                                value: selectedDuration ?? '—'),
                            _InvRow(
                                label: 'Status',
                                value: 'To Be Paid',
                                isStatus: true),
                          ],
                        ),
                      ),
                      // Total
                      Container(
                        color: const Color(0xFF7FC014),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Amount Due',
                                style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500)),
                            Text('₹${getAmount()}',
                                style: GoogleFonts.dmMono(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── CTA ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (selectedStop == null ||
                          selectedDuration == null) {
                        _showErrorSnack(
                            'Please select stop and duration');
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentPage(
                              stop: selectedStop!,
                              duration: selectedDuration!,
                              amount: getAmount(),
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding:
                          const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text('Move to Payment →',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable invoice row ─────────────────────────────
class _InvRow extends StatelessWidget {
  final String label, value;
  final bool isStatus;
  const _InvRow(
      {required this.label, required this.value, this.isStatus = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border:
            Border(bottom: BorderSide(color: Color(0xFFF3F3F3))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 13, color: Colors.black38)),
          isStatus
              ? Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3DE),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(value,
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B6D11))),
                )
              : Flexible(
                  child: Text(value,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                ),
        ],
      ),
    );
  }
}