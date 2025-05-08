import 'package:flutter/material.dart';
import 'package:semarnari_apk/absen.dart';
import 'package:semarnari_apk/benner.dart';
import 'package:semarnari_apk/login.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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

class _HomePageState extends State<HomePage> {
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

  final List<Widget> _pages = [

  ];

  @override
  void initState() {
    _loadUserData();
    fetchInformation();
    super.initState();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    setState(() {
      accessRole = prefs.getString('access_role');
    });

    print('test Access Role 1: $accessRole');



    if (username == null || username.isEmpty) {
      print("Username is null or empty!");
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
      print("API Response body: ${response.body}");

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
              'branch_name': userData['branch_name'] ?? 'No Branch'
            };
            _isLoading = false;
          });
          await _loadAttendanceUser();
        }
      } else {
        final String message = responseBody['message'] ?? 'No data available';
        print(message);

        setState(() {
          _isLoading = false; // Set loading to false if no data available
        });
      }
    } catch (e) {
      print("Error fetching data: $e");
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
      print('Response body: ${response.body}');

      if (response.statusCode == 200 && responseBody['status'] == true) {
        setState(() {
          attendanceData = List.from(responseBody['data']);
        });
        print('Attendance Data: $attendanceData');
        isAttendanceLoaded = true; // Tandai sudah dimuat
      } else {
        // Handle error response
        print('Failed to load attendance data');
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> fetchInformation() async {
    final String apiUrl = "https://semarnari.sportballnesia.com/api/master/data/get_latest_information";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        print('Response data: ${data}');
        setState(() {
          _informationList = List<Map<String, dynamic>>.from(data['data']);
        });
      } else {
      }
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
                        await prefs.clear();

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
    // Dynamically set the HomeScreen with the username and all data
    _pages.insert(0, HomeScreen(data, _informationList, accessRole! , isLoading: _isLoading));
    _pages.insert(1, const ProfileScreen());
    _pages.insert(2, PresenceScreen(attendanceData: attendanceData));
    print('test Access Role: $accessRole');


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
        child: ListView(
          children: [
            _pages[_currentPageIndex],
          ],
        ),
      ),
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none, // Memastikan tombol tidak terpotong
        alignment: AlignmentDirectional.topCenter,
        children: [
          BottomNavigationBar(
            unselectedLabelStyle: const TextStyle(color: Colors.white, fontSize: 12),
            selectedLabelStyle: const TextStyle(color: Colors.white, fontSize: 12),
            backgroundColor: const Color(0xFF152349),
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white60,
            currentIndex: _currentPageIndex,
            onTap: (index) {
              if (index == 1) return;
              setState(() {
                _currentPageIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined, size: 32),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: IgnorePointer(
                  child: SizedBox.shrink(), // Ruang kosong untuk tombol tengah
                ),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.list_alt_outlined, size: 32),
                label: 'Present',
              ),
            ],
          ),
          Positioned(
            bottom: 18, // Jarak tombol tengah dari BottomNavigationBar
            child: InkWell(
              onTap: () {
                print('terklick');
              },
              child: Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF152349),
                  border: Border.all(
                    color: Colors.white, // Border color
                    width: 5,            // Border width (adjust as needed)
                  ),
                ),

                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AbsenPage()),
                    );
                  },
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 45,
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class HomeScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<Map<String, dynamic>> info; // Accept data in constructor
  final bool isLoading; // Accept loading state
  final String access_role; // Accept access_role

  // Constructor to accept data and loading state
  const HomeScreen(this.data, this.info, this.access_role, {super.key, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    bool enabled = isLoading;
    String fullName = data['fullName'] ?? 'Guest';
    String email = data['email'] ?? 'No email';
    String branch = data['branch_name'] ?? 'No branch';
    String accessRole = access_role;

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

    return Column(
      children: [
        // Profile container with background
        Container(
          height: 120,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFF152349),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Card(
                    color: Colors.white.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Skeletonizer(
                              enabled: isLoading,
                              child: ListView.builder(
                                itemCount: 1,
                                itemBuilder: (context, index) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Welcome, $fullName!',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        'Email: $email',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        'Cabang: $branch',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          InkWell(
                            onTap: () {
                              // Navigate to ProfilePage when the icon is tapped
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ProfilePage()), // Navigate correctly to ProfilePage
                              );
                            },
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.account_circle_outlined,
                                  color: Colors.white,
                                  size: 45,
                                ),
                                Text(
                                  'Profile',
                                  style: TextStyle(
                                    color: Colors.white, // Choose a text color that contrasts with the background
                                    fontSize: 12,         // Adjust the font size as needed
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

              ],
            ),
          ),
        ),
        const SizedBox(height: 10,),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                                MaterialPageRoute(builder: (context) => AttendanceScreen())
                            );
                          },
                          borderRadius: BorderRadius.circular(16.0), // Matches Card's border radius
                          child: Card(
                            color: const Color(0xFF152349),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0), // Optional rounded corners
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/images/checklist.png',
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2.0), // Space between card and text
                    const Text(
                      'Kehadiran',
                      style: TextStyle(fontSize: 12.0),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => SchedulePage())
                            );
                          },
                          borderRadius: BorderRadius.circular(16.0), // Matches Card's border radius
                          child: Card(
                            color: const Color(0xFF152349),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0), // Optional rounded corners
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/images/schedule.png',
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2.0), // Space between card and text
                    const Text(
                      'Jadwal',
                      style: TextStyle(fontSize: 12.0),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => RaportPage()),
                            );
                          },
                          borderRadius: BorderRadius.circular(16.0), // Matches Card's border radius
                          child: Card(
                            color: const Color(0xFF152349),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0), // Optional rounded corners
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/images/report.png',
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2.0), // Space between card and text
                    const Text(
                      'Raport',
                      style: TextStyle(fontSize: 12.0),
                    ),
                  ],
                ),
              ],
            ),

        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const EditProfilePage()),
                          );
                        },
                        borderRadius: BorderRadius.circular(16.0), // Matches Card's border radius
                        child: Card(
                          color: const Color(0xFF152349),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0), // Optional rounded corners
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/images/book.png',
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2.0), // Space between card and text
                  const Text(
                    'Edit Profil',
                    style: TextStyle(fontSize: 12.0),
                  ),
                ],
              ),
              Column(
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RankingPage()),
                          );
                        },
                        borderRadius: BorderRadius.circular(16.0), // Matches Card's border radius
                        child: Card(
                          color: const Color(0xFF152349),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0), // Optional rounded corners
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/images/trophy.png',
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2.0), // Space between card and text
                  const Text(
                    'Peringkat',
                    style: TextStyle(fontSize: 12.0),
                  ),
                ],
              ),
              Column(
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SppPage()),
                          );
                        },
                        borderRadius: BorderRadius.circular(16.0), // Matches Card's border radius
                        child: Card(
                          color: const Color(0xFF152349),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0), // Optional rounded corners
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/images/invoice.png',
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2.0), // Space between card and text
                  const Text(
                    'SPP',
                    style: TextStyle(fontSize: 12.0),
                  ),
                ],
              ),
            ],
          ),

        ),
        if (accessRole == "2")
          Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(
                Icons.warning, // Warning triangle icon
                color: Colors.orange, // Set the icon color to orange (typically used for warnings)
                size: 18.0, // Adjust the size if necessary
              ),
              SizedBox(width: 8.0), // Add space between icon and text
              Text(
                'Menu Admin & Guru',
                textAlign: TextAlign.left, // Align text to the left
                style: TextStyle(
                  fontWeight: FontWeight.bold, // Make the text bold
                  fontSize: 14.0, // Optional: Adjust the font size if needed
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (accessRole == "2")
                Column(
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => StudentListPage())
                            );
                          },
                          borderRadius: BorderRadius.circular(16.0), // Matches Card's border radius
                          child: Card(
                            color: const Color(0xFF152349),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0), // Optional rounded corners
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/images/students.png',
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2.0), // Space between card and text
                    const Text(
                      'Daftar Siswa',
                      style: TextStyle(fontSize: 10.0),
                    ),
                  ],
                ),
              if (accessRole == "2") // Only show if accessRole == 2
                Column(
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => MakeSchedulePage())
                            );
                          },
                          borderRadius: BorderRadius.circular(16.0), // Matches Card's border radius
                          child: Card(
                            color: const Color(0xFF152349),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0), // Optional rounded corners
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/images/task-planning.png',
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2.0), // Space between card and text
                    const Text(
                      'Buat Jadwal',
                      style: TextStyle(fontSize: 10.0),
                    ),
                  ],
                ),
              if (accessRole == "2") // Only show if accessRole == 2
                Column(
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => BranchPage())
                            );
                          },
                          borderRadius: BorderRadius.circular(16.0), // Matches Card's border radius
                          child: Card(
                            color: const Color(0xFF152349),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0), // Optional rounded corners
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/images/branch.png',
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2.0), // Space between card and text
                    const Text(
                      'Sanggar',
                      style: TextStyle(fontSize: 10.0),
                    ),
                  ],
                ),
              if (accessRole == "2") // Only show if accessRole == 2
                Column(
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ClassRoomPage())
                            );
                          },
                          borderRadius: BorderRadius.circular(16.0), // Matches Card's border radius
                          child: Card(
                            color: const Color(0xFF152349),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0), // Optional rounded corners
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/images/wayang.png',
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2.0), // Space between card and text
                    const Text(
                      'Kelas',
                      style: TextStyle(fontSize: 10.0),
                    ),
                  ],
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (accessRole == "2")
                Column(
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => CreateAdminPage())
                            );
                          },
                          borderRadius: BorderRadius.circular(16.0), // Matches Card's border radius
                          child: Card(
                            color: const Color(0xFF152349),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0), // Optional rounded corners
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/images/working.png',
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2.0), // Space between card and text
                    const Text(
                      'Buat Admin',
                      style: TextStyle(fontSize: 10.0),
                    ),
                  ],
                ),
              if (accessRole == "2")
                Column(
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => SPPPaymentsPage())
                            );
                          },
                          borderRadius: BorderRadius.circular(16.0), // Matches Card's border radius
                          child: Card(
                            color: const Color(0xFF152349),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0), // Optional rounded corners
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/images/invoice.png',
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2.0), // Space between card and text
                    const Text(
                      'Catat SPP',
                      style: TextStyle(fontSize: 10.0),
                    ),
                  ],
                ),
              if (accessRole == "2")
                Column(
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            // Navigator.push(
                            //     context,
                            //     MaterialPageRoute(builder: (context) => SPPPaymentsPage())
                            // );
                          },
                          borderRadius: BorderRadius.circular(16.0), // Matches Card's border radius
                          child: Card(
                            color: const Color(0xFF152349),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0), // Optional rounded corners
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/images/score.png',
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2.0), // Space between card and text
                    const Text(
                      'Input Nilai',
                      style: TextStyle(fontSize: 10.0),
                    ),
                  ],
                ),
              if (accessRole == "2")
                Column(
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => MakeInformationPage())
                            );
                          },
                          borderRadius: BorderRadius.circular(16.0), // Matches Card's border radius
                          child: Card(
                            color: const Color(0xFF152349),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0), // Optional rounded corners
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/images/messages.png',
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2.0), // Space between card and text
                    const Text(
                      'Tambah Info',
                      style: TextStyle(fontSize: 10.0),
                    ),
                  ],
                ),
              if (accessRole == "2")
                Column(
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => BannerPage())
                            );
                          },
                          borderRadius: BorderRadius.circular(16.0), // Matches Card's border radius
                          child: Card(
                            color: const Color(0xFF152349),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0), // Optional rounded corners
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/images/advertising.png',
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2.0), // Space between card and text
                    const Text(
                      'Banner',
                      style: TextStyle(fontSize: 10.0),
                    ),
                  ],
                ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info, // Info circle icon
                        color: Colors.green, // Set the icon color to green (hijab color)
                        size: 18.0, // Adjust the size if necessary
                      ),
                      SizedBox(width: 8.0), // Add space between icon and text
                      Text(
                        'Informasi Terbaru',
                        textAlign: TextAlign.left, // Align text to the left
                        style: TextStyle(
                          fontWeight: FontWeight.bold, // Make the text bold
                          fontSize: 14.0, // Optional: Adjust the font size if needed
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AllNotification()),
                      );
                    },
                    child: Text(
                      'Semua informasi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.0,
                        color: Colors.blue, // Tambahkan warna agar terlihat sebagai link
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.0),
              Column(
                children: info.isNotEmpty
                    ? info.map((item) {
                  return GestureDetector(
                    onTap: () => _showDetailDialog(
                      item["title"] ?? "Tanpa Judul",
                      item["description"] ?? "Tanpa Deskripsi",
                    ),
                    child: Container(
                      width: double.infinity,
                      child: Card(
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.circle_notifications_outlined, color: Colors.blueAccent),

                              SizedBox(width: 10.0), // Beri jarak antara ikon dan teks

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Judul informasi (dibatasi agar tidak terlalu panjang)
                                        Expanded(
                                          child: Text(
                                            item["title"] ?? "Tanpa Judul",
                                            style: TextStyle(
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blueAccent,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis, // Tambahkan ellipsis jika teks terlalu panjang
                                          ),
                                        ),

                                        SizedBox(width: 8.0), // Beri jarak sebelum waktu

                                        // Waktu (diletakkan di pojok kanan)
                                        Row(
                                          children: [
                                            Icon(Icons.access_time, size: 14.0, color: Colors.grey),
                                            SizedBox(width: 4.0),
                                            Text(
                                              item["created_at"] ?? "-",
                                              style: TextStyle(
                                                fontSize: 12.0,
                                                fontStyle: FontStyle.italic,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 6.0),

                                    // Deskripsi singkat (dibatasi maksimal 50 karakter)
                                    Text(
                                      item["thumbnail"] != null && item["thumbnail"].length > 50
                                          ? "${item["thumbnail"].substring(0, 50)}..."
                                          : item["thumbnail"] ?? "Tanpa Deskripsi",
                                      style: TextStyle(fontSize: 14.0, color: Colors.black87),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis, // Tambahkan ellipsis jika teks terlalu panjang
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList()
                    : [
                  // Jika Tidak Ada Informasi
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Card(
                      elevation: 3.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange, size: 24.0),
                            SizedBox(width: 8.0),
                            Expanded(
                              child: Text(
                                'Tidak ada informasi terbaru',
                                style: TextStyle(fontSize: 14.0, fontStyle: FontStyle.italic, color: Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8,),
            ],
          ),
        ),
      ],
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
      child: Column(
        children: List.generate(attendanceData.length, (index) {
          var attendance = attendanceData[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  attendance['photo'] != null && attendance['photo'].isNotEmpty
                      ? Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      image: DecorationImage(
                        image: MemoryImage(
                          const Base64Decoder().convert(attendance['photo']),
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                      : CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey.shade300,
                    child: Icon(Icons.person, size: 30, color: Colors.grey.shade700),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                              decoration: BoxDecoration(
                                color: attendance['status'] == 'Absen'
                                    ? Colors.green
                                    : attendance['status'] == 'Ijin'
                                    ? Colors.orange
                                    : Colors.red, // Warna berdasarkan tipe
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "${attendance['status']}", // Tampilkan tipe kehadiran
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.red),
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
                            color: Colors.black87,
                            fontWeight: FontWeight.bold
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
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'absen':
        return Colors.green;
      case 'sakit':
        return Colors.yellow;
      case 'ijin':
        return Colors.red;
      default:
        return Colors.black54;
    }
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
