import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'make_schedule.dart';

class SchedulePage extends StatefulWidget {
  @override
  _SchedulePageState createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  List<dynamic> _schedules = [];
  String? _username;
  String? _accessRole;

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

      print(data);
      setState(() {
        _schedules = data['data'] ?? [];
      });
    } else {
      print('Failed to load schedules');
    }
  }

  Future<void> _deleteSchedule(String scheduleId) async {
    final response = await http.post(
      Uri.parse('https://semarnari.sportballnesia.com/api/master/data/delete_schedule'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'schedule_id': scheduleId}),
    );

    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      setState(() {
        _schedules.removeWhere((schedule) => schedule['schedule_id'] == scheduleId);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF152349),
        automaticallyImplyLeading: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 30,
              width: 30,
            ),
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
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(
              Icons.calendar_today,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
      body: _schedules.isEmpty
          ? Center(
        child: _username?.isEmpty ?? true
            ? Text('Memuat data...')
            : Text('Tidak ada jadwal yang tersedia'),
      )
          : ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemCount: _schedules.length,
        itemBuilder: (context, index) {
          final schedule = _schedules[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            margin: EdgeInsets.only(bottom: 12),
            color: Colors.grey[200],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 18),
                          SizedBox(width: 8),
                          Text(
                            schedule['date'] ?? 'Unknown date',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            schedule['time'] ?? 'Unknown time',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.access_time, size: 18),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    schedule['subject'] ?? 'Unknown subject',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          schedule['class_name'] ?? 'Unknown class',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _showScheduleDetails(context, schedule),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Detail',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          if (_accessRole == '2') ...[
                            SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteSchedule(schedule['schedule_id'].toString()),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: _accessRole == '2'
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MakeSchedulePage()),
          );
        },
        child: Icon(Icons.add),
      )
          : null,
    );
  }
}
