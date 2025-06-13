import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tentang_aplikasi.dart';
import 'faq.dart';
import 'kebijakan_privasi.dart';

class Setting {
  static const String appName = 'Semar Nari';
}

class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  bool _fingerprintEnabled = false;
  bool _fingerprintAvailable = false;
  bool _isDarkMode = false;
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadFingerprintStatus();
    _checkFingerprintAvailable();
    _loadTheme();
  }

  Future<void> _loadFingerprintStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fingerprintEnabled = prefs.getBool('fingerprint_enabled') ?? false;
    });
  }

  Future<void> _checkFingerprintAvailable() async {
    final available = await auth.canCheckBiometrics;
    setState(() {
      _fingerprintAvailable = available;
    });
  }

  Future<void> _toggleFingerprint(bool value) async {
    if (value) {
      try {
        final authenticated = await auth.authenticate(
          localizedReason: 'Aktifkan fingerprint untuk login cepat',
          options: const AuthenticationOptions(biometricOnly: true),
        );
        if (authenticated) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('fingerprint_enabled', true);
          setState(() {
            _fingerprintEnabled = true;
          });
        }
      } catch (e) {
        print('Error during fingerprint authentication: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fingerprint gagal diaktifkan.')),
        );
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('fingerprint_enabled', false);
      setState(() {
        _fingerprintEnabled = false;
      });
    }
  }

  Future<String> _getAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final darkMode = prefs.getBool('dark_mode') ?? false;
    setState(() {
      _isDarkMode = darkMode;
    });
    // Sinkronkan dengan global theme jika berbeda
    final inherited = MyAppTheme.of(context);
    if (inherited != null && inherited.isDarkMode != darkMode) {
      inherited.changeTheme(darkMode);
    }
  }

  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    setState(() {
      _isDarkMode = value;
    });
    // Trigger rebuild seluruh aplikasi
    MyAppTheme.of(context)?.changeTheme(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF152349),
        automaticallyImplyLeading: true,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 32,
              width: 32,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Semar Nari',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    fontFamily: 'Montserrat',
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Sanggar Tari Kota Semarang',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
          ],
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(
              Icons.settings,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
      body: Container(
        color: theme.colorScheme.background,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Icon(Icons.apps, color: theme.colorScheme.primary),
                ),
                title: const Text('App Name'),
                subtitle: Text(Setting.appName, style: theme.textTheme.bodyMedium),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: FutureBuilder<String>(
                future: _getAppVersion(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      title: Text('Version'),
                      subtitle: Text('Loading...'),
                    );
                  }
                  final version = snapshot.data ?? '-';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
                      child: Icon(Icons.verified, color: theme.colorScheme.secondary),
                    ),
                    title: const Text('Version'),
                    subtitle: Text(version, style: theme.textTheme.bodyMedium),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Text('Keamanan', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.fingerprint, color: theme.colorScheme.primary),
                    title: const Text('Aktifkan Fingerprint'),
                    subtitle: !_fingerprintAvailable
                        ? const Text('Fingerprint tidak tersedia di perangkat ini')
                        : null,
                    trailing: Switch(
                      value: _fingerprintEnabled,
                      onChanged: _fingerprintAvailable ? _toggleFingerprint : null,
                    ),
                  ),
                  // const Divider(height: 1),
                  // ListTile(
                  //   leading: Icon(Icons.dark_mode, color: theme.colorScheme.primary),
                  //   title: const Text('Dark Mode'),
                  //   trailing: Switch(
                  //     value: _isDarkMode,
                  //     onChanged: (val) => _toggleDarkMode(val),
                  //   ),
                  // ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.privacy_tip, color: theme.colorScheme.primary),
                    title: const Text('Kebijakan Privasi'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const KebijakanPrivasiPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Bantuan', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Column(
                children: [
                  // ListTile(
                  //   leading: Icon(Icons.phone, color: theme.colorScheme.secondary),
                  //   title: const Text('Hubungi Kami'),
                  //   onTap: () {
                  //
                  //   },
                  // ),
                  // const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.help_outline, color: theme.colorScheme.secondary),
                    title: const Text('FAQ'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FAQPage()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.info_outline, color: theme.colorScheme.secondary),
                    title: const Text('Tentang Aplikasi'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TentangAplikasiPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
            // ...tambahkan pengaturan lain di sini...
          ],
        ),
      ),
    );
  }
}

// Tambahkan widget InheritedWidget untuk theme switching global
class MyAppTheme extends InheritedWidget {
  final bool isDarkMode;
  final void Function(bool) changeTheme;

  const MyAppTheme({
    Key? key,
    required this.isDarkMode,
    required this.changeTheme,
    required Widget child,
  }) : super(key: key, child: child);

  static MyAppTheme? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MyAppTheme>();
  }

  @override
  bool updateShouldNotify(MyAppTheme oldWidget) => isDarkMode != oldWidget.isDarkMode;
}
