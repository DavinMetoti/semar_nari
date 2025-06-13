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

      final currentClass = classes.firstWhere(
        (classRoom) => classRoom['name'] == selectedClassName,
        orElse: () => {'id': '', 'name': ''},
      );

      if (currentClass['id'] == '') {
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
      'class_id': selectedClassId,
    };

    final response = await http.post(
      Uri.parse('https://semarnari.sportballnesia.com/api/master/user/update'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );

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
    final Color mainBlue = const Color(0xFF152349);
    final Color softBlue = const Color(0xFFb6d0f7);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainBlue,
        automaticallyImplyLeading: true,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 32,
              width: 32,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Semar Nari',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    fontFamily: 'Montserrat',
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Sanggar Tari Kota Semarang',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontFamily: 'Montserrat',
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
      body: ListView(
        padding: const EdgeInsets.all(18.0),
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [softBlue, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: mainBlue.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            margin: const EdgeInsets.only(bottom: 22),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [mainBlue, softBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: const Icon(Icons.person, color: Colors.white, size: 38),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.fullname,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF152349),
                          fontFamily: 'Montserrat',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, color: mainBlue, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            widget.phone,
                            style: TextStyle(
                              color: mainBlue,
                              fontWeight: FontWeight.w500,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.active == '1' ? 'Aktif' : 'Tidak Aktif',
                          style: TextStyle(
                            color: widget.active == '1' ? mainBlue : Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _ModernInfoTile(
            icon: Icons.account_circle,
            label: 'Username',
            value: widget.username,
          ),
          _ModernInfoTile(
            icon: Icons.email,
            label: 'Email',
            value: widget.email,
          ),
          _ModernInfoTile(
            icon: Icons.child_care,
            label: 'Tingkatan',
            value: widget.grade == '0' ? 'TK' : 'Kelas ${widget.grade}',
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: mainBlue.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              leading: Icon(Icons.school, color: mainBlue),
              title: const Text('Kelas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              trailing: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedClassName,
                  hint: const Text('Pilih Kelas'),
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
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Pilih Kelas', style: TextStyle(fontSize: 14)),
                      ),
                    ...classes.map<DropdownMenuItem<String>>((classRoom) {
                      return DropdownMenuItem<String>(
                        value: classRoom['name'],
                        child: Text(classRoom['name'], style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: mainBlue.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              leading: Icon(Icons.room, color: mainBlue),
              title: const Text('Sanggar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              trailing: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedBranchName,
                  hint: const Text('Pilih Sanggar'),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedBranchName = newValue;
                      selectedBranchId = branches.firstWhere(
                        (branch) => branch['name'] == newValue,
                        orElse: () => {'id': '', 'name': ''},
                      )['id'];
                    });
                  },
                  items: branches.map<DropdownMenuItem<String>>((branch) {
                    return DropdownMenuItem<String>(
                      value: branch['name'],
                      child: Text(branch['name'], style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: mainBlue.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              leading: Icon(
                isActive ? Icons.check_circle : Icons.cancel,
                color: isActive ? mainBlue : Colors.red,
              ),
              title: const Text('Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              trailing: Switch(
                value: isActive,
                activeColor: mainBlue,
                onChanged: (bool value) {
                  setState(() {
                    isActive = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _updateUser,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 6.0),
                child: Text(
                  'Update',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: mainBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ModernInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final Color mainBlue = const Color(0xFF152349);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: mainBlue.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: mainBlue),
        title: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }
}
