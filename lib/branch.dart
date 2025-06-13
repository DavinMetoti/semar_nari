import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home.dart';

class Branch {
  final String? id;
  final String name;
  final String latitude;
  final String longitude;

  Branch({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id']?.toString(),
      name: json['name'] ?? '',
      latitude: json['latitude']?.toString() ?? '0',
      longitude: json['longitude']?.toString() ?? '0',
    );
  }
}

class BranchPage extends StatefulWidget {
  @override
  _BranchPageState createState() => _BranchPageState();
}

class _BranchPageState extends State<BranchPage> {
  List<Branch> _branches = [];
  bool _isLoading = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchBranches();
  }

  Future<void> _fetchBranches() async {
    final response = await http.get(Uri.parse('https://semarnari.sportballnesia.com/api/master/data/get_all_branch'));

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);

      if (responseData['status'] == true && responseData['data'] != null) {
        setState(() {
          _branches = (responseData['data'] as List)
              .map((branchData) => Branch.fromJson(branchData))
              .toList();
          _isLoading = false;
        });

      } else {
        _showError(responseData['message'] ?? 'Failed to fetch data');
      }
    } else {
      _showError('Failed to load branches');
    }
  }


  Future<void> _createBranch() async {
    final response = await http.post(
      Uri.parse('https://semarnari.sportballnesia.com/api/master/data/create_branch'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "name": _nameController.text,
        "latitude": _latitudeController.text,
        "longitude": _longitudeController.text,
      }),
    );

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      if (responseData['status'] == true) {
        _fetchBranches();
        Navigator.of(context).pop();
        _showSuccess('Branch created successfully');
      } else {
        _showError(responseData['message'] ?? 'Failed to create branch');
      }
    } else {
      _showError('Failed to create branch with status code: ${response.statusCode}');
    }
  }

  Future<void> _deleteBranch(String? id) async {
    if (id == null) return;

    // Log payload yang dikirim
    final payload = json.encode({"id": id.toString()});

    final response = await http.post(
      Uri.parse('https://semarnari.sportballnesia.com/api/master/data/delete_branch'),
      headers: {"Content-Type": "application/json"},
      body: payload,
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['status'] == true) {
        _fetchBranches();
        _showSuccess('Branch deleted successfully');
      } else {
        _showError(responseData['message'] ?? 'Failed to delete branch');
      }
    } else {
      _showError('Failed to delete branch with status code: ${response.statusCode}');
    }
  }


  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
    );
  }

  void _showCreateBranchModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Buat Sanggar Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Branch Name'),
              ),
              TextField(
                controller: _latitudeController,
                decoration: InputDecoration(labelText: 'Latitude'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _longitudeController,
                decoration: InputDecoration(labelText: 'Longitude'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _createBranch,
              child: Text('Create Branch'),
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
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    "Memuat data cabang...",
                    style: TextStyle(color: Color(0xFF31416A), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Header Card
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
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(16),
                            child: const Icon(
                              Icons.map_rounded,
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
                                  "Sanggar",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Total cabang: ${_branches.length}",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _showCreateBranchModal,
                            icon: const Icon(Icons.add, color: Colors.white, size: 20),
                            label: const Text(
                              'Tambah',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              textStyle: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _branches.isEmpty
                      ? Center(
                          child: Text(
                            "Belum ada cabang terdaftar.",
                            style: TextStyle(color: Color(0xFF31416A), fontWeight: FontWeight.w600),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          itemCount: _branches.length,
                          itemBuilder: (ctx, index) {
                            final branch = _branches[index];
                            return AnimatedContainer(
                              duration: Duration(milliseconds: 350 + index * 40),
                              curve: Curves.easeOutCubic,
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () {},
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFe0eafc), Color(0xFFcfdef3)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                      leading: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.teal.withOpacity(0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(10),
                                        child: const Icon(Icons.location_on, color: Colors.teal, size: 28),
                                      ),
                                      title: Text(
                                        branch.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF31416A),
                                        ),
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 6.0),
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: [
                                              const Icon(Icons.my_location, size: 16, color: Color(0xFF31416A)),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Lat: ${branch.latitude}',
                                                style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                              ),
                                              const SizedBox(width: 12),
                                              const Icon(Icons.explore, size: 16, color: Color(0xFF31416A)),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Lng: ${branch.longitude}',
                                                style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 26),
                                        onPressed: () => _deleteBranch(branch.id),
                                        tooltip: "Hapus cabang",
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
