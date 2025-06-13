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
  bool isLoading = false;

  final _amountController = TextEditingController();
  final _processedByController = TextEditingController();

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
    setState(() => isLoading = true);
    try {
      students = await getData('');
      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memuat data siswa"), backgroundColor: Colors.red),
      );
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

    if (picked != null) {
      setState(() {
        paymentDate = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF31416A);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
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
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF31416A), Color(0xFF5B6BAA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: const Icon(Icons.payments_rounded, size: 54, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pembayaran SPP',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF31416A),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Dropdown for selecting student
                  Container(
                    padding: const EdgeInsets.only(left: 14, right: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black12),
                      color: Colors.white,
                    ),
                    child: isLoading
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2, color: themeColor),
                            ),
                          )
                        : DropdownButton<String>(
                            isExpanded: true,
                            hint: const Text(
                              'Pilih Siswa',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            items: students
                                .map((student) => DropdownMenuItem<String>(
                                      value: student.id,
                                      child: Text(student.fullname),
                                    ))
                                .toList(),
                            value: selectedStudentId,
                            onChanged: (value) {
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
                              color: themeColor,
                            ),
                            underline: const SizedBox(),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Input fields appear after student is selected
                  if (selectedStudentName != null)
                    Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person, color: Color(0xFF31416A), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                selectedStudentName ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Color(0xFF31416A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Flexible(
                              child: TextField(
                                controller: TextEditingController(text: month),
                                onChanged: (value) {
                                  setState(() {
                                    month = value;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Bulan',
                                  prefixIcon: Icon(Icons.calendar_month, color: themeColor),
                                  filled: true,
                                  fillColor: const Color(0xFFF6F8FB),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: TextField(
                                controller: TextEditingController(text: year),
                                onChanged: (value) {
                                  setState(() {
                                    year = value;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Tahun',
                                  prefixIcon: Icon(Icons.date_range, color: themeColor),
                                  filled: true,
                                  fillColor: const Color(0xFFF6F8FB),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              amountPaid = value;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Jumlah Dibayarkan',
                            prefixIcon: Icon(Icons.attach_money, color: themeColor),
                            filled: true,
                            fillColor: const Color(0xFFF6F8FB),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: () {
                            _selectPaymentDate(context);
                          },
                          child: AbsorbPointer(
                            child: TextField(
                              controller: TextEditingController(text: paymentDate),
                              decoration: InputDecoration(
                                labelText: 'Tanggal Pembayaran',
                                prefixIcon: Icon(Icons.event, color: themeColor),
                                filled: true,
                                fillColor: const Color(0xFFF6F8FB),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: status,
                          onChanged: (value) {
                            setState(() {
                              status = value!;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Status',
                            prefixIcon: Icon(Icons.verified, color: themeColor),
                            filled: true,
                            fillColor: const Color(0xFFF6F8FB),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: <String>['Unpaid', 'Paid']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _processedByController,
                          onChanged: (value) {
                            setState(() {
                              processedBy = value;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Penanggung Jawab',
                            prefixIcon: Icon(Icons.account_box, color: themeColor),
                            filled: true,
                            fillColor: const Color(0xFFF6F8FB),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (selectedStudentId != null &&
                                  month != null &&
                                  year != null &&
                                  (_amountController.text.isNotEmpty || amountPaid != null)) {
                                final paymentData = {
                                  'student': selectedStudentId,
                                  'month': month,
                                  'year': year,
                                  'amount_paid': _amountController.text.isNotEmpty ? _amountController.text : amountPaid,
                                  'payment_date': paymentDate,
                                  'status': status,
                                  'processed_by': _processedByController.text.isNotEmpty ? _processedByController.text : processedBy,
                                };
                                savePaymentData(context, paymentData);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Mohon lengkapi semua data yang diperlukan'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.save_alt, color: Colors.white),
                            label: const Text(
                              'Simpan Pembayaran',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
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
    );
  }
}
