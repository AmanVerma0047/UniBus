import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Payment Page
class PaymentPage extends StatelessWidget {
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
                  child: Image.asset(
                    'assets/upiqr.jpeg', // <-- replace with your image path
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  "Confirm Your Payment",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                Text("Stop: $stop"),
                Text("Duration: $duration"),
                Text("Amount: ₹$amount"),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () {
                    // ✅ Show SnackBar at the top
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          "✅ Payment Successful!",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.only(
                          top: 16, // distance from the top
                          left: 16,
                          right: 16,
                        ),
                        backgroundColor: const Color(0XFF7FC014),
                        duration: const Duration(seconds: 2),
                      ),
                    );

                    // Optional: delay navigation slightly for better UX
                    Future.delayed(const Duration(milliseconds: 800), () {
                      Navigator.pop(context);
                    });
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
                  child:Text(
                      'Pay Now',
                      style: GoogleFonts.righteous(
                        color: Color(0xFF7FC014),
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
