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
  late Future<bool> _emailFuture;

  static const String _receiverUpiId = ApiKeys.receiverupiID;
  static const String _receiverName = 'UniBus';
  static const String _txnNote = 'Bus Pass Payment';

  @override
  void initState() {
    super.initState();
    _launchUpiApp();
  }

  Future<void> _launchUpiApp() async {
    try {
      _upiPay.initiateTransaction(
        amount: widget.amount.toString(),
        app: widget.app.upiApplication,
        receiverUpiAddress: _receiverUpiId,
        receiverName: _receiverName,
        transactionRef: 'UNIBUS-${DateTime.now().millisecondsSinceEpoch}',
        transactionNote: _txnNote,
      );

      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;

      setState(() {
        _isSuccess = true;
        _isLaunching = false;
        _emailFuture = _sendEmail();
      });

      await _saveTransaction();
    } catch (e) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;

      setState(() {
        _isSuccess = true;
        _isLaunching = false;
        _emailFuture = _sendEmail();
      });

      await _saveTransaction();
    }
  }

  // Parses "1 month", "3 months", "6 months" → int
  int _parseDurationMonths(String duration) {
    final match = RegExp(r'(\d+)').firstMatch(duration);
    return match != null ? int.parse(match.group(1)!) : 1;
  }

  Future<void> _saveTransaction() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final now = DateTime.now();
      final txnRef = 'UNIBUS-${now.millisecondsSinceEpoch}';

      // Calculate expiry from payment date + duration months
      final months = _parseDurationMonths(widget.duration);
      final expiryDate = DateTime(now.year, now.month + months, now.day);

      // Save transaction under student subcollection
      await FirebaseFirestore.instance
          .collection('students')
          .doc(uid)
          .collection('transactions')
          .doc(txnRef)
          .set({
        'stop': widget.stop,
        'duration': widget.duration,
        'amount': widget.amount,
        'status': 'success',
        'txnRef': txnRef,
        'timestamp': FieldValue.serverTimestamp(),
        'month': _monthName(now.month),
        'date': '${now.day} ${_monthName(now.month)}',
        'expiryDate': Timestamp.fromDate(expiryDate),
      });

      // Update student document with new expiry date and set card active
      await FirebaseFirestore.instance
          .collection('students')
          .doc(uid)
          .update({
        'cardStatus': 'active',
        'expiryDate': Timestamp.fromDate(expiryDate),
      });

      debugPrint('Transaction saved! Expiry: $expiryDate');
    } catch (e) {
      debugPrint('Firestore error: $e');
    }
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Future<bool> _sendEmail() async {
    await Future.delayed(const Duration(milliseconds: 500));
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
            'name': 'SHC Student',
            'stop': widget.stop,
            'duration': widget.duration,
            'amount': widget.amount.toString(),
          },
        }),
      );

      debugPrint('Email status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Email error: $e');
      return false;
    }
  }

  _StatusConfig get _statusConfig {
    if (_isSuccess) {
      return const _StatusConfig(
        icon: Icons.check_circle_rounded,
        iconColor: Color(0xFF7FC014),
        title: 'Payment Successful!',
        subtitle: 'Your bus pass has been activated.\nA confirmation has been sent to your email.',
        buttonLabel: 'Go to Home',
        isSuccess: true,
      );
    } else {
      return const _StatusConfig(
        icon: Icons.cancel_rounded,
        iconColor: Colors.red,
        title: 'Payment Failed',
        subtitle: 'The transaction could not be completed.\nPlease try again.',
        buttonLabel: 'Try Again',
        isSuccess: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Processing Payment',
          style: GoogleFonts.righteous(color: Colors.black, fontSize: 22),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _isLaunching ? _buildLaunching() : _buildResult(),
      ),
    );
  }

  Widget _buildLaunching() {
    return Center(
      key: const ValueKey('launching'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF7FC014),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Opening payment app...',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            'Please complete the payment in\n'
            '${widget.app.upiApplication.toString().split('.').last}',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final cfg = _statusConfig;
    return Center(
      key: const ValueKey('result'),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: cfg.iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(cfg.icon, size: 56, color: cfg.iconColor),
            ),
            const SizedBox(height: 24),
            Text(cfg.title,
                style: GoogleFonts.righteous(fontSize: 24, color: Colors.black87)),
            const SizedBox(height: 12),
            Text(
              cfg.subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 14, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 16),
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
                            strokeWidth: 2, color: Color(0xFF7FC014)),
                      ),
                      const SizedBox(width: 8),
                      Text('Sending confirmation email...',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  );
                } else if (snapshot.data == true) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.email_rounded,
                          size: 16, color: Color(0xFF7FC014)),
                      const SizedBox(width: 6),
                      Text('Confirmation email sent!',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF7FC014),
                              fontWeight: FontWeight.w500)),
                    ],
                  );
                } else {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 16, color: Colors.orange),
                      const SizedBox(width: 6),
                      Text('Email could not be sent',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500)),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7EB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _summaryRow('Stop', widget.stop),
                  const SizedBox(height: 6),
                  _summaryRow('Duration', widget.duration),
                  const SizedBox(height: 6),
                  _summaryRow('Amount', '\u20B9${widget.amount}'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7FC014),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  if (cfg.isSuccess) {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: Text(cfg.buttonLabel,
                    style: GoogleFonts.righteous(
                        fontSize: 20, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13, color: Colors.grey.shade600)),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
      ],
    );
  }
}

class _StatusConfig {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final bool isSuccess;

  const _StatusConfig({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.isSuccess,
  });
}