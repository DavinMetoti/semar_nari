import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers for input fields
  TextEditingController idController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController fullnameController = TextEditingController();
  TextEditingController nisController = TextEditingController();
  TextEditingController branchController = TextEditingController();
  TextEditingController classIdController = TextEditingController();
  TextEditingController dateOfBirthController = TextEditingController();
  TextEditingController religionController = TextEditingController();
  TextEditingController fatherNameController = TextEditingController();
  TextEditingController motherNameController = TextEditingController();
  TextEditingController parentPhoneController = TextEditingController();
  TextEditingController childPhoneController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController reasonForJoiningController = TextEditingController();
  TextEditingController gradeController = TextEditingController();

  // Flags and data
  bool isLoading = false;
  String? username;
  int? activeStatus;
  int? accessRole; // 1 for "Siswa", 2 for "Guru"

  // Gender and Nationality dropdown values
  String? genderValue = 'M'; // M for Male, F for Female
  String? nationalityValue = 'WNI'; // WNI for Indonesian, WNA for Foreign

  bool isFlipped = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  // Tambahkan daftar kelas
  final Map<String, String> gradeOptions = {
    'TK': '0',
    'Kelas 1': '1',
    'Kelas 2': '2',
    'Kelas 3': '3',
    'Kelas 4': '4',
    'Kelas 5': '5',
    'Kelas 6': '6',
  };

  @override
  void initState() {
    super.initState();
    _getUsernameFromSharedPreferences();
    _controller = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Fetch username from SharedPreferences
  Future<void> _getUsernameFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username');
    });

    if (username != null) {
      fetchStudentData();
    }
  }

  // Fetch the student data from API (for pre-filling the form)
  Future<void> fetchStudentData() async {
    if (username == null) return;

    setState(() {
      isLoading = true;
    });

    final response = await http.post(
      Uri.parse('https://semarnari.sportballnesia.com/api/master/user/get'),
      body: json.encode({'username': username}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final student = data['data'];

      setState(() {
        // Set initial values from fetched data
        usernameController.text = student['username'] ?? '';
        idController.text = student['id'] ?? '';
        emailController.text = student['email'] ?? '';
        fullnameController.text = student['fullname'] ?? '';
        nisController.text = student['nis'] ?? '';
        branchController.text = student['branch_name'] ?? '';
        classIdController.text = student['class_name'] ?? 'Belum ditentukan';
        dateOfBirthController.text = student['date_of_birth'] ?? '';
        religionController.text = student['religion'] ?? '';
        fatherNameController.text = student['father_name'] ?? '';
        motherNameController.text = student['mother_name'] ?? '';
        parentPhoneController.text = student['parent_phone_number'] ?? '';
        childPhoneController.text = student['child_phone_number'] ?? '';
        addressController.text = student['address'] ?? '';
        reasonForJoiningController.text = student['reason_for_joining'] ?? '';
        gradeController.text = student['grade'] ?? '';
        accessRole = int.tryParse(student['access_role'].toString()) ?? 1;
        activeStatus = int.tryParse(student['active'].toString());
        genderValue = student['gender'] ?? 'M';
        nationalityValue = student['nationality'] ?? 'WNI';

        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Handle form submission
  Future<void> submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      // Prepare the data for the update
      final data = {
        'id': idController.text,
        'fullname': fullnameController.text,
        'gender': genderValue,
        'date_of_birth': dateOfBirthController.text,
        'religion': religionController.text,
        'nationality': nationalityValue,
        'father_name': fatherNameController.text,
        'mother_name': motherNameController.text,
        'parent_phone_number': parentPhoneController.text,
        'child_phone_number': childPhoneController.text,
        'address': addressController.text,
        'reason_for_joining': reasonForJoiningController.text,
        'grade': gradeController.text,
      };

      final response = await http.post(
        Uri.parse('https://semarnari.sportballnesia.com/api/master/user/update'),
        body: json.encode(data),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully!')));
        // Flip card and fetch user data again, do not pop
        setState(() {
          isFlipped = false;
        });
        _controller.reverse();
        await fetchStudentData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile!')));
      }

      setState(() {
        isLoading = false;
      });
    }
  }

  // Method to show Date Picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != DateTime.now()) {
      setState(() {
        dateOfBirthController.text = "${picked.toLocal()}".split(' ')[0]; // Format the date as yyyy-mm-dd
      });
    }
  }

  void flipCard() {
    setState(() {
      isFlipped = !isFlipped;
      if (isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
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
      body: Container(
        color: Colors.white,
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: flipCard,
                      child: AnimatedSize(
                        duration: Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        child: AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            final isBack = _animation.value > 0.5;
                            final angle = _animation.value * 3.1416;
                            return Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateY(angle),
                              child: isBack
                                  ? Transform(
                                      alignment: Alignment.center,
                                      transform: Matrix4.identity()..rotateY(3.1416),
                                      child: buildEditFormCard(theme),
                                    )
                                  : buildProfileCard(theme),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  // Instruction text instead of buttons
                  SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Klik kartu untuk ${isFlipped ? "kembali melihat profil" : "edit profil"}',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  // "Simpan Perubahan" button, only show when editing, closer to card
                  if (isFlipped)
                    Padding(
                      padding: const EdgeInsets.only(top: 18.0, bottom: 0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: submitForm,
                          icon: Icon(Icons.save_rounded, color: Colors.white),
                          label: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Text(
                              'Simpan Perubahan',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: 8),
                ],
              ),
      ),
    );
  }

  Widget buildProfileCard(ThemeData theme) {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      margin: EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB6E0FE), Color(0xFF398FE5)], // Soft blue gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFB6E0FE), Color(0xFF398FE5)],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 54, color: theme.primaryColor),
                  ),
                ),
              ),
              SizedBox(height: 22),
              buildReadOnlyField('Username', usernameController),
              buildReadOnlyField('Email', emailController),
              buildReadOnlyField('NIS', nisController),
              buildReadOnlyField('Sanggar', branchController),
              buildReadOnlyField(
                'Kelas',
                TextEditingController(
                  text: gradeOptions.entries
                          .firstWhere(
                            (e) => e.value == gradeController.text,
                            orElse: () => MapEntry('TK', '0'),
                          )
                          .key,
                ),
              ),
              buildReadOnlyField('Ruang Kelas', classIdController),
              SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    avatar: Icon(
                      Icons.check_circle,
                      color: activeStatus == 1 ? Colors.blue : Colors.red,
                      size: 20,
                    ),
                    label: Text(
                      activeStatus == 1 ? 'Aktif' : 'Tidak Aktif',
                      style: TextStyle(
                        color: activeStatus == 1 ? Colors.blue : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: (activeStatus == 1 ? Colors.blue[50] : Colors.red[50]),
                  ),
                  Chip(
                    avatar: Icon(
                      Icons.account_circle,
                      color: accessRole == 1 ? Colors.blue : Colors.orange,
                      size: 20,
                    ),
                    label: Text(
                      accessRole == 1 ? 'Siswa' : 'Guru',
                      style: TextStyle(
                        color: accessRole == 1 ? Colors.blue : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: (accessRole == 1 ? Colors.blue[50] : Colors.orange[50]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildEditFormCard(ThemeData theme) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              buildTextField('Nama Lengkap', fullnameController),
              buildDropdownField(
                'Jenis Kelamin',
                {'Laki-laki': 'M', 'Perempuan': 'F'},
                (value) => setState(() => genderValue = value),
                genderValue,
              ),
              buildDropdownField(
                'Kewarganegaraan',
                {'WNI': 'WNI', 'WNA': 'WNA'},
                (value) => setState(() => nationalityValue = value),
                nationalityValue,
              ),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: buildTextField('Tanggal Lahir', dateOfBirthController),
                ),
              ),
              buildTextField('Agama', religionController),
              buildTextField('Nama Ayah', fatherNameController),
              buildTextField('Nama Ibu', motherNameController),
              buildTextField('Nomor Telepon Orang Tua', parentPhoneController),
              buildTextField('Nomor Telepon Anak', childPhoneController),
              buildTextField('Alamat', addressController), // "pangan" as input
              buildTextField('Alasan Bergabung', reasonForJoiningController),
              buildDropdownField(
                'Kelas',
                gradeOptions,
                (value) {
                  setState(() {
                    gradeController.text = value ?? '0';
                  });
                },
                gradeController.text.isEmpty ? '0' : gradeController.text,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for read-only fields (non-editable)
  Widget buildReadOnlyField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        enabled: false,
        style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.blueGrey[400], fontWeight: FontWeight.w500),
          filled: true,
          fillColor: Color(0xFFF2F2F2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // Helper for editable text fields
  Widget buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.blueGrey[400], fontWeight: FontWeight.w500),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        style: TextStyle(fontSize: 16),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label wajib diisi';
          }
          return null;
        },
      ),
    );
  }

  // Helper for dropdown fields
  Widget buildDropdownField(String label, Map<String, String> items, Function(String?) onChanged, String? selectedValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.blueGrey[400], fontWeight: FontWeight.w500),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        value: selectedValue,
        onChanged: onChanged,
        items: items.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.value,
            child: Text(entry.key, style: TextStyle(fontSize: 16)),
          );
        }).toList(),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label wajib diisi';
          }
          return null;
        },
      ),
    );
  }
}
