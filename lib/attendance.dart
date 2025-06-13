import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'package:semarnari_apk/services/apiServices.dart';
import 'home.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http; // tambahkan import ini
import 'package:skeletonizer/skeletonizer.dart'; // tambahkan import skeletonizer

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final ApiService apiService = ApiService();
  final List<String> months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  List<ChartData> attendanceData = [];
  bool isLoading = false;
  Map<String, dynamic> userData = {};
  int totalAttendance = 0;
  int hadir = 0, ijin = 0, sakit = 0, alpa = 0;
  String selectedMonth = '';
  String? errorMessage;
  String selectedMonthRange = '';
  int rangeStart = DateTime.now().month;
  int rangeEnd = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    selectedMonth = months[DateTime.now().month - 1];
    rangeStart = DateTime.now().month;
    rangeEnd = DateTime.now().month;
    selectedMonthRange = '$rangeStart-$rangeEnd';
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');

      if (username == null || username.isEmpty) {
        _redirectToLogin();
        return;
      }

      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      await Future.delayed(const Duration(milliseconds: 500)); // Simulate loading

      final response = await apiService.post('user/get', {'username': username});
      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (responseBody['data'] != null && responseBody['data'].isNotEmpty) {
        final data = responseBody['data'];
        setState(() {
          userData = {
            'user_id': data['id'] ?? '',
            'username': data['username'] ?? 'Guest',
            'email': data['email'] ?? 'No email',
            'fullName': data['fullname'] ?? 'No name',
            'branch_name': data['branch_name'] ?? 'No Branch'
          };
        });
        await _loadAttendanceUser();
      } else {
        setState(() {
          errorMessage = responseBody['message'] ?? 'Failed to load user data';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching data: $e';
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _redirectToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Future<int> _getTotalScheduleFromApi(String username, String monthRange) async {
    final response = await http.get(
      Uri.parse('https://semarnari.sportballnesia.com/api/master/data/all_schedule?username=$username&month=$monthRange'),
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['data'] is List) {
        return (body['data'] as List).length;
      }
    }
    return 0;
  }

  Future<void> _loadAttendanceUser() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final _username = userData['username'] ?? '';
      final monthRange = '$rangeStart-$rangeEnd';

      // 1. Get total schedule dari endpoint baru
      final totalSchedule = await _getTotalScheduleFromApi(_username, monthRange);

      // 2. Get attendance history
      final historyResponse = await apiService.post(
        'user/get_attendance_history',
        {
          "user_id": userData['user_id'],
          "month": monthRange,
        },
      );

      final historyBody = jsonDecode(historyResponse.body);

      List filteredData = [];
      if (historyResponse.statusCode == 200 && historyBody['status'] == true && historyBody['data'] != null) {
        final allData = historyBody['data'] as List;
        filteredData = allData.where((entry) {
          if (entry['attendance_date'] == null) return false;
          try {
            final entryDate = DateFormat('yyyy-MM-dd').parse(entry['attendance_date']);
            return entryDate.month >= rangeStart && entryDate.month <= rangeEnd;
          } catch (e) {
            return false;
          }
        }).toList();
      }

      // Count attendance statuses
      int h = 0, i = 0, s = 0;
      for (var entry in filteredData) {
        switch (entry['status']) {
          case 'Absen': h++; break;
          case 'Ijin': i++; break;
          case 'Sakit': s++; break;
        }
      }

      // Calculate alpa (absence without permission)
      final a = totalSchedule - filteredData.length;

      setState(() {
        totalAttendance = totalSchedule;
        hadir = h;
        ijin = i;
        sakit = s;
        alpa = a;

        attendanceData = totalSchedule > 0
            ? [
                ChartData('Hadir', h, Colors.blue),
                ChartData('Ijin', i, Colors.orange),
                ChartData('Sakit', s, Colors.yellow[700]!),
                ChartData('Alpa', a, Colors.redAccent),
              ]
            : [];
      });
    } catch (e) {
      setState(() {
        attendanceData = [];
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF152349),
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset('assets/images/logo.png', height: 30, width: 30),
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
            IconButton(
              icon: const Icon(Icons.home, size: 30.0, color: Colors.white),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      // Skeleton loading
      return Skeletonizer(
        enabled: true,
        child: ListView(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: const Color(0xFF152349),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Colors.blue, size: 36),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120,
                            height: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 80,
                            height: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 100,
                            height: 12,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Container(
                      width: 160,
                      height: 22,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            color: Colors.grey[300],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 48,
                            color: Colors.grey[300],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 140,
                      height: 18,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      height: 180,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 100,
                      height: 18,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    // Legend skeleton
                    Column(
                      children: List.generate(4, (i) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Card(
                            elevation: 3,
                            color: Colors.grey[100],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Colors.white,
                                    radius: 20,
                                  ),
                                  const SizedBox(width: 14),
                                  Container(
                                    width: 60,
                                    height: 16,
                                    color: Colors.grey[300],
                                  ),
                                  const Spacer(),
                                  Container(
                                    width: 40,
                                    height: 14,
                                    color: Colors.grey[300],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: const Color(0xFF152349),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Colors.blue[900], size: 36),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData['fullName'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        userData['branch_name'] ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        userData['email'] ?? '',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Text(
                  'Statistik Kehadiran',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF152349)),
                ),
                const SizedBox(height: 16),
                _buildMonthRangePicker(),
                const SizedBox(height: 16),
                Text(
                  'Maksimal Kehadiran: $totalAttendance',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                _buildChartSection(),
                const SizedBox(height: 16),
                const Text(
                  'Keterangan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF152349)),
                ),
                const SizedBox(height: 16),
                _buildLegendSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthRangePicker() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            value: rangeStart,
            decoration: InputDecoration(
              labelText: "Bulan Mulai",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: List.generate(months.length, (i) {
              return DropdownMenuItem(
                value: i + 1,
                child: Text(months[i]),
              );
            }),
            onChanged: (val) {
              if (val != null && val <= rangeEnd) {
                setState(() {
                  rangeStart = val;
                  selectedMonthRange = '$rangeStart-$rangeEnd';
                });
                _loadAttendanceUser();
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<int>(
            value: rangeEnd,
            decoration: InputDecoration(
              labelText: "Bulan Akhir",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: List.generate(months.length, (i) {
              return DropdownMenuItem(
                value: i + 1,
                child: Text(months[i]),
              );
            }),
            onChanged: (val) {
              if (val != null && val >= rangeStart) {
                setState(() {
                  rangeEnd = val;
                  selectedMonthRange = '$rangeStart-$rangeEnd';
                });
                _loadAttendanceUser();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection() {
    if (attendanceData.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_chart_outlined, color: Colors.grey[400], size: 80.0),
          const SizedBox(height: 16),
          const Text(
            'Belum ada presensi pada rentang bulan ini',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Lakukan presensi agar data dapat terlihat',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      );
    }

    return SizedBox(
      height: 300,
      child: SfCircularChart(
        legend: Legend(
          isVisible: true,
          position: LegendPosition.bottom,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
        series: <PieSeries<ChartData, String>>[
          PieSeries<ChartData, String>(
            dataSource: attendanceData,
            xValueMapper: (ChartData data, _) => data.category,
            yValueMapper: (ChartData data, _) => data.value,
            pointColorMapper: (ChartData data, _) => data.color,
            dataLabelMapper: (ChartData data, _) =>
                '${data.category}: ${data.value}',
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              textStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            explode: true,
            explodeIndex: 0,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendSection() {
    if (attendanceData.isEmpty) {
      return const Center(
        child: Icon(
          Icons.sentiment_dissatisfied,
          color: Colors.orangeAccent,
          size: 60.0,
        ),
      );
    }

    IconData getIcon(String category) {
      switch (category) {
        case 'Hadir':
          return Icons.check_circle_outline;
        case 'Ijin':
          return Icons.assignment_turned_in_outlined;
        case 'Sakit':
          return Icons.local_hospital_outlined;
        case 'Alpa':
          return Icons.cancel_outlined;
        default:
          return Icons.circle;
      }
    }

    Color getIconColor(String category) {
      switch (category) {
        case 'Hadir':
          return Colors.green[700]!;
        case 'Ijin':
          return Colors.blue[800]!;
        case 'Sakit':
          return Colors.orange[800]!;
        case 'Alpa':
          return Colors.red[700]!;
        default:
          return Colors.grey[700]!;
      }
    }

    Color getCardColor(String category) {
      switch (category) {
        case 'Hadir':
          return Colors.green[50]!;
        case 'Ijin':
          return Colors.blue[50]!;
        case 'Sakit':
          return Colors.orange[50]!;
        case 'Alpa':
          return Colors.red[50]!;
        default:
          return Colors.grey[100]!;
      }
    }

    return Column(
      children: attendanceData.map((data) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Card(
            elevation: 3,
            color: getCardColor(data.category),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 20,
                    child: Icon(
                      getIcon(data.category),
                      color: getIconColor(data.category),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      data.category,
                      style: TextStyle(
                        color: getIconColor(data.category),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    totalAttendance > 0
                        ? '${data.value} (${(data.value / totalAttendance * 100).toStringAsFixed(0)}%)'
                        : '${data.value}',
                    style: TextStyle(
                      color: Colors.grey[900],
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class ChartData {
  final String category;
  final int value;
  final Color color;

  ChartData(this.category, this.value, this.color);
}
