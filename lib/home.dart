import 'package:flutter/material.dart';
import 'package:semarnari_apk/absen.dart';
import 'package:semarnari_apk/benner.dart';
import 'package:semarnari_apk/input_value.dart';
import 'package:semarnari_apk/login.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:semarnari_apk/services/apiServices.dart';
import 'package:semarnari_apk/profile.dart';
import 'attendance.dart';
import 'list_student.dart';
import 'class_room.dart';
import 'schedule.dart';
import 'make_schedule.dart';
import 'branch.dart';
import 'edit_profile.dart';
import 'raport.dart';
import 'ranking.dart';
import 'create_admin.dart';
import 'spp_payment.dart';
import 'make_information.dart';
import 'all_information.dart';
import 'spp.dart';
import 'branch.dart';
import 'setting.dart';

class BNBCustomPainter extends CustomPainter {
  final Color backgroundColor;

  BNBCustomPainter({required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width * 0.35, 0);
    path.quadraticBezierTo(size.width * 0.40, 0, size.width * 0.40, 20);
    path.arcToPoint(
      Offset(size.width * 0.60, 20),
      radius: const Radius.circular(30),
      clockwise: false,
    );
    path.quadraticBezierTo(size.width * 0.60, 0, size.width * 0.65, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawShadow(path, Colors.black.withOpacity(0.2), 5, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}


void main() => runApp(const NavigationBarApp());

class NavigationBarApp extends StatelessWidget {
  const NavigationBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  String username = '';
  String studentId = '';
  String? accessRole;
  final String _userID = '';
  Map<String, dynamic> data = {};
  int _currentPageIndex = 0;
  final ApiService apiService = ApiService();
  bool _isLoading = false;
  List<Map<String, dynamic>> attendanceData = [];
  bool isAttendanceLoaded = false;
  List<Map<String, dynamic>> _informationList = [];

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  final List<Widget> _pages = [];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _loadUserData();
    fetchInformation();
    // Mulai animasi setelah build
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    setState(() {
      accessRole = prefs.getString('access_role');
    });


    if (username == null || username.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
      );
    }

    try {
      setState(() {
        _isLoading = true;
      });

      await Future.delayed(const Duration(milliseconds: 500)); // Simulate a delay

      // API request
      final response = await apiService.post('user/get', {'username': username});

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      // Check if response data exists
      if (responseBody['data'] != null && responseBody['data'].isNotEmpty) {
        final userData = responseBody['data'];

        if (mounted) {
          setState(() {
            data = {
              'user_id': userData['id'] ?? '',
              'username': userData['username'] ?? 'Guest',
              'email': userData['email'] ?? 'No email',
              'fullName': userData['fullname'] ?? 'No name',
              'branch_name': userData['branch_name'] ?? 'No Branch',
              'photo': userData['photo'] ?? '', // <-- pastikan key photo ada
            };
            _isLoading = false;
          });
          await _loadAttendanceUser();
        }
      } else {
        final String message = responseBody['message'] ?? 'No data available';

        setState(() {
          _isLoading = false; // Set loading to false if no data available
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false; // Ensure loading is false if there's an error
      });
    }

    // Ensure loading is false after the 500ms delay, even if no data is fetched
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 500)); // Wait for another 500ms before finishing
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAttendanceUser() async {
    try {
      final response = await apiService.post('user/get_attendance_history', {
        "user_id": data['user_id'],
      });

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == true) {
        setState(() {
          attendanceData = List.from(responseBody['data']);
        });
        isAttendanceLoaded = true; // Tandai sudah dimuat
      } else {
        // Handle error response
      }
    } catch (e) {
    }
  }

