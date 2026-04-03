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
  // ── Student info ─────────────────────────
  String? _studentId;
  String? _studentName;
  String? _studentBatch;
  String? _studentEmail;
  bool _loading = true;

  // ── Selection state ──────────────────────
  String? selectedBus;
  String? selectedStop;
  String? selectedDuration;

  // ── Fees data from Firestore ─────────────
  // { "Gomti Nagar Bus": { "Sainik Gate": 500, ... }, ... }
  Map<String, Map<String, int>> _feesData = {};
  List<String> _busOptions = [];
  List<String> get _stopOptions =>
      selectedBus != null ? (_feesData[selectedBus]?.keys.toList() ?? []) : [];

  // ── Duration multipliers ─────────────────
  final Map<String, double> _durationMultiplier = {
    "1 Month": 1.0,
    "3 Months": 2.8,   // slight discount
    "6 Months": 5.4,   // bigger discount
  };

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    await Future.wait([_fetchStudentData(), _fetchFees()]);
    setState(() => _loading = false);
  }

  Future<void> _fetchStudentData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!userDoc.exists) return;

      final studentId = userDoc['studentId'] as String?;
      if (studentId == null) return;

      final studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(studentId)
          .get();

      if (studentDoc.exists) {
        final data = studentDoc.data()!;
        _studentId = studentId;
        _studentName = data['name'] ?? '';
        _studentBatch = data['batch'] ?? '';
        _studentEmail = data['email'] ?? '';
      }
    } catch (e) {
      debugPrint('Error fetching student: $e');
    }
  }

  Future<void> _fetchFees() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Fees')
          .get();

      final Map<String, Map<String, int>> fees = {};
      for (final doc in snapshot.docs) {
        final busName = doc.id; // e.g. "Gomti Nagar Bus"
        final data = doc.data();
        final Map<String, int> stops = {};
        data.forEach((stop, price) {
          // price stored as String in Firestore ("800"), parse to int
          stops[stop] = int.tryParse(price.toString()) ?? 0;
        });
        fees[busName] = stops;
      }

      _feesData = fees;
      _busOptions = fees.keys.toList()..sort();
    } catch (e) {
      debugPrint('Error fetching fees: $e');
    }
  }

  // Base monthly price for selected stop
  int get _baseMonthlyPrice {
    if (selectedBus == null || selectedStop == null) return 0;
    return _feesData[selectedBus]?[selectedStop] ?? 0;
  }

  // Final amount = base × multiplier, rounded
  int getAmount() {
    if (selectedDuration == null || _baseMonthlyPrice == 0) return 0;
    final multiplier = _durationMultiplier[selectedDuration] ?? 1.0;
    return (_baseMonthlyPrice * multiplier).round();
  }

  void _showErrorSnack(String message) {
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            fontSize: 28,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text('Select bus, stop & duration',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 13, color: Colors.black38)),
                  ],
                ),
              ),

              // ── Bus selector ─────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SELECT BUS',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black38,
                            letterSpacing: 1)),
                    const SizedBox(height: 10),
                    Row(
                      children: _busOptions.map((bus) {
                        final isActive = selectedBus == bus;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                                right: bus != _busOptions.last ? 10 : 0),
                            child: GestureDetector(
                              onTap: () => setState(() {
                                selectedBus = bus;
                                // Reset stop when bus changes
                                selectedStop = null;
                              }),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 10),
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
                                    Icon(
                                      Icons.directions_bus_rounded,
                                      color: isActive
                                          ? Colors.white
                                          : Colors.black38,
                                      size: 22,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(bus,
                                        textAlign: TextAlign.center,
                                        style:
                                            GoogleFonts.spaceGrotesk(
                                                fontSize: 12,
                                                fontWeight:
                                                    FontWeight.w600,
                                                color: isActive
                                                    ? Colors.white
                                                    : Colors.black54)),
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

              // ── Stop dropdown ────────────────────────
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
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.black.withOpacity(0.08)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedStop,
                          isExpanded: true,
                          hint: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16),
                            child: Text(
                              selectedBus == null
                                  ? 'Select a bus first'
                                  : 'Choose your stop',
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14,
                                  color: Colors.black38),
                            ),
                          ),
                          icon: const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Icon(Icons.keyboard_arrow_down_rounded,
                                color: Colors.black38),
                          ),
                          borderRadius: BorderRadius.circular(14),
                          items: _stopOptions.map((stop) {
                            final price = _feesData[selectedBus]?[stop] ?? 0;
                            return DropdownMenuItem<String>(
                              value: stop,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(stop,
                                        style: GoogleFonts.spaceGrotesk(
                                            fontSize: 14,
                                            fontWeight:
                                                FontWeight.w500)),
                                    Text('₹$price/mo',
                                        style: GoogleFonts.dmMono(
                                            fontSize: 12,
                                            color: Colors.black38)),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: selectedBus == null
                              ? null
                              : (val) =>
                                  setState(() => selectedStop = val),
                        ),
                      ),
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
                          _durationMultiplier.entries.map((entry) {
                        final isActive = selectedDuration == entry.key;
                        final isLast =
                            entry.key == _durationMultiplier.keys.last;
                        // Show preview price if stop selected
                        final previewPrice = _baseMonthlyPrice > 0
                            ? '₹${(_baseMonthlyPrice * entry.value).round()}'
                            : entry.key == '1 Month'
                                ? '1×'
                                : entry.key == '3 Months'
                                    ? '2.8×'
                                    : '5.4×';

                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                                right: isLast ? 0 : 8),
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
                                            fontSize: 12,
                                            fontWeight:
                                                FontWeight.w500,
                                            color: isActive
                                                ? Colors.white
                                                : Colors.black54)),
                                    const SizedBox(height: 3),
                                    Text(previewPrice,
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
                                  fontSize: 12,
                                  color: Colors.white38),
                            ),
                          ],
                        ),
                      ),
                      // Rows
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
                                label: 'Bus',
                                value: selectedBus ?? '—'),
                            _InvRow(
                                label: 'Stop',
                                value: selectedStop ?? '—'),
                            _InvRow(
                                label: 'Duration',
                                value: selectedDuration ?? '—'),
                            _InvRow(
                                label: 'Rate',
                                value: _baseMonthlyPrice > 0
                                    ? '₹$_baseMonthlyPrice / month'
                                    : '—'),
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
                            Text(
                              getAmount() > 0
                                  ? '₹${getAmount()}'
                                  : '—',
                              style: GoogleFonts.dmMono(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
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
                      if (selectedBus == null) {
                        _showErrorSnack('Please select a bus');
                      } else if (selectedStop == null) {
                        _showErrorSnack('Please select a stop');
                      } else if (selectedDuration == null) {
                        _showErrorSnack('Please select a duration');
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
                      padding: const EdgeInsets.symmetric(vertical: 18),
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

// ── Reusable invoice row ──────────────────────────────
class _InvRow extends StatelessWidget {
  final String label, value;
  final bool isStatus;

  const _InvRow(
      {required this.label,
      required this.value,
      this.isStatus = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F3F3))),
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
                          color: const Color(0xFF3B6D11))),
                )
              : Flexible(
                  child: Text(value,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
        ],
      ),
    );
  }
}