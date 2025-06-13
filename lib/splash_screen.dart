import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'home.dart';
import 'login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  String? _tempDirectoryPath;
  bool _tempDirLoaded = false;

  @override
  void initState() {
    super.initState();
    _getTemporaryDirectory();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1700),
      vsync: this,
    );

    // Scale: membesar lalu mengecil sebelum fade out
    _logoScaleAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.18).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.18, end: 0.85).chain(CurveTween(curve: Curves.easeInOutBack)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.85, end: 0.7).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(_controller);

    _logoFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.7, 1.0, curve: Curves.easeOut)),
    );

    _controller.forward();

    // Transisi ke halaman berikutnya setelah animasi selesai + sedikit delay
    _controller.addStatusListener((status) async {
      if (status == AnimationStatus.completed && _tempDirLoaded) {
        await Future.delayed(const Duration(milliseconds: 120));
        _navigateToNextScreen();
      }
    });
  }

  Future<void> _getTemporaryDirectory() async {
    try {
      Directory tempDir = await getTemporaryDirectory();
      setState(() {
        _tempDirectoryPath = tempDir.path;
        _tempDirLoaded = true;
      });
    } catch (e) {
      _tempDirLoaded = true;
    }
    // Jika animasi sudah selesai, langsung navigasi (dengan delay)
    if (_controller.status == AnimationStatus.completed) {
      await Future.delayed(const Duration(milliseconds: 120));
      _navigateToNextScreen();
    }
  }

  Future<void> _navigateToNextScreen() async {
    if (!_tempDirLoaded) return;

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('user_token');

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 900),
        pageBuilder: (context, animation, secondaryAnimation) =>
            (token != null && token.isNotEmpty) ? const HomePage() : const LoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
          final slide = Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeOutCubic))
              .animate(animation);
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _logoFadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _logoFadeAnimation.value,
            child: child,
          );
        },
        child: Stack(
          children: [
            // Tambahkan posisi logo agar sama dengan login (top: 90)
            Positioned(
              top: 90,
              left: 0,
              right: 0,
              child: Center(
                child: ScaleTransition(
                  scale: _logoScaleAnimation,
                  child: Hero(
                    tag: 'main_logo',
                    child: Material(
                      color: Colors.transparent,
                      child: Image.asset('assets/images/logo.png', width: 110),
                    ),
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
