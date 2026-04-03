import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:unibus/services/API_KEYS.dart';
import 'package:upi_pay/upi_pay.dart';

class PaymentProcessingPage extends StatefulWidget {
  final ApplicationMeta app;
  final String stop;
  final String duration;
  final int amount;

  const PaymentProcessingPage({
    super.key,
    required this.app,
    required this.stop,
    required this.duration,
    required this.amount,
  });

  @override
  State<PaymentProcessingPage> createState() => _PaymentProcessingPageState();
}

class _PaymentProcessingPageState extends State<PaymentProcessingPage> {
  bool _isLaunching = true;
  bool _isSuccess = false;
  final UpiPay _upiPay = UpiPay();

  Future<bool>? _emailFuture;

  static const String _receiverUpiId = ApiKeys.receiverupiID;
  static const String _receiverName = 'UniBus';
  static const String _txnNote = 'Bus Pass Payment';

  String? _studentId;

  @override
  void initState() {
    super.initState();
    _launchUpiApp();
  }

  // fetching student id from users collection
  Future<String?> _resolveStudentId() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) {
        debugPrint(' UID is null');
        return null;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        debugPrint(' User doc not found');
        return null;
      }

      final data = userDoc.data();
      debugPrint(' User data: $data');

      final studentId = data?['studentId']?.toString();

      debugPrint(' studentId: $studentId');

      return studentId;
    } catch (e) {
      debugPrint(' studentId error: $e');
      return null;
    }
  }

  //  dummy payment gateway integration
  Future<void> _launchUpiApp() async {
    try {
      await _upiPay.initiateTransaction(
        amount: widget.amount.toString(),
        app: widget.app.upiApplication,
        receiverUpiAddress: _receiverUpiId,
        receiverName: _receiverName,
        transactionRef: 'UNIBUS-${DateTime.now().millisecondsSinceEpoch}',
        transactionNote: _txnNote,
      );

      await Future.delayed(
        const Duration(seconds: 2),
      ); //checks if the app is open for duration of 2 seconds

      if (!mounted) return;
      setState(() {
        //making the status to success for the payment
        _isSuccess = true;
        _isLaunching = false;
        _emailFuture = _sendEmail(); //send email once the payment is done
      });
      await _saveTransaction(); //saving transaction details to the firebase server
    } catch (e) {
      debugPrint(' Payment error: $e'); //else payment error

      if (!mounted) return;
      setState(() {
        _isSuccess = true;
        _isLaunching = false;
        _emailFuture = _sendEmail();
      });

      await _saveTransaction();
    }
  }

  //parsing duration from the month
  //Extracts the first number from a string and returns it as an integer. If no number exists, it returns 1.
  int _parseDurationMonths(String duration) {
    final match = RegExp(r'(\d+)').firstMatch(duration);
    return match != null ? int.parse(match.group(1)!) : 1;
  }

  // save the transaction to the server
  Future<void> _saveTransaction() async {
    try {
      _studentId = await _resolveStudentId(); //get student id from the server

      if (_studentId == null) {
        debugPrint(' studentId NULL — stopping');
        return;
      }

      final now = DateTime.now();
      final txnRef =
          'UNIBUS-${now.millisecondsSinceEpoch}'; //refering a txn ID based on the time passed since epoch
      final months = _parseDurationMonths(
        widget.duration,
      ); //initialization of duration to month variable in integer

      debugPrint(' Saving for $_studentId'); // console log for debug purpose

      final studentRef = FirebaseFirestore
          .instance //taking a copy of the data from the database
          .collection('students')
          .doc(_studentId);

      final studentDoc = await studentRef.get(); // storing that in studentDoc

      DateTime baseDate = now;
      DateTime? previousExpiry;
      int previousMonths = 0;

      if (studentDoc.exists) {
        final data = studentDoc.data();
        final rawExpiry =
            data?['expiryDate']; // saving the expiryDate from the data
        final prevValidity =
            data?['validity']; //saving the validity from the data

        if (prevValidity != null) {
          previousMonths = _parseDurationMonths(
            prevValidity,
          ); // parshing validity to get the integer from pass
        }

        if (rawExpiry != null) {
          previousExpiry = (rawExpiry as Timestamp)
              .toDate(); //parshing the expiry date to get the integer expiry date

          if (previousExpiry.isAfter(now)) {
            baseDate = previousExpiry;
            debugPrint(
              '📅 Extending existing pass',
            ); //extending the pass to the next expiry date
          }
        }
      }
      //extending the pass structure

      final newExpiry = DateTime(
        baseDate.year,
        baseDate.month + months,
        baseDate.day,
      );

      final totalMonths = previousMonths + months;

      debugPrint('🆕 New Expiry: $newExpiry');
      debugPrint('🆕 New Pass: $totalMonths');

      //  Save transaction to the firebase
      await studentRef.collection('transactions').doc(txnRef).set({
        'stop': widget.stop,
        'duration': widget.duration,
        'amount': widget.amount,
        'status': 'success',
        'txnRef': txnRef,
        'timestamp': FieldValue.serverTimestamp(),
        'transactionDate': Timestamp.fromDate(now),
        'newExpiryDate': Timestamp.fromDate(newExpiry),
      });

      debugPrint(' Transaction saved');

      // Updating main student collections
      await studentRef.set({
        'cardStatus': 'active',
        'expiryDate': Timestamp.fromDate(newExpiry),
        'validity': '$totalMonths months',
        'stop': widget.stop,
      }, SetOptions(merge: true));

      debugPrint(' Student updated SUCCESS');
    } catch (e) {
      debugPrint(' Firestore error: $e');
    }
  }

  //sending Email after finishing the transaction
  Future<bool> _sendEmail() async {
    try {
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': ApiKeys.emailJsServiceId,
          'template_id': ApiKeys.emailJsTemplateId,
          'user_id': ApiKeys.emailJsPublicKey,
          'template_params': {
            'to_email': 'vaman0183@gmail.com',
            'stop': widget.stop,
            'duration': widget.duration,
            'amount': widget.amount.toString(),
          },
        }),
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  //UI after the transaction has been done
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Processing Payment')),
      body: _isLaunching
          ? const Center(child: CircularProgressIndicator())
          : _buildResult(),
    );
  }

  Widget _buildResult() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Success icon ───────────────────────
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3DE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFF3B6D11),
                size: 44,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Payment Successful',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Your bus pass has been activated.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: Colors.black38,
              ),
            ),

            const SizedBox(height: 24),

            // ── Summary pill ───────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.07)),
              ),
              child: Column(
                children: [
                  _ResultRow(label: 'Stop', value: widget.stop),
                  const SizedBox(height: 10),
                  _ResultRow(label: 'Duration', value: widget.duration),
                  const SizedBox(height: 10),
                  _ResultRow(
                    label: 'Amount',
                    value: '₹${widget.amount}',
                    valueStyle: GoogleFonts.dmMono(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3B6D11),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Email status ───────────────────────
            if (_emailFuture != null)
              FutureBuilder<bool>(
                future: _emailFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF7FC014),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sending confirmation email...',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            color: Colors.black38,
                          ),
                        ),
                      ],
                    );
                  } else if (snapshot.data == true) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.mark_email_read_rounded,
                          size: 16,
                          color: Color(0xFF3B6D11),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Confirmation email sent',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            color: const Color(0xFF3B6D11),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 16,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Email could not be sent',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            color: Colors.red.shade400,
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),

            const SizedBox(height: 32),

            // ── Go to Home button ──────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Go to Home',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


}

class _ResultRow extends StatelessWidget {
  final String label, value;
  final TextStyle? valueStyle;

  const _ResultRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.spaceGrotesk(
                fontSize: 13, color: Colors.black38)),
        Text(value,
            style: valueStyle ??
                GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black)),
      ],
    );
  }
}
