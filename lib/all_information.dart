import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AllNotification extends StatefulWidget {
  @override
  _AllNotificationState createState() => _AllNotificationState();
}

class _AllNotificationState extends State<AllNotification> {
  final String apiUrl = "https://semarnari.sportballnesia.com/api/master/data/get_all_information";
  List<dynamic> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body); // Ubah ke Map
        setState(() {
          notifications = responseData["data"] ?? []; // Ambil data dalam key "data"
          isLoading = false;
        });
      } else {
        throw Exception("Gagal mengambil data");
      }
    } catch (error) {
      print("Error: $error");
      setState(() {
        isLoading = false;
      });
    }
  }


  void _showDetailDialog(String title, String description) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Text(description, style: TextStyle(fontSize: 14.0)),
          ),
          actions: [
            TextButton(
              child: Text("Tutup"),
              onPressed: () {
                Navigator.of(context).pop();
              },
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
              Icons.notifications_active,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Loading indicator
          : ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final item = notifications[index];
          final String title = item["title"] ?? "Tanpa Judul";
          final String description = item["description"] ?? "Tanpa Deskripsi";
          final String shortDescription = description.length > 50
              ? "${description.substring(0, 50)}..."
              : description;

          return Card(
            elevation: 3.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: ListTile(
              leading: Icon(Icons.notifications, color: Colors.blueAccent),
              title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(shortDescription, style: TextStyle(fontSize: 14.0)),
              trailing: Icon(Icons.arrow_forward_ios, size: 16.0),
              onTap: () => _showDetailDialog(title, description),
            ),
          );
        },
      ),
    );
  }
}
