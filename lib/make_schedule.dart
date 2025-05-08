import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:multi_dropdown/multi_dropdown.dart';

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
          _branches = responseData['data'];  // Assuming the list is under the 'data' key
        });
      } else {
        print('Unexpected response format');
      }
    } else {
      print('Failed to load branches');
    }
  }

  Future<void> _fetchClassRooms() async {
    final response = await http.get(Uri.parse('https://semarnari.sportballnesia.com/api/master/data/all_class_rooms'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data is Map && data.containsKey('data') && data['data'] is List) {
        setState(() {
          _classRooms = List<dynamic>.from(data['data']); // Ensure _classRooms is a list
          _selectedClass = _classRooms.isNotEmpty ? _classRooms[0]['id'].toString() : null; // Set initial selection
        });
      } else {
        print('Unexpected response format or missing data key');
      }
    } else {
      print('Failed to load class rooms');
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

    print(json.encode(data));

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Schedule created successfully')));
    } else {
      final responseData = json.decode(response.body);
      String errorMessage = responseData['message'] ?? 'Failed to create schedule';
      print(errorMessage);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
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
              Icons.calendar_today,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Buat Jadwal',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                ),
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
                    );
                    if (selectedDate != null) {
                      setState(() {
                        _dateController.text = "${selectedDate.toLocal()}".split(' ')[0];
                      });
                    }
                  },
                ),
                SizedBox(height: 12),
                _buildTextField(
                  controller: _timeController,
                  label: 'Waktu',
                  icon: Icons.access_time,
                  readOnly: true,
                  onTap: () async {
                    TimeOfDay? selectedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (selectedTime != null) {
                      setState(() {
                        _timeController.text = selectedTime.format(context);
                      });
                    }
                  },
                ),
                SizedBox(height: 12),
                // Subject
                _buildTextField(
                  controller: _subjectController,
                  label: 'Judul',
                  icon: Icons.subject,
                ),
                SizedBox(height: 12),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Deskripsi',
                  icon: Icons.description,
                ),
                SizedBox(height: 12),
                _buildTextField(
                  controller: _detailsController,
                  label: 'Keterangan',
                  icon: Icons.notes,
                ),
                SizedBox(height: 12),
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
                SizedBox(height: 12),
                // Class Dropdown
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
                SizedBox(height: 20),
                Container(
                  width: double.infinity, // Make the button width full
                  child: ElevatedButton(
                    onPressed: _submitSchedule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal, // Button color
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text('Submit', style: TextStyle(fontSize: 18,color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        ),
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
        prefixIcon: Icon(icon, color: Colors.teal),
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.teal, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      onTap: onTap,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a value';
        }
        return null;
      },
    );
  }

  // Custom dropdown widget for uniform design
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
        prefixIcon: Icon(Icons.list, color: Colors.teal),
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.teal, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
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
          return 'Please select an option';
        }
        return null;
      },
    );
  }


}
