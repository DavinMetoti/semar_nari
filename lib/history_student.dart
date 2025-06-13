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
  List<dynamic> filteredHistory = [];
  bool isLoading = true;
  String errorMessage = '';

  DateTime? startMonth;
  DateTime? endMonth;

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
          // Filter duplicate dates, prioritize 'Absen', else pick the first
          final Map<String, Map<String, dynamic>> uniqueByDate = {};
          for (var record in data['data']) {
            final date = record['attendance_date'];
            if (!uniqueByDate.containsKey(date)) {
              uniqueByDate[date] = record;
            } else {
              // Prioritize 'Absen'
              if (record['status'] == 'Absen') {
                uniqueByDate[date] = record;
              }
            }
          }
          setState(() {
            attendanceHistory = uniqueByDate.values.toList();
            _applyFilter();
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

  void _applyFilter() {
    if (startMonth == null && endMonth == null) {
      filteredHistory = List.from(attendanceHistory);
    } else {
      filteredHistory = attendanceHistory.where((record) {
        final date = DateTime.tryParse(record['attendance_date'] ?? '');
        if (date == null) return false;
        final start = startMonth ?? DateTime(2000);
        final end = endMonth != null
            ? DateTime(endMonth!.year, endMonth!.month + 1, 0)
            : DateTime(2100);
        return date.isAfter(start.subtract(const Duration(days: 1))) &&
            date.isBefore(end.add(const Duration(days: 1)));
      }).toList();
    }
    setState(() {});
  }

  Future<void> _selectMonth(BuildContext context, bool isStart) async {
    final now = DateTime.now();
    final initialDate = isStart
        ? (startMonth ?? now)
        : (endMonth ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12),
      locale: const Locale('id', 'ID'),
      helpText: isStart ? 'Pilih Bulan Mulai' : 'Pilih Bulan Selesai',
      fieldLabelText: 'Bulan/Tahun',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF152349),
              onPrimary: Colors.white,
              onSurface: Color(0xFF152349),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startMonth = DateTime(picked.year, picked.month);
        } else {
          endMonth = DateTime(picked.year, picked.month);
        }
        _applyFilter();
      });
    }
  }

  void _resetFilter() {
    setState(() {
      startMonth = null;
      endMonth = null;
      _applyFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Cegah error MaterialLocalizations jika halaman ini diakses langsung
    return Localizations(
      locale: const Locale('id', 'ID'),
      delegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      child: Builder(
        builder: (context) => Scaffold(
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
                            letterSpacing: 1.2,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        Text(
                          'Sanggar Tari Kota Semarang',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontFamily: 'Montserrat',
                            letterSpacing: 0.5,
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
                // Modern, elegant student name card
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFb6d0f7), Color(0xFFe3f0fc)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueGrey.withOpacity(0.10),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF398FE5), Color(0xFFB6E0FE)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: const Icon(Icons.person, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.studentName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF152349),
                                fontFamily: 'Montserrat',
                                letterSpacing: 0.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Riwayat Presensi',
                                style: TextStyle(
                                  color: Color(0xFF398FE5),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectMonth(context, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Row(
                            children: [
                              Text(
                                startMonth != null
                                    ? DateFormat('MMMM yyyy', 'id_ID').format(startMonth!)
                                    : 'Bulan Mulai',
                                style: TextStyle(
                                  color: Color(0xFF152349),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectMonth(context, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Row(
                            children: [
                              Text(
                                endMonth != null
                                    ? DateFormat('MMMM yyyy', 'id_ID').format(endMonth!)
                                    : 'Bulan Selesai',
                                style: TextStyle(
                                  color: Color(0xFF152349),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: "Reset Filter",
                      onPressed: _resetFilter,
                      icon: Icon(Icons.refresh, color: Color(0xFF152349)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.list_alt, color: Color(0xFF152349)),
                    const SizedBox(width: 6),
                    Text(
                      'Jumlah data: ${filteredHistory.length}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF152349),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : errorMessage.isNotEmpty
                      ? Center(child: Text(errorMessage))
                      : filteredHistory.isEmpty
                      ? const Center(child: Text('Tidak ada data presensi'))
                      : ListView.builder(
                    itemCount: filteredHistory.length,
                    itemBuilder: (context, index) {
                      final record = filteredHistory[index];
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
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> record) {
    final date = DateTime.tryParse(record['attendance_date'] ?? '') ?? DateTime.now();
    final formattedDate = DateFormat('EEEE, d MMMM y', 'id_ID').format(date);
    final checkInTime = record['check_in_time'] ?? '-';

    IconData statusIcon;
    Color statusColor;
    switch (record['status']) {
      case 'Absen':
        statusIcon = Icons.check_circle;
        statusColor = Color(0xFF2196F3);
        break;
      case 'Ijin':
        statusIcon = Icons.info_outline;
        statusColor = Color(0xFF00B8D4);
        break;
      case 'Sakit':
        statusIcon = Icons.local_hospital;
        statusColor = Color(0xFF1976D2);
        break;
      case 'Alpa':
        statusIcon = Icons.cancel;
        statusColor = Color(0xFFD32F2F);
        break;
      case 'Terlambat':
        statusIcon = Icons.access_time;
        statusColor = Color(0xFF8E24AA);
        break;
      default:
        statusIcon = Icons.help_outline;
        statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Color(0xFFe3f0fc), Color(0xFFb6d0f7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.10),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Icon(statusIcon, color: statusColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    formattedDate,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF152349),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: statusColor,
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
            const SizedBox(height: 14),
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
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF31416A)),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Color(0xFF31416A))),
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
