import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

const String baseUrl = "http://127.0.0.1:8000";

class ApiService {
  final String baseUrl = 'http://127.0.0.1:8000';

  /// Resolve backend image path to full URL
  String resolveImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    if (imagePath.startsWith('http')) return imagePath;
    return '$baseUrl$imagePath';
  }

  /// Fetch wardrobe items
  Future<List<Map<String, dynamic>>> getWardrobe() async {
    final res = await http.get(Uri.parse('$baseUrl/wardrobe/'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      // Debug prints
      print("Raw API response: $data");
      print("Type of data: ${data.runtimeType}");

      if (data is List) {
        // Convert each element to Map<String,dynamic>
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        throw Exception(
            'Unexpected API response format: Expected List of objects');
      }
    } else {
      throw Exception('Failed to fetch wardrobe');
    }
  }

  /// Add wardrobe item
  Future<void> addWardrobeItem({
    required Map<String, String> fields,
    File? image,
    Uint8List? webImage,
    String? webFilename,
  }) async {
    final uri = Uri.parse('$baseUrl/wardrobe/add-item');
    final request = http.MultipartRequest('POST', uri);

    fields.forEach((key, value) => request.fields[key] = value);

    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
    } else if (webImage != null && webFilename != null) {
      request.files.add(
        http.MultipartFile.fromBytes('image', webImage, filename: webFilename),
      );
    }

    final res = await request.send();
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to add item');
    }
  }
}
