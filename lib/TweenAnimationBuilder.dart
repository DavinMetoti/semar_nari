import 'package:flutter/material.dart';
import 'dart:async';

class AnimatedSplashScreen extends StatefulWidget {
  @override
  _AnimatedSplashScreenState createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to Home after animation completes
    _navigateToHome();
  }

  // Function to navigate to the Home screen after a delay
  _navigateToHome() async {
    await Future.delayed(Duration(seconds: 3)); // Adjust the duration of the animation
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue, // Background color for splash screen
      body: Center(
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(seconds: 3),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Image.asset(
                'assets/images/logo.png', // Your logo or animated widget here
                width: 200,
                height: 200,
              ),
            );
          },
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(child: Text('Welcome to Home!')),
    );
  }
}
