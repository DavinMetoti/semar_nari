import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'home.dart';

class ClassRoom {
  final String id;
  final String grade;
  final String name;
  final String capacity;
  final String status;

  ClassRoom({
    required this.id,
    required this.grade,
    required this.name,
    required this.capacity,
    required this.status,
  });

  // Factory constructor to create a ClassRoom object from JSON
  factory ClassRoom.fromJson(Map<String, dynamic> json) {
    return ClassRoom(
      id: json['id'].toString(),
      grade: json['grade'] == "0" ? 'TK' : json['grade'].toString(),
      name: json['name'],
      capacity: json['capacity'].toString(),
      status: json['status'],
    );
  }

  // Method to convert ClassRoom object to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grade': grade,
      'name': name,
      'capacity': capacity,
      'status': status,
    };
  }
}

class ClassRoomService {
  final String baseUrl = "https://semarnari.sportballnesia.com/api/master/data";

  // Fetch all class rooms
  Future<List<ClassRoom>> fetchClassRooms() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/all_class_rooms'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((item) => ClassRoom.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load class rooms');
      }
    } catch (e) {
      throw Exception('Failed to load class rooms: $e');
    }
  }

  // Add a new class room
  Future<void> makeClassRoom(ClassRoom classRoom) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/make_class_rooms'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(classRoom.toJson()),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to create class room');
      }
      Fluttertoast.showToast(
        msg: "Class room created successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      // Handle error
      Fluttertoast.showToast(
        msg: "Failed to create class room: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 2,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  Future<void> editClassRoom(ClassRoom classRoom) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/edit_class_rooms'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(classRoom.toJson()),
      );

      if (response.statusCode != 200) {
        Fluttertoast.showToast(msg: "Failed to update class room", gravity: ToastGravity.BOTTOM);  // Show toast on failure
        throw Exception('Failed to update class room');
      } else {
        Fluttertoast.showToast(msg: "Class room updated successfully", gravity: ToastGravity.BOTTOM);  // Show toast on success
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to update class room: $e", gravity: ToastGravity.BOTTOM);  // Show error toast
      throw Exception('Failed to update class room: $e');
    }
  }

  // Delete a class room by ID
  Future<void> deleteClassRoom(String id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/delete_class_rooms'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': id}),
      );

      // Log the response status and body for debugging
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode != 200) {
        Fluttertoast.showToast(
            msg: "Failed to delete class room",
            gravity: ToastGravity.TOP
        );  // Show toast on failure
        throw Exception('Failed to delete class room');
      } else {
        Fluttertoast.showToast(
            msg: "Class room deleted successfully",
            gravity: ToastGravity.TOP
        );  // Show toast on success
      }
    } catch (e) {
      Fluttertoast.showToast(
          msg: "Failed to delete class room: $e",
          gravity: ToastGravity.BOTTOM
      );  // Show error toast
      throw Exception('Failed to delete class room: $e');
    }
  }

}

class ClassRoomPage extends StatefulWidget {
  @override
  _ClassRoomPageState createState() => _ClassRoomPageState();
}

class _ClassRoomPageState extends State<ClassRoomPage> {
  late Future<List<ClassRoom>> futureClassRooms;
  final ClassRoomService _classRoomService = ClassRoomService();

  String selectedGrade = '0';
  String selectedStatus = 'Actived';

  @override
  void initState() {
    super.initState();
    futureClassRooms = _classRoomService.fetchClassRooms();
  }

  void _showForm({ClassRoom? classRoom}) {
    final nameController = TextEditingController(text: classRoom?.name ?? '');
    final capacityController = TextEditingController(text: classRoom?.capacity ?? '');

    // Initialize selectedGrade and selectedStatus for editing
    selectedGrade = classRoom?.grade ?? '0';
    selectedStatus = classRoom?.status ?? 'Actived';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.all(20),
          title: Text(classRoom == null ? 'Tambah Kelas' : 'Edit Kelas'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nama Kelas field
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('Nama Kelas:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: '',
                      hintText: 'Enter classroom name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    ),
                  ),
                ),

                // Tingkat field (Dropdown)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('Pilih Tingkat:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: DropdownButtonFormField2<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    hint: const Text(
                      'Select Grade',
                      style: TextStyle(fontSize: 14),
                    ),
                    items: [
                      DropdownMenuItem(value: '0', child: Text('TK')),
                      DropdownMenuItem(value: '1', child: Text('Kelas 1')),
                      DropdownMenuItem(value: '2', child: Text('Kelas 2')),
                      DropdownMenuItem(value: '3', child: Text('Kelas 3')),
                      DropdownMenuItem(value: '4', child: Text('Kelas 4')),
                      DropdownMenuItem(value: '5', child: Text('Kelas 5')),
                      DropdownMenuItem(value: '6', child: Text('Kelas 6')),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedGrade = newValue!;
                      });
                    },
                    value: selectedGrade == 'TK' ? '0' : selectedGrade, // Ensure 'TK' maps to '0'
                  )
                ),

                // Kapasitas Kelas field
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('Kapasitas Kelas:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: TextField(
                    controller: capacityController,
                    decoration: InputDecoration(
                      labelText: '',
                      hintText: 'Enter classroom capacity',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    ),
                  ),
                ),

                // Status field (Dropdown)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('Status:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: DropdownButtonFormField2<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    hint: const Text(
                      'Select Status',
                      style: TextStyle(fontSize: 14),
                    ),
                    items: [
                      DropdownMenuItem(value: 'Actived', child: Text('Actived')),
                      DropdownMenuItem(value: 'Deactived', child: Text('Deactived')),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedStatus = newValue!;
                      });
                    },
                    value: selectedStatus, // This should match one of the item values
                  )
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final grade = selectedGrade;
                final capacity = capacityController.text;

                if (capacity.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid number for capacity')),
                  );
                  return;
                }

                final newClassRoom = ClassRoom(
                  id: classRoom?.id ?? "",
                  grade: grade,
                  name: nameController.text,
                  capacity: capacity,
                  status: selectedStatus,
                );

                if (classRoom == null) {
                  // Creating a new class room
                  _classRoomService.makeClassRoom(newClassRoom).then((_) {
                    setState(() {
                      futureClassRooms = _classRoomService.fetchClassRooms();
                    });
                    Navigator.of(context).pop();
                  }).catchError((e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  });
                } else {
                  // Editing an existing class room
                  _classRoomService.editClassRoom(newClassRoom).then((_) {
                    setState(() {
                      futureClassRooms = _classRoomService.fetchClassRooms();
                    });
                    Navigator.of(context).pop();
                  }).catchError((e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  });
                }
              },
              child: Text(classRoom == null ? 'Add' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  // Delete a class room
  void _deleteClassRoom(String id) {
    _classRoomService.deleteClassRoom(id).then((_) {
      setState(() {
        futureClassRooms = _classRoomService.fetchClassRooms();
      });
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF152349),
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 30,
                  width: 30,
                ),
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
              icon: const Icon(
                Icons.home,
                size: 30.0,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<ClassRoom>>(
        future: futureClassRooms,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final classRooms = snapshot.data ?? [];

          return ListView.builder(
            itemCount: classRooms.length,
            itemBuilder: (context, index) {
              final classRoom = classRooms[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                elevation: 5,
                child: ListTile(
                  contentPadding: EdgeInsets.all(12),
                  title: Text(classRoom.name, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Kelas: ${classRoom.grade}\nKapasitas: ${classRoom.capacity}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _showForm(classRoom: classRoom),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deleteClassRoom(classRoom.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: Icon(Icons.add),
      ),
    );
  }
}
