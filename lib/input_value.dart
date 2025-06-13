import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'home.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:month_year_picker/month_year_picker.dart';


class InputValuePage extends StatefulWidget {
  @override
  _InputValuePageState createState() => _InputValuePageState();
}

class _InputValuePageState extends State<InputValuePage> {
  List<dynamic> _branches = [];
  String? _selectedBranch;
  List<dynamic> _students = [];
  bool _isLoadingBranches = false;
  bool _isLoadingStudents = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _studentFilter = 'semua'; // new filter state
  Map<int, Map<String, dynamic>> _attendanceCache = {};
  Map<int, Map<String, dynamic>> _semesterScoreCache = {};
  Map<int, Map<String, dynamic>> _finalSemesterScoreCache = {};
  bool _isRefreshing = false;
  String _exportType = 'absensi'; // default export type
  String? _selectedTahunAjaran;
  List<String> _tahunAjaranList = [];

  @override
  void initState() {
    super.initState();
    fetchBranches();
    _tahunAjaranList = _generateTahunAjaranList();
    _selectedTahunAjaran = _tahunAjaranList.last;
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

  Future<void> fetchBranches() async {
    setState(() {
      _isLoadingBranches = true;
      _errorMessage = null;
    });
    try {
      final response = await http.get(
        Uri.parse('https://semarnari.sportballnesia.com/api/master/data/get_all_branch'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _branches = data['data'] ?? [];
        });
      } else {
        setState(() {
          _branches = [];
          _errorMessage = 'Failed to fetch branches: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _branches = [];
        _errorMessage = 'Error: $e';
      });
    }
    setState(() {
      _isLoadingBranches = false;
    });
  }

  Future<void> fetchStudents(String branchId) async {
    setState(() {
      _isLoadingStudents = true;
      _errorMessage = null;
    });
    try {
      final response = await http.post(
        Uri.parse('https://semarnari.sportballnesia.com/api/master/user/get_all_student'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'branch': branchId}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _students = data['data'] ?? [];
        });
        await _fetchAllReports();
      } else {
        setState(() {
          _students = [];
          _errorMessage = 'Failed to fetch students: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _students = [];
        _errorMessage = 'Error: $e';
      });
    }
    setState(() {
      _isLoadingStudents = false;
    });
  }

  Future<void> _fetchAllReports() async {
    if (_students.isEmpty) return;
    setState(() {
      _isRefreshing = true;
    });
    final tahunAjaran = _selectedTahunAjaran ?? _tahunAjaranList.last;
    Map<int, Map<String, dynamic>> tempAttendance = {};
    Map<int, Map<String, dynamic>> tempSemester = {};
    Map<int, Map<String, dynamic>> tempFinalSemester = {};
    for (var student in _students) {
      final dynamic rawId = student['id'];
      final int? accountId = rawId is int
          ? rawId
          : (rawId is String ? int.tryParse(rawId) : null);
      if (accountId == null) continue;
      // Fetch attendance only if not in cache
      if (!_attendanceCache.containsKey(accountId)) {
        try {
          final response = await http.post(
            Uri.parse('https://semarnari.sportballnesia.com/api/master/user/get_attendance_report'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode({
              "account_id": accountId,
              "tahun_ajaran": tahunAjaran,
            }),
          );
          if (response.statusCode == 200) {
            final resp = json.decode(response.body);
            if (resp is Map && resp['data'] != null && resp['data'] is List && resp['data'].isNotEmpty) {
              tempAttendance[accountId] = Map<String, dynamic>.from(resp['data'][0]);
            }
          }
        } catch (_) {}
      } else {
        tempAttendance[accountId] = _attendanceCache[accountId]!;
      }
      // Fetch semester score only if not in cache
      if (!_semesterScoreCache.containsKey(accountId)) {
        try {
          final response = await http.post(
            Uri.parse('https://semarnari.sportballnesia.com/api/master/user/get_semester_exams'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode({
              "account_id": accountId,
              "tahun_ajaran": tahunAjaran,
            }),
          );
          if (response.statusCode == 200) {
            final resp = json.decode(response.body);
            if (resp is Map && resp['data'] != null && resp['data'] is List && resp['data'].isNotEmpty) {
              tempSemester[accountId] = Map<String, dynamic>.from(resp['data'][0]);
            }
          }
        } catch (_) {}
      } else {
        tempSemester[accountId] = _semesterScoreCache[accountId]!;
      }
      // Fetch final semester score only if not in cache
      if (!_finalSemesterScoreCache.containsKey(accountId)) {
        try {
          final response = await http.post(
            Uri.parse('https://semarnari.sportballnesia.com/api/master/user/get_final_semester_exams'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode({
              "account_id": accountId,
              "tahun_ajaran": tahunAjaran,
            }),
          );
          if (response.statusCode == 200) {
            final resp = json.decode(response.body);
            if (resp is Map && resp['data'] != null && resp['data'] is List && resp['data'].isNotEmpty) {
              tempFinalSemester[accountId] = Map<String, dynamic>.from(resp['data'][0]);
            }
          }
        } catch (_) {}
      } else {
        tempFinalSemester[accountId] = _finalSemesterScoreCache[accountId]!;
      }
    }
    setState(() {
      _attendanceCache = tempAttendance;
      _semesterScoreCache = tempSemester;
      _finalSemesterScoreCache = tempFinalSemester;
      _isRefreshing = false;
    });
  }

  Future<bool> _checkAttendanceReport(int? accountId, {Map<String, dynamic>? autofill}) async {
    if (accountId != null && _attendanceCache.containsKey(accountId)) {
      if (autofill != null) {
        autofill.addAll(_attendanceCache[accountId]!);
      }
      return true;
    }
    return false;
  }

  Future<bool> _checkSemesterScoreReport(int? accountId, {Map<String, dynamic>? autofill}) async {
    if (accountId != null && _semesterScoreCache.containsKey(accountId)) {
      if (autofill != null) {
        autofill.addAll(_semesterScoreCache[accountId]!);
      }
      return true;
    }
    return false;
  }

  Future<bool> _checkFinalSemesterScoreReport(int? accountId, {Map<String, dynamic>? autofill}) async {
    if (accountId != null && _finalSemesterScoreCache.containsKey(accountId)) {
      if (autofill != null) {
        autofill.addAll(_finalSemesterScoreCache[accountId]!);
      }
      return true;
    }
    return false;
  }

  // Helper untuk kapitalisasi awal setiap kata
  String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) =>
            word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '')
        .join(' ');
  }

