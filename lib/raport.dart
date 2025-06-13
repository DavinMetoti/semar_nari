import 'package:flutter/material.dart';
import 'home.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RaportPage extends StatefulWidget {
  @override
  State<RaportPage> createState() => _RaportPageState();
}

class _RaportPageState extends State<RaportPage> with SingleTickerProviderStateMixin {
  late String selectedTahunAjaran;
  late List<String> tahunAjaranList;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  bool _isLoading = false;
  bool _hasFetched = false;
  String? _errorMsg;
  Map<String, dynamic>? _attendanceReport;
  Map<String, dynamic>? _semesterExams;
  Map<String, dynamic>? _finalSemesterExams;

  String? displayedTahunAjaran;

  @override
  void initState() {
    super.initState();
    tahunAjaranList = _generateTahunAjaranList();
    selectedTahunAjaran = tahunAjaranList.last;
    displayedTahunAjaran = selectedTahunAjaran;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  List<String> _generateTahunAjaranList() {
    int startYear = 2022;
    int currentYear = DateTime.now().year;
    int endYear = currentYear + 1;
    List<String> list = [];
    for (int y = startYear; y < endYear; y++) {
      list.add('$y/${y + 1}');
    }
    return list;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String?> _getAccountId() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    if (username == null) return null;
    final response = await http.post(
      Uri.parse('https://semarnari.sportballnesia.com/api/master/user/get'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username}),
    );
    final Map<String, dynamic> responseBody = jsonDecode(response.body);
    if (responseBody['data'] != null && responseBody['data'].isNotEmpty) {
      final userData = responseBody['data'];
      return userData['id']?.toString();
    }
    return null;
  }

  Future<void> _fetchRaport() async {
    setState(() {
      _isLoading = true;
      _hasFetched = true;
      _errorMsg = null;
      _attendanceReport = null;
      _semesterExams = null;
      _finalSemesterExams = null;
    });

    try {
      final accountId = await _getAccountId();
      if (accountId == null) {
        setState(() {
          _errorMsg = 'Gagal mengambil akun pengguna.';
          _isLoading = false;
        });
        return;
      }

      final headers = {'Content-Type': 'application/json'};

      // Tahun ajaran format: "2022-2023"
      String tahunAjaran = (selectedTahunAjaran).replaceAll('/', '-');

      final attendanceResp = await http.post(
        Uri.parse('https://semarnari.sportballnesia.com/api/master/user/get_attendance_report'),
        headers: headers,
        body: json.encode({"account_id": accountId, "tahun_ajaran": tahunAjaran}),
      );

      final semesterResp = await http.post(
        Uri.parse('https://semarnari.sportballnesia.com/api/master/user/get_semester_exams'),
        headers: headers,
        body: json.encode({"account_id": accountId, "tahun_ajaran": tahunAjaran}),
      );

      final finalSemesterResp = await http.post(
        Uri.parse('https://semarnari.sportballnesia.com/api/master/user/get_final_semester_exams'),
        headers: headers,
        body: json.encode({"account_id": accountId, "tahun_ajaran": tahunAjaran}),
      );

      setState(() {
        _attendanceReport = jsonDecode(attendanceResp.body);
        _semesterExams = jsonDecode(semesterResp.body);
        _finalSemesterExams = jsonDecode(finalSemesterResp.body);
        _isLoading = false;
        displayedTahunAjaran = selectedTahunAjaran;
      });
    } catch (e) {
      setState(() {
        _errorMsg = 'Terjadi kesalahan saat mengambil data.';
        _isLoading = false;
      });
    }
  }

