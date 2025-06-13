import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:multi_dropdown/multi_dropdown.dart';
import 'package:flutter_svg/flutter_svg.dart';

List<String> _selectedClasses = [];

class MakeSchedulePage extends StatefulWidget {
  @override
  _MakeSchedulePageState createState() => _MakeSchedulePageState();
}

class _MakeSchedulePageState extends State<MakeSchedulePage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _dateController = TextEditingController();
  TextEditingController _timeController = TextEditingController();
  TextEditingController _subjectController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _detailsController = TextEditingController();
  String? _selectedLocation;
  String? _selectedClass;
  List<dynamic> _branches = [];
  List<dynamic> _classRooms = [];

  @override
  void initState() {
    super.initState();
    _fetchBranches();
    _fetchClassRooms();
  }

  Future<void> _fetchBranches() async {
    final response = await http.get(Uri.parse('https://semarnari.sportballnesia.com/api/master/data/get_all_branch'));
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData is Map && responseData.containsKey('data')) {
        setState(() {
          _branches = responseData['data'];
        });
      } else {
      }
    } else {
    }
  }

  Future<void> _fetchClassRooms() async {
    final response = await http.get(Uri.parse('https://semarnari.sportballnesia.com/api/master/data/all_class_rooms'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data is Map && data.containsKey('data') && data['data'] is List) {
        setState(() {
          _classRooms = List<dynamic>.from(data['data']);
          _selectedClass = _classRooms.isNotEmpty ? _classRooms[0]['id'].toString() : null;
        });
      } else {
      }
    } else {
    }
  }

  Future<void> _submitSchedule() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final data = {
      'date': _dateController.text,
      'time': _timeController.text,
      'subject': _subjectController.text,
      'description': _descriptionController.text,
      'details': _detailsController.text,
      'class_id': _selectedClass,
      'location': _selectedLocation,
    };

    final response = await http.post(
      Uri.parse('https://semarnari.sportballnesia.com/api/master/data/make_schedule'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Schedule created successfully')));
    } else {
      final responseData = json.decode(response.body);
      String errorMessage = responseData['message'] ?? 'Failed to create schedule';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(110),
        child: Stack(
          children: [
            ClipPath(
              clipper: _HeaderClipper(),
              child: Container(
                height: 200,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF152349), Color(0xFF3b5998)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Container(
                height: 64,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // justify between
                  crossAxisAlignment: CrossAxisAlignment.center, // align-items center
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          height: 34,
                          width: 34,
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Semar Nari',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Sanggar Tari Kota Semarang',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.calendar_today,
                        size: 28.0,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Clean, subtle gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF6F9FC), Color(0xFFE3ECF7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  constraints: BoxConstraints(maxWidth: 440),
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.97),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueGrey.withOpacity(0.07),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Padding(
                            padding: const EdgeInsets.only(bottom: 18.0),
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xFF152349).withOpacity(0.09),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: EdgeInsets.all(8),
                                  child: Icon(Icons.event_note_rounded,
                                      color: Color(0xFF152349), size: 26),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Buat Jadwal',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF152349),
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 8),
                          _buildTextField(
                            controller: _dateController,
                            label: 'Tanggal',
                            icon: Icons.calendar_today,
                            readOnly: true,
                            onTap: () async {
                              DateTime? selectedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2101),
                                builder: (context, child) {
                                  return Theme(
                                    data: ThemeData.light().copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: Color(0xFF152349),
                                        onPrimary: Colors.white,
                                        surface: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (selectedDate != null) {
                                setState(() {
                                  _dateController.text = "${selectedDate.toLocal()}".split(' ')[0];
                                });
                              }
                            },
                          ),
                          SizedBox(height: 14),
                          _buildTextField(
                            controller: _timeController,
                            label: 'Waktu',
                            icon: Icons.access_time,
                            readOnly: true,
                            onTap: () async {
                              TimeOfDay? selectedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: ThemeData.light().copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: Color(0xFF152349),
                                        onPrimary: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (selectedTime != null) {
                                setState(() {
                                  _timeController.text = selectedTime.format(context);
                                });
                              }
                            },
                          ),
                          SizedBox(height: 14),
                          _buildTextField(
                            controller: _subjectController,
                            label: 'Judul',
                            icon: Icons.subject,
                          ),
                          SizedBox(height: 14),
                          _buildTextField(
                            controller: _descriptionController,
                            label: 'Deskripsi',
                            icon: Icons.description,
                          ),
                          SizedBox(height: 14),
                          _buildTextField(
                            controller: _detailsController,
                            label: 'Keterangan',
                            icon: Icons.notes,
                          ),
                          SizedBox(height: 14),
                          _buildDropdown(
                            label: 'Sanggar',
                            value: _selectedLocation,
                            items: _branches,
                            onChanged: (newValue) {
                              setState(() {
                                _selectedLocation = newValue;
                              });
                            },
                          ),
                          SizedBox(height: 14),
                          _buildDropdown(
                            label: 'Kelas',
                            value: _selectedClass,
                            items: _classRooms,
                            onChanged: (newValue) {
                              setState(() {
                                _selectedClass = newValue;
                              });
                            },
                          ),
                          SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submitSchedule,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF152349),
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 4,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Submit',
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFF2980B9)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF2980B9), width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.97),
        labelStyle: TextStyle(
          color: Color(0xFF152349),
          fontWeight: FontWeight.w600,
        ),
      ),
      style: TextStyle(
        color: Color(0xFF152349),
        fontWeight: FontWeight.w500,
      ),
      onTap: onTap,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Harap diisi';
        }
        return null;
      },
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<dynamic> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.list, color: Color(0xFF2980B9)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF2980B9), width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.97),
        labelStyle: TextStyle(
          color: Color(0xFF152349),
          fontWeight: FontWeight.w600,
        ),
      ),
      style: TextStyle(
        color: Color(0xFF152349),
        fontWeight: FontWeight.w500,
      ),
      onChanged: onChanged,
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item['id'].toString(),
          child: Text(item['name']),
        );
      }).toList(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Harap dipilih';
        }
        return null;
      },
    );
  }
}

// Clean, elegant header clipper
class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(
      size.width / 2, size.height, size.width, size.height - 30);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
