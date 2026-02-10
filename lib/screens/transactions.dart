import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5, bottom: 10),
            child: Text(
              'Transactions',
              style: GoogleFonts.righteous(
                color: Colors.black,
                fontSize: 24,
              ),
            ),
          ),

          const TransactionCard(
            month: "September",
            title: "Sainik Gate",
            amount: "₹500",
            date: "20 September",
          ),
          const TransactionCard(
            month: "August",
            title: "Sainik Gate",
            amount: "₹500",
            date: "1 August",
          ),
          const TransactionCard(
            month: "July",
            title: "Sainik Gate",
            amount: "₹500",
            date: "3 July",
          ),
          const TransactionCard(
            month: "June",
            title: "Sainik Gate",
            amount: "₹500",
            date: "10 June",
          ),
        ],
      ),
    );
  }
}

class TransactionCard extends StatelessWidget {
  final String month;
  final String title;
  final String amount;
  final String date;

  const TransactionCard({
    super.key,
    required this.month,
    required this.title,
    required this.amount,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            month,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 15),
                  ),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
