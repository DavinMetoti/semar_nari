import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:semarnari_apk/services/apiServices.dart';
import 'package:semarnari_apk/register.dart';
import 'package:semarnari_apk/home.dart';
import 'package:photo_view/photo_view.dart';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  final ApiService apiService = ApiService();
  List<dynamic> banners = [];
  bool isLoadingBanners = true;
  int _currentBannerIndex = 0;
  final CarouselController _carouselController = CarouselController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _fetchBanners();
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
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showBottomSheetAlert(context, "Username atau Password tidak boleh kosong", Colors.orange);
      return;
    }

    try {
      final response = await apiService.login(username, password);
      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      final String message = responseBody['message'] ?? 'Pesan tidak ditemukan';

      if (responseBody['data'] != null && responseBody['data'].isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', username);
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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/bg-apk2.jpeg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Selamat Datang",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _navigateToRegisterPage,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account yet? ",
                              style: TextStyle(fontSize: 14, color: Colors.white),
                            ),
                            Text(
                              "Register now",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.yellow,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF152349),
                          padding: const EdgeInsets.all(10.0),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        child: const Text('Login', style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(height: 20),

                      if (!isLoadingBanners && banners.isNotEmpty)
                        Column(
                          children: [
                            const SizedBox(height: 10),
                            CarouselSlider(
                              items: banners.map((banner) {
                                return GestureDetector(
                                  onTap: () => _showBannerZoom(context, banner['benner']),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 5),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          spreadRadius: 2,
                                          blurRadius: 5,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: _buildBannerImage(banner['benner']),
                                    ),
                                  ),
                                );
                              }).toList(),
                              options: CarouselOptions(
                                height: MediaQuery.of(context).size.width * 0.5,
                                autoPlay: true,
                                enlargeCenterPage: true,
                                aspectRatio: 16/9,
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
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: banners.asMap().entries.map((entry) {
                                return Container(
                                  width: 8.0,
                                  height: 8.0,
                                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(
                                        _currentBannerIndex == entry.key ? 0.9 : 0.4),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),
                      const Text(
                        '© SEMARNARI Semarang 2024',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}