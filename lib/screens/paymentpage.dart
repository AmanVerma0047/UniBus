import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unibus/screens/upiappspage.dart';
import 'package:http/http.dart' as http;
import 'package:unibus/services/API_KEYS.dart';

class PaymentPage extends StatefulWidget {
  final String stop;
  final String duration;
  final int amount;

  const PaymentPage({
    super.key,
    required this.stop,
    required this.duration,
    required this.amount,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  Future<void> sendEmail() async {
    await http.post(
      Uri.parse("https://api.emailjs.com/api/v1.0/email/send"),
      headers: {
        "origin": "http://localhost",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "service_id": ApiKeys.emailJsServiceId,
        "template_id": ApiKeys.emailJsTemplateId,
        "user_id": ApiKeys.emailJsTemplateId,
        "template_params": {
          "to_email": "student@email.com",
          "stop": widget.stop,
          "duration": widget.duration,
          "amount": widget.amount.toString(),
        },
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionRef =
        DateTime.now().millisecondsSinceEpoch.toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        // ── Black back arrow ──────────────────────
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'Payment',
          style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Section label ──────────────────────
              Text('ORDER SUMMARY',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black38,
                      letterSpacing: 1)),
              const SizedBox(height: 10),

              // ── Summary card ───────────────────────
              ClipRRect(
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
                          Text('BUS PASS',
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white54,
                                  letterSpacing: 1)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade700,
                              borderRadius:
                                  BorderRadius.circular(100),
                            ),
                            child: Text('Pending',
                                style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
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
                          _SumRow(
                              label: 'Stop',
                              value: widget.stop),
                          _SumRow(
                              label: 'Duration',
                              value: widget.duration),
                          _SumRow(
                              label: 'Transaction Ref',
                              value: '#$transactionRef',
                              mono: true),
                          _SumRow(
                              label: 'Payment To',
                              value: 'UniBus'),
                        ],
                      ),
                    ),
                    // Total footer
                    Container(
                      color: const Color(0xFF7FC014),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Amount',
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500)),
                          Text('₹${widget.amount}',
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

              const SizedBox(height: 16),

              // ── Info note ──────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3DE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFF3B6D11), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You will be redirected to your UPI app to complete this payment securely. Do not close the app during the transaction.',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            color: const Color(0xFF3B6D11),
                            height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Pay Now button ─────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UpiAppsPage(
                          stop: widget.stop,
                          duration: widget.duration,
                          amount: widget.amount,
                        ),
                      ),
                    );
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
                  child: Text('Pay Now →',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable summary row ──────────────────────────────
class _SumRow extends StatelessWidget {
  final String label, value;
  final bool mono;

  const _SumRow({
    required this.label,
    required this.value,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Color(0xFFF3F3F3))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 13, color: Colors.black38)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: mono
                    ? GoogleFonts.dmMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87)
                    : GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black)),
          ),
        ],
      ),
    );
  }
}