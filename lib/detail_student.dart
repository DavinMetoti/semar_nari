import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DetailStudentPage extends StatefulWidget {
  final String studentId;
  final String fullname;
  final String username;
  final String email;
  final String branchName;
  final String phone;
  final String active;
  final String class_name;
  final String grade;


  DetailStudentPage({
    required this.studentId,
    required this.fullname,
    required this.username,
    required this.email,
    required this.branchName,
    required this.phone,
    required this.active,
    required this.class_name,
    required this.grade,
  });

  @override
  _DetailStudentPageState createState() => _DetailStudentPageState();
}

class _DetailStudentPageState extends State<DetailStudentPage> {
  String? selectedBranchName;
  String? selectedBranchId;
  String? selectedClassName;
  String? selectedClassId;
  bool isActive = false;
  List<Map<String, dynamic>> branches = [];
  List<Map<String, dynamic>> classes = [];

  @override
  void initState() {
    super.initState();
    isActive = widget.active == '1';
    selectedBranchName = widget.branchName;
    selectedClassName = widget.class_name.isEmpty ? null : widget.class_name;
    _fetchBranches();
    _fetchClasses();
  }

  Future<void> _fetchBranches() async {
    final response = await http.get(Uri.parse('https://semarnari.sportballnesia.com/api/master/data/get_all_branch'));
    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      List<dynamic> branchList = data['data'];
      setState(() {
        branches = branchList.map((branch) {
          return {
            'id': branch['id'].toString(),
            'name': branch['name'],
          };
        }).toList();
      });

      final currentBranch = branches.firstWhere(
            (branch) => branch['name'] == selectedBranchName,
        orElse: () => {'id': '', 'name': ''},
      );
      selectedBranchId = currentBranch['id'];
    } else {
      throw Exception('Failed to load branches');
    }
  }

  Future<void> _fetchClasses() async {
    final response = await http.get(Uri.parse('https://semarnari.sportballnesia.com/api/master/data/all_class_rooms'));
    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      List<dynamic> classList = data['data'];
      setState(() {
        classes = classList.map((classRoom) {
          return {
            'id': classRoom['id'].toString(),
            'name': classRoom['name'],
          };
        }).toList();
      });

      // Perbaikan pencarian currentClass
      final currentClass = classes.firstWhere(
            (classRoom) => classRoom['name'] == selectedClassName,
        orElse: () => {'id': '', 'name': ''},
      );

      if (currentClass['id'] == '') {
        // Jika selectedClassName tidak ditemukan dalam daftar, reset ke null
        selectedClassName = null;
        selectedClassId = null;
      } else {
        selectedClassId = currentClass['id'];
      }
    } else {
      throw Exception('Failed to load classes');
    }
  }


  Future<void> _updateUser() async {
    if (selectedBranchId == null || selectedBranchId!.isEmpty || selectedClassId == null || selectedClassId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please select both a branch and a class'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final Map<String, dynamic> payload = {
      'id': widget.studentId,
      'active': isActive ? 1 : 0,
      'branch': selectedBranchId,
      'class_id': selectedClassId, // Pass the selected class id
    };

    final response = await http.post(
      Uri.parse('https://semarnari.sportballnesia.com/api/master/user/update'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );

    print(payload);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('User updated successfully'),
          backgroundColor: Colors.green,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update user'),
          backgroundColor: Colors.red,
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error updating user'),
        backgroundColor: Colors.red,
      ));
    }
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
              Icons.account_circle,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(Icons.person, color: Colors.blue),
                title: Text('Nama: ${widget.fullname}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(Icons.account_circle, color: Colors.blue),
                title: Text('Username: ${widget.username}', style: TextStyle(fontSize: 14)),
              ),
            ),
            Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(Icons.email, color: Colors.blue),
                title: Text('Email: ${widget.email}', style: TextStyle(fontSize: 14)),
              ),
            ),
            Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(
                  Icons.child_care, // Ikon berbeda untuk TK dan kelas lainnya
                  color: Colors.blue,
                ),
                title: Text(
                  widget.grade == '0' ? 'Tingkatan: TK' : 'Tingkatan: Kelas ${widget.grade}', // Jika grade 0 maka TK, selain itu tampilkan kelas sesuai grade
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
            Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(Icons.school, color: Colors.blue),
                title: Text('Kelas: ', style: TextStyle(fontSize: 14)),
                trailing: DropdownButton<String>(
                  value: selectedClassName,
                  hint: Text('Pilih Kelas'),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedClassName = newValue;
                      selectedClassId = classes.firstWhere(
                            (classRoom) => classRoom['name'] == newValue,
                        orElse: () => {'id': '', 'name': ''},
                      )['id'];
                    });
                  },
                  items: [
                    if (selectedClassName == null)
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text('Pilih Kelas', style: TextStyle(fontSize: 14)),
                      ),
                    ...classes.map<DropdownMenuItem<String>>((classRoom) {
                      return DropdownMenuItem<String>(
                        value: classRoom['name'],
                        child: Text(classRoom['name'], style: TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(Icons.room, color: Colors.blue),
                title: Text('Sanggar: ', style: TextStyle(fontSize: 14)),
                trailing: DropdownButton<String>(
                  value: selectedBranchName ?? '', // Provide fallback empty string
                  hint: Text('Pilih Sanggar'),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedBranchName = newValue;
                      // Update selectedBranchId when branch name changes
                      selectedBranchId = branches.firstWhere(
                            (branch) => branch['name'] == newValue,
                        orElse: () => {'id': '', 'name': ''},
                      )['id'];
                    });
                  },
                  items: branches.map<DropdownMenuItem<String>>((branch) {
                    return DropdownMenuItem<String>(
                      value: branch['name'],
                      child: Text(branch['name'], style: TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                ),
              ),
            ),
            Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(Icons.phone, color: Colors.blue),
                title: Text('Nomor Telepon: ${widget.phone}', style: TextStyle(fontSize: 14)),
              ),
            ),
            Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(
                  isActive ? Icons.check_circle : Icons.cancel,
                  color: isActive ? Colors.green : Colors.red,
                ),
                title: Text('Status: ', style: TextStyle(fontSize: 14)),
                trailing: Switch(
                  value: isActive,
                  onChanged: (bool value) {
                    setState(() {
                      isActive = value;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: double.infinity, // Membuat tombol memenuhi lebar layar
                child: ElevatedButton(
                  onPressed: _updateUser,
                  child: Text(
                    'Update',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF152349),
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
