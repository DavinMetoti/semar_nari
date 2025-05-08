import 'package:flutter/material.dart';
import 'package:semarnari_apk/services/apiServices.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final ApiService apiService = ApiService();
  bool isChecked = false;
  String? selectedBranch;
  String? selectedGender;
  int? selectedGrade;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _gradeController = TextEditingController();
  final _genderController = TextEditingController();
  final _branchController = TextEditingController();
  final _reasonController = TextEditingController();
  final _phoneController = TextEditingController();
  List<dynamic> branches = [];

  @override
  void initState() {
    super.initState();
    fetchBranches();
  }

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

  void _navigateToLoginPage(BuildContext context) {
    Navigator.pop(context);
  }

  Future<void> registerUser() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final gradeString = _gradeController.text.trim();
    final gender = _genderController.text.trim();
    final branch = _branchController.text.trim();
    final reason = _reasonController.text.trim();
    final phone = _phoneController.text.trim();

    // Validate if passwords match
    if (password != confirmPassword) {
      showErrorBottomSheet(
        context,
        "Password doesn't match",
      );
      return; // Exit if validation fails
    }

    // Validate if terms are accepted and a branch is selected
    if (!isChecked || selectedBranch == null || selectedGrade == null) {
      showErrorBottomSheet(
        context,
        'Please accept the agreement, select a branch, and enter grade',
      );
      return; // Exit if validation fails
    }

    try {
      final response = await apiService.register(
        name,
        email,
        username,
        password,
        selectedBranch!,
        selectedGrade!,
        selectedGender!,
        reason,
        phone,
      );

      print('Response: $response');

      if (response['status'] == 'success') {
        showSuccessBottomSheet(
          context,
          'Registration successful. Please log in to continue.',
        );
      } else {
        // Extract error message from the response
        String errorMessage = 'An error occurred';
        if (response['message'] is Map) {
          errorMessage = response['message']['username'] ??
              response['message'].values.first.toString();
        } else if (response['message'] is String) {
          errorMessage = response['message'];
        }

        // Show error in bottom sheet
        showErrorBottomSheet(
          context,
          errorMessage,
        );
      }
    } catch (e, stackTrace) {
      // Handle exceptions and show error in bottom sheet
      showErrorBottomSheet(
        context,
        'Error: $e',
      );
      print('Error: $e');
      print('Stack Trace: $stackTrace');
    }
  }


  void showSuccessBottomSheet(BuildContext context, String message) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        return SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                Icon(
                  Icons.check_circle,
                  size: 60,
                  color: Colors.green,
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close bottom sheet
                    _navigateToLoginPage(context); // Navigate to login page
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.green),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7), // Set border radius to 7px
                      ),
                    ),
                    minimumSize: MaterialStateProperty.all(const Size(double.infinity, 50)), // Full width and 50 height
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void showErrorBottomSheet(BuildContext context, String message) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        return SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                Icon(
                  Icons.error,
                  size: 60,
                  color: Colors.red,
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close bottom sheet
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.red),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    minimumSize: MaterialStateProperty.all(const Size(double.infinity, 50)),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFFDFFF8),
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/bg-apk2.jpeg"), // Path gambar
                  fit: BoxFit.cover, // Menutupi seluruh layar
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 250),
              child: Card(
                color: Colors.white.withOpacity(0.7), // Transparansi 20%
                elevation: 5, // Menambahkan efek bayangan
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                "Registrasi",
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Color(0xFF152349),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 40),
                              // Name Input Field
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Name',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Email Input Field
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 20),
                              // Username Input Field
                              TextFormField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Password Input Field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Confirm Password Input Field
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Confirm Password',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Branch Selection Dropdown
                              DropdownButtonFormField<String>(
                                value: selectedBranch,
                                hint: const Text('Select Branch'),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                                items: branches.map<DropdownMenuItem<String>>((branch) {
                                  return DropdownMenuItem<String>(
                                    value: branch['id'].toString(),
                                    child: Text(branch['name'], style: TextStyle(fontSize: 16)),
                                  );
                                }).toList(),
                                onChanged: (String? value) {
                                  setState(() {
                                    selectedBranch = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 20),
                              // Grade Input Field
                              DropdownButtonFormField<int>(
                                value: selectedGrade,
                                hint: const Text('Select Grade'),
                                items: [
                                  DropdownMenuItem<int>(
                                    value: 0,
                                    child: Text('TK'),
                                  ),
                                  DropdownMenuItem<int>(
                                    value: 1,
                                    child: Text('Kelas 1'),
                                  ),
                                  DropdownMenuItem<int>(
                                    value: 2,
                                    child: Text('Kelas 2'),
                                  ),
                                  DropdownMenuItem<int>(
                                    value: 3,
                                    child: Text('Kelas 3'),
                                  ),
                                  DropdownMenuItem<int>(
                                    value: 4,
                                    child: Text('Kelas 4'),
                                  ),
                                  DropdownMenuItem<int>(
                                    value: 5,
                                    child: Text('Kelas 5'),
                                  ),
                                  DropdownMenuItem<int>(
                                    value: 6,
                                    child: Text('Kelas 6'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    selectedGrade = value;
                                  });
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Gender',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 20),
                              DropdownButtonFormField<String>(
                                value: selectedGender,
                                hint: const Text('Select Gender'),
                                items: [
                                  DropdownMenuItem<String>(
                                    value: "M",
                                    child: Text('Laki-laki'),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: "F",
                                    child: Text('Perempuan'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    selectedGender = value;
                                  });
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Grade',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _reasonController,
                                decoration: const InputDecoration(
                                  labelText: 'Alasan Bergabung',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _phoneController,
                                decoration: const InputDecoration(
                                  labelText: 'No. Telp',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Checkbox(
                                    value: isChecked,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        isChecked = value!;
                                      });
                                    },
                                  ),
                                  const Expanded(  // Wrap the Text widget with Expanded to allow wrapping
                                    child: Text(
                                      'bersèdia mentaati segala peraturan yg ada di sanggar baik jadwal pelatihan, kurikulum ataupun biaya2 dan kegìatan2 diluar sanggar',
                                      softWrap: true,  // Allow text to wrap when it exceeds the container width
                                      overflow: TextOverflow.visible,  // Allow the text to be fully visible if it overflows
                                      style: TextStyle(
                                        fontSize: 12,  // Adjust font size if necessary
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Register Button
                              ElevatedButton(
                                onPressed: registerUser,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF152349),
                                  padding: const EdgeInsets.all(10.0),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.white,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                ),
                                child: const Text('Register', style: TextStyle(color: Colors.white)),
                              ),
                              const SizedBox(height: 20),
                              // Login Link
                              TextButton(
                                onPressed: () => _navigateToLoginPage(context),
                                child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Sudah punya akun? ",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF152349),
                                    ),
                                  ),
                                  Text(
                                    "Login sekarang",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
