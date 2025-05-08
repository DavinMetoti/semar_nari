import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:photo_view/photo_view.dart'; // For zoomable image preview

class BannerPage extends StatefulWidget {
  @override
  _BannerPageState createState() => _BannerPageState();
}

class _BannerPageState extends State<BannerPage> {
  List<dynamic> banners = [];
  bool isLoading = true;
  String errorMessage = '';
  final String apiUrl = "https://semarnari.sportballnesia.com/api/master/data/benner";
  final String apiUrlDelete = "https://semarnari.sportballnesia.com/api/master/data/benner_delete";
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _fetchBanners();
  }

  Future<void> _fetchBanners() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          banners = data['data'] ?? [];
          isLoading = false;
        });
        print('Banners loaded successfully:');
        print(banners);
      } else {
        setState(() {
          errorMessage = 'Failed to load banners: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<File> _compressImage(File file) async {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);

    // Resize image to max width 800px (maintain aspect ratio)
    final resized = img.copyResize(image!, width: 800);

    // Compress with quality 85%
    final compressedBytes = img.encodeJpg(resized, quality: 85);

    // Create temp file
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(compressedBytes);

    return tempFile;
  }

  Future<String> _imageToBase64(File file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  Future<void> _addBanner() async {
    if (_imageFile == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      // 1. Compress the image
      final compressedFile = await _compressImage(_imageFile!);

      // 2. Convert to base64
      final base64Image = await _imageToBase64(compressedFile);

      // 3. Prepare request body
      final requestBody = json.encode({
        'benner': 'data:image/jpeg;base64,$base64Image',
      });

      // 4. Send to API
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      if (response.statusCode == 200) {
        _fetchBanners(); // Refresh list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Banner added successfully')),
        );
      } else {
        setState(() {
          errorMessage = 'Failed to add banner: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
        _imageFile = null;
      });
    }
  }

  Future<void> _deleteBanner(String id) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrlDelete), // Make sure apiUrl is defined for your endpoint
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id': id,
        }),
      );

      if (response.statusCode == 200) {
        _fetchBanners(); // Refresh list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Banner deleted successfully')),
        );
      } else {
        setState(() {
          errorMessage = 'Failed to delete banner: ${response.statusCode} - ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Widget _buildBannerImage(String imageUrl) {
    // Check if the URL is base64 encoded
    if (imageUrl.startsWith('data:image')) {
      final base64String = imageUrl.split(',').last;
      return Image.memory(
        base64Decode(base64String),
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
      );
    } else {
      // Regular network image
      return Image.network(
        imageUrl,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
      );
    }
  }

  void _showImagePreview(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(),
          body: Center(
            child: PhotoView(
              imageProvider: imageUrl.startsWith('data:image')
                  ? MemoryImage(base64Decode(imageUrl.split(',').last))
                  : NetworkImage(imageUrl) as ImageProvider,
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Banners'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchBanners,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        child: Icon(Icons.add),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : banners.isEmpty
          ? Center(child: Text('No banners available'))
          : ListView.builder(
        itemCount: banners.length,
        itemBuilder: (context, index) {
          final banner = banners[index];
          return ListTile(
            leading: GestureDetector(
              onTap: () => _showImagePreview(banner['benner']),
              child: _buildBannerImage(banner['benner']),
            ),
            title: Text('Banner ${banner['id']}'),
            subtitle: Text(banner['created_at'] ?? ''),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteDialog(banner['id']),
            ),
          );
        },
      ),
      persistentFooterButtons: _imageFile != null
          ? [
        ElevatedButton(
          onPressed: _addBanner,
          child: Text('Upload Banner'),
        ),
        ElevatedButton(
          onPressed: () => setState(() => _imageFile = null),
          child: Text('Cancel'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
        ),
      ]
          : null,
    );
  }

  void _showDeleteDialog(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Banner'),
        content: Text('Are you sure you want to delete this banner?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteBanner(id);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }}