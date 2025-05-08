import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:semarnari_apk/services/apiServices.dart';
import 'package:semarnari_apk/login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic> data = {};
  final ApiService apiService = ApiService();
  bool _isLoading = true; // Default to true to show skeleton on load
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  GlobalKey<RefreshIndicatorState>();

  // Controllers for the password fields
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');

    if (username == null || username.isEmpty) {
      print("Username is null or empty!");
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      await Future.delayed(const Duration(milliseconds: 500)); // Simulate a delay

      final response =
      await apiService.post('user/get', {'username': username});
      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (responseBody['data'] != null && responseBody['data'].isNotEmpty) {
        final userData = responseBody['data'];

        setState(() {
          data = {
            'id': userData['id'] ?? 'Unknown ID',
            'username': userData['username'] ?? 'Guest',
            'email': userData['email'] ?? 'No email',
            'fullName': userData['fullname'] ?? 'No name',
            'branch': userData['branch_name'] ?? 'No Branch',
            'gender': userData['gender'] ?? 'Not specified',
            'date_of_birth': userData['date_of_birth'] ?? 'Not available',
            'religion': userData['religion'] ?? 'Not specified',
            'address': userData['address'] ?? 'No address',
            'photo': userData['photo'] ?? 'No photo',
            'active': userData['active'] == '1' ? 'Active' : 'Deactive',
            'created_at': userData['created_at'] ?? 'No Date',
            'grade': userData['grade'] ?? 'No grade',
            'photo': userData['photo'],
            'class_name': userData['class_name'],
          };
          _isLoading = false;
        });
      } else {
        print(responseBody['message'] ?? 'No data available');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to handle the change password action
  void _changePassword() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (username == null || username.isEmpty) {
      print("Username is null or empty!");
      return;
    }

    if (newPassword != confirmPassword) {
      print("New password and confirm password do not match!");
      return;
    }

    try {
      final response = await apiService.post('user/change_password', {
        'username': username,
        'old_password': oldPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      });

      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      if (responseBody['status'] == 'success') {
        // Password changed successfully
        _showBottomSheetAlert(
          context,
          "Password changed successfully!",
          Colors.green, // Success color
        );
      } else {
        // Failed to change password
        _showBottomSheetAlert(
          context,
          "Failed to change password: ${responseBody['message']}",
          Colors.red, // Error color
        );
      }
    } catch (e) {
      print("Error occurred: $e");
      // Show error message if the request fails
      _showBottomSheetAlert(
        context,
        "An error occurred. Please try again.",
        Colors.red, // Error color
      );
    }
  }

  void _showBottomSheetAlert(BuildContext context, String message, Color backgroundColor) {
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
                  backgroundColor == Colors.green ? Icons.check_circle : Icons.error,
                  size: 60,
                  color: backgroundColor,
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
                // Only show the button if the background color is green (success)
                if (backgroundColor == Colors.green)
                  ElevatedButton(
                    onPressed: () async{
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      Navigator.pop(context); // Close bottom sheet
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.green),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7), // Set border radius to 7px
                        ),
                      ),
                      minimumSize: WidgetStateProperty.all(const Size(double.infinity, 50)), // Full width and 50 height
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

  void _navigateToLoginPage(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/login'); // Navigate to login page
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
              Icons.account_circle_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _loadUserData,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _isLoading
                ? Skeletonizer(
              child: Column(
                children: [
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(
                    4,
                        (index) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        height: 20,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header Section
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF152349),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(
                          data['photo'] ??
                              'https://via.placeholder.com/150',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['fullName'] ?? 'No Name',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['email'] ?? 'No Email',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  data['active'] == 'Active'
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: data['active'] == 'Active'
                                      ? Colors.green
                                      : Colors.red,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  data['active'] ?? 'Unknown',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Details Section
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          icon: Icons.star,
                          label: 'Tingkat',
                          value: (int.tryParse(data['grade'].toString()) ?? 0) == 0
                              ? 'TK'
                              : (int.tryParse(data['grade'].toString()) ?? 0).toString(),
                        ),
                        _buildDetailRow(
                          icon: Icons.school,
                          label: 'Kelas',
                          value: data['class_name'] == null || data['class_name'].toString().isEmpty
                              ? 'Belum ditentukan'
                              : data['class_name'] ?? 'TK',  // Fallback to 'TK' if class_name is null
                        ),
                        _buildDetailRow(
                          icon: Icons.room,
                          label: 'Sanggar',
                          value: data['branch'] ?? 'No Branch',
                        ),
                        _buildDetailRow(
                          icon: Icons.cake,
                          label: 'Tanggal Lahir',
                          value: data['date_of_birth'] ?? 'No Date',
                        ),
                        _buildDetailRow(
                          icon: Icons.account_balance,
                          label: 'Agama',
                          value: data['religion'] ?? 'Not specified',
                        ),
                        _buildDetailRow(
                          icon: Icons.date_range,
                          label: 'Bergabung Pada',
                          value: data['created_at'] != null
                              ? DateFormat.yMMMMd().format(DateTime.parse(data['created_at']))
                              : 'No Date',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Change Password Section
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ganti Password',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _oldPasswordController,
                          decoration: const InputDecoration(
                            labelText: 'Password Lama',
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _newPasswordController,
                          decoration: const InputDecoration(
                            labelText: 'Password Baru',
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _confirmPasswordController,
                          decoration: const InputDecoration(
                            labelText: 'Konfirmasi Password',
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text('Change Password', style: TextStyle(
                            color: Colors.white
                          ),),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
