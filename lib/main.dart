import 'package:flutter/material.dart';
import 'package:unibus/screens/Topup.dart';
import 'package:unibus/screens/homescreen.dart';
import 'package:unibus/screens/splashscreen.dart';
import 'package:unibus/screens/transactions.dart';


void main() {
  runApp(UniBusApp());
}

class UniBusApp extends StatelessWidget {
  const UniBusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniBus',
      debugShowCheckedModeBanner: false,
      
      theme: ThemeData(
        primaryColor: const Color(0xFF7FC014), // sets main brand color
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7FC014),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF7FC014),
          foregroundColor: Colors.white, // text & icons in AppBar
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF7FC014),
          foregroundColor: Colors.white,
        ),
      ),
      home: MyApp(),
      routes: {
      '/transaction': (context) => const TransactionsPage(),
      '/topup':(context) => const Topup(),
      },
    );
  }
}


