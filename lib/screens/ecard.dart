import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ECard extends StatefulWidget {
  const ECard({super.key});

  @override
  State<ECard> createState() => _ECardState();
}

class _ECardState extends State<ECard> {
  bool isLoading = true;

  String studentId = "";
  String name = "";
  String batch = "";
  String year = "";
  String cardStatus = "";
  DateTime? expiryDate;

  @override
  void initState() {
    super.initState();
    fetchCardData();
  }

  Future<void> fetchCardData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return;

      final fetchedStudentId = userDoc['studentId'];

      final studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(fetchedStudentId)
          .get();

      if (!studentDoc.exists) return;

      final data = studentDoc.data()!;

      // Auto-check expiry and update cardStatus if expired
      DateTime? parsedExpiry;
      if (data['expiryDate'] != null) {
        parsedExpiry = (data['expiryDate'] as Timestamp).toDate();
        final isExpired = parsedExpiry.isBefore(DateTime.now());

        if (isExpired && data['cardStatus'] == 'active') {
          await FirebaseFirestore.instance
              .collection('students')
              .doc(fetchedStudentId)
              .update({'cardStatus': 'inactive'});
          data['cardStatus'] = 'inactive';
        }
      }

      setState(() {
        studentId = fetchedStudentId;
        name = data['name'] ?? "";
        batch = data['batch'] ?? "";
        year = data['year'].toString();
        cardStatus = data['cardStatus'] ?? "inactive";
        expiryDate = parsedExpiry;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching e-card data: $e");
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final bool isActive = cardStatus.toLowerCase() == "active";

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5, bottom: 20),
            child: Text(
              'E-Card',
              style: GoogleFonts.righteous(color: Colors.black, fontSize: 24),
              textAlign: TextAlign.center,
            ),
          ),

          Center(
            child: Container(
              width: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: isActive
                      ? [const Color(0xFF8BC34A), const Color(0xFF33691E)]
                      : [const Color(0xFFE53935), const Color(0xFFB71C1C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isActive
                            ? const Color(0xFF7FC014)
                            : Colors.red)
                        .withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    top: 40,
                    left: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: const BoxDecoration(
                        color: Color(0x22000000),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    right: -40,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: const BoxDecoration(
                        color: Color(0x22000000),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isActive
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    cardStatus.toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Bus icon
                            const Icon(Icons.directions_bus_rounded,
                                color: Colors.white70, size: 28),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // College name
                        Text(
                          "The Study Hall\nCollege",
                          style: GoogleFonts.righteous(
                            color: Colors.white,
                            fontSize: 22,
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Student name
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        // Batch & Year
                        Text(
                          '$batch  •  Year $year',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),

                        // Student ID
                        Text(
                          studentId,
                          style: GoogleFonts.poppins(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Expiry date
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today,
                                  color: Colors.white70, size: 14),
                              const SizedBox(width: 8),
                              Text(
                                expiryDate != null
                                    ? 'Valid Until: ${_formatDate(expiryDate!)}'
                                    : 'No active pass',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // QR Code
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: QrImageView(
                              data:
                                  '$studentId|$cardStatus|$name|$batch Year $year|The Study Hall College',
                              version: QrVersions.auto,
                              size: 130.0,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Info note
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              isActive
                  ? 'Show this card to the bus conductor for verification.'
                  : 'Your pass has expired. Please recharge to activate your card.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}