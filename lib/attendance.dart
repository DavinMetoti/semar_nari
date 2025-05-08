import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'package:semarnari_apk/services/apiServices.dart';
import 'home.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    selectedMonth = months[DateTime.now().month - 1];
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

  Future<void> _loadAttendanceUser() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final selectedMonthIndex = months.indexOf(selectedMonth) + 1;

      // 1. Get total schedule
      final totalResponse = await apiService.post(
        'user/get_total_most_present',
        {
          "user_id": userData['user_id'],
          "month": selectedMonthIndex,
        },
      );

      final totalBody = jsonDecode(totalResponse.body);
      final totalSchedule = (totalBody['status'] == true && totalBody['data'] is List)
          ? (totalBody['data'] as List).length
          : 0;

      // 2. Get attendance history
      final historyResponse = await apiService.post(
        'user/get_attendance_history',
        {"user_id": userData['user_id']},
      );

      final historyBody = jsonDecode(historyResponse.body);

      if (historyResponse.statusCode != 200 || historyBody['status'] != true) {
        throw Exception('Failed to load attendance history');
      }

      final allData = historyBody['data'] as List;
      final filteredData = allData.where((entry) {
        if (entry['attendance_date'] == null) return false;
        try {
          final entryDate = DateFormat('yyyy-MM-dd').parse(entry['attendance_date']);
          return entryDate.month == selectedMonthIndex;
        } catch (e) {
          return false;
        }
      }).toList();

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
          ChartData('Sakit', s, Colors.yellow),
          ChartData('Alpa', a, Colors.grey),
        ]
            : [];
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading attendance: $e';
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
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Text(
          errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    return ListView(
      children: [
        const Text(
          'Statistik Kehadiran',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        _buildMonthDropdown(),
        const SizedBox(height: 16),
        Text(
          'Maksimal Kehadiran: $totalAttendance',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        _buildChartSection(),
        const SizedBox(height: 16),
        const Text(
          'Keterangan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        _buildLegendSection(),
      ],
    );
  }

  Widget _buildMonthDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedMonth,
          icon: const Icon(Icons.arrow_drop_down),
          items: months.map((String month) {
            return DropdownMenuItem<String>(
              value: month,
              child: Text(month),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() => selectedMonth = newValue);
              _loadAttendanceUser();
            }
          },
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    if (attendanceData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48.0),
            SizedBox(height: 16),
            Text(
              'Belum ada presensi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Lakukan presensi agar data dapat terlihat',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: SfCartesianChart(
        primaryXAxis: CategoryAxis(),
        series: <BarSeries<ChartData, String>>[
          BarSeries<ChartData, String>(
            dataSource: attendanceData,
            xValueMapper: (ChartData data, _) => data.category,
            yValueMapper: (ChartData data, _) => data.value.toDouble(),
            pointColorMapper: (ChartData data, _) => data.color,
          ),
        ],
        annotations: <CartesianChartAnnotation>[
          CartesianChartAnnotation(
            coordinateUnit: CoordinateUnit.point,
            x: 'Hadir',
            y: hadir.toDouble(),
            widget: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              ],
            ),
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

    return Column(
      children: attendanceData.map((data) {
        return Card(
          color: data.color,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${data.category}: ${(data.value / totalAttendance * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
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