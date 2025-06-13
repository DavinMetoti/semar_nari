import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MakeInformationPage extends StatefulWidget {
  @override
  _MakeInformationPageState createState() => _MakeInformationPageState();
}

class _MakeInformationPageState extends State<MakeInformationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _thumbnailController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  List<Map<String, dynamic>> _informationList = [];

  @override
  void initState() {
    super.initState();
    fetchInformation();
  }

  Future<void> createInformation() async {
    final String apiUrl = "https://semarnari.sportballnesia.com/api/master/data/make_information";
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'title': _titleController.text,
          'thumbnail': _thumbnailController.text,
          'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Information created successfully')));

        // ✅ Kirim notifikasi push setelah sukses
        await sendPushNotification(_titleController.text, _thumbnailController.text);

        fetchInformation();
        _titleController.clear();
        _thumbnailController.clear();
        _descriptionController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create information')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> sendPushNotification(String title, String message) async {
    final String notificationUrl = "https://semarnari.sportballnesia.com/api/master/user/send_notification";

    try {
      final response = await http.post(
        Uri.parse(notificationUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'title': title,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
      } else {
      }
    } catch (e) {
    }
  }

  Future<void> fetchInformation() async {
    final String apiUrl = "https://semarnari.sportballnesia.com/api/master/data/get_all_information";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _informationList = List<Map<String, dynamic>>.from(data['data']);
        });
      } else {
        throw Exception('Failed to load information');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> deleteInformation(String id) async {

    final String apiUrl = "https://semarnari.sportballnesia.com/api/master/data/delete_information";
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': int.parse(id)}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Information deleted successfully')));
        fetchInformation();
      } else {
        throw Exception('Failed to delete information');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _modernFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF152349), Color(0xFF3b5998)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.12),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Text(
              "Tambah Informasi",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _titleController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Judul',
                labelStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.07),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white, width: 1.5),
                ),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Judul wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _thumbnailController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Thumbnail',
                labelStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.07),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white, width: 1.5),
                ),
                counterStyle: TextStyle(color: Colors.white54),
              ),
              maxLength: 100,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Thumbnail wajib diisi';
                } else if (value.length > 100) {
                  return 'Thumbnail tidak boleh lebih dari 100 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Deskripsi (opsional)',
                labelStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.07),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white, width: 1.5),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF152349),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  elevation: 2,
                ),
                icon: Icon(Icons.send_rounded),
                label: Text('Kirim Informasi'),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    createInformation();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modernInfoCard(Map<String, dynamic> info) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [Colors.white, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(0xFF152349),
          child: Icon(Icons.campaign, color: Colors.white),
        ),
        title: Text(
          info['title'] ?? '',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF152349),
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          info['thumbnail'] ?? 'No description',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 13,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () => deleteInformation(info['id'].toString()),
          tooltip: "Hapus informasi",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFf8fafc),
      appBar: AppBar(
        backgroundColor: const Color(0xFF152349),
        automaticallyImplyLeading: true,
        elevation: 0,
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
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
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
              Icons.info_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Curved blue background
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF152349), Color(0xFF3b5998)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(180),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _modernFormCard(),
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: _informationList.isEmpty
                        ? Center(
                            child: Text(
                              'Belum ada informasi',
                              style: TextStyle(
                                color: Color(0xFF152349),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _informationList.length,
                            itemBuilder: (context, index) {
                              final info = _informationList[index];
                              return _modernInfoCard(info);
                            },
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
