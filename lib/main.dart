import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:semarnari_apk/firebase_options.dart';

import 'splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await _requestPermissions();

  // Get the device token for FCM
  String? deviceToken = await _getDeviceToken();
  print('Device Token: $deviceToken');

  runApp(const MyApp());
}

// Request permissions function
Future<void> _requestPermissions() async {
  await Permission.camera.request();
  await Permission.location.request();
  await Permission.locationAlways.request();
}

// Get the device token for FCM
Future<String?> _getDeviceToken() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  return await messaging.getToken();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SplashScreen(), // Mengarah ke SplashScreen
    );
  }
}
