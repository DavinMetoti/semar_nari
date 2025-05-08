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
        fetchInformation();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create information')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> fetchInformation() async {
    final String apiUrl = "https://semarnari.sportballnesia.com/api/master/data/get_all_information";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        print('Response data: ${data}');
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
    print('Deleting information with ID: $id');

    final String apiUrl = "https://semarnari.sportballnesia.com/api/master/data/delete_information";
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': int.parse(id)}),
      );
      print('Response body: ${response.body}');

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
              Icons.info_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(labelText: 'Title'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _thumbnailController,
                    decoration: InputDecoration(labelText: 'Thumbnail'),
                    maxLength: 100, // Membatasi input hingga 100 karakter
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a thumbnail URL';
                      } else if (value.length > 100) {
                        return 'Thumbnail URL cannot exceed 100 characters';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(labelText: 'Description (optional)'),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        createInformation();
                      }
                    },
                    child: Text('Submit'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: _informationList.isEmpty
                  ? Center(child: Text('No information available'))
                  : ListView.builder(
                itemCount: _informationList.length,
                itemBuilder: (context, index) {
                  final info = _informationList[index];
                  return Card(
                    child: ListTile(
                      title: Text(info['title']),
                      subtitle: Text(info['thumbnail'] ?? 'No description'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteInformation(info['id'].toString()),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
