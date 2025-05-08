import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home.dart'; // Make sure to import your HomePage

class HistoryStudentPage extends StatefulWidget {
  final String studentId;
  final String studentName;

  const HistoryStudentPage({
    Key? key,
    required this.studentId,
    required this.studentName,
  }) : super(key: key);

  @override
  _HistoryStudentPageState createState() => _HistoryStudentPageState();
}

class _HistoryStudentPageState extends State<HistoryStudentPage> {
  List<dynamic> attendanceHistory = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      _fetchAttendanceHistory();
    });
  }

  Future<void> _fetchAttendanceHistory() async {
    try {
      final response = await http.post(
        Uri.parse('https://semarnari.sportballnesia.com/api/master/user/get_attendance_history'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': widget.studentId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          setState(() {
            attendanceHistory = data['data'];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Gagal memuat riwayat presensi';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Gagal memuat data (${response.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
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
            const Icon(
              Icons.calendar_today,
              size: 30.0,
              color: Colors.white,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Riwayat Presensi:  ${widget.studentName}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage.isNotEmpty
                  ? Center(child: Text(errorMessage))
                  : attendanceHistory.isEmpty
                  ? const Center(child: Text('Tidak ada data presensi'))
                  : ListView.builder(
                itemCount: attendanceHistory.length,
                itemBuilder: (context, index) {
                  final record = attendanceHistory[index];
                  return _buildAttendanceCard(record);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context),
        backgroundColor: const Color(0xFF152349),
        child: const Icon(Icons.arrow_back, color: Colors.white),
      ),
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> record) {
    final date = DateTime.tryParse(record['attendance_date'] ?? '') ?? DateTime.now();
    final formattedDate = DateFormat('EEEE, d MMMM y', 'id_ID').format(date);
    final checkInTime = record['check_in_time'] ?? '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(record['status']),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    record['status'] ?? 'Tidak diketahui',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Jam Masuk', checkInTime),
            if (record['location'] != null && record['location'].toString().isNotEmpty)
              _buildDetailRow('Lokasi', record['location']),
            if (record['remarks'] != null && record['remarks'].toString().isNotEmpty)
              _buildDetailRow('Keterangan', record['remarks']),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Absen':
        return Colors.green;
      case 'Ijin':
        return Colors.orange;
      case 'Sakit':
        return Colors.blue;
      case 'Alpa':
        return Colors.red;
      case 'Terlambat':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}