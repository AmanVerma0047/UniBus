import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unibus/screens/upiappspage.dart';
import 'package:upi_pay/upi_pay.dart';
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
  final UpiPay _upiPay = UpiPay();

  Future<void> startPayment() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    await Future.delayed(const Duration(seconds: 1));

    final response = await _upiPay.initiateTransaction(
      app: UpiApplication.googlePay, // direct open (best guess)
      receiverUpiAddress: ApiKeys.receiverupiID,
      receiverName: "UniBus",
      transactionRef: DateTime.now().millisecondsSinceEpoch.toString(),
      transactionNote: "Bus Pass Payment",
      amount: widget.amount.toString(),
    );

    Navigator.pop(context); // remove loader

    if (response.status == UpiTransactionStatus.success) {
      await sendEmail();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Payment Successful!"),
          backgroundColor: Color(0XFF7FC014),
        ),
      );

      Future.delayed(const Duration(milliseconds: 800), () {
        Navigator.pop(context);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Payment Failed or Cancelled"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payment',
          style: GoogleFonts.righteous(color: Colors.black, fontSize: 24),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Center(
        child: Card(
          elevation: 4,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: const Color(0xFF7FC014),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset('assets/upiqr.jpeg', fit: BoxFit.contain),
                ),
                const SizedBox(height: 16),

                const Text(
                  "Confirm Your Payment",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                Text("Stop: ${widget.stop}"),
                Text("Duration: ${widget.duration}"),
                Text("Amount: ₹${widget.amount}"),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UpiAppsPage(
                          stop: widget.stop,
                          duration: widget.duration,
                          amount: widget.amount,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Pay Now',
                    style: GoogleFonts.righteous(
                      color: const Color(0xFF7FC014),
                      fontSize: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
