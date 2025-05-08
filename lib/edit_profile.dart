import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
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

  @override
  void initState() {
    super.initState();
    _getUsernameFromSharedPreferences();
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
      };

      final response = await http.post(
        Uri.parse('https://semarnari.sportballnesia.com/api/master/user/update'),
        body: json.encode(data),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully!')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile!')));
        print(response.body);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profil'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                elevation: 5,
                margin: EdgeInsets.symmetric(vertical: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Username: ${usernameController.text}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Email: ${emailController.text}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'NIS: ${nisController.text}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Sanggar: ${branchController.text}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Kelas: ${gradeController.text}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Ruang Kelas: ${classIdController.text}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: activeStatus == 1 ? Colors.green : Colors.red,
                              ),
                              SizedBox(width: 8),
                              Text(
                                activeStatus == 1 ? 'Aktif' : 'Tidak Aktif',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.account_circle,
                                color: accessRole == 1 ? Colors.blue : Colors.orange,
                              ),
                              SizedBox(width: 8),
                              Text(
                                accessRole == 1 ? 'Siswa' : 'Guru',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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
              buildTextField('Alamat', addressController),
              buildTextField('Alasan Bergabung', reasonForJoiningController),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: submitForm,
                child: Text('Simpan Perubahan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for text fields
  Widget buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label wajib diisi';
          }
          return null;
        },
      ),
    );
  }

  // Helper method for dropdown fields
  Widget buildDropdownField(String label, Map<String, String> items, Function(String?) onChanged, String? selectedValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: label),
        value: selectedValue,
        onChanged: onChanged,
        items: items.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.value,
            child: Text(entry.key),
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
