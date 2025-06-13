import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:math';

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
  final Map<int, bool> _flipped = {};

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      _loadUsernameAndFetchPayments();
    });
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
      builder: (BuildContext dialogContext) {
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
                Navigator.of(dialogContext).pop();

                try {
                  int id = int.tryParse(payment['payment_id'].toString()) ?? 0;
                  if (id == 0) {
                    throw Exception("ID pembayaran tidak valid");
                  }

                  String apiUrl =
                      "https://semarnari.sportballnesia.com/api/master/data/delete_payment/$id";

                  final response = await http.delete(Uri.parse(apiUrl));

                  if (response.statusCode == 200) {
                    setState(() {
                      _filteredPayments.remove(payment);
                    });

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
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF152349),
        elevation: 0,
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
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Sanggar Tari Kota Semarang',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        letterSpacing: 0.2,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF31416A), Color(0xFF5B6BAA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 22),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: const Icon(
                        Icons.payments_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Riwayat Pembayaran SPP",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              letterSpacing: 0.2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 1,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _username != null
                                ? "Untuk: $_username"
                                : "Data pembayaran SPP Anda",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildSearchAndFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
      child: Row(
        children: [
          if (_accessRole == '2')
            Expanded(
              flex: 2,
              child: TextField(
                controller: _searchController,
                onChanged: (value) => _filterPayments(),
                decoration: InputDecoration(
                  hintText: 'Cari Nama Siswa',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF31416A)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          if (_accessRole == '2') const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: _selectedMonth.isEmpty ? null : _selectedMonth,
              decoration: InputDecoration(
                hintText: 'Pilih Bulan',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedMonth = newValue ?? '';
                  _filterPayments();
                });
              },
              items: _getAvailableMonths(),
              style: const TextStyle(fontSize: 14, color: Color(0xFF31416A)),
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF31416A)),
            ),
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
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF31416A)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      itemCount: _filteredPayments.length,
      itemBuilder: (context, index) {
        var payment = _filteredPayments[index];
        bool isPaid = payment['status'] == 'Paid';
        bool isFlipped = _flipped[index] ?? false;

        // Konsistenkan tinggi card
        const double cardHeight = 140;

        return GestureDetector(
          onTap: () {
            setState(() {
              _flipped[index] = !isFlipped;
            });
          },
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: isFlipped ? 1 : 0, end: isFlipped ? 1 : 0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              // value: 0 (front), 1 (back)
              final angle = value * pi;
              final isBack = angle > pi / 2;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: cardHeight,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
                  child: isBack
                      ? Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(pi),
                          child: _buildAtmCardBack(payment, isPaid, index, cardHeight),
                        )
                      : _buildAtmCardFront(payment, isPaid, index, cardHeight),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAtmCardFront(Map<String, dynamic> payment, bool isPaid, int index, double cardHeight) {
    // Ambil nama bulan dari field 'month'
    String monthName = '';
    if (payment['month'] != null) {
      int monthNum = int.tryParse(payment['month'].toString()) ?? 0;
      if (monthNum >= 1 && monthNum <= 12) {
        monthName = DateFormat.MMMM('id_ID').format(DateTime(0, monthNum));
      }
    }
    return Container(
      key: const ValueKey(false),
      height: cardHeight,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isPaid
              ? [Color(0xFF43CEA2), Color(0xFF185A9D)]
              : [Color(0xFFFFAF7B), Color(0xFFD76D77)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 22),
          child: Row(
            children: [
              // Tambahkan bulan di depan card
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.credit_card_rounded,
                    color: Colors.white.withOpacity(0.85),
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      monthName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 0.2,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${payment['fullname']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: Colors.white,
                        letterSpacing: 0.2,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      NumberFormat.currency(
                        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                        .format(double.tryParse(payment['amount_paid']) ?? 0),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 16,
                        letterSpacing: 0.2,
                        shadows: [
                          Shadow(
                            color: Colors.black12,
                            blurRadius: 1,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPaid ? Colors.white.withOpacity(0.18) : Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isPaid ? Colors.greenAccent : Colors.redAccent,
                    width: 1.2,
                  ),
                ),
                child: Text(
                  isPaid ? "Lunas" : "Belum",
                  style: TextStyle(
                    color: isPaid ? Colors.greenAccent[100] : Colors.redAccent[100],
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    shadows: [
                      Shadow(
                        color: Colors.black12,
                        blurRadius: 1,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              if (_accessRole == '2')
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white, size: 24),
                    onPressed: () => _onDelete(payment),
                    tooltip: "Hapus pembayaran",
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAtmCardBack(Map<String, dynamic> payment, bool isPaid, int index, double cardHeight) {
    return Container(
      key: const ValueKey(true),
      height: cardHeight,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isPaid
              ? [Color(0xFF43CEA2), Color(0xFF185A9D)]
              : [Color(0xFFFFAF7B), Color(0xFFD76D77)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Colors.white.withOpacity(0.85),
                size: 38,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Penanggung Jawab:',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Text(
                      '${payment['processed_by']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Tanggal Pembayaran:',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy').format(DateTime.parse(payment['created_at'])),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.flip,
                color: Colors.white.withOpacity(0.5),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
