import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:g_stock/pages/home_screen.dart';
import 'package:g_stock/pages/login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 100,
              width: 100,
              child: Image.asset(
                'assets/Logo Gudang.png',
              ),
            ), //nanti logonya ganti aja
            SizedBox(
              height: 20,
            ),
            CircularProgressIndicator(
              color: Colors.orangeAccent,
              strokeWidth: 4,
            )
          ],
        ),
      ),
    );
  }
}
