import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:unibus/screens/Topup.dart';
import 'package:unibus/screens/homescreen.dart';
import 'package:unibus/screens/login.dart';
import 'package:unibus/screens/splashscreen.dart';
import 'package:unibus/screens/transactions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(const UniBusApp());
}

class UniBusApp extends StatelessWidget {
  const UniBusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniBus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF7FC014),
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7FC014),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF7FC014),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const LoginScreen(), // temporarily start with login
      routes: {
        '/transaction': (context) => const TransactionsPage(),
        '/topup': (context) => const Topup(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
