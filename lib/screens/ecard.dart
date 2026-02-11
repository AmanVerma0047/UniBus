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

  @override
  void initState() {
    super.initState();
    fetchCardData();
  }

  Future<void> fetchCardData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get studentId from users collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return;

      final fetchedStudentId = userDoc['studentId'];

      // Get student details
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
      debugPrint("Error fetching e-card data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
              width: 280,
              height: 450,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: cardStatus.toLowerCase() == "inactive"
                      ? [Color(0xFFE53935), Color(0xFFB71C1C)]
                      : [Color(0xFF8BC34A), Color(0xFF33691E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 40,
                    left: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: const BoxDecoration(
                        color: Color(0x33000000),
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
                        color: Color(0x33000000),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Validity : ${cardStatus.toUpperCase()}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 30),

                        const Text(
                          "The Study Hall\nCollege",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Text(
                          "$name ($batch) Year $year",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),

                        const Spacer(),

                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: QrImageView(
                              data:
                                  "$studentId | $cardStatus | $name | $batch Year $year | The Study Hall College",
                              version: QrVersions.auto,
                              size: 120.0,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