  Future<void> fetchInformation() async {
    final String apiUrl = "https://semarnari.sportballnesia.com/api/master/data/get_latest_information";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _informationList = List<Map<String, dynamic>>.from(data['data']);
        });
      } else {}
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showLogoutConfirmationModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        return Padding(
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
              const Icon(
                Icons.exit_to_app,
                size: 60,
                color: Colors.red,
              ),
              const SizedBox(height: 10),
              const Text(
                'Konfirmasi Logout',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Apakah Anda yakin ingin logout?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Tutup modal
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        // Hapus data pengguna dari SharedPreferences
                        final prefs = await SharedPreferences.getInstance();
                        final fingerprintEnabled = prefs.getBool('fingerprint_enabled') ?? false;
                        final username = prefs.getString('username') ?? '';
                        final password = prefs.getString('password') ?? '';
                        await prefs.clear();
                        if (fingerprintEnabled) {
                          await prefs.setBool('fingerprint_enabled', true);
                          if (username.isNotEmpty) await prefs.setString('username', username);
                          if (password.isNotEmpty) await prefs.setString('password', password);
                        }

                        // Navigasi ke halaman login
                        Navigator.of(context).pop(); // Tutup modal
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Logout'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tambahkan pengecekan null pada accessRole
    if (accessRole == null) {
      // Tampilkan loading atau widget kosong sampai accessRole terisi
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF152349),
          automaticallyImplyLeading: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Hindari insert berkali-kali, gunakan clear dan add
    _pages.clear();
    _pages.add(HomeScreen(data, _informationList, accessRole!, isLoading: _isLoading));
    _pages.add(const ProfileScreen());
    _pages.add(PresenceScreen(attendanceData: attendanceData));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF152349),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () {
              _showLogoutConfirmationModal(context);
            },
          ),
        ],
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 30,
              width: 30,
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Semar Nari',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Sanggar Tari Kota Semarang',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _loadUserData,
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            );
          },
          child: ListView(
            children: [
              _pages[_currentPageIndex],
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 90,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                child: CustomPaint(
                  size: const Size(double.infinity, 90),
                  painter: BNBCustomPainter(
                    backgroundColor: Theme.of(context).colorScheme.background,
                  ),
                ),
              ),
              SizedBox(
                height: 90,
                child: BottomNavigationBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  currentIndex: _currentPageIndex,
                  selectedItemColor: Theme.of(context).colorScheme.primary,
                  unselectedItemColor: Colors.grey,
                  onTap: (index) {
                    if (index == 1) return;
                    setState(() {
                      _currentPageIndex = index;
                    });
                  },
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home_rounded),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.circle, color: Colors.transparent),
                      label: '',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.event_note_rounded),
                      label: 'Present',
                    ),
                  ],
                ),
              ),
              // Tombol Tengah
              Positioned(
                bottom: 40, // dinaikkan agar tidak terpotong
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AbsenPage()));
                  },
                  child: Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF152349), Color(0xFF253D80)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 35,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _ReminderAbsenCard extends StatefulWidget {
  @override
  State<_ReminderAbsenCard> createState() => _ReminderAbsenCardState();
}