  Widget _buildSectionTable({
    required String title,
    required IconData icon,
    required Color color,
    required dynamic data,
    required String emptyMessage,
    Map<String, dynamic>? rawResponse,
    bool isSkeleton = false,
  }) {
    if (isSkeleton) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              radius: 22,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 60,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (rawResponse != null && rawResponse['status'] == false) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 22),
              radius: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                rawResponse['message'] ?? emptyMessage,
                style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      );
    }

    if (data == null || data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 22),
              radius: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                emptyMessage,
                style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      );
    }

    List<TableRow> rows = [];
    rows.add(
      TableRow(
        decoration: BoxDecoration(color: color.withOpacity(0.08)),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Text('Target', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Text('Realisasi', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Text('Persen', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Text('Nilai', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Text('Grade', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    for (var item in data) {
      rows.add(TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Text(item['target'] ?? '-', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Text(item['reality'] ?? '-', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Text(item['percentage'] ?? '-', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Text(item['value'] ?? '-', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: item['degree'] != null
                ? Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item['degree'],
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : Text('-'),
          ),
        ],
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 22),
                radius: 22,
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: 600),
              child: Table(
                columnWidths: const {
                  0: FixedColumnWidth(120),
                  1: FixedColumnWidth(120),
                  2: FixedColumnWidth(120),
                  3: FixedColumnWidth(120),
                  4: FixedColumnWidth(120),
                },
                border: TableBorder.symmetric(
                  inside: BorderSide(color: Colors.grey.shade200),
                ),
                children: rows,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    if (_isLoading) {
      return Column(
        children: [
          _buildSectionTable(
            title: "Absensi",
            icon: Icons.event_available_rounded,
            color: Colors.blue,
            data: null,
            emptyMessage: "",
            isSkeleton: true,
          ),
          _buildSectionTable(
            title: "Ujian Semester",
            icon: Icons.assignment_turned_in_rounded,
            color: Colors.orange,
            data: null,
            emptyMessage: "",
            isSkeleton: true,
          ),
          _buildSectionTable(
            title: "Ujian Akhir Semester",
            icon: Icons.grade_rounded,
            color: Colors.green,
            data: null,
            emptyMessage: "",
            isSkeleton: true,
          ),
        ],
      );
    }
    if (_errorMsg != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Text(
          _errorMsg!,
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      );
    }

    final attendanceData = _attendanceReport?['data'];
    final semesterData = _semesterExams?['data'];
    final finalSemesterData = _finalSemesterExams?['data'];

    final bool isEmptyData =
        (attendanceData == null || attendanceData.isEmpty) &&
        (semesterData == null || semesterData.isEmpty) &&
        (finalSemesterData == null || finalSemesterData.isEmpty);

    if (!_hasFetched) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Column(
          children: [
            Icon(Icons.filter_alt_rounded, size: 48, color: Color(0xFF3B5998)),
            const SizedBox(height: 16),
            Text(
              "Gunakan filter tahun ajaran,\nlalu tekan tombol 'Lihat Raport'.",
              style: TextStyle(
                color: Color(0xFF152349),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_attendanceReport == null && _semesterExams == null && _finalSemesterExams == null || isEmptyData) {
      return Column(
        children: [
          Image.asset(
            'assets/images/sorry.png',
            width: 120,
            color: Colors.grey[400],
            colorBlendMode: BlendMode.modulate,
          ),
          const SizedBox(height: 18),
          Text(
            'Belum ada data raport untuk tahun ini.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF152349),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Silakan cek kembali di lain waktu.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildSectionTable(
          title: "Absensi",
          icon: Icons.event_available_rounded,
          color: Colors.blue,
          data: attendanceData,
          emptyMessage: "Tidak ada data absensi.",
          rawResponse: _attendanceReport,
        ),
        _buildSectionTable(
          title: "Ujian Semester",
          icon: Icons.assignment_turned_in_rounded,
          color: Colors.orange,
          data: semesterData,
          emptyMessage: "Tidak ada data ujian semester.",
          rawResponse: _semesterExams,
        ),
        _buildSectionTable(
          title: "Ujian Akhir Semester",
          icon: Icons.grade_rounded,
          color: Colors.green,
          data: finalSemesterData,
          emptyMessage: "Tidak ada data ujian akhir semester.",
          rawResponse: _finalSemesterExams,
        ),
      ],
    );
  }

  String _getTahunAjaranLabel() {
    return displayedTahunAjaran ?? selectedTahunAjaran;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF152349),
        automaticallyImplyLeading: false,
        elevation: 0,
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
            IconButton(
              icon: const Icon(
                Icons.home,
                size: 30.0,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
            ),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter tahun ajaran dan tombol lihat raport sejajar
                Row(
                  children: [
                    // Dropdown Tahun Ajaran
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF152349), Color(0xFF3B5998)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedTahunAjaran,
                            borderRadius: BorderRadius.circular(16),
                            dropdownColor: Color(0xFF3B5998),
                            icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            items: tahunAjaranList
                                .map((tahun) => DropdownMenuItem(
                                      value: tahun,
                                      child: Text(
                                        tahun.split('/').first, // tampilkan hanya tahun awal
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedTahunAjaran = value;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Button Lihat Raport
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          label: Text(
                            'Lihat Raport',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF3B5998),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            shadowColor: Color(0xFF152349).withOpacity(0.2),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            foregroundColor: Colors.white,
                            textStyle: TextStyle(color: Colors.white),
                          ),
                          onPressed: _isLoading ? null : _fetchRaport,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Header tahun ajaran atau keterangan filter
                if (!_hasFetched)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(
                      child: Text(
                        "Gunakan filter tahun ajaran,\nlalu tekan tombol 'Lihat Raport'.",
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else ...[
                  Center(
                    child: Card(
                      elevation: 12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      shadowColor: Color(0xFF3B5998).withOpacity(0.25),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          gradient: LinearGradient(
                            colors: [Color(0xFF3B5998), Color(0xFF152349)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 16,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 36,
                                  backgroundColor: Colors.white,
                                  child: Icon(Icons.school, color: Color(0xFF3B5998), size: 40),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Laporan Nilai',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tahun Ajaran',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white70,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _getTahunAjaranLabel(),
                                  style: TextStyle(
                                    color: Color(0xFF3B5998),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                                child: _buildResult(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                (!_hasFetched) ? SizedBox.shrink() : SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
