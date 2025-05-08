import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'home.dart';

class UserModel {
  final String id;
  final String fullname;

  UserModel({required this.id, required this.fullname});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      fullname: json['fullname'],
    );
  }

  static List<UserModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => UserModel.fromJson(json)).toList();
  }
}

Future<List<UserModel>> getData(String filter) async {
  var response = await Dio().get(
    "https://semarnari.sportballnesia.com/api/master/user/get_student",
    queryParameters: {"filter": filter},
  );

  final data = response.data;
  if (data != null) {
    return UserModel.fromJsonList(data['data']);
  }

  return [];
}

Future<void> savePaymentData(BuildContext context, Map<String, dynamic> paymentData) async {
  try {
    final response = await Dio().post(
      "https://semarnari.sportballnesia.com/api/master/user/spp_payments",
      data: paymentData,
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Pembayaran berhasil disimpan!"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal menyimpan pembayaran."),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Terjadi kesalahan: $e"),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class SPPPaymentsPage extends StatefulWidget {
  @override
  _SPPPaymentsPageState createState() => _SPPPaymentsPageState();
}

class _SPPPaymentsPageState extends State<SPPPaymentsPage> {
  String? selectedStudentId;
  String? selectedStudentName;
  String? month;
  String? year;
  String? amountPaid;
  String? paymentDate;
  String status = 'Unpaid';
  String? processedBy;
  List<UserModel> students = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    month = now.month.toString();
    year = now.year.toString();
    paymentDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      students = await getData('');
      setState(() {});
    } catch (e) {
      print("Error fetching students: $e");
    }
  }

  Future<void> _selectPaymentDate(BuildContext context) async {
    final DateTime initialDate = DateTime.now();
    final DateTime firstDate = DateTime(2000);
    final DateTime lastDate = DateTime(2101);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null && picked != initialDate) {
      setState(() {
        paymentDate = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dropdown for selecting student
            Container(
              padding: const EdgeInsets.only(left: 14, right: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black26),
                color: Colors.white, // Use white background for dropdown
              ),
              child: DropdownButton<String>(
                isExpanded: true,
                hint: const Text(
                  'Select Student',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                items: students
                    .map((student) => DropdownMenuItem<String>(
                  value: student.id, // Use the student's ID as value
                  child: Text(student.fullname), // Display the fullname
                ))
                    .toList(),
                value: selectedStudentId,
                onChanged: (value) async {
                  if (value != null) {
                    setState(() {
                      selectedStudentId = value;
                      selectedStudentName = students
                          .firstWhere((student) => student.id == value)
                          .fullname;
                    });
                  }
                },
                icon: Icon(
                  Icons.arrow_drop_down_circle,
                  color: Colors.black, // Custom icon color
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Input fields appear after student is selected
            if (selectedStudentName != null)
              Column(
                children: [
                  // Month input
                  TextField(
                    controller: TextEditingController(text: month),
                    onChanged: (value) {
                      setState(() {
                        month = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Bulan',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Year input
                  TextField(
                    controller: TextEditingController(text: year),
                    onChanged: (value) {
                      setState(() {
                        year = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Tahun',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Amount Paid input
                  TextField(
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        amountPaid = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Jumlah Dibayarkan',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Payment Date input using calendar
                  GestureDetector(
                    onTap: () {
                      _selectPaymentDate(context);
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        controller: TextEditingController(text: paymentDate),
                        decoration: InputDecoration(
                          labelText: 'Tanggal Pembayaran',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Status input (DropdownButton without custom styling)
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,  // Set to expand to take the full width
                      value: status,
                      onChanged: (value) {
                        setState(() {
                          status = value!;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: <String>['Unpaid', 'Paid']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Processed By input (optional)
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        processedBy = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Penanggung Jawab',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  ElevatedButton(
                    onPressed: () {
                      if (selectedStudentId != null &&
                          month != null &&
                          year != null &&
                          amountPaid != null) {
                        final paymentData = {
                          'student': selectedStudentId,
                          'month': month,
                          'year': year,
                          'amount_paid': amountPaid,
                          'payment_date': paymentDate,
                          'status': status,
                          'processed_by': processedBy,
                        };

                        savePaymentData(context, paymentData);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please fill all required fields'),
                          ),
                        );
                      }
                    },
                    child: Text('Submit Payment'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
