import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  String? _selectedBus;
  String? _studentStop;
  String? _studentBus;

  // { "Gomti Nagar Bus": [{"stop": "Study Hall", "time": "7:30"}, ...] }
  Map<String, List<Map<String, String>>> _scheduleData = {};
  List<String> _busOptions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    await Future.wait([_fetchStudentStop(), _fetchSchedule()]);
    // Auto-select student's bus if found
    if (_studentBus != null && _scheduleData.containsKey(_studentBus)) {
      _selectedBus = _studentBus;
    } else if (_busOptions.isNotEmpty) {
      _selectedBus = _busOptions.first;
    }
    setState(() => _loading = false);
  }

  Future<void> _fetchStudentStop() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get studentId from users collection
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
      if (!studentDoc.exists) return;

      final data = studentDoc.data()!;
      final schedule = data['schedule'] as String?;

      // Format: "8:27 AM | Sainik Gate"
      if (schedule != null && schedule.contains('|')) {
        _studentStop = schedule.split('|').last.trim();
      }

      // Also read which bus they're on if stored
      // Fallback: match stop name against schedule docs to find bus
    } catch (e) {
      debugPrint('Error fetching student stop: $e');
    }
  }

  Future<void> _fetchSchedule() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('schedule')
          .get();

      final Map<String, List<Map<String, String>>> data = {};

      for (final doc in snapshot.docs) {
        final busName = doc.id; // "Gomti Nagar Bus" / "Malihabad Bus"
        final fields = doc.data();

        // Convert map of {stop: time} → sorted list by time
        final List<Map<String, String>> stops = fields.entries
            .map((e) => {
                  'stop': e.key,
                  'time': e.value.toString(),
                })
            .toList();

        // Sort by time string — parse "7:30" / "8:05" etc.
        stops.sort((a, b) {
          final ta = _parseTime(a['time']!);
          final tb = _parseTime(b['time']!);
          return ta.compareTo(tb);
        });

        data[busName] = stops;
      }

      _scheduleData = data;
      _busOptions = data.keys.toList()..sort();

      // Try to find which bus the student's stop belongs to
      if (_studentStop != null) {
        for (final entry in data.entries) {
          final found = entry.value.any((s) =>
              s['stop']!.toLowerCase() == _studentStop!.toLowerCase());
          if (found) {
            _studentBus = entry.key;
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching schedule: $e');
    }
  }

  // Parses "7:30", "8:05", "9:00" → minutes since midnight for sorting
  int _parseTime(String t) {
    // Strip AM/PM if present
    final clean = t.replaceAll(RegExp(r'[APMapm\s]'), '');
    final parts = clean.split(':');
    if (parts.length < 2) return 0;
    int h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    // If original had PM and hour < 12, add 12
    if (t.toUpperCase().contains('PM') && h < 12) h += 12;
    return h * 60 + m;
  }

  // Format stored time "7:30" → display "7:30 AM"
  String _formatTime(String t) {
    if (t.toUpperCase().contains('AM') || t.toUpperCase().contains('PM')) {
      return t; // already formatted
    }
    final parts = t.split(':');
    if (parts.length < 2) return t;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final period = h >= 12 ? 'PM' : 'AM';
    final displayH = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$displayH:${m.toString().padLeft(2, '0')} $period';
  }

  String _studentPickupTime() {
    if (_selectedBus == null || _studentStop == null) return '';
    final stops = _scheduleData[_selectedBus] ?? [];
    for (final s in stops) {
      if (s['stop']!.toLowerCase() == _studentStop!.toLowerCase()) {
        return _formatTime(s['time']!);
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text('Bus Schedule',
            style: GoogleFonts.spaceGrotesk(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7FC014)))
          : _scheduleData.isEmpty
              ? Center(
                  child: Text('No schedule available.',
                      style: GoogleFonts.spaceGrotesk(color: Colors.black38)))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Bus tab selector ───────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                      child: Row(
                        children: _busOptions.map((bus) {
                          final isActive = _selectedBus == bus;
                          final isStudentBus = bus == _studentBus;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                  right: bus != _busOptions.last ? 10 : 0),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedBus = bus),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.black
                                        : Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isActive
                                          ? Colors.black
                                          : Colors.black.withOpacity(0.08),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.directions_bus_rounded,
                                        size: 16,
                                        color: isActive
                                            ? Colors.white
                                            : Colors.black38,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(bus,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.spaceGrotesk(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isActive
                                                    ? Colors.white
                                                    : Colors.black54)),
                                      ),
                                      if (isStudentBus) ...[
                                        const SizedBox(width: 5),
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? const Color(0xFF7FC014)
                                                : const Color(0xFF7FC014),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Expanded(
                      child: ListView(
                        padding:
                            const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        children: [
                          // ── Route label ──────────────
                          Row(
                            children: [
                              const Icon(Icons.directions_bus_rounded,
                                  color: Color(0xFF7FC014), size: 18),
                              const SizedBox(width: 8),
                              Text(
                                _selectedBus ?? '',
                                style: GoogleFonts.spaceGrotesk(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF3DE),
                                  borderRadius:
                                      BorderRadius.circular(100),
                                ),
                                child: Text('Morning',
                                    style: GoogleFonts.spaceGrotesk(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF3B6D11))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ── Student boarding banner ───
                          if (_studentStop != null &&
                              _selectedBus == _studentBus) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
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
                                            style: GoogleFonts.spaceGrotesk(
                                                fontSize: 11,
                                                color: Colors.white38)),
                                        Text(
                                          _studentStop!,
                                          style: GoogleFonts.spaceGrotesk(
                                              fontSize: 16,
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
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white),
                                      ),
                                      Text('Pickup Time',
                                          style: GoogleFonts.spaceGrotesk(
                                              fontSize: 10,
                                              color: Colors.white38)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // ── Full route timeline ───────
                          Text('Full Route',
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87)),
                          const SizedBox(height: 12),

                          Builder(builder: (context) {
                            final stops =
                                _scheduleData[_selectedBus] ?? [];
                            return ListView.builder(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              itemCount: stops.length,
                              itemBuilder: (context, index) {
                                final stop = stops[index];
                                final isStudentStop =
                                    stop['stop']!.toLowerCase() ==
                                        (_studentStop?.toLowerCase() ??
                                            '');
                                final isFirst = index == 0;
                                final isLast =
                                    index == stops.length - 1;

                                return IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Timeline
                                      SizedBox(
                                        width: 44,
                                        child: Column(
                                          children: [
                                            Container(
                                              width: 2,
                                              height: 20,
                                              color: isFirst
                                                  ? Colors.transparent
                                                  : const Color(
                                                      0xFF7FC014),
                                            ),
                                            Container(
                                              width: isStudentStop ||
                                                      isLast
                                                  ? 18
                                                  : 12,
                                              height: isStudentStop ||
                                                      isLast
                                                  ? 18
                                                  : 12,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isStudentStop
                                                    ? const Color(
                                                        0xFF7FC014)
                                                    : isLast
                                                        ? Colors.black
                                                        : Colors.white,
                                                border: Border.all(
                                                  color: isStudentStop ||
                                                          isLast
                                                      ? isLast
                                                          ? Colors.black
                                                          : const Color(
                                                              0xFF7FC014)
                                                      : Colors.grey
                                                          .shade400,
                                                  width: 2,
                                                ),
                                              ),
                                              child: isStudentStop
                                                  ? const Icon(
                                                      Icons
                                                          .person_pin_circle,
                                                      color: Colors.white,
                                                      size: 10)
                                                  : isLast
                                                      ? const Icon(
                                                          Icons
                                                              .school_rounded,
                                                          color:
                                                              Colors.white,
                                                          size: 10)
                                                      : null,
                                            ),
                                            Expanded(
                                              child: Container(
                                                width: 2,
                                                color: isLast
                                                    ? Colors.transparent
                                                    : const Color(
                                                        0xFF7FC014),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),

                                      // Stop card
                                      Expanded(
                                        child: Container(
                                          margin: const EdgeInsets
                                              .symmetric(vertical: 5),
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 11),
                                          decoration: BoxDecoration(
                                            color: isStudentStop
                                                ? const Color(0xFFEAF3DE)
                                                : isLast
                                                    ? const Color(
                                                        0xFFF1EFE8)
                                                    : Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isStudentStop
                                                  ? const Color(
                                                      0xFF7FC014)
                                                  : isLast
                                                      ? Colors.black
                                                          .withOpacity(
                                                              0.15)
                                                      : Colors
                                                          .black
                                                          .withOpacity(
                                                              0.06),
                                              width:
                                                  isStudentStop ? 1.5 : 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        stop['stop']!,
                                                        style: GoogleFonts
                                                            .spaceGrotesk(
                                                          fontSize: 13,
                                                          fontWeight: isStudentStop ||
                                                                  isLast
                                                              ? FontWeight
                                                                  .w600
                                                              : FontWeight
                                                                  .w400,
                                                          color: isStudentStop
                                                              ? const Color(
                                                                  0xFF3B6D11)
                                                              : Colors
                                                                  .black87,
                                                        ),
                                                      ),
                                                    ),
                                                    if (isStudentStop) ...[
                                                      const SizedBox(
                                                          width: 6),
                                                      Container(
                                                        padding: const EdgeInsets
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
                                                            style: GoogleFonts.spaceGrotesk(
                                                                fontSize: 9,
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600)),
                                                      ),
                                                    ],
                                                    if (isLast) ...[
                                                      const SizedBox(
                                                          width: 6),
                                                      Container(
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 7,
                                                            vertical: 2),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors
                                                              .black,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      20),
                                                        ),
                                                        child: Text(
                                                            'Destination',
                                                            style: GoogleFonts.spaceGrotesk(
                                                                fontSize: 9,
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600)),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                _formatTime(
                                                    stop['time']!),
                                                style:
                                                    GoogleFonts.dmMono(
                                                  fontSize: 12,
                                                  fontWeight:
                                                      FontWeight.w500,
                                                  color: isStudentStop
                                                      ? const Color(
                                                          0xFF7FC014)
                                                      : Colors
                                                          .black38,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}