class _ReminderAbsenCardState extends State<_ReminderAbsenCard> with TickerProviderStateMixin {
  bool _visible = true;
  late AnimationController _slideFadeController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _slideFadeController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _slideFadeController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideFadeController,
      curve: Curves.easeOutBack,
    ));
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) _slideFadeController.forward();
    });
  }

  @override
  void dispose() {
    _slideFadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _closeCard() async {
    await _slideFadeController.reverse();
    if (mounted) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _slideFadeController,
      builder: (context, child) {
        return AnimatedOpacity(
          opacity: _fadeAnimation.value,
          duration: const Duration(milliseconds: 250),
          child: AnimatedSlide(
            offset: _slideAnimation.value,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.blue.shade100.withOpacity(0.18),
            highlightColor: Colors.blue.shade50.withOpacity(0.12),
            onTap: () {
              // Optional: bisa tambahkan aksi jika card ditekan
            },
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withOpacity(0.97),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade100, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade100.withOpacity(0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 0),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Image.asset(
                              'assets/images/logo.png',
                              width: 70,
                              height: 70,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Jangan lupa absen hari ini.',
                              style: const TextStyle(
                                color: Color(0xFF152349),
                                fontWeight: FontWeight.w700,
                                fontSize: 15.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Yuk, semangat berlatih dan tetap tersenyum 😊',
                          style: TextStyle(
                            color: Color(0xFF31416A),
                            fontWeight: FontWeight.w500,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _closeCard,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade100.withOpacity(0.18),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.close, size: 18, color: Color(0xFF152349)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<Map<String, dynamic>> info;
  final bool isLoading;
  final String access_role;

  const HomeScreen(this.data, this.info, this.access_role, {super.key, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    bool enabled = isLoading;
    String fullName = data['fullName'] ?? 'Guest';
    String email = data['email'] ?? 'No email';
    String branch = data['branch_name'] ?? 'No branch';
    String accessRole = access_role;

    final List<_MenuItem> userMenus = [
      _MenuItem(
        icon: 'assets/images/checklist.png',
        label: 'Kehadiran',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AttendanceScreen())),
        color: Colors.indigo,
      ),
      _MenuItem(
        icon: 'assets/images/schedule.png',
        label: 'Jadwal',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SchedulePage())),
        color: Colors.deepPurple,
      ),
      _MenuItem(
        icon: 'assets/images/report.png',
        label: 'Raport',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RaportPage())),
        color: Colors.pinkAccent,
      ),
      _MenuItem(
        icon: 'assets/images/book.png',
        label: 'Edit Profil',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfilePage())),
        color: Colors.teal,
      ),
      _MenuItem(
        icon: 'assets/images/invoice.png',
        label: 'SPP',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SppPage())),
        color: Colors.green,
      ),
      _MenuItem(
        icon: 'assets/images/gear.png',
        label: 'Setting',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SettingPage())),
        color: Colors.orangeAccent,
      ),
    ];

    final List<_MenuItem> adminMenus = [
      _MenuItem(
        icon: 'assets/images/students.png',
        label: 'Daftar Siswa',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StudentListPage())),
        color: Colors.blue,
      ),
      _MenuItem(
        icon: 'assets/images/task-planning.png',
        label: 'Buat Jadwal',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MakeSchedulePage())),
        color: Colors.deepOrange,
      ),
      _MenuItem(
        icon: 'assets/images/branch.png',
        label: 'Sanggar',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BranchPage())),
        color: Colors.cyan,
      ),
      _MenuItem(
        icon: 'assets/images/wayang.png',
        label: 'Kelas',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ClassRoomPage())),
        color: Colors.purple,
      ),
      _MenuItem(
        icon: 'assets/images/working.png',
        label: 'Buat Admin',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CreateAdminPage())),
        color: Colors.redAccent,
      ),
      _MenuItem(
        icon: 'assets/images/invoice.png',
        label: 'Catat SPP',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SPPPaymentsPage())),
        color: Colors.green,
      ),
      _MenuItem(
        icon: 'assets/images/score.png',
        label: 'Input Nilai',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => InputValuePage())),
        color: Colors.deepPurpleAccent,
      ),
      _MenuItem(
        icon: 'assets/images/messages.png',
        label: 'Tambah Info',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MakeInformationPage())),
        color: Colors.blueGrey,
      ),
      _MenuItem(
        icon: 'assets/images/advertising.png',
        label: 'Banner',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BannerPage())),
        color: Colors.orange,
      ),
    ];

    void _showDetailDialog(String title, String description) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            title: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
            ),
            content: Text(description, style: TextStyle(fontSize: 14.0)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Tutup"),
              ),
            ],
          );
        },
      );
    }

    return Stack(
      children: [
        // Curved blue background
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 180,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF152349), Color(0xFF3b5998)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(48),
                bottomRight: Radius.circular(48),
              ),
            ),
          ),
        ),
        // Main content
        ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 15),
            // --- MODERN WELCOME CARD START ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.18),
                          Colors.blue.shade50.withOpacity(0.18),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueGrey.withOpacity(0.10),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 25,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width - 68 - 0 - 18 - 60, // avatar + padding + spacing + approx. profile btn
                            child: Skeletonizer(
                              enabled: isLoading,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // FOTO PROFIL
                                  Builder(
                                    builder: (context) {
                                      final photo = data['photo']?.toString() ?? '';
                                      if (photo.isNotEmpty && photo != 'null') {
                                        if (photo.startsWith('data:image/')) {
                                          try {
                                            final base64Str = photo.split(',').last;
                                            return Container(
                                              width: 48,
                                              height: 48,
                                              margin: const EdgeInsets.only(right: 16),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 2),
                                              ),
                                              child: ClipOval(
                                                child: Image.memory(
                                                  base64Decode(base64Str),
                                                  width: 48,
                                                  height: 48,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            );
                                          } catch (_) {
                                            return Container(
                                              width: 48,
                                              height: 48,
                                              margin: const EdgeInsets.only(right: 16),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.grey.shade300,
                                              ),
                                              child: const Icon(Icons.account_circle, size: 44, color: Colors.white),
                                            );
                                          }
                                        } else {
                                          return Container(
                                            width: 48,
                                            height: 48,
                                            margin: const EdgeInsets.only(right: 16),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 2),
                                            ),
                                            child: ClipOval(
                                              child: Image.network(
                                                photo,
                                                width: 48,
                                                height: 48,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Icon(
                                                  Icons.account_circle,
                                                  size: 44,
                                                  color: Colors.grey.shade300,
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                      } else {
                                        return Container(
                                          width: 48,
                                          height: 48,
                                          margin: const EdgeInsets.only(right: 16),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.grey.shade300,
                                          ),
                                          child: const Icon(Icons.account_circle, size: 44, color: Colors.white),
                                        );
                                      }
                                    },
                                  ),
                                  // TEKS: Hi, Nama, Email, Branch
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Hi, ',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                            Flexible(
                                              child: Text(
                                                fullName,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  letterSpacing: 0.2,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Text(
                                              '👋',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.email_outlined, color: Colors.blue.shade300, size: 16),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                email,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.location_on_outlined, color: Colors.pink.shade200, size: 16),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                branch,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Profile button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Color(0xFF152349),
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // --- MODERN WELCOME CARD END ---
            const SizedBox(height: 30),
            if (access_role != "2") _ReminderAbsenCard(),
            const SizedBox(height: 2),
            // Menu utama
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Menu Utama",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // User menu: horizontal scroll, square, shadow
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: userMenus.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, idx) {
                        final menu = userMenus[idx];
                        return _SquareMenuCard(
                          icon: menu.icon,
                          label: menu.label,
                          onTap: menu.onTap,
                          color: menu.color,
                        );
                      },
                    ),
                  ),
                  if (accessRole == "2") ...[
                    const SizedBox(height: 22),
                    Text(
                      "Menu Admin",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Admin menu: grid, 3 columns, square, shadow
                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: adminMenus.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, idx) {
                        final menu = adminMenus[idx];
                        return _SquareMenuCard(
                          icon: menu.icon,
                          label: menu.label,
                          onTap: menu.onTap,
                          color: menu.color,
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Info section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modern info header
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF3b5998), Color(0xFF5dade2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(7),
                        child: Icon(Icons.info_outline, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Informasi Terbaru',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AllNotification()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.blueGrey.shade700 // dark mode
                                : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Semua informasi',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white70 // dark mode
                                  : Colors.blue.shade700, // light mode
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Redesigned vertical info cards (like all_information.dart)
                  info.isNotEmpty
                      ? ListView.separated(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: info.length > 3 ? 3 : info.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final item = info[index];
                            final String title = item["title"] ?? "Tanpa Judul";
                            final String description = item["description"] ?? "Tanpa Deskripsi";
                            final String shortDescription = description.length > 70
                                ? "${description.substring(0, 70)}..."
                                : description;
                            final String createdAt = item["created_at"] ?? "-";
                            return AnimatedContainer(
                              duration: Duration(milliseconds: 350 + index * 40),
                              curve: Curves.easeOutCubic,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFe0eafc), Color(0xFFcfdef3)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () => _showDetailDialog(title, description),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF3b5998), Color(0xFF5dade2)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          padding: const EdgeInsets.all(10),
                                          child: const Icon(Icons.circle_notifications_outlined, color: Colors.white, size: 28),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      title,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xFF152349),
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        createdAt,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontStyle: FontStyle.italic,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                shortDescription,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF31416A),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.arrow_forward_ios, size: 18, color: Color(0xFF31416A)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Container(
                            width: double.infinity,
                            height: 90,
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.blueGrey.shade700 // dark mode
                                  : Colors.blue.shade50,      // light mode
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(width: 10),
                                Icon(Icons.info_outline, color: Colors.blue, size: 28),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Tidak ada informasi terbaru',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Model menu item
class _MenuItem {
  final String icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  _MenuItem({required this.icon, required this.label, required this.onTap, required this.color});
}

// Persegi menu card untuk user & admin
class _SquareMenuCard extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _SquareMenuCard({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.85), color.withOpacity(0.65)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.18),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  icon,
                  width: 26,
                  height: 26,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                  letterSpacing: 0.2,
                  shadows: [
                    Shadow(
                      color: Colors.black38,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class PresenceScreen extends StatelessWidget {
  final List<Map<String, dynamic>> attendanceData;

  const PresenceScreen({super.key, required this.attendanceData});

  @override
  Widget build(BuildContext context) {
    return attendanceData.isEmpty
        ? const Center(
      child: Text(
        'No attendance data available',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    )
        : SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: List.generate(attendanceData.length, (index) {
          var attendance = attendanceData[index];

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFFDEE2FF), Color(0xFFEFF0F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  attendance['photo'] != null && attendance['photo'].isNotEmpty
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Image.memory(
                      const Base64Decoder().convert(attendance['photo']),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  )
                      : CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey.shade300,
                    child: Icon(Icons.person, size: 30, color: Colors.grey.shade700),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildStatusBadge(attendance['status']),
                            const Spacer(),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                                const SizedBox(width: 4),
                                Text(
                                  attendance['location'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${attendance['attendance_date'] ?? ''} | ${attendance['check_in_time'] ?? '-'}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    Color bgColor;
    String label = status ?? 'Unknown';

    switch (status) {
      case 'Absen':
        bgColor = Colors.green;
        break;
      case 'Ijin':
        bgColor = Colors.orange;
        break;
      case 'Alpha':
        bgColor = Colors.redAccent;
        break;
      default:
        bgColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Profile Page',
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}
