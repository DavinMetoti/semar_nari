import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'home.dart';
import 'detail_student.dart';
import 'history_student.dart';

class StudentListPage extends StatefulWidget {
  @override
  _StudentListPageState createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  List<dynamic> branches = [];
  List<dynamic> students = [];
  String? selectedBranch;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchBranches();
  }

  // Fetch all branches from the API
  Future<void> fetchBranches() async {
    final response = await http.get(Uri.parse('https://semarnari.sportballnesia.com/api/master/data/get_all_branch'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        branches = data['data'];
      });
    } else {
      // Handle error if necessary
    }
  }

  // Fetch students based on the selected branch
  Future<void> fetchStudents() async {
    if (selectedBranch == null) return;

    // Clear previous student data
    setState(() {
      students = [];
      isLoading = true;
    });

    final response = await http.post(
      Uri.parse('https://semarnari.sportballnesia.com/api/master/user/get_all_student'),
      headers: {
        'Content-Type': 'application/json', // Ensure content type is set to JSON
      },
      body: json.encode({'branch': selectedBranch}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        students = data['data'];
        isLoading = false;
      });

      print(students);
    } else {
      // Handle error if necessary
      setState(() {
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Branch Dropdown
            Text('Pilih Cabang:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 10),
            DropdownButtonFormField2<String>(
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              hint: const Text(
                'Pilih Cabang',
                style: TextStyle(fontSize: 14),
              ),
              items: branches.map<DropdownMenuItem<String>>((branch) {
                return DropdownMenuItem<String>(
                  value: branch['id'].toString(),
                  child: Text(branch['name'], style: TextStyle(fontSize: 16)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedBranch = value.toString();
                  // Fetch students after selecting a branch
                  fetchStudents();
                });
              },
              buttonStyleData: const ButtonStyleData(
                padding: EdgeInsets.only(right: 8),
              ),
              iconStyleData: const IconStyleData(
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Colors.black45,
                ),
                iconSize: 24,
              ),
              dropdownStyleData: DropdownStyleData(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Loading Indicator
            if (isLoading)
              Center(child: CircularProgressIndicator()),

            // Student List
            if (!isLoading && students.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  (student['fullname']?.toString().split(' ').take(2).join(' ') ?? 'Nama Tidak Diketahui').toUpperCase(),
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => HistoryStudentPage(
                                              studentId: student['id'].toString(),
                                              studentName: student['fullname'] ?? 'Siswa',
                                            ),
                                          ),
                                        );
                                      },
                                      icon: Icon(
                                        Icons.calendar_today,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                      tooltip: 'Lihat Presensi',
                                    ),
                                    // Eye Icon Button
                                    IconButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => DetailStudentPage(
                                              studentId: student['id'].toString(),
                                              fullname: student['fullname'] ?? 'Nama Tidak Diketahui',
                                              username: student['username'] ?? 'Tidak Tersedia',
                                              email: student['email'] ?? 'Email Tidak Diketahui',
                                              branchName: student['branch_name'] ?? 'Cabang Tidak Diketahui',
                                              phone: student['child_phone_number'] ?? 'Nomor Telepon Tidak Tersedia',
                                              class_name: student['class_name'] ?? 'Kelas Tidak Tersedia',
                                              active: student['active'] ?? '0',
                                              grade: student['grade'] ?? '0',
                                            ),
                                          ),
                                        ).then((_) {
                                          fetchStudents();
                                        });
                                      },
                                      icon: Icon(
                                        Icons.visibility,
                                        color: Colors.blueAccent,
                                        size: 20,
                                      ),
                                      tooltip: 'Lihat Detail',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // Username
                            Text(
                              'Username: ${student['username'] ?? 'Tidak Tersedia'}',
                              style: TextStyle(fontSize: 12),
                            ),
                            SizedBox(height: 8),

                            // Email
                            Text(
                              'Email: ${student['email'] ?? 'Email Tidak Diketahui'}',
                              style: TextStyle(fontSize: 12),
                            ),
                            SizedBox(height: 8),

                            // Branch Name
                            Text(
                              'Branch: ${student['branch_name'] ?? 'Cabang Tidak Diketahui'}',
                              style: TextStyle(fontSize: 12),
                            ),
                            SizedBox(height: 8),

                            // Phone Number
                            Text(
                              'Phone: ${student['parent_phone_number'] ?? 'Nomor Telepon Tidak Tersedia'}',
                              style: TextStyle(fontSize: 12),
                            ),
                            SizedBox(height: 16),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            // No Data Found
            if (!isLoading && students.isEmpty)
              Center(child: Text('Tidak ada data siswa ditemukan.', style: TextStyle(fontSize: 16))),
          ],
        ),
      ),
    );
  }
}
