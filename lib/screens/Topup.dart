import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unibus/screens/paymentpage.dart';

class Topup extends StatefulWidget {
  const Topup({super.key});

  @override
  State<Topup> createState() => _TopupState();
}

class _TopupState extends State<Topup> {
  String? selectedStop;
  String? selectedDuration;

  final List<String> stops = ["Sainik Gate", "Hydel", "Scooter India","Krishna Nagar","Gomti Nagar"];
  final List<String> durations = ["1 month", "3 months", "6 months"];

  int getAmount() {
    switch (selectedDuration) {
      case "3 months":
        return 1400;
      case "6 months":
        return 2700;
      default:
        return 500;
    }
  }

  void showTopSnackBar(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10, // below status bar
        left: 16,
        right: 16,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    // Auto dismiss after 2 sec
    Future.delayed(const Duration(seconds: 2)).then((_) => entry.remove());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Bus Stop",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedStop,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.green.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              hint: const Text("Choose Stop"),
              items: stops
                  .map(
                    (stop) => DropdownMenuItem(value: stop, child: Text(stop)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedStop = value;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedDuration,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.green.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              hint: const Text("Choose Duration"),
              items: durations
                  .map((dur) => DropdownMenuItem(value: dur, child: Text(dur)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedDuration = value;
                });
              },
            ),
            const SizedBox(height: 24),
            const Text(
              "Invoice",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      "Fee Invoice",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text("No. : 219"),
                  const Text("Name : Aman Verma"),
                  const Text("Course : BCA"),
                  Text("Stop : ${selectedStop ?? "--"}"),
                  Text("Duration : ${selectedDuration ?? "--"}"),
                  Text("Amount: ${getAmount()} Rs"),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF7FC014),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "₹${getAmount()}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Text(
                        "Payment: To Be Paid",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (selectedStop == null || selectedDuration == null) {
                    showTopSnackBar(context, "Please select stop and duration");
                  } else {
                    // Navigate to Payment Page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentPage(
                          stop: selectedStop!,
                          duration: selectedDuration!,
                          amount: getAmount(),
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF7FC014),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                      'Move to Payment',
                      style: GoogleFonts.righteous(
                        color: const Color.fromARGB(255, 255, 255, 255),
                        fontSize: 24,
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
