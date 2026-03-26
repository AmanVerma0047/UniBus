import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const List<Map<String, String>> _busSchedule = [
  {'stop': 'Study Hall School', 'time': '7:30 AM'},
  {'stop': 'Gomti River', 'time': '7:40 AM'},
  {'stop': 'Ahimamau Best Price', 'time': '7:45 AM'},
  {'stop': 'Utrathiya', 'time': '7:55 AM'},
  {'stop': 'Priyam Plaza', 'time': '8:05 AM'},
  {'stop': 'Ashiyana/Power House', 'time': '8:10 AM'},
  {'stop': 'Piccadily', 'time': '8:15 AM'},
  {'stop': 'Krishna Nagar', 'time': '8:16 AM'},
  {'stop': 'Chungi', 'time': '8:18 AM'},
  {'stop': 'Transport Nagar', 'time': '8:22 AM'},
  {'stop': 'Amausi', 'time': '8:25 AM'},
  {'stop': 'Shanti Nagar', 'time': '8:27 AM'},
  {'stop': 'Hydel', 'time': '8:30 AM'},
  {'stop': 'Scooter India', 'time': '8:45 AM'},
  {'stop': 'College', 'time': '9:00 AM'},
];

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  String _timeForStop(String stopName) {
    for (final s in _busSchedule) {
      if (s['stop']!.toLowerCase() == stopName.toLowerCase()) {
        return s['time']!;
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Bus Schedule',
          style: GoogleFonts.righteous(color: Colors.black, fontSize: 22),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('students')
            .doc(uid)
            .get(),
        builder: (context, snapshot) {
          String? studentStop;

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final schedule = data['schedule'] as String?;
            // Extract stop from "8:27 AM | Sainik Gate"
            if (schedule != null && schedule.contains('|')) {
              studentStop = schedule.split('|').last.trim();
            }
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              // ── Route label ──
              Row(
                children: [
                  const Icon(Icons.directions_bus_rounded,
                      color: Color(0xFF7FC014), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Gomti Nagar Route',
                    style: GoogleFonts.righteous(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Morning Departure',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 16),

              // ── Student's stop banner ──
              if (studentStop != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7FC014), Color(0xFF5A8A00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7FC014).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.place_rounded,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Boarding Stop',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              studentStop,
                              style: GoogleFonts.righteous(
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _timeForStop(studentStop),
                            style: GoogleFonts.righteous(
                              fontSize: 22,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Pickup Time',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── Full Route Timeline ──
              Text(
                'Full Route',
                style: GoogleFonts.righteous(
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _busSchedule.length,
                itemBuilder: (context, index) {
                  final stop = _busSchedule[index];
                  final isStudentStop =
                      stop['stop']!.toLowerCase() ==
                      (studentStop?.toLowerCase() ?? '');
                  final isFirst = index == 0;
                  final isLast = index == _busSchedule.length - 1;
                  final isCollege = isLast;

                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Timeline ──
                        SizedBox(
                          width: 44,
                          child: Column(
                            children: [
                              // Top connector line
                              Container(
                                width: 2,
                                height: 20,
                                color: isFirst
                                    ? Colors.transparent
                                    : const Color(0xFF7FC014),
                              ),
                              // Stop dot
                              Container(
                                width: isStudentStop || isCollege ? 18 : 12,
                                height: isStudentStop || isCollege ? 18 : 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isStudentStop
                                      ? const Color(0xFF7FC014)
                                      : isCollege
                                          ? const Color(0xFF5A8A00)
                                          : Colors.white,
                                  border: Border.all(
                                    color: isStudentStop || isCollege
                                        ? const Color(0xFF7FC014)
                                        : Colors.grey.shade400,
                                    width: 2,
                                  ),
                                ),
                                child: isStudentStop
                                    ? const Icon(Icons.person_pin_circle,
                                        color: Colors.white, size: 10)
                                    : isCollege
                                        ? const Icon(Icons.school_rounded,
                                            color: Colors.white, size: 10)
                                        : null,
                              ),
                              // Bottom connector line
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: isLast
                                      ? Colors.transparent
                                      : const Color(0xFF7FC014),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 10),

                        // ── Stop Card ──
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: isStudentStop
                                  ? const Color(0xFFEAF7EB)
                                  : isCollege
                                      ? const Color(0xFFF0F7E0)
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isStudentStop
                                    ? const Color(0xFF7FC014)
                                    : isCollege
                                        ? const Color(0xFF7FC014)
                                            .withOpacity(0.5)
                                        : Colors.grey.shade200,
                                width: isStudentStop ? 1.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          stop['stop']!,
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: isStudentStop ||
                                                    isCollege
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: isStudentStop
                                                ? const Color(0xFF5A8A00)
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      if (isStudentStop) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF7FC014),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            'You',
                                            style: GoogleFonts.poppins(
                                              fontSize: 9,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (isCollege) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF5A8A00),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            'Destination',
                                            style: GoogleFonts.poppins(
                                              fontSize: 9,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Text(
                                  stop['time']!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isStudentStop
                                        ? const Color(0xFF7FC014)
                                        : Colors.grey.shade500,
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
              ),
            ],
          );
        },
      ),
    );
  }
}