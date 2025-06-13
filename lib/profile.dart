import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:ui'; // Tambahkan untuk efek glassmorphism
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:semarnari_apk/services/apiServices.dart';
import 'package:semarnari_apk/login.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http; // Tambahkan untuk http upload
import 'package:mime/mime.dart';

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
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');

    if (username == null || username.isEmpty) {
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
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
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
      return;
    }

    if (newPassword != confirmPassword) {
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
                    onPressed: () async {
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

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile == null) return;

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();

      final mimeType = lookupMimeType(pickedFile.path);
      if (mimeType == null || !mimeType.startsWith('image/')) {
        _showBottomSheetAlert(context, "File yang dipilih bukan gambar yang valid!", Colors.red);
        return;
      }

      final photoBase64 = 'data:$mimeType;base64,${base64Encode(bytes)}';

      // Ambil username dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');

      if (username == null || username.isEmpty) {
        _showBottomSheetAlert(context, "Username tidak ditemukan!", Colors.red);
        return;
      }

      // Ambil account_id berdasarkan username
      final responseUser = await apiService.post('user/get', {'username': username});
      final responseBodyUser = jsonDecode(responseUser.body);

      if (responseUser.statusCode != 200 || responseBodyUser['data'] == null) {
        _showBottomSheetAlert(context, "Gagal mengambil data user!", Colors.red);
        return;
      }

      final accountId = responseBodyUser['data']['id'];

      // Kirim foto ke server
      final url = Uri.parse('https://semarnari.sportballnesia.com/api/master/user/update_photo_profile');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'account_id': accountId,
          'photo_base64': photoBase64,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == true) {
        _showBottomSheetAlert(context, "Foto profil berhasil diupdate!", Colors.green);
        await _loadUserData();
      } else {
        final msg = responseBody['message'] ?? "Gagal update foto.";
        _showBottomSheetAlert(context, "Gagal update foto: $msg", Colors.red);
      }
    } catch (e) {
      _showBottomSheetAlert(context, "Terjadi kesalahan saat upload foto.", Colors.red);
    } finally {
      setState(() {
        _isUploadingPhoto = false;
      });
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: double.infinity,
                          height: 140,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF152349),
                                Color(0xFF31416A),
                                Color(0xFF5B6BAA),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(20.0),
                            height: 140,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.15),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 44,
                                        backgroundColor: Colors.white,
                                        child: (data['photo'] != null &&
                                                data['photo'].toString().isNotEmpty)
                                            ? (() {
                                                final photo = data['photo'].toString();
                                                if (photo.startsWith('data:image/')) {
                                                  // Extract base64 string
                                                  final base64Str = photo.split(',').last;
                                                  try {
                                                    return ClipOval(
                                                      child: Image.memory(
                                                        base64Decode(base64Str),
                                                        width: 84,
                                                        height: 84,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    );
                                                  } catch (_) {
                                                    return Icon(
                                                      Icons.account_circle,
                                                      size: 84,
                                                      color: Colors.grey.shade300,
                                                    );
                                                  }
                                                } else {
                                                  return ClipOval(
                                                    child: Image.network(
                                                      photo,
                                                      width: 84,
                                                      height: 84,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) => Icon(
                                                        Icons.account_circle,
                                                        size: 84,
                                                        color: Colors.grey.shade300,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              })()
                                            : Icon(
                                                Icons.account_circle,
                                                size: 84,
                                                color: Colors.grey.shade300,
                                              ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black12,
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.all(6),
                                          child: _isUploadingPhoto
                                              ? SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                              : Icon(Icons.camera_alt, color: Color(0xFF31416A), size: 20),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 22),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        data['fullName'] ?? 'No Name',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 20,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.email_outlined,
                                            color: Colors.white70,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              data['email'] ?? 'No Email',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 13,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: data['active'] == 'Active'
                                              ? Colors.green.withOpacity(0.15)
                                              : Colors.red.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
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
                                              style: TextStyle(
                                                color: data['active'] == 'Active'
                                                    ? Colors.green
                                                    : Colors.red,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
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
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Details Section
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 18.0),
                          child: Column(
                            children: [
                              _buildDetailRow(
                                icon: Icons.star_rounded,
                                label: 'Tingkat',
                                value: (int.tryParse(data['grade'].toString()) ?? 0) == 0
                                    ? 'TK'
                                    : (int.tryParse(data['grade'].toString()) ?? 0).toString(),
                              ),
                              _buildDetailRow(
                                icon: Icons.class_outlined,
                                label: 'Kelas',
                                value: data['class_name'] == null || data['class_name'].toString().isEmpty
                                    ? 'Belum ditentukan'
                                    : data['class_name'] ?? 'TK',
                              ),
                              _buildDetailRow(
                                icon: Icons.location_on_outlined,
                                label: 'Sanggar',
                                value: data['branch'] ?? 'No Branch',
                              ),
                              _buildDetailRow(
                                icon: Icons.cake_outlined,
                                label: 'Tanggal Lahir',
                                value: data['date_of_birth'] ?? 'No Date',
                              ),
                              _buildDetailRow(
                                icon: Icons.account_balance_outlined,
                                label: 'Agama',
                                value: data['religion'] ?? 'Not specified',
                              ),
                              _buildDetailRow(
                                icon: Icons.calendar_month_outlined,
                                label: 'Bergabung',
                                value: data['created_at'] != null
                                    ? DateFormat.yMMMMd().format(DateTime.parse(data['created_at']))
                                    : 'No Date',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Change Password Section
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 18.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ganti Password',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF152349),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _oldPasswordController,
                                decoration: InputDecoration(
                                  labelText: 'Password Lama',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                obscureText: true,
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _newPasswordController,
                                decoration: InputDecoration(
                                  labelText: 'Password Baru',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                obscureText: true,
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _confirmPasswordController,
                                decoration: InputDecoration(
                                  labelText: 'Konfirmasi Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                obscureText: true,
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: _changePassword,
                                  icon: const Icon(Icons.save_alt, color: Colors.white),
                                  label: const Text(
                                    'Change Password',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF152349),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
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
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F8),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(7),
            child: Icon(icon, size: 20, color: const Color(0xFF31416A)),
          ),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF31416A),
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                color: Color(0xFF31416A),
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
