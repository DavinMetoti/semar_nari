import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:semarnari_apk/services/apiServices.dart';
import 'package:semarnari_apk/register.dart';
import 'package:semarnari_apk/home.dart';
import 'package:photo_view/photo_view.dart';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:semarnari_apk/otp.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  final ApiService apiService = ApiService();
  List<dynamic> banners = [];
  bool isLoadingBanners = true;
  int _currentBannerIndex = 0;
  final CarouselController _carouselController = CarouselController();

  late AnimationController _pageFadeController;
  late Animation<double> _pageFadeAnimation;

  bool _isLoadingLogin = false;
  bool _fingerprintEnabled = false;
  bool _fingerprintAvailable = false;
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();

    _pageFadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pageFadeAnimation = CurvedAnimation(parent: _pageFadeController, curve: Curves.easeIn);

    // Fade-in seluruh halaman login
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _pageFadeController.forward();
    });

    // Fetch banner langsung (atau bisa tambahkan delay jika ingin lebih sinkron)
    _fetchBanners();
    _loadFingerprintStatus();
    _checkFingerprintAvailable();
  }

  Future<void> _fetchBanners() async {
    try {
      final response = await http.get(Uri.parse('https://semarnari.sportballnesia.com/api/master/data/benner'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          banners = data['data'] ?? [];
          isLoadingBanners = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingBanners = false;
      });
    }
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

  Future<void> _loginWithFingerprint() async {
    try {
      final authenticated = await auth.authenticate(
        localizedReason: 'Login dengan fingerprint',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (authenticated) {
        final prefs = await SharedPreferences.getInstance();
        final username = prefs.getString('username') ?? '';
        final password = prefs.getString('password') ?? '';
        if (username.isNotEmpty && password.isNotEmpty) {
          _usernameController.text = username;
          _passwordController.text = password;
          _login();
        } else {
          _showBottomSheetAlert(context, 'Data login belum tersedia. Silakan login manual terlebih dahulu.', Colors.orange);
        }
      }
    } catch (e) {
      _showBottomSheetAlert(context, 'Fingerprint gagal: $e', Colors.red);
    }
  }

  void _showBannerZoom(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(),
          body: PhotoView(
            imageProvider: imageUrl.startsWith('data:image')
                ? MemoryImage(base64Decode(imageUrl.split(',').last))
                : NetworkImage(imageUrl) as ImageProvider,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
          ),
        ),
      ),
    );
  }

  Widget _buildBannerImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      final base64String = imageUrl.split(',').last;
      return Image.memory(
        base64Decode(base64String),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
      );
    } else {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
      );
    }
  }

  void _login() async {
    final usernameOrEmail = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (usernameOrEmail.isEmpty || password.isEmpty) {
      _showBottomSheetAlert(context, "Username/Email atau Password tidak boleh kosong", Colors.orange);
      return;
    }

    setState(() {
      _isLoadingLogin = true;
    });

    try {
      // Kirim username/email ke backend, backend harus handle username/email
      final response = await apiService.login(usernameOrEmail, password);
      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      final String message = responseBody['message'] ?? 'Pesan tidak ditemukan';

      if (responseBody['data'] != null && responseBody['data'].isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', usernameOrEmail);
        await prefs.setString('password', password); // simpan password untuk fingerprint login
        await prefs.setString('token', responseBody['token']);
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('access_role', responseBody['data']['access_role'] ?? 'default_role');
        await prefs.setString('id', responseBody['data']['id'] ?? '0');

        _showBottomSheetAlert(context, message, Colors.green);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        _showBottomSheetAlert(context, message, Colors.red);
      }
    } catch (e) {
      _showBottomSheetAlert(context, 'Terjadi kesalahan: $e', Colors.red);
    } finally {
      setState(() {
        _isLoadingLogin = false;
      });
    }
  }

  void _showBottomSheetAlert(BuildContext context, String message, Color backgroundColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                Icon(
                  backgroundColor == Colors.green ? Icons.check_circle : Icons.error,
                  size: 60,
                  color: backgroundColor,
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToRegisterPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }

  @override
  void dispose() {
    _pageFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _pageFadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _pageFadeAnimation.value,
            child: child,
          );
        },
        child: Stack(
          children: [
            // Atas melengkung biru dengan efek gradient dan shadow
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipPath(
                clipper: TopCurveClipper(),
                child: Container(
                  height: 260,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF152349), Color(0xFF3a497b)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 90),
                    Center(
                      child: Hero(
                        tag: 'main_logo',
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              "assets/images/logo.png",
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
                          child: Column(
                            children: [
                              const Text(
                                "Selamat Datang",
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Color(0xFF152349),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "Masuk ke akun Semar Nari Anda",
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 18),
                              TextField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.person, color: Color(0xFF152349)),
                                  labelText: 'Username atau Email',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFF152349), width: 2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.lock, color: Color(0xFF152349)),
                                  labelText: 'Password',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFF152349), width: 2),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                      color: Colors.grey[700],
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => OTPPage()),
                                    );
                                  },
                                  child: const Text(
                                    'Lupa Password?',
                                    style: TextStyle(
                                      color: Color(0xFF152349),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF152349), Color(0xFF3a497b)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.13),
                                              blurRadius: 10,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          onPressed: _isLoadingLogin ? null : _login,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            textStyle: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: _isLoadingLogin
                                              ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2.5,
                                                  ),
                                                )
                                              : const Text('Login', style: TextStyle(color: Colors.white)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_fingerprintEnabled && _fingerprintAvailable) ...[
                                    const SizedBox(width: 10),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Color(0xFF152349), width: 2),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                      ),
                                      onPressed: _loginWithFingerprint,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.fingerprint, color: Color(0xFF152349), size: 40),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: _navigateToRegisterPage,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text(
                                      "Belum punya akun? ",
                                      style: TextStyle(fontSize: 14, color: Colors.black87),
                                    ),
                                    Text(
                                      "Daftar sekarang",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF152349),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Banner modern di bawah
                    if (isLoadingBanners)
                      // Skeleton loader for banners, perbaiki overflow dengan ListView dan Expanded
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          itemCount: 2,
                          separatorBuilder: (context, index) => const SizedBox(width: 16),
                          itemBuilder: (context, index) => Container(
                            width: 180,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      )
                    else if (banners.isNotEmpty)
                      Column(
                        children: [
                          CarouselSlider.builder(
                            itemCount: banners.length,
                            itemBuilder: (context, index, realIdx) {
                              final banner = banners[index];
                              return GestureDetector(
                                onTap: () => _showBannerZoom(context, banner['benner']),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 5),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.10),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: _buildBannerImage(banner['benner']),
                                  ),
                                ),
                              );
                            },
                            options: CarouselOptions(
                              height: 120,
                              autoPlay: true,
                              enlargeCenterPage: true,
                              aspectRatio: 16 / 9,
                              autoPlayInterval: const Duration(seconds: 5),
                              autoPlayAnimationDuration: const Duration(milliseconds: 800),
                              autoPlayCurve: Curves.fastOutSlowIn,
                              pauseAutoPlayOnTouch: true,
                              viewportFraction: 0.8,
                              onPageChanged: (index, reason) {
                                setState(() {
                                  _currentBannerIndex = index;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: banners.asMap().entries.map((entry) {
                              return Container(
                                width: 8.0,
                                height: 8.0,
                                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withOpacity(
                                      _currentBannerIndex == entry.key ? 0.9 : 0.3),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    const SizedBox(height: 18),
                    FutureBuilder<String>(
                      future: PackageInfo.fromPlatform().then((info) => info.version),
                      builder: (context, snapshot) {
                        final version = snapshot.data ?? '-';
                        return Text(
                          'Versi aplikasi: $version',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black38,
                            letterSpacing: 0.2,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Clipper modern untuk lengkungan biru atas
class TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
      size.width / 2, size.height + 40,
      size.width, size.height - 60,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Misal pada fungsi logout, ganti bagian berikut:
// final prefs = await SharedPreferences.getInstance();
// await
