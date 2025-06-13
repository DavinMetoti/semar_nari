import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'splash_screen.dart';
import 'dart:io'; // Import dart:io untuk Directory
import 'setting.dart'; // Import MyAppTheme

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pindahkan pemanggilan getTemporaryDirectory ke dalam fungsi atau widget
  // di mana Flutter Engine sudah terinisialisasi.
  // final directory = await getTemporaryDirectory(); // Hapus baris ini dari main()

  // ✅ OneSignal Init
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("8cd848a7-4604-427a-9f7c-5f559154a43a");
  OneSignal.Notifications.requestPermission(false);

  await _requestPermissions();

  // (Opsional) Cetak device token OneSignal
  var deviceState = await OneSignal.User.pushSubscription.id;

  runApp(const MyAppRoot());
}

// Request permissions function
Future<void> _requestPermissions() async {
  await Permission.camera.request();
  await Permission.location.request();
  await Permission.locationAlways.request();
  await Permission.notification.request();
}

class MyAppRoot extends StatefulWidget {
  const MyAppRoot({Key? key}) : super(key: key);

  @override
  State<MyAppRoot> createState() => _MyAppRootState();
}

class _MyAppRootState extends State<MyAppRoot> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final darkMode = prefs.getBool('dark_mode') ?? false;
    setState(() {
      _isDarkMode = darkMode;
    });
  }

  void _changeTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', isDark);
    setState(() {
      _isDarkMode = isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MyAppTheme(
      isDarkMode: _isDarkMode,
      changeTheme: _changeTheme,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
          useMaterial3: true,
        ),
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: const SplashScreen(),
      ),
    );
  }
}
