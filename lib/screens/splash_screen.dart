import 'package:flutter/material.dart';
import './home-screen.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (context.mounted) { // Thêm kiểm tra context còn hoạt động không
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF635AD9), // Đổi sang màu tím cho đồng bộ với App
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'QUẢN LÝ CHI TIÊU',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}