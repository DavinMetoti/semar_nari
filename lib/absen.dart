import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:semarnari_apk/services/apiServices.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';


class AbsenPage extends StatefulWidget {
  const AbsenPage({super.key});

  @override
  _AbsenPageState createState() => _AbsenPageState();
}

class _AbsenPageState extends State<AbsenPage> {
  final List<Map<String, dynamic>> _absenList = [];
  final ImagePicker _picker = ImagePicker();
  final ApiService apiService = ApiService();

  String? _selectedType;
  String? _fullName;
  String? _userID;
  String? _branchName;
  double? _branchLatitude;
  double? _branchLongitude;
  late Timer _timer;
  late DateTime _currentTime;
  bool _isLoading = false;
  List<Map<String, dynamic>> attendanceData = [];
  Map<String, dynamic> data = {};
  bool isAttendanceLoaded = false;

  double? _latitude;
  double? _longitude;
  double? _distanceToBranch;

  @override
  void initState() {
    super.initState();

    _fetchUserDataAndLocation(); // Gabungkan load data dan lokasi

    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    Future.delayed(const Duration(seconds: 300), () {
      if (mounted) _loadAttendanceUser();
    });
  }

  Future<void> _fetchUserDataAndLocation() async {
    await _loadUserData(); // Load user data lebih dulu
    await _getCurrentLocation(); // Baru ambil lokasi setelah data user selesai
  }

