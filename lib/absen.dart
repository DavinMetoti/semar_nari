import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'dart:ui';
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

    _fetchUserDataAndLocation();

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
    await _loadUserData();
    await _getCurrentLocation();
  }

  @override
  void dispose() {
    _timer.cancel();
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

        if (newFullName != _fullName ||
            newUserID != _userID ||
            newBranchName != _branchName ||
            newLatitude != _branchLatitude ||
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
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _calculateDistance();
      });
    } catch (e) {
    }
  }

  void _calculateDistance() {
    if (_branchLatitude != null && _branchLongitude != null && _latitude != null && _longitude != null) {
      const double radiusEarth = 6371000;
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
          _selectedType = null;
        }
      });
    }
  }

  Future<void> _loadAttendanceUser() async {
    try {
      if (_userID == null) {
        return;
      }

      final response = await apiService.post('user/get_attendance_history', {
        "user_id": _userID,
      });

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final responseBody = jsonDecode(response.body);

        if (responseBody['status'] == true && responseBody['data'] is List) {
          final List<Map<String, dynamic>> newAttendanceData =
              List<Map<String, dynamic>>.from(responseBody['data']);

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

        } else {
          if (mounted) {
            setState(() {
              isAttendanceLoaded = true;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            isAttendanceLoaded = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isAttendanceLoaded = true;
        });
      }
    }
  }

  double _degreeToRadian(double degree) {
    return degree * pi / 180;
  }

  Future<void> _refreshData() async {
    await _loadUserData();
    await _getCurrentLocation();
    setState(() {
      _absenList.removeAt(0);
    });
  }

  void _addAttendance(File? image) {
    if (_selectedType != null && _fullName != null) {
      setState(() {
        _absenList.add({
          'type': _selectedType,
          'name': _fullName,
          'time': DateTime.now(),
          'image': image,
        });
        _selectedType = null;
      });
    }
  }

  Future<void> _takePicture() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      File image = File(pickedFile.path);
      _addAttendance(image);
    }
  }

  void _deleteAttendance(int index) {
    setState(() {
      _absenList.removeAt(index);
    });
  }

  Future<void> _saveAttendance(int index) async {
    String? compressedPhoto;

    if (index < 0 || index >= _absenList.length) {
      _showBottomSheetAlert(context, "Index tidak valid", Colors.red);
      return;
    }

    final attendance = _absenList[index];

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

      if (response.statusCode == 201 && responseBody['status'] == 'success') {
        _showBottomSheetAlert(context, "${responseBody['message']}", Colors.green);
        setState(() {
          _absenList.removeAt(index);
        });
      } else {
        _showBottomSheetAlert(context, "Gagal menyimpan attendance: ${responseBody['message']}", Colors.red);
      }
    } catch (e) {
      _showBottomSheetAlert(context, "Error saat menyimpan attendance: $e", Colors.red);
    } finally {
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

  bool _isAlreadyAbsen(String type) {
    return _absenList.any((item) => item['type'] == type);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF152349),
        elevation: 0,
        automaticallyImplyLeading: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 32,
              width: 32,
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Semar Nari',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Sanggar Tari Kota Semarang',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
            onPressed: _refreshData,
            tooltip: "Refresh",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF152349),
        onPressed: _refreshData,
        child: const Icon(Icons.refresh, color: Colors.white),
        elevation: 4,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFe3f0ff),
                  Color(0xFFb3d8fd),
                  Color(0xFFeaf6ff),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          RefreshIndicator(
            onRefresh: _refreshData,
            child: Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(0.0),
                  children: [
                    SizedBox(
                      key: const ValueKey(1),
                      height: 270,
                      width: double.infinity,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: 140,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF152349), Color(0xFF2B3A67)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(18),
                                bottomRight: Radius.circular(18),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 28.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 18),
                                      Text(
                                        _fullName ?? '',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, color: Colors.white70, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            _branchName ?? '',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(top: 24),
                                    padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 6.0),
                                    decoration: BoxDecoration(
                                      color: _distanceToBranch != null && _distanceToBranch! > 50
                                          ? Colors.redAccent
                                          : Colors.green,
                                      borderRadius: BorderRadius.circular(12.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.gps_fixed,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _distanceToBranch != null
                                              ? "${_distanceToBranch!.toStringAsFixed(2)} m"
                                              : "Menghitung...",
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 90,
                            left: 24,
                            right: 24,
                            child: Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                color: Colors.white.withOpacity(0.28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.10),
                                    blurRadius: 24,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.18),
                                  width: 1.5,
                                ),
                                backgroundBlendMode: BlendMode.overlay,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(22.0),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                                                const SizedBox(width: 8),
                                                Text(
                                                  DateFormat('dd MMM yyyy').format(_currentTime),
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                const Icon(Icons.access_time, color: Colors.white, size: 20),
                                                const SizedBox(width: 8),
                                                Text(
                                                  DateFormat('HH:mm').format(_currentTime),
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        if (_absenList.isNotEmpty)
                                          ..._absenList.map((attendance) {
                                            return InkWell(
                                              borderRadius: BorderRadius.circular(14),
                                              onTap: () {
                                                if (attendance['image'] != null) {
                                                  _showImage(attendance['image']!);
                                                }
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    if (attendance['image'] != null)
                                                      CircleAvatar(
                                                        radius: 28,
                                                        backgroundImage: FileImage(attendance['image']!),
                                                      )
                                                    else
                                                      CircleAvatar(
                                                        radius: 28,
                                                        backgroundColor: Colors.grey[200],
                                                        child: Icon(Icons.person, color: Colors.grey[500], size: 32),
                                                      ),
                                                    const SizedBox(width: 16),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
                                                            decoration: BoxDecoration(
                                                              color: attendance['type'] == 'Absen'
                                                                  ? Colors.green
                                                                  : attendance['type'] == 'Ijin'
                                                                      ? Colors.orange
                                                                      : Colors.red,
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: Text(
                                                              "${attendance['type']}",
                                                              style: const TextStyle(
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.white,
                                                                fontSize: 16,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(height: 5),
                                                          Text(
                                                            DateFormat('dd MMM yyyy HH:mm:ss').format(attendance['time']),
                                                            style: const TextStyle(fontSize: 13, color: Colors.black54),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                                      onPressed: () {
                                                        _deleteAttendance(_absenList.indexOf(attendance));
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        if (_absenList.isEmpty)
                                          DropdownButtonFormField<String>(
                                            value: _selectedType,
                                            decoration: InputDecoration(
                                              labelText: 'Pilih Tipe Kehadiran',
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                        if (_absenList.isEmpty) const SizedBox(height: 12),
                                        if ((_distanceToBranch == null || _distanceToBranch! <= 50) && (_selectedType != null && _absenList.isEmpty))
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              icon: Icon(
                                                _selectedType == 'Absen' ? Icons.camera_alt : Icons.check_circle,
                                                color: Colors.white,
                                              ),
                                              onPressed: (_fullName != null && !_isAlreadyAbsen(_selectedType!))
                                                  ? (_selectedType == 'Absen'
                                                      ? _takePicture
                                                      : () => _addAttendance(null))
                                                  : null,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF2B3A67),
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                textStyle: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                elevation: 2,
                                              ),
                                              label: Text(
                                                _isAlreadyAbsen(_selectedType!)
                                                    ? 'Sudah Absen'
                                                    : (_selectedType == 'Absen'
                                                        ? 'Ambil Foto & Absen'
                                                        : 'Tambahkan Absen'),
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        if (_distanceToBranch != null && _distanceToBranch! > 50 && _selectedType == 'Absen')
                                          const Padding(
                                            padding: EdgeInsets.only(top: 8.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                                                SizedBox(width: 6),
                                                Flexible(
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
                                          ),
                                        if (_absenList.isNotEmpty || _selectedType == 'Ijin' || _selectedType == 'Sakit')
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton.icon(
                                                icon: const Icon(Icons.save, color: Colors.white),
                                                onPressed: () {
                                                  _addAttendance(null);
                                                  if (_absenList.isNotEmpty) {
                                                    int indexToSave = 0;
                                                    _saveAttendance(indexToSave);
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  textStyle: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  elevation: 2,
                                                ),
                                                label: const Text(
                                                  'Simpan Absensi',
                                                  style: TextStyle(color: Colors.white),
                                                ),
                                              ),
                                            ),
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
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'History Attendance',
                            style: TextStyle(
                              color: Color(0xFF2B3A67),
                              fontWeight: FontWeight.bold,
                              fontSize: 19,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          isAttendanceLoaded
                              ? (attendanceData.isNotEmpty
                                  ? ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: attendanceData.length,
                                      itemBuilder: (context, index) {
                                        var attendance = attendanceData[index];
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 24),
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(18),
                                            onTap: () {},
                                            child: Container(
                                              margin: const EdgeInsets.symmetric(vertical: 10),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.white.withOpacity(0.95),
                                                    Colors.blueGrey.withOpacity(0.08),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(18),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.07),
                                                    blurRadius: 16,
                                                    offset: const Offset(0, 8),
                                                  ),
                                                ],
                                                border: Border.all(
                                                  color: Colors.grey.withOpacity(0.10),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(18.0),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 30,
                                                      backgroundColor: Colors.grey.shade200,
                                                      child: Icon(Icons.person, size: 32, color: Colors.grey.shade600),
                                                    ),
                                                    const SizedBox(width: 18),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              Container(
                                                                padding: const EdgeInsets.symmetric(
                                                                    vertical: 5, horizontal: 14),
                                                                decoration: BoxDecoration(
                                                                  color: _getStatusColor(
                                                                      attendance['status'] as String? ?? 'Unknown'),
                                                                  borderRadius: BorderRadius.circular(8),
                                                                ),
                                                                child: Text(
                                                                  attendance['status'] as String? ?? 'Unknown',
                                                                  style: const TextStyle(
                                                                    fontWeight: FontWeight.bold,
                                                                    color: Colors.white,
                                                                    fontSize: 15,
                                                                  ),
                                                                ),
                                                              ),
                                                              Row(
                                                                children: [
                                                                  const Icon(Icons.location_on,
                                                                      size: 16, color: Colors.redAccent),
                                                                  const SizedBox(width: 4),
                                                                  Text(
                                                                    attendance['location'] as String? ?? '-',
                                                                    style: const TextStyle(
                                                                      fontSize: 13,
                                                                      color: Colors.black54,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(height: 10),
                                                          Text(
                                                            '${attendance['attendance_date'] ?? ''} | ${attendance['check_in_time'] ?? '-'}',
                                                            style: const TextStyle(
                                                              fontSize: 15,
                                                              color: Colors.black87,
                                                              fontWeight: FontWeight.w500,
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
                                  child: Padding(
                                    padding: EdgeInsets.all(24.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
                if (_isLoading)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {},
                      child: AbsorbPointer(
                        child: Container(
                          color: Colors.black.withOpacity(0.5),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.hourglass_empty,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Loading...",
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
        ],
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
