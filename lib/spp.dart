import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home.dart';
import 'package:intl/intl.dart';

class SppPage extends StatefulWidget {
  @override
  _SppPageState createState() => _SppPageState();
}

class _SppPageState extends State<SppPage> {
  String? _username;
  List<dynamic> _sppPayments = [];
  List<dynamic> _filteredPayments = [];
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();
  String _selectedMonth = '';
  String? _accessRole;


  @override
  void initState() {
    super.initState();
    _loadUsernameAndFetchPayments();
  }

  Future<void> _loadUsernameAndFetchPayments() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username');


    if (username != null && username.isNotEmpty) {
      setState(() {
        _username = username;
        _accessRole = prefs.getString('access_role');
      });
      await _fetchSppPayment(username);
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchSppPayment(String username) async {
    final String apiUrl =
        'https://semarnari.sportballnesia.com/api/master/data/get_payments';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _sppPayments = data['data'];
          _filteredPayments = _sppPayments;
          _isLoading = false;
        });
      } else {
        setState(() {
          _sppPayments = [];
          _filteredPayments = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _sppPayments = [];
        _filteredPayments = [];
        _isLoading = false;
      });
    }
  }

  void _filterPayments() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPayments = _sppPayments.where((payment) {
        bool matchesName = payment['fullname']
            .toString()
            .toLowerCase()
            .contains(query);
        bool matchesMonth = _selectedMonth.isEmpty ||
            DateFormat('MMMM yyyy').format(DateTime.parse(payment['created_at'])) == _selectedMonth;
        return matchesName && matchesMonth;
      }).toList();
    });
  }

  void _onDelete(Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) { // Simpan konteks untuk dialog
        return AlertDialog(
          title: Text("Konfirmasi"),
          content: Text("Apakah Anda yakin ingin menghapus pembayaran ini?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text("Batal"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Tutup dialog sebelum request

                try {
                  int id = int.tryParse(payment['payment_id'].toString()) ?? 0;
                  if (id == 0) {
                    throw Exception("ID pembayaran tidak valid");
                  }

                  String apiUrl =
                      "https://semarnari.sportballnesia.com/api/master/data/delete_payment/$id";

                  final response = await http.delete(Uri.parse(apiUrl));

                  print("url: ${apiUrl}");
                  print("Status Code: ${response.statusCode}");
                  print("Response Body: ${response.body}");


                  if (response.statusCode == 200) {
                    setState(() {
                      _filteredPayments.remove(payment);
                    });

                    // ✅ Gunakan context utama untuk Snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Pembayaran berhasil dihapus")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Gagal menghapus pembayaran")),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Terjadi kesalahan: $e")),
                  );
                }
              },
              child: Text("Hapus", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF152349),
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
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredPayments.isEmpty
                ? _buildNoDataView()
                : _buildPaymentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          if (_accessRole == '2')
            TextField(
              controller: _searchController,
              onChanged: (value) => _filterPayments(),
              decoration: InputDecoration(
                labelText: 'Cari Nama Siswa',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _selectedMonth.isEmpty ? null : _selectedMonth,
            decoration: InputDecoration(
              labelText: 'Pilih Bulan',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(10.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue, width: 2.0),
                borderRadius: BorderRadius.circular(10.0),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            onChanged: (String? newValue) {
              setState(() {
                _selectedMonth = newValue ?? '';
                _filterPayments();
              });
            },
            items: _getAvailableMonths(),
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> _getAvailableMonths() {
    Set<String> months = _sppPayments
        .map((p) => DateFormat('MMMM yyyy').format(DateTime.parse(p['created_at'])))
        .toSet();
    return months
        .map((month) => DropdownMenuItem<String>(
      value: month,
      child: Text(month),
    ))
        .toList();
  }

  Widget _buildNoDataView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/sorry.png',
            width: 100,
          ),
          const SizedBox(height: 20),
          const Text(
            'Mohon maaf hasil search tidak \n ditemukan atau belum ada data',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _filteredPayments.length,
      itemBuilder: (context, index) {
        var payment = _filteredPayments[index];

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: Icon(
              payment['status'] == 'Paid' ? Icons.check_circle : Icons
                  .warning,
              color: payment['status'] == 'Paid' ? Colors.green : Colors
                  .red,
            ),
            title: Text(
              '${payment['fullname']}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  NumberFormat.currency(
                      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                      .format(double.tryParse(payment['amount_paid']) ?? 0),
                ),
                Text('Penanggung Jawab: ${payment['processed_by']}'),
                Text(
                  'Tanggal: ${DateFormat('dd MMM yyyy').format(
                      DateTime.parse(payment['created_at']))}',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_accessRole == '2')
                  IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _onDelete(payment),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