  @override
  void dispose() {
    _timer?.cancel(); // Pastikan timer dihentikan saat widget dihapus
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    if (username == null) return;

    try {
      final response = await apiService.post('user/get', {'username': username});
      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (responseBody['data'] != null && responseBody['data'].isNotEmpty) {
        final newFullName = responseBody['data']['fullname'] ?? 'Guest';
        final newUserID = responseBody['data']['id'] ?? 0;
        final newBranchName = responseBody['data']['branch_name'] ?? 'Unknown';
        final newLatitude = double.tryParse(responseBody['data']['latitude']?.toString() ?? '') ?? 0.0;
        final newLongitude = double.tryParse(responseBody['data']['longitude']?.toString() ?? '') ?? 0.0;

        // ✅ Update state hanya jika ada perubahan
        if (newFullName != _fullName || newUserID != _userID ||
            newBranchName != _branchName || newLatitude != _branchLatitude ||
            newLongitude != _branchLongitude) {

          setState(() {
            _fullName = newFullName;
            _userID = newUserID;
            _branchName = newBranchName;
            _branchLatitude = newLatitude;
            _branchLongitude = newLongitude;
          });
        }

        _loadAttendanceUser();
      }
    } catch (e) {
      debugPrint("Error saat mengambil data user: $e");
    }
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _calculateDistance();
      });
    } catch (e) {
      print("Error mendapatkan lokasi: $e");
    }
  }

  // Calculate distance between current location and branch
  void _calculateDistance() {
    if (_branchLatitude != null && _branchLongitude != null && _latitude != null && _longitude != null) {
      const double radiusEarth = 6371000; // Radius bumi dalam meter
      double dLat = _degreeToRadian(_latitude! - _branchLatitude!);
      double dLon = _degreeToRadian(_longitude! - _branchLongitude!);

      double a = sin(dLat / 2) * sin(dLat / 2) +
          cos(_degreeToRadian(_branchLatitude!)) *
              cos(_degreeToRadian(_latitude!)) *
              sin(dLon / 2) *
              sin(dLon / 2);
      double c = 2 * atan2(sqrt(a), sqrt(1 - a));
      double distance = radiusEarth * c;

      setState(() {
        _distanceToBranch = distance;
        if (_distanceToBranch! > 100) {
          _selectedType = null; // Reset dropdown jika terlalu jauh
        }
      });
    }
  }

  Future<void> _loadAttendanceUser() async {
    try {
      if (_userID == null) {
        debugPrint('Error: _userID is null');
        return;
      }

      final response = await apiService.post('user/get_attendance_history', {
        "user_id": _userID,
      });

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final responseBody = jsonDecode(response.body);
        debugPrint('Response body: ${response.body}');

        if (responseBody['status'] == true && responseBody['data'] is List) {
          final List<Map<String, dynamic>> newAttendanceData =
          List<Map<String, dynamic>>.from(responseBody['data']); // ✅ Pastikan tipe datanya sesuai

          // ✅ Hanya update jika ada perubahan data
          if (!listEquals(attendanceData, newAttendanceData)) {
            setState(() {
              attendanceData = newAttendanceData;
              isAttendanceLoaded = true;
            });
          } else {
            setState(() {
              isAttendanceLoaded = true;
            });
          }

          debugPrint('Attendance Data Loaded: $attendanceData');
        } else {
          debugPrint('Failed to load attendance data: ${responseBody['message'] ?? 'Unknown error'}');
          if (mounted) {
            setState(() {
              isAttendanceLoaded = true;
            });
          }
        }
      } else {
        debugPrint('Server error: ${response.statusCode}');
        if (mounted) {
          setState(() {
            isAttendanceLoaded = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading attendance: $e');
      if (mounted) {
        setState(() {
          isAttendanceLoaded = true;
        });
      }
    }
  }
  // Convert degree to radian
  double _degreeToRadian(double degree) {
    return degree * pi / 180;
  }

  // Refresh data
  Future<void> _refreshData() async {
    await _loadUserData();
    await _getCurrentLocation();
    setState(() {
      _absenList.removeAt(0);
    });
    print('data refresh');
  }

  // Add attendance
  void _addAttendance(File? image) {
    if (_selectedType != null && _fullName != null) {
      setState(() {
        _absenList.add({
          'type': _selectedType,
          'name': _fullName,
          'time': DateTime.now(),
          'image': image,
        });
        _selectedType = null; // Reset dropdown
      });
    }
  }

  // Take picture using camera
  Future<void> _takePicture() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      File image = File(pickedFile.path);
      _addAttendance(image);
    }
  }

  // Delete attendance
  void _deleteAttendance(int index) {
    setState(() {
      _absenList.removeAt(index);
    });
  }

  // Save attendance to API
  Future<void> _saveAttendance(int index) async {
    String? compressedPhoto;

    if (index < 0 || index >= _absenList.length) {
      _showBottomSheetAlert(context, "Index tidak valid", Colors.red);
      return;
    }

    final attendance = _absenList[index];

    // Show loading screen and disable user interaction
    setState(() {
      _isLoading = true;
    });

    if (attendance['image'] != null) {
      final imageBytes = attendance['image'].readAsBytesSync();
      final originalImage = img.decodeImage(imageBytes);

      if (originalImage != null) {
        final resizedImage = img.copyResize(originalImage, width: 800);
        final compressedImageBytes = img.encodeJpg(resizedImage, quality: 75);
        compressedPhoto = base64Encode(compressedImageBytes);
      }
    }

    try {
      final response = await apiService.post('user/attendance', {
        "user_id": _userID,
        "attendance_date": DateFormat('yyyy-MM-dd').format(_currentTime),
        "check_in_time": DateFormat('HH:mm:ss').format(attendance['time']),
        "status": attendance['type'],
        "remarks": "",
        "photo": (compressedPhoto != null && compressedPhoto.isNotEmpty) ? compressedPhoto : null,
        "location": _branchName,
      });

      final responseBody = jsonDecode(response.body);
      print('Response body: ${response.body}');

      if (response.statusCode == 201 && responseBody['status'] == 'success') {
        _showBottomSheetAlert(context, "${responseBody['message']}", Colors.green);
        // Remove from list after saving
        setState(() {
          _absenList.removeAt(index);
        });
      } else {
        _showBottomSheetAlert(context, "Gagal menyimpan attendance: ${responseBody['message']}", Colors.red);
      }
    } catch (e) {
      _showBottomSheetAlert(context, "Error saat menyimpan attendance: $e", Colors.red);
      print(e);
    } finally {
      // Hide loading screen and re-enable user interaction
      setState(() {
        _isLoading = false;
      });
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
              ],
            ),
          ),
        );
      },
    );
  }

  // Show image in dialog
  void _showImage(File image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(image),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }

  // Check if already attended with a certain type
  bool _isAlreadyAbsen(String type) {
    return _absenList.any((item) => item['type'] == type);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
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
              Icons.camera_alt_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(0.0),
              children: [
                SizedBox(
                  key: const ValueKey(1),
                  height: 250, // Sesuaikan tinggi container pertama untuk mengakomodasi elemen bertumpuk
                  width: double.infinity,
                  child: Stack(
                    clipBehavior: Clip.none, // Izinkan elemen keluar dari batas Stack
                    children: [
                      Container(
                        height: 150,
                        decoration: const BoxDecoration(
                          color: Color(0xFF152349),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(7),
                            bottomRight: Radius.circular(7),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$_fullName',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '$_branchName',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w300,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 2.0),
                                decoration: BoxDecoration(
                                  color: _distanceToBranch != null && _distanceToBranch! > 50
                                      ? Colors.red
                                      : Colors.green,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Text(
                                  _distanceToBranch != null
                                      ? "${_distanceToBranch!.toStringAsFixed(2)} m"
                                      : "Menghitung...",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 60, // Posisi setengah masuk ke dalam container pertama
                        left: 16,
                        right: 16,
                        key: const ValueKey(1),
                        child: Visibility(
                          visible: true,
                          child: Container(
                            height: 190,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4), // Warna bayangan dengan transparansi
                                  offset: const Offset(2, 2), // Posisi bayangan (horizontal, vertical)
                                  blurRadius: 7, // Tingkat blur bayangan
                                  spreadRadius: 0.2, // Penyebaran bayangan
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today,
                                            color: Colors.blue,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6), // Memberi jarak antara ikon dan teks
                                          Text(
                                            DateFormat('dd MMM yyyy').format(_currentTime),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black,
                                                fontWeight: FontWeight.bold
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.access_time,
                                            color: Colors.blue,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6), // Memberi jarak antara ikon dan teks
                                          Text(
                                            DateFormat('HH:mm').format(_currentTime),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10,),
                                  Container(
                                    child: Column(
                                      children: _absenList.map((attendance) {
                                        return InkWell(
                                          onTap: () {
                                            if (attendance['image'] != null) {
                                              _showImage(attendance['image']!);
                                            }
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Gambar Bulat (jika ada)
                                                if (attendance['image'] != null)
                                                  ClipOval(
                                                    child: Image.file(
                                                      attendance['image']!,
                                                      width: 50,
                                                      height: 50,
                                                      fit: BoxFit.cover, // Memastikan gambar terpotong dengan baik dalam bentuk bulat
                                                    ),
                                                  )
                                                else
                                                  CircleAvatar(
                                                    radius: 25,
                                                    backgroundColor: Colors.grey[300], // Placeholder jika tidak ada gambar
                                                    child: Icon(
                                                      Icons.person,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),

                                                const SizedBox(width: 16),

                                                // Kolom untuk Detail Kehadiran
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                                                            decoration: BoxDecoration(
                                                              color: attendance['type'] == 'Absen'
                                                                  ? Colors.green
                                                                  : attendance['type'] == 'Ijin'
                                                                  ? Colors.orange
                                                                  : Colors.red, // Warna berdasarkan tipe
                                                              borderRadius: BorderRadius.circular(4),
                                                            ),
                                                            child: Text(
                                                              "${attendance['type']}", // Tampilkan tipe kehadiran
                                                              style: const TextStyle(
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.white,
                                                                fontSize: 16,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        DateFormat('dd MMM yyyy HH:mm:ss').format(attendance['time']),
                                                        style: const TextStyle(fontSize: 12),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                // Tombol Hapus
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red, // Warna ikon hapus
                                                  ),
                                                  onPressed: () {
                                                    _deleteAttendance(_absenList.indexOf(attendance));
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  const SizedBox(height: 10), // Memberi jarak antara ikon dan teks
                                  if (_absenList.isEmpty)
                                    DropdownButtonFormField<String>(
                                      value: _selectedType,
                                      decoration: const InputDecoration(
                                        labelText: 'Pilih Tipe Kehadiran',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: ['Absen', 'Ijin', 'Sakit']
                                          .map((type) => DropdownMenuItem<String>(
                                        value: type,
                                        child: Text(type),
                                      ))
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedType = value;
                                        });
                                      },
                                    ),
                                  if (_absenList.isEmpty)
                                    const SizedBox(height: 10),
                                  if ((_distanceToBranch == null || _distanceToBranch! <= 50) && (_selectedType != null && _absenList.isEmpty))
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: (_fullName != null && !_isAlreadyAbsen(_selectedType!))
                                            ? (_selectedType == 'Absen'
                                            ? _takePicture
                                            : () => _addAttendance(null))
                                            : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          padding: const EdgeInsets.all(10.0),
                                          textStyle: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(7),
                                          ),
                                        ),
                                        child: Text(
                                            _isAlreadyAbsen(_selectedType!)
                                                ? 'Sudah Absen'
                                                : (_selectedType == 'Absen'
                                                ? 'Tambahkan Absen'
                                                : 'Tambahkan Absen'),
                                            style: const TextStyle(color: Colors.white)
                                        ),
                                      ),
                                    ),
                                  if (_distanceToBranch != null && _distanceToBranch! > 50 && _selectedType == 'Absen' )
                                    const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(width: 4),
                                        Flexible(
                                          flex: 1,
                                          child: Text(
                                            "Oops! You're too far from the location. Pull down to update your position.",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.red,
                                              fontStyle: FontStyle.italic,
                                            ),
                                            textAlign: TextAlign.center,
                                            softWrap: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (_absenList.isNotEmpty || _selectedType == 'Ijin' || _selectedType == 'Sakit')
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          _addAttendance(null); // Panggil fungsi dengan benar

                                          if (_absenList.isNotEmpty) {
                                            int indexToSave = 0;
                                            _saveAttendance(indexToSave);
                                          } else {
                                            print("Tidak ada data absen untuk disimpan.");
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          padding: const EdgeInsets.all(10.0),
                                          textStyle: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(7),
                                          ),
                                        ),
                                        child: const Text(
                                            'Simpan Absensi',
                                            style: TextStyle(color: Colors.white)
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'History Attendance',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tambahkan Flexible agar ListView memiliki batasan ukuran
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          isAttendanceLoaded
                              ? (attendanceData.isNotEmpty
                              ? ListView.builder(
                            shrinkWrap: true, // ✅ ListView menyesuaikan tinggi kontennya
                            physics: NeverScrollableScrollPhysics(), // ✅ Matikan scroll agar tidak konflik
                            itemCount: attendanceData.length,
                            itemBuilder: (context, index) {
                              var attendance = attendanceData[index];

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 30,
                                          backgroundColor: Colors.grey.shade300,
                                          child: Icon(Icons.person, size: 30, color: Colors.grey.shade700),
                                        ),
                                        const SizedBox(width: 12),

                                        // Detail Kehadiran
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  // Status Kehadiran
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        vertical: 4, horizontal: 8),
                                                    decoration: BoxDecoration(
                                                      color: _getStatusColor(
                                                          attendance['status'] as String? ?? 'Unknown'),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      attendance['status'] as String? ?? 'Unknown',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),

                                                  const SizedBox(width: 8),

                                                  // Lokasi
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.location_on,
                                                          size: 16, color: Colors.red),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        attendance['location'] as String? ?? '-',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.black54,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),

                                              // Tanggal dan waktu check-in
                                              Text(
                                                '${attendance['attendance_date'] ?? ''} | ${attendance['check_in_time'] ?? '-'}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black87,
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
                              );
                            },
                          )
                              : const Center(
                            child: Text(
                              'No attendance data available.',
                              style: TextStyle(fontSize: 16, color: Colors.black54),
                            ),
                          ))
                              : const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ],
                      ),
                    )

                  ],
                )
              ],
            ),
            if (_isLoading)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {}, // Prevent interaction
                  child: AbsorbPointer( // Absorbs all pointer events
                    child: Container(
                      color: Colors.black.withOpacity(0.5), // Semi-transparent overlay
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // Ensures items are vertically centered
                          children: [
                            CircularProgressIndicator(), // Loading spinner
                            SizedBox(height: 20), // Space between icon and message
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center, // Center the message
                              children: [
                                Icon(
                                  Icons.hourglass_empty, // Loading icon
                                  color: Colors.white,
                                ),
                                SizedBox(width: 8), // Space between icon and text
                                Text(
                                  "Loading...", // Loading message
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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

Color _getStatusColor(String? status) {
  switch (status) {
    case 'Absen':
      return Colors.green;
    case 'Ijin':
      return Colors.orange;
    case 'Sakit':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

