import 'package:dynamochess/screens/home.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: double.infinity,
          width: double.infinity,
          color: const Color(0xFFffffff),
          child: Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: Image.asset(
                "assets/images/logopng.png",
                fit: BoxFit.cover,
              ),
            ),
          ),
        )
      ],
    );
  }

  Future<void> _navigateToLoginScreen() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Get.offAll(() => const HomeScreen());
      // Get.offAll(() => const LoginScreen());
    }
  }
}