  Future<void> _exportExcel() async {
    List<Map<String, dynamic>> exportData = [];
    String sheetTitle = '';
    String cabangName = '';

    switch (_exportType) {
      case 'absensi':
        sheetTitle = 'Nilai Absensi';
        break;
      case 'semester':
        sheetTitle = 'Nilai Semester';
        break;
      case 'akhir':
        sheetTitle = 'Nilai Akhir Semester';
        break;
    }

    // Get cabang name from dropdown
    if (_selectedBranch != null) {
      final cabang = _branches.firstWhere(
            (b) => b['id'].toString() == _selectedBranch,
        orElse: () => null,
      );
      if (cabang != null) {
        cabangName = cabang['name'] ?? '';
      }
    }

    for (var student in _students) {
      final dynamic rawId = student['id'];
      final int? accountId = rawId is int
          ? rawId
          : (rawId is String ? int.tryParse(rawId) : null);
      dynamic nilai, huruf, target, realisasi, percent;
      if (_exportType == 'absensi') {
        nilai = _attendanceCache[accountId]?['value'];
        huruf = _attendanceCache[accountId]?['degree'];
        target = _attendanceCache[accountId]?['target'];
        realisasi = _attendanceCache[accountId]?['reality'];
        percent = _attendanceCache[accountId]?['percentage'];
      } else if (_exportType == 'semester') {
        nilai = _semesterScoreCache[accountId]?['value'];
        huruf = _semesterScoreCache[accountId]?['degree'];
        target = _semesterScoreCache[accountId]?['target'];
        realisasi = _semesterScoreCache[accountId]?['reality'];
        percent = _semesterScoreCache[accountId]?['percentage'];
      } else if (_exportType == 'akhir') {
        nilai = _finalSemesterScoreCache[accountId]?['value'];
        huruf = _finalSemesterScoreCache[accountId]?['degree'];
        target = _finalSemesterScoreCache[accountId]?['target'];
        realisasi = _finalSemesterScoreCache[accountId]?['reality'];
        percent = _finalSemesterScoreCache[accountId]?['percentage'];
      }

      exportData.add({
        'Nama': student['fullname'] ?? student['email'] ?? '',
        'Target': target ?? 0,
        'Realisasi': realisasi ?? 0,
        '%': percent ?? 0,
        'Angka': nilai ?? 0,
        'Huruf': huruf ?? '',
      });
    }

    final xlsio.Workbook workbook = xlsio.Workbook();
    final xlsio.Worksheet sheet = workbook.worksheets[0];

    // Header Judul
    final String judul =
        'Rekapitulasi ${sheetTitle} Cabang ${cabangName.isNotEmpty ? cabangName : "-"}';
    sheet.getRangeByName('A1:F1').merge();
    sheet.getRangeByName('A1').setText(judul);
    sheet.getRangeByName('A1').cellStyle.bold = true;
    sheet.getRangeByName('A1').cellStyle.fontSize = 14;

    // Header Kolom
    sheet.getRangeByName('A2').setText('Nama');
    sheet.getRangeByName('B2').setText('Target');
    sheet.getRangeByName('C2').setText('Realisasi');
    sheet.getRangeByName('D2').setText('%');
    sheet.getRangeByName('E2:F2').merge();
    sheet.getRangeByName('E2').setText('Nilai');
    for (final col in ['A2', 'B2', 'C2', 'D2', 'E2']) {
      sheet.getRangeByName(col).cellStyle.bold = true;
    }

    // Subheader Nilai
    sheet.getRangeByName('E3').setText('Angka');
    sheet.getRangeByName('F3').setText('Huruf');
    sheet.getRangeByName('E3').cellStyle.bold = true;
    sheet.getRangeByName('F3').cellStyle.bold = true;

    // Data mulai baris ke-4
    for (int i = 0; i < exportData.length; i++) {
      final row = exportData[i];
      final rowNum = i + 4;

      sheet.getRangeByName('A$rowNum').setText(row['Nama'] ?? '');
      sheet.getRangeByName('B$rowNum').setNumber(_toDouble(row['Target']));
      sheet.getRangeByName('C$rowNum').setNumber(_toDouble(row['Realisasi']));
      sheet.getRangeByName('D$rowNum').setNumber(_toDouble(row['%']));
      sheet.getRangeByName('E$rowNum').setNumber(_toDouble(row['Angka']));
      sheet.getRangeByName('F$rowNum').setText(row['Huruf']?.toString() ?? '');

    }

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    try {
      Directory? directory;
      try {
        directory = await getTemporaryDirectory();
      } catch (_) {
        directory = await getApplicationDocumentsDirectory();
      }
      final String path = directory.path;
      final String fileName = '$sheetTitle.xlsx';
      final File file = File('$path/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      await OpenFile.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal export file: $e')),
      );
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }



  Widget _buildBranchDropdown() {
    if (_isLoadingBranches) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
      );
    }
    if (_errorMessage != null) {
      return Text(
        _errorMessage!,
        style: TextStyle(color: Colors.red),
      );
    }
    return DropdownButtonFormField<String>(
      value: _selectedBranch,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: 'Pilih Cabang',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      hint: Text('Pilih Cabang'),
      items: _branches.map<DropdownMenuItem<String>>((branch) {
        return DropdownMenuItem<String>(
          value: branch['id'].toString(),
          child: Text(branch['name'] ?? ''),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedBranch = value;
          _students = [];
        });
      },
      isExpanded: true,
    );
  }

  Widget _buildTahunAjaranDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedTahunAjaran,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: 'Tahun Ajaran',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: _tahunAjaranList
          .map((tahun) => DropdownMenuItem<String>(
                value: tahun,
                child: Text(tahun.split('/').first), // hanya tahun awal
              ))
          .toList(),
      onChanged: (val) {
        setState(() {
          _selectedTahunAjaran = val;
          _attendanceCache.clear();
          _semesterScoreCache.clear();
          _finalSemesterScoreCache.clear();
        });
        if (_selectedBranch != null) {
          fetchStudents(_selectedBranch!);
        }
      },
      isExpanded: true,
    );
  }

  Widget _buildFilterDropdown() {
    return DropdownButtonFormField<String>(
      value: _studentFilter,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: 'Filter Siswa',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: [
        DropdownMenuItem(value: 'semua', child: Text('Semua')),
        DropdownMenuItem(value: 'absensi', child: Text('Sudah Nilai Absensi')),
        DropdownMenuItem(value: 'semester', child: Text('Sudah Nilai Semester')),
        DropdownMenuItem(value: 'akhir', child: Text('Sudah Nilai Akhir Semester')),
        DropdownMenuItem(value: 'belum', child: Text('Belum Dinilai')),
      ],
      onChanged: (value) {
        setState(() {
          _studentFilter = value ?? 'semua';
        });
      },
      isExpanded: true,
    );
  }

  Widget _buildStudentList() {
    if (_isLoadingStudents) {
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[300],
                radius: 22,
              ),
              title: Container(
                height: 16,
                width: 80,
                color: Colors.grey[300],
              ),
              subtitle: Container(
                height: 12,
                width: 40,
                color: Colors.grey[200],
                margin: const EdgeInsets.only(top: 8),
              ),
            ),
          ),
        ),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: TextStyle(color: Colors.red),
        ),
      );
    }
    final filteredStudents = _students.where((item) {
      final name = (item['fullname'] ?? item['email'] ?? '').toString().toLowerCase();
      if (!name.contains(_searchQuery.toLowerCase())) return false;

      final dynamic rawId = item['id'];
      final int? accountId = rawId is int
          ? rawId
          : (rawId is String ? int.tryParse(rawId) : null);

      final bool hasAttendance = accountId != null && _attendanceCache.containsKey(accountId);
      final bool hasSemesterScore = accountId != null && _semesterScoreCache.containsKey(accountId);
      final bool hasFinalSemesterScore = accountId != null && _finalSemesterScoreCache.containsKey(accountId);

      switch (_studentFilter) {
        case 'absensi':
          return hasAttendance;
        case 'semester':
          return hasSemesterScore;
        case 'akhir':
          return hasFinalSemesterScore;
        case 'belum':
          return !hasAttendance && !hasSemesterScore && !hasFinalSemesterScore;
        default:
          return true;
      }
    }).toList();

    // Urutkan by abjad fullname (atau email jika fullname null)
    filteredStudents.sort((a, b) {
      final nameA = ((a['fullname'] ?? a['email']) ?? '').toString().toLowerCase();
      final nameB = ((b['fullname'] ?? b['email']) ?? '').toString().toLowerCase();
      return nameA.compareTo(nameB);
    });

    if (_students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
            SizedBox(height: 8),
            Text('Belum ada siswa untuk cabang ini.', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }
    if (filteredStudents.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada siswa yang cocok.',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        // Clear cache and fetch again
        setState(() {
          _attendanceCache.clear();
          _semesterScoreCache.clear();
          _finalSemesterScoreCache.clear();
        });
        await _fetchAllReports();
      },
      child: ListView.builder(
        itemCount: filteredStudents.length,
        itemBuilder: (context, index) {
          final item = filteredStudents[index];
          final fullname = item['fullname'] ?? item['email'] ?? 'No Name';
          final displayName = capitalizeWords(fullname.toString());
          final dynamic rawId = item['id'];
          final int? accountId = rawId is int
              ? rawId
              : (rawId is String ? int.tryParse(rawId) : null);

          final bool hasAttendance = accountId != null && _attendanceCache.containsKey(accountId);
          final bool hasSemesterScore = accountId != null && _semesterScoreCache.containsKey(accountId);
          final bool hasFinalSemesterScore = accountId != null && _finalSemesterScoreCache.containsKey(accountId);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    displayName[0],
                    style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  displayName,
                  style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Roboto'),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item['email'] != null)
                      Text(item['email'], style: TextStyle(color: Colors.grey[700], fontFamily: 'Roboto')),
                    SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: [
                        if (hasAttendance)
                          Chip(
                            avatar: Icon(Icons.check_circle, color: Colors.green[700], size: 18),
                            label: Text(
                              _attendanceCache[accountId]?['value'] != null
                                  ? '${_attendanceCache[accountId]!['degree']}'
                                  : 'Absensi',
                              style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.w500),
                            ),
                            backgroundColor: Colors.green[50],
                            visualDensity: VisualDensity.compact,
                          ),
                        if (hasSemesterScore)
                          Chip(
                            avatar: Icon(Icons.school, color: Colors.blue[700], size: 18),
                            label: Text(
                              _semesterScoreCache[accountId]?['value'] != null
                                  ? '${_semesterScoreCache[accountId]!['degree']}'
                                  : 'Semester',
                              style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.w500),
                            ),
                            backgroundColor: Colors.blue[50],
                            visualDensity: VisualDensity.compact,
                          ),
                        if (hasFinalSemesterScore)
                          Chip(
                            avatar: Icon(Icons.grade, color: Colors.orange[700], size: 18),
                            label: Text(
                              _finalSemesterScoreCache[accountId]?['value'] != null
                                  ? '${_finalSemesterScoreCache[accountId]!['degree']}'
                                  : 'Akhir Semester',
                              style: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.w500),
                            ),
                            backgroundColor: Colors.orange[50],
                            visualDensity: VisualDensity.compact,
                          ),
                        if (!hasAttendance && !hasSemesterScore && !hasFinalSemesterScore)
                          Chip(
                            avatar: Icon(Icons.info_outline, color: Colors.grey[600], size: 18),
                            label: Text('Belum Dinilai', style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500)),
                            backgroundColor: Colors.grey[200],
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ],
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                onTap: () async {
                  final selected = await showDialog<String>(
                    context: context,
                    builder: (context) => Dialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.assignment_turned_in_rounded, size: 48, color: Color(0xFF152349)),
                            SizedBox(height: 12),
                            Text(
                              'Pilih Jenis Nilai',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Color(0xFF152349),
                              ),
                            ),
                            SizedBox(height: 20),
                            ElevatedButton.icon(
                              icon: Icon(Icons.check_circle_outline),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[50],
                                foregroundColor: Colors.green[900],
                                minimumSize: Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              onPressed: () => Navigator.pop(context, 'absensi'),
                              label: Text('Nilai Absensi', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                            SizedBox(height: 12),
                            ElevatedButton.icon(
                              icon: Icon(Icons.school_outlined),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[50],
                                foregroundColor: Colors.blue[900],
                                minimumSize: Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              onPressed: () => Navigator.pop(context, 'uts'),
                              label: Text('Nilai Semester', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                            SizedBox(height: 12),
                            ElevatedButton.icon(
                              icon: Icon(Icons.grade_outlined),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[50],
                                foregroundColor: Colors.orange[900],
                                minimumSize: Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              onPressed: () => Navigator.pop(context, 'uas'),
                              label: Text('Nilai Akhir Semester', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                  if (selected != null) {
                    final autofill = <String, dynamic>{};
                    if (selected == 'uts') {
                      final bool hasSemesterScoreDialog = await _checkSemesterScoreReport(accountId, autofill: autofill);
                      showDialog(
                        context: context,
                        builder: (context) => _StudentSemesterScoreDialog(
                          studentName: displayName,
                          accountId: accountId,
                          hasSemesterScore: hasSemesterScoreDialog,
                          autofill: autofill,
                        ),
                      );
                    } else if (selected == 'uas') {
                      final bool hasFinalSemesterScoreDialog = await _checkFinalSemesterScoreReport(accountId, autofill: autofill);
                      showDialog(
                        context: context,
                        builder: (context) => _StudentFinalSemesterScoreDialog(
                          studentName: displayName,
                          accountId: accountId,
                          hasFinalSemesterScore: hasFinalSemesterScoreDialog,
                          autofill: autofill,
                        ),
                      );
                    } else {
                      final bool hasAttendanceDialog = await _checkAttendanceReport(accountId, autofill: autofill);
                      showDialog(
                        context: context,
                        builder: (context) => _StudentScoreDialog(
                          studentName: displayName,
                          scoreType: selected,
                          accountId: accountId,
                          hasAttendance: hasAttendanceDialog,
                          autofill: autofill,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F7FB),
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
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBranchDropdown(),
            const SizedBox(height: 16),
            _buildTahunAjaranDropdown(),
            const SizedBox(height: 16),
            _buildFilterDropdown(),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Theme.of(context).colorScheme.primary),
                      textStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    onPressed: _selectedBranch == null || _isLoadingBranches
                        ? null
                        : () => fetchStudents(_selectedBranch!),
                    label: Text('Tampilkan Siswa'),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey[400]!,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: DropdownButton<String>(
                            value: _exportType,
                            isExpanded: true,
                            underline: const SizedBox(),
                            icon: Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'absensi',
                                child: Text('Absensi'),
                              ),
                              DropdownMenuItem(
                                value: 'semester',
                                child: Text('Semester'),
                              ),
                              DropdownMenuItem(
                                value: 'akhir',
                                child: Text('Akhir Semester'),
                              ),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _exportType = val ?? 'absensi';
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          label: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.grid_on, size: 18), // Excel icon
                              SizedBox(width: 8),
                              Text('Export'),
                            ],
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onPressed: _students.isEmpty ? null : _exportExcel,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Cari siswa...',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child: _buildStudentList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const List<Map<String, dynamic>> bulanList = [
  {"label": "Januari", "value": 1},
  {"label": "Februari", "value": 2},
  {"label": "Maret", "value": 3},
  {"label": "April", "value": 4},
  {"label": "Mei", "value": 5},
  {"label": "Juni", "value": 6},
  {"label": "Juli", "value": 7},
  {"label": "Agustus", "value": 8},
  {"label": "September", "value": 9},
  {"label": "Oktober", "value": 10},
  {"label": "November", "value": 11},
  {"label": "Desember", "value": 12},
];

class _StudentScoreDialog extends StatefulWidget {
  final String studentName;
  final String scoreType;
  final int? accountId;
  final bool hasAttendance;
  final Map<String, dynamic>? autofill;

  const _StudentScoreDialog({
    required this.studentName,
    required this.scoreType,
    this.accountId,
    this.hasAttendance = false,
    this.autofill,
  });

  @override
  State<_StudentScoreDialog> createState() => _StudentScoreDialogState();
}

class _StudentScoreDialogState extends State<_StudentScoreDialog> {
  final _formKey = GlobalKey<FormState>();
  final _targetController = TextEditingController();
  final _realisasiController = TextEditingController();
  final _nilaiController = TextEditingController();
  final _percentController = TextEditingController();
  final _hurufController = TextEditingController();
  final _monthController = TextEditingController();
  String _semesterType = 'genap'; // default value
  int _selectedMonth = DateTime.now().month;
  String? _selectedTahunAjaran;
  List<String> _tahunAjaranList = [];

  bool _isSaving = false;
  String? _saveError;
  bool _isUpdating = false;
  String? _updateError;
  int? _accountId;

  @override
  void initState() {
    super.initState();
    _accountId = widget.accountId;
    _tahunAjaranList = _generateTahunAjaranList();
    _selectedTahunAjaran = _tahunAjaranList.last;
    if (widget.autofill != null && widget.autofill!.isNotEmpty) {
      final data = widget.autofill!;
      _targetController.text = data['target']?.toString() ?? '';
      _realisasiController.text = data['reality']?.toString() ?? '';
      _percentController.text = data['percentage']?.toString() ?? '';
      _nilaiController.text = data['value']?.toString() ?? '';
      _hurufController.text = data['degree']?.toString() ?? '';
      _selectedMonth = int.tryParse(data['month']?.toString() ?? '') ?? DateTime.now().month;
      _monthController.text = _selectedMonth.toString();
      _semesterType = _getSemesterType(_selectedMonth);
    } else {
      _selectedMonth = DateTime.now().month;
      _monthController.text = _selectedMonth.toString();
      _semesterType = _getSemesterType(_selectedMonth);
    }
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

  String _getSemesterType(int month) {
    return (month >= 1 && month <= 6) ? 'genap' : 'ganjil';
  }

  void _calculateValues() {
    final target = double.tryParse(_targetController.text) ?? 0;
    final realisasi = double.tryParse(_realisasiController.text) ?? 0;
    double percent = 0;
    double nilai = 0;
    String huruf = '';

    if (target > 0) {
      percent = (realisasi / target) * 100;
      nilai = (percent / 100) * 30;
      percent = percent.clamp(0, 100);
      nilai = double.parse(nilai.toStringAsFixed(2));
    }

    if (nilai <= 21) {
      huruf = 'C';
    } else if (nilai > 21 && nilai <= 22.49) {
      huruf = 'C+';
    } else if (nilai > 22.49 && nilai <= 23.99) {
      huruf = 'B-';
    } else if (nilai == 24) {
      huruf = 'B';
    } else if (nilai > 24 && nilai <= 25.99) {
      huruf = 'B+';
    } else if (nilai > 25.99 && nilai <= 26.99) {
      huruf = 'A-';
    } else if (nilai == 27) {
      huruf = 'A';
    } else if (nilai > 27) {
      huruf = 'A+';
    }

    _percentController.text = percent.toStringAsFixed(2);
    _nilaiController.text = nilai.toStringAsFixed(2);
    _hurufController.text = huruf;
    setState(() {});
  }

  Future<void> _saveAttendance() async {
    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      int? accountId = _accountId;
      if (accountId == null) {
        setState(() {
          _saveError = 'Account ID tidak ditemukan.';
          _isSaving = false;
        });
        return;
      }

      final target = int.tryParse(_targetController.text) ?? 0;
      final reality = double.tryParse(_realisasiController.text) ?? 0;
      final percentage = double.tryParse(_percentController.text) ?? 0.0;
      final value = double.tryParse(_nilaiController.text) ?? 0.0;
      final degree = _hurufController.text;
      final year = DateTime.now().year.toString();
      final month = int.tryParse(_monthController.text) ?? DateTime.now().month;
      final semesterType = _semesterType;
      final tahunAjaran = _selectedTahunAjaran ?? _tahunAjaranList.last;

      final payload = {
        "account_id": accountId,
        "target": target,
        "reality": reality,
        "percentage": percentage,
        "value": value,
        "degree": degree,
        "year": year,
        "month": month,
        "semester_type": semesterType,
        "tahun_ajaran": tahunAjaran,
      };

      final response = await http.post(
        Uri.parse('https://semarnari.sportballnesia.com/api/master/user/create_attendance_report'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data nilai berhasil disimpan!')),
        );
      } else {
        String errorMsg = 'Gagal menyimpan data: ${response.statusCode}';
        try {
          final resp = json.decode(response.body);
          if (resp is Map && resp['message'] != null) {
            errorMsg = resp['message'].toString();
          }
        } catch (_) {}
        setState(() {
          _saveError = errorMsg;
        });
      }
    } catch (e) {
      setState(() {
        _saveError = 'Terjadi kesalahan: $e';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _updateAttendance() async {
    setState(() {
      _isUpdating = true;
      _updateError = null;
    });

    try {
      int? accountId = _accountId;
      if (accountId == null) {
        setState(() {
          _updateError = 'Account ID tidak ditemukan.';
          _isUpdating = false;
        });
        return;
      }

      final target = int.tryParse(_targetController.text) ?? 0;
      final reality = double.tryParse(_realisasiController.text) ?? 0;
      final percentage = double.tryParse(_percentController.text) ?? 0.0;
      final value = double.tryParse(_nilaiController.text) ?? 0.0;
      final degree = _hurufController.text;
      final year = DateTime.now().year.toString();
      final month = int.tryParse(_monthController.text) ?? DateTime.now().month;
      final semesterType = _semesterType;
      final tahunAjaran = _selectedTahunAjaran ?? _tahunAjaranList.last;

      final payload = {
        "account_id": accountId,
        "target": target,
        "reality": reality,
        "percentage": percentage,
        "value": value,
        "degree": degree,
        "year": year,
        "month": month,
        "semester_type": semesterType,
        "tahun_ajaran": tahunAjaran,
      };

      final response = await http.post(
        Uri.parse('https://semarnari.sportballnesia.com/api/master/user/update_attendance_report'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data nilai berhasil diupdate!')),
        );
      } else {
        String errorMsg = 'Gagal update data: ${response.statusCode}';
        try {
          final resp = json.decode(response.body);
          if (resp is Map && resp['message'] != null) {
            errorMsg = resp['message'].toString();
          }
        } catch (_) {}
        setState(() {
          _updateError = errorMsg;
        });
      }
    } catch (e) {
      setState(() {
        _updateError = 'Terjadi kesalahan: $e';
      });
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String scoreTypeLabel;
    switch (widget.scoreType) {
      case 'absensi':
        scoreTypeLabel = 'Nilai Absensi';
        break;
      case 'uts':
        scoreTypeLabel = 'Nilai Semester';
        break;
      case 'uas':
        scoreTypeLabel = 'Nilai Akhir Semester';
        break;
      default:
        scoreTypeLabel = '';
    }
    final currentYear = DateTime.now().year.toString();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person, size: 48, color: Color(0xFF152349)),
              SizedBox(height: 8),
              Text(
                widget.studentName,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF152349)),
              ),
              SizedBox(height: 4),
              Text(
                'Tahun: $currentYear',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              SizedBox(height: 16),
              Text(
                scoreTypeLabel,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87),
              ),
              SizedBox(height: 16),
              if (_saveError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _saveError!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              if (_updateError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _updateError!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(_targetController, 'Target Absensi', TextInputType.number, onChanged: (_) => _calculateValues()),
                    SizedBox(height: 12),
                    _buildTextField(_realisasiController, 'Realisasi Absen', TextInputType.number, onChanged: (_) => _calculateValues()),
                    SizedBox(height: 12),
                    _buildTextField(_percentController, 'Persentase (%)', TextInputType.number, enabled: false),
                    SizedBox(height: 12),
                    _buildTextField(_nilaiController, 'Nilai', TextInputType.number, enabled: false),
                    SizedBox(height: 12),
                    _buildTextField(_hurufController, 'Huruf', TextInputType.text, enabled: false),
                    SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _selectedMonth,
                      decoration: InputDecoration(
                        labelText: 'Bulan',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: bulanList
                          .map((b) => DropdownMenuItem<int>(
                                value: b['value'],
                                child: Text(b['label']),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedMonth = val;
                            _monthController.text = val.toString();
                            _semesterType = _getSemesterType(val);
                          });
                        }
                      },
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _semesterType,
                      decoration: InputDecoration(
                        labelText: 'Semester',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: [
                        DropdownMenuItem(value: 'genap', child: Text('Genap')),
                        DropdownMenuItem(value: 'ganjil', child: Text('Ganjil')),
                      ],
                      onChanged: null, // disable manual change, auto by bulan
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedTahunAjaran,
                      decoration: InputDecoration(
                        labelText: 'Tahun Ajaran',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: _tahunAjaranList
                          .map((tahun) => DropdownMenuItem<String>(
                                value: tahun,
                                child: Text(tahun.split('/').first), // hanya tahun awal
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedTahunAjaran = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.hasAttendance ? Colors.orange[700] : Color(0xFF152349),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: (widget.hasAttendance ? _isUpdating : _isSaving)
                            ? null
                            : () async {
                          if (widget.hasAttendance) {
                            await _updateAttendance();
                          } else {
                            if (_formKey.currentState?.validate() ?? false) {
                              await _saveAttendance();
                            }
                          }
                        },
                        child: (widget.hasAttendance
                            ? (_isUpdating
                            ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text('Update Nilai Absensi', style: TextStyle(fontWeight: FontWeight.bold)))
                            : (_isSaving
                            ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)))),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      TextInputType type, {
        bool enabled = true,
        void Function(String)? onChanged,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      enabled: enabled,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: enabled ? Colors.grey[100] : Colors.grey[200],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: (value) {
        if (enabled && (value == null || value.trim().isEmpty)) {
          return 'Wajib diisi';
        }
        return null;
      },
    );
  }
}

class _StudentSemesterScoreDialog extends StatefulWidget {
  final String studentName;
  final int? accountId;
  final bool hasSemesterScore;
  final Map<String, dynamic>? autofill;

  const _StudentSemesterScoreDialog({
    required this.studentName,
    this.accountId,
    this.hasSemesterScore = false,
    this.autofill,
  });

  @override
  State<_StudentSemesterScoreDialog> createState() => _StudentSemesterScoreDialogState();
}

class _StudentSemesterScoreDialogState extends State<_StudentSemesterScoreDialog> {
  final _formKey = GlobalKey<FormState>();
  final _targetController = TextEditingController();
  final _realisasiController = TextEditingController();
  final _nilaiController = TextEditingController();
  final _percentController = TextEditingController();
  final _hurufController = TextEditingController();
  final _monthController = TextEditingController();
  String _semesterType = 'genap';
  int _selectedMonth = DateTime.now().month;
  String? _selectedTahunAjaran;
  List<String> _tahunAjaranList = [];

  bool _isSaving = false;
  String? _saveError;
  bool _isUpdating = false;
  String? _updateError;
  int? _accountId;

  @override
  void initState() {
    super.initState();
    _accountId = widget.accountId;
    _tahunAjaranList = _generateTahunAjaranList();
    _selectedTahunAjaran = _tahunAjaranList.last;
    if (widget.autofill != null && widget.autofill!.isNotEmpty) {
      final data = widget.autofill!;
      _targetController.text = '100'; // Always 100
      _realisasiController.text = data['reality']?.toString() ?? '';
      _percentController.text = data['percentage']?.toString() ?? '';
      _nilaiController.text = data['value']?.toString() ?? '';
      _hurufController.text = data['degree']?.toString() ?? '';
      _selectedMonth = int.tryParse(data['month']?.toString() ?? '') ?? DateTime.now().month;
      _monthController.text = _selectedMonth.toString();
      _semesterType = _getSemesterType(_selectedMonth);
    } else {
      _targetController.text = '100'; // Always 100
      _selectedMonth = DateTime.now().month;
      _monthController.text = _selectedMonth.toString();
      _semesterType = _getSemesterType(_selectedMonth);
    }
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

  String _getSemesterType(int month) {
    return (month >= 1 && month <= 6) ? 'genap' : 'ganjil';
  }

  void _calculateValues() {
    final target = 100.0; // Always 100
    final realisasi = double.tryParse(_realisasiController.text) ?? 0;
    double percent = 0;
    double nilai = 0;
    String huruf = '';

    if (target > 0) {
      percent = (realisasi / target) * 100;
      nilai = (percent / 100) * 30;
      percent = percent.clamp(0, 100);
      nilai = double.parse(nilai.toStringAsFixed(2));
    }

    // Huruf mapping as requested
    if (nilai <= 21) {
      huruf = 'C';
    } else if (nilai > 21 && nilai <= 22.49) {
      huruf = 'C+';
    } else if (nilai > 22.49 && nilai <= 23.99) {
      huruf = 'B-';
    } else if (nilai == 24) {
      huruf = 'B';
    } else if (nilai > 24 && nilai <= 25.99) {
      huruf = 'B+';
    } else if (nilai > 25.99 && nilai <= 26.99) {
      huruf = 'A-';
    } else if (nilai == 27) {
      huruf = 'A';
    } else if (nilai > 27) {
      huruf = 'A+';
    }

    _percentController.text = percent.toStringAsFixed(2);
    _nilaiController.text = nilai.toStringAsFixed(2);
    _hurufController.text = huruf;
    setState(() {});
  }

  Future<void> _saveSemesterExams() async {
    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      int? accountId = _accountId;
      if (accountId == null) {
        setState(() {
          _saveError = 'Account ID tidak ditemukan.';
          _isSaving = false;
        });
        return;
      }

      final target = int.tryParse(_targetController.text) ?? 0;
      final reality = double.tryParse(_realisasiController.text) ?? 0;
      final percentage = double.tryParse(_percentController.text) ?? 0.0;
      final value = double.tryParse(_nilaiController.text) ?? 0.0;
      final degree = _hurufController.text;
      final year = DateTime.now().year.toString();
      final month = int.tryParse(_monthController.text) ?? DateTime.now().month;
      final semesterType = _semesterType;
      final tahunAjaran = _selectedTahunAjaran ?? _tahunAjaranList.last;

      final payload = {
        "account_id": accountId,
        "target": target,
        "reality": reality,
        "percentage": percentage,
        "value": value,
        "degree": degree,
        "year": year,
        "month": month,
        "semester_type": semesterType,
        "tahun_ajaran": tahunAjaran,
      };

      final response = await http.post(
        Uri.parse('https://semarnari.sportballnesia.com/api/master/user/create_semester_exams'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data nilai semester berhasil disimpan!')),
        );
      } else {
        String errorMsg = 'Gagal menyimpan data: ${response.statusCode}';
        try {
          final resp = json.decode(response.body);
          if (resp is Map && resp['message'] != null) {
            errorMsg = resp['message'].toString();
          }
        } catch (_) {}
        setState(() {
          _saveError = errorMsg;
        });
      }
    } catch (e) {
      setState(() {
        _saveError = 'Terjadi kesalahan: $e';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _updateSemesterExams() async {
    setState(() {
      _isUpdating = true;
      _updateError = null;
    });

    try {
      int? accountId = _accountId;
      if (accountId == null) {
        setState(() {
          _updateError = 'Account ID tidak ditemukan.';
          _isUpdating = false;
        });
        return;
      }

      final target = int.tryParse(_targetController.text) ?? 0;
      final reality = double.tryParse(_realisasiController.text) ?? 0;
      final percentage = double.tryParse(_percentController.text) ?? 0.0;
      final value = double.tryParse(_nilaiController.text) ?? 0.0;
      final degree = _hurufController.text;
      final year = DateTime.now().year.toString();
      final month = int.tryParse(_monthController.text) ?? DateTime.now().month;
      final semesterType = _semesterType;
      final tahunAjaran = _selectedTahunAjaran ?? _tahunAjaranList.last;

      final payload = {
        "account_id": accountId,
        "target": target,
        "reality": reality,
        "percentage": percentage,
        "value": value,
        "degree": degree,
        "year": year,
        "month": month,
        "semester_type": semesterType,
        "tahun_ajaran": tahunAjaran,
      };

      final response = await http.post(
        Uri.parse('https://semarnari.sportballnesia.com/api/master/user/update_semester_exams'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data nilai semester berhasil diupdate!')),
        );
      } else {
        String errorMsg = 'Gagal update data: ${response.statusCode}';
        try {
          final resp = json.decode(response.body);
          if (resp is Map && resp['message'] != null) {
            errorMsg = resp['message'].toString();
          }
        } catch (_) {}
        setState(() {
          _updateError = errorMsg;
        });
      }
    } catch (e) {
      setState(() {
        _updateError = 'Terjadi kesalahan: $e';
      });
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year.toString();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.school_outlined, size: 48, color: Colors.blue[900]),
              SizedBox(height: 8),
              Text(
                widget.studentName,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF152349)),
              ),
              SizedBox(height: 4),
              Text(
                'Tahun: $currentYear',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              SizedBox(height: 16),
              Text(
                "Form Nilai Semester",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87),
              ),
              SizedBox(height: 16),
              if (_saveError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _saveError!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              if (_updateError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _updateError!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(_targetController, 'Target Nilai Semester', TextInputType.number, onChanged: (_) => _calculateValues()),
                    SizedBox(height: 12),
                    _buildTextField(_realisasiController, 'Realisasi Nilai Semester', TextInputType.number, onChanged: (_) => _calculateValues()),
                    SizedBox(height: 12),
                    _buildTextField(_percentController, 'Persentase (%)', TextInputType.number, enabled: false),
                    SizedBox(height: 12),
                    _buildTextField(_nilaiController, 'Nilai Akhir', TextInputType.number, enabled: false),
                    SizedBox(height: 12),
                    _buildTextField(_hurufController, 'Nilai Huruf', TextInputType.text, enabled: false),
                    SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _selectedMonth,
                      decoration: InputDecoration(
                        labelText: 'Bulan',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: bulanList
                          .map((b) => DropdownMenuItem<int>(
                                value: b['value'],
                                child: Text(b['label']),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedMonth = val;
                            _monthController.text = val.toString();
                            _semesterType = _getSemesterType(val);
                          });
                        }
                      },
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _semesterType,
                      decoration: InputDecoration(
                        labelText: 'Semester',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: [
                        DropdownMenuItem(value: 'genap', child: Text('Genap')),
                        DropdownMenuItem(value: 'ganjil', child: Text('Ganjil')),
                      ],
                      onChanged: null, // disable manual change, auto by bulan
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedTahunAjaran,
                      decoration: InputDecoration(
                        labelText: 'Tahun Ajaran',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: _tahunAjaranList
                          .map((tahun) => DropdownMenuItem<String>(
                                value: tahun,
                                child: Text(tahun.split('/').first), // hanya tahun awal
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedTahunAjaran = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.hasSemesterScore ? Colors.orange[700] : Colors.blue[900],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: (widget.hasSemesterScore ? _isUpdating : _isSaving)
                            ? null
                            : () async {
                          if (widget.hasSemesterScore) {
                            await _updateSemesterExams();
                          } else {
                            if (_formKey.currentState?.validate() ?? false) {
                              await _saveSemesterExams();
                            }
                          }
                        },
                        child: (widget.hasSemesterScore
                            ? (_isUpdating
                            ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text('Update Nilai Semester', style: TextStyle(fontWeight: FontWeight.bold)))
                            : (_isSaving
                            ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text('Simpan Nilai Semester', style: TextStyle(fontWeight: FontWeight.bold)))),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      TextInputType type, {
        bool enabled = true,
        void Function(String)? onChanged,
      }) {
    final isTargetField = label.contains('Target Nilai Semester');
    return TextFormField(
      controller: controller,
      keyboardType: type,
      enabled: isTargetField ? false : enabled,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: (isTargetField ? Colors.grey[200] : (enabled ? Colors.grey[100] : Colors.grey[200])),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: (value) {
        if (!isTargetField && enabled && (value == null || value.trim().isEmpty)) {
          return 'Wajib diisi';
        }
        return null;
      },
    );
  }
}

class _StudentFinalSemesterScoreDialog extends StatefulWidget {
  final String studentName;
  final int? accountId;
  final bool hasFinalSemesterScore;
  final Map<String, dynamic>? autofill;

  const _StudentFinalSemesterScoreDialog({
    required this.studentName,
    this.accountId,
    this.hasFinalSemesterScore = false,
    this.autofill,
  });

  @override
  State<_StudentFinalSemesterScoreDialog> createState() => _StudentFinalSemesterScoreDialogState();
}

class _StudentFinalSemesterScoreDialogState extends State<_StudentFinalSemesterScoreDialog> {
  final _formKey = GlobalKey<FormState>();
  final _targetController = TextEditingController();
  final _realisasiController = TextEditingController();
  final _nilaiController = TextEditingController();
  final _percentController = TextEditingController();
  final _hurufController = TextEditingController();
  final _monthController = TextEditingController();
  String _semesterType = 'genap';
  int _selectedMonth = DateTime.now().month;
  String? _selectedTahunAjaran;
  List<String> _tahunAjaranList = [];

  bool _isSaving = false;
  String? _saveError;
  bool _isUpdating = false;
  String? _updateError;
  int? _accountId;

  @override
  void initState() {
    super.initState();
    _accountId = widget.accountId;
    _tahunAjaranList = _generateTahunAjaranList();
    _selectedTahunAjaran = _tahunAjaranList.last;
    if (widget.autofill != null && widget.autofill!.isNotEmpty) {
      final data = widget.autofill!;
      _targetController.text = '100'; // Always 100
      _realisasiController.text = data['reality']?.toString() ?? '';
      _percentController.text = data['percentage']?.toString() ?? '';
      _nilaiController.text = data['value']?.toString() ?? '';
      _hurufController.text = data['degree']?.toString() ?? '';
      _selectedMonth = int.tryParse(data['month']?.toString() ?? '') ?? DateTime.now().month;
      _monthController.text = _selectedMonth.toString();
      _semesterType = _getSemesterType(_selectedMonth);
    } else {
      _targetController.text = '100'; // Always 100
      _selectedMonth = DateTime.now().month;
      _monthController.text = _selectedMonth.toString();
      _semesterType = _getSemesterType(_selectedMonth);
    }
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

  String _getSemesterType(int month) {
    return (month >= 1 && month <= 6) ? 'genap' : 'ganjil';
  }

  void _calculateValues() {
    final target = 100.0; // Always 100
    final realisasi = double.tryParse(_realisasiController.text) ?? 0;
    double percent = 0;
    double nilai = 0;
    String huruf = '';

    if (target > 0) {
      percent = (realisasi / target) * 100;
      nilai = (percent / 100) * 40;
      percent = percent.clamp(0, 100);
      nilai = double.parse(nilai.toStringAsFixed(2));
    }

    // Huruf mapping as requested
    if (nilai == 28) {
      huruf = 'C';
    } else if (nilai > 28 && nilai < 30) {
      huruf = 'C+';
    } else if (nilai >= 30 && nilai < 32) {
      huruf = 'B-';
    } else if (nilai == 32) {
      huruf = 'B';
    } else if (nilai > 32 && nilai < 34) {
      huruf = 'B+';
    } else if (nilai >= 34 && nilai < 36) {
      huruf = 'A-';
    } else if (nilai == 36) {
      huruf = 'A';
    } else if (nilai > 36) {
      huruf = 'A+';
    }

    _percentController.text = percent.toStringAsFixed(2);
    _nilaiController.text = nilai.toStringAsFixed(2);
    _hurufController.text = huruf;
    setState(() {});
  }

  Future<void> _saveFinalSemesterExams() async {
    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      int? accountId = _accountId;
      if (accountId == null) {
        setState(() {
          _saveError = 'Account ID tidak ditemukan.';
          _isSaving = false;
        });
        return;
      }

      final target = int.tryParse(_targetController.text) ?? 0;
      final reality = double.tryParse(_realisasiController.text) ?? 0;
      final percentage = double.tryParse(_percentController.text) ?? 0.0;
      final value = double.tryParse(_nilaiController.text) ?? 0.0;
      final degree = _hurufController.text;
      final year = DateTime.now().year.toString();
      final month = int.tryParse(_monthController.text) ?? DateTime.now().month;
      final semesterType = _semesterType;
      final tahunAjaran = _selectedTahunAjaran ?? _tahunAjaranList.last;

      final payload = {
        "account_id": accountId,
        "target": target,
        "reality": reality,
        "percentage": percentage,
        "value": value,
        "degree": degree,
        "year": year,
        "month": month,
        "semester_type": semesterType,
        "tahun_ajaran": tahunAjaran,
      };

      final response = await http.post(
        Uri.parse('https://semarnari.sportballnesia.com/api/master/user/create_final_semester_exams'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data nilai akhir semester berhasil disimpan!')),
        );
      } else {
        String errorMsg = 'Gagal menyimpan data: ${response.statusCode}';
        try {
          final resp = json.decode(response.body);
          if (resp is Map && resp['message'] != null) {
            errorMsg = resp['message'].toString();
          }
        } catch (_) {}
        setState(() {
          _saveError = errorMsg;
        });
      }
    } catch (e) {
      setState(() {
        _saveError = 'Terjadi kesalahan: $e';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _updateFinalSemesterExams() async {
    setState(() {
      _isUpdating = true;
      _updateError = null;
    });

    try {
      int? accountId = _accountId;
      if (accountId == null) {
        setState(() {
          _updateError = 'Account ID tidak ditemukan.';
          _isUpdating = false;
        });
        return;
      }

      final target = int.tryParse(_targetController.text) ?? 0;
      final reality = double.tryParse(_realisasiController.text) ?? 0;
      final percentage = double.tryParse(_percentController.text) ?? 0.0;
      final value = double.tryParse(_nilaiController.text) ?? 0.0;
      final degree = _hurufController.text;
      final year = DateTime.now().year.toString();
      final month = int.tryParse(_monthController.text) ?? DateTime.now().month;
      final semesterType = _semesterType;
      final tahunAjaran = _selectedTahunAjaran ?? _tahunAjaranList.last;

      final payload = {
        "account_id": accountId,
        "target": target,
        "reality": reality,
        "percentage": percentage,
        "value": value,
        "degree": degree,
        "year": year,
        "month": month,
        "semester_type": semesterType,
        "tahun_ajaran": tahunAjaran,
      };

      final response = await http.post(
        Uri.parse('https://semarnari.sportballnesia.com/api/master/user/update_final_semester_exams'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data nilai akhir semester berhasil diupdate!')),
        );
      } else {
        String errorMsg = 'Gagal update data: ${response.statusCode}';
        try {
          final resp = json.decode(response.body);
          if (resp is Map && resp['message'] != null) {
            errorMsg = resp['message'].toString();
          }
        } catch (_) {}
        setState(() {
          _updateError = errorMsg;
        });
      }
    } catch (e) {
      setState(() {
        _updateError = 'Terjadi kesalahan: $e';
      });
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year.toString();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.grade_outlined, size: 48, color: Colors.orange[900]),
              SizedBox(height: 8),
              Text(
                widget.studentName,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF152349)),
              ),
              SizedBox(height: 4),
              Text(
                'Tahun: $currentYear',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              SizedBox(height: 16),
              Text(
                "Form Nilai Akhir Semester",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87),
              ),
              SizedBox(height: 16),
              if (_saveError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _saveError!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              if (_updateError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _updateError!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(_targetController, 'Target Nilai Akhir Semester', TextInputType.number, onChanged: (_) => _calculateValues()),
                    SizedBox(height: 12),
                    _buildTextField(_realisasiController, 'Realisasi Nilai Akhir Semester', TextInputType.number, onChanged: (_) => _calculateValues()),
                    SizedBox(height: 12),
                    _buildTextField(_percentController, 'Persentase (%)', TextInputType.number, enabled: false),
                    SizedBox(height: 12),
                    _buildTextField(_nilaiController, 'Nilai Akhir', TextInputType.number, enabled: false),
                    SizedBox(height: 12),
                    _buildTextField(_hurufController, 'Nilai Huruf', TextInputType.text, enabled: false),
                    SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _selectedMonth,
                      decoration: InputDecoration(
                        labelText: 'Bulan',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: bulanList
                          .map((b) => DropdownMenuItem<int>(
                                value: b['value'],
                                child: Text(b['label']),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedMonth = val;
                            _monthController.text = val.toString();
                            _semesterType = _getSemesterType(val);
                          });
                        }
                      },
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _semesterType,
                      decoration: InputDecoration(
                        labelText: 'Semester',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: [
                        DropdownMenuItem(value: 'genap', child: Text('Genap')),
                        DropdownMenuItem(value: 'ganjil', child: Text('Ganjil')),
                      ],
                      onChanged: null, // disable manual change, auto by bulan
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedTahunAjaran,
                      decoration: InputDecoration(
                        labelText: 'Tahun Ajaran',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: _tahunAjaranList
                          .map((tahun) => DropdownMenuItem<String>(
                                value: tahun,
                                child: Text(tahun.split('/').first), // hanya tahun awal
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedTahunAjaran = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.hasFinalSemesterScore ? Colors.orange[700] : Colors.orange[900],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: (widget.hasFinalSemesterScore ? _isUpdating : _isSaving)
                            ? null
                            : () async {
                          if (widget.hasFinalSemesterScore) {
                            await _updateFinalSemesterExams();
                          } else {
                            if (_formKey.currentState?.validate() ?? false) {
                              await _saveFinalSemesterExams();
                            }
                          }
                        },
                        child: (widget.hasFinalSemesterScore
                            ? (_isUpdating
                            ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text('Update Nilai Akhir Semester', style: TextStyle(fontWeight: FontWeight.bold)))
                            : (_isSaving
                            ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text('Simpan Nilai Akhir Semester', style: TextStyle(fontWeight: FontWeight.bold)))),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      TextInputType type, {
        bool enabled = true,
        void Function(String)? onChanged,
      }) {
    final isTargetField = label.contains('Target Nilai Akhir Semester');
    return TextFormField(
      controller: controller,
      keyboardType: type,
      enabled: isTargetField ? false : enabled,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: (isTargetField ? Colors.grey[200] : (enabled ? Colors.grey[100] : Colors.grey[200])),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: (value) {
        if (!isTargetField && enabled && (value == null || value.trim().isEmpty)) {
          return 'Wajib diisi';
        }
        return null;
      },
    );
  }
}
