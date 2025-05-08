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
    print("Response Body: ${response.body}"); // Debugging

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);

      if (responseData['status'] == true && responseData['data'] != null) {
        setState(() {
          _branches = (responseData['data'] as List)
              .map((branchData) => Branch.fromJson(branchData))
              .toList();
          _isLoading = false;
        });

        // Cetak daftar branch yang telah di-fetch
        for (var branch in _branches) {
          print("Branch: ID=${branch.id}, Name=${branch.name}, Lat=${branch.latitude}, Lng=${branch.longitude}");
        }
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
    print(response.body);

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
    print("Payload Sent: $payload");

    final response = await http.post(
      Uri.parse('https://semarnari.sportballnesia.com/api/master/data/delete_branch'),
      headers: {"Content-Type": "application/json"},
      body: payload,
    );

    // Log response dari server
    print("Response Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

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
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showCreateBranchModal,
              child: Text('Buat Sanggar Baru', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _branches.length,
              itemBuilder: (ctx, index) {
                final branch = _branches[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 5.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(15),
                    leading: Icon(Icons.location_on, color: Colors.teal),
                    title: Text(
                      branch.name,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Latitude: ${branch.latitude}', style: TextStyle(color: Colors.grey[600])),
                        Text('Longitude: ${branch.longitude}', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteBranch(branch.id),
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
