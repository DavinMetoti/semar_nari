import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'make_schedule.dart';
import 'home.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SchedulePage extends StatefulWidget {
  @override
  _SchedulePageState createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  List<dynamic> _schedules = [];
  List<dynamic> _filteredSchedules = [];
  String? _username;
  String? _accessRole;

  // Filter variables
  String? _selectedClass;
  String? _selectedDate;
  String _searchQuery = '';

  // For "Tampilkan lebih banyak"
  int _visibleCount = 5;
  bool _showAll = false;

  // Static class filter options
  final List<String> _staticClassList = [
    'Semar', 'Gareng', 'Petruk', 'Bagong'
  ];

  List<String> _classList = [];
  List<String> _dateList = [];

  @override
  void initState() {
    super.initState();
    _loadUsernameAndRole();
  }

  Future<void> _loadUsernameAndRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? '';
      _accessRole = prefs.getString('access_role');
    });
    if (_username?.isNotEmpty ?? false) {
      _fetchSchedules();
    }
  }

  Future<void> _fetchSchedules() async {
    if (_username?.isEmpty ?? true) {
      return;
    }

    final response = await http.get(Uri.parse('https://semarnari.sportballnesia.com/api/master/data/all_schedule?username=$_username'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      setState(() {
        _schedules = data['data'] ?? [];
        // Only keep schedules today or after (hide past dates)
        final now = DateTime.now();
        _schedules = _schedules.where((e) {
          final dateStr = e['date'];
          if (dateStr == null) return false;
          final date = DateTime.tryParse(dateStr);
          if (date == null) return false;
          // Only show today or future
          return !date.isBefore(DateTime(now.year, now.month, now.day));
        }).toList();
        _filteredSchedules = _schedules;
        // Use static class list for filter, but also add any other classes found
        final dynamicClasses = _schedules
            .map<String?>((e) => e['class_name'] as String?)
            .where((e) => e != null)
            .toSet()
            .cast<String>()
            .toList();
        _classList = [
          ..._staticClassList,
          ...dynamicClasses.where((c) => !_staticClassList.contains(c)),
        ];
        _dateList = _schedules
            .map<String?>((e) => e['date'] as String?)
            .where((e) => e != null)
            .toSet()
            .cast<String>()
            .toList();
      });
    } else {
    }
  }

  Future<void> _deleteSchedule(String scheduleId) async {
    final response = await http.post(
      Uri.parse('https://semarnari.sportballnesia.com/api/master/data/delete_schedule'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'schedule_id': scheduleId}),
    );

    if (response.statusCode == 200) {
      setState(() {
        _schedules.removeWhere((schedule) => schedule['schedule_id'] == scheduleId);
        _applyFilters();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Jadwal berhasil dihapus')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus jadwal')));
    }
  }

  void _showScheduleDetails(BuildContext context, dynamic schedule) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(schedule['subject'] ?? 'Unknown subject'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Tanggal: ${schedule['date'] ?? 'Unknown date'}", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text("Waktu: ${schedule['time'] ?? 'Unknown time'}", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text("Deskripsi: ${schedule['description'] ?? 'No description available'}", textAlign: TextAlign.justify),
              SizedBox(height: 8),
              Text("Detail: ${schedule['details'] ?? 'No details available'}", textAlign: TextAlign.justify),
              SizedBox(height: 8),
              Text("Lokasi: ${schedule['branch_name'] ?? 'No location specified'}", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  void _applyFilters() {
    setState(() {
      _showAll = false;
      _visibleCount = 5;
      _filteredSchedules = _schedules.where((schedule) {
        final matchesClass = _selectedClass == null || _selectedClass == '' || schedule['class_name'] == _selectedClass;
        final matchesDate = _selectedDate == null || _selectedDate == '' || schedule['date'] == _selectedDate;
        final matchesSearch = _searchQuery.isEmpty ||
            (schedule['subject']?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (schedule['description']?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        return matchesClass && matchesDate && matchesSearch;
      }).toList();
    });
  }

  Widget _buildFilterBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.93),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.07),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Flexible(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _selectedClass,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Kelas',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  ),
                  items: [
                    DropdownMenuItem(value: '', child: Text('Semua Kelas')),
                    ..._classList.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedClass = val == '' ? null : val;
                      _applyFilters();
                    });
                  },
                ),
              ),
              SizedBox(width: 8),
              Flexible(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _selectedDate,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Tanggal',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  ),
                  items: [
                    DropdownMenuItem(value: '', child: Text('Semua Tanggal')),
                    ..._dateList.map((d) => DropdownMenuItem(
                        value: d,
                        child: Text(DateFormat('dd MMM yyyy').format(DateTime.parse(d))))),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedDate = val == '' ? null : val;
                      _applyFilters();
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(
              hintText: 'Cari subjek atau deskripsi...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
                _applyFilters();
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine how many schedules to show
    final int showCount = _showAll
        ? _filteredSchedules.length
        : (_filteredSchedules.length > _visibleCount ? _visibleCount : _filteredSchedules.length);

    return Scaffold(
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
      body: Stack(
        children: [
          // Soft blue gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFe9f0fa), Color(0xFFdbeafe)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 10),
                if (_accessRole == '2') _buildFilterBar(),
                Expanded(
                  child: (_filteredSchedules.isEmpty)
                      ? Center(
                          child: _username?.isEmpty ?? true
                              ? Text('Memuat data...',
                                  style: TextStyle(
                                    color: Color(0xFF152349),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ))
                              : Text('Tidak ada jadwal yang tersedia',
                                  style: TextStyle(
                                    color: Color(0xFF152349),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  )),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
                                itemCount: showCount,
                                itemBuilder: (context, index) {
                                  final schedule = _filteredSchedules[index];
                                  return Container(
                                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blueGrey.withOpacity(0.08),
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      title: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              schedule['subject'] ?? 'Unknown subject',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF152349),
                                                fontSize: 17,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            schedule['time'] ?? '',
                                            style: TextStyle(
                                              color: Colors.blueGrey[700],
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(height: 4),
                                          Text(
                                            schedule['description'] ?? '',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.blueGrey[800],
                                              fontSize: 13,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(Icons.calendar_today, size: 15, color: Colors.blueGrey[400]),
                                              SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  schedule['date'] != null
                                                      ? DateFormat('dd MMM yyyy').format(DateTime.parse(schedule['date']))
                                                      : '',
                                                  style: TextStyle(
                                                    color: Colors.blueGrey[600],
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Icon(Icons.class_, size: 15, color: Colors.blueGrey[400]),
                                              SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  schedule['class_name'] ?? '',
                                                  style: TextStyle(
                                                    color: Colors.blueGrey[600],
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
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.info_outline, color: Color(0xFF152349)),
                                            onPressed: () => _showScheduleDetails(context, schedule),
                                            tooltip: "Detail",
                                          ),
                                          if (_accessRole == '2')
                                            IconButton(
                                              icon: Icon(Icons.delete, color: Colors.red[700]),
                                              onPressed: () => _deleteSchedule(schedule['schedule_id'].toString()),
                                              tooltip: "Hapus",
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (!_showAll && _filteredSchedules.length > _visibleCount)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _showAll = true;
                                    });
                                  },
                                  child: Text(
                                    "Tampilkan lebih banyak",
                                    style: TextStyle(
                                      color: Color(0xFF152349),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _accessRole == '2'
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MakeSchedulePage()),
                );
              },
              backgroundColor: Color(0xFF152349),
              child: Icon(Icons.add, color: Colors.white),
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            )
          : null,
    );
  }
}
