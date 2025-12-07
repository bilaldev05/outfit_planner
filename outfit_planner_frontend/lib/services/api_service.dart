import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

const String BASE_URL =  "http://127.0.0.1:8000"; // Android emulator

class ApiService {
  final String baseUrl;
  ApiService({this.baseUrl = BASE_URL});

  String resolveImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    if (imagePath.startsWith('http')) return imagePath;
    return '$baseUrl$imagePath';
  }

  Future<List<Map<String, dynamic>>> getWardrobe() async {
    final res = await http.get(Uri.parse('$baseUrl/wardrobe/'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is List) return data.map((e) => Map<String, dynamic>.from(e)).toList();
      throw Exception('Unexpected response format');
    } else {
      throw Exception('Failed to fetch wardrobe');
    }
  }

  Future<void> addWardrobeItem({
    required Map<String, String> fields,
    File? image,
    Uint8List? webImage,
    String? webFilename,
  }) async {
    final uri = Uri.parse('$baseUrl/wardrobe/add-item');
    final request = http.MultipartRequest('POST', uri);
    request.fields.addAll(fields);
    if (image != null) request.files.add(await http.MultipartFile.fromPath('image', image.path));
    else if (webImage != null && webFilename != null) {
      request.files.add(http.MultipartFile.fromBytes('image', webImage, filename: webFilename));
    }
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to add item: ${res.statusCode} ${res.body}');
    }
  }

  Future<Map<String, dynamic>> recommendOutfit({
    required String event,
    String? preferColor,
    String? season,
  }) async {
    final uri = Uri.parse('$baseUrl/recommend?event=${Uri.encodeQueryComponent(event)}'
        '${preferColor != null ? "&prefer_color=${Uri.encodeQueryComponent(preferColor)}" : ""}'
        '${season != null ? "&season=${Uri.encodeQueryComponent(season)}" : ""}');
    final res = await http.get(uri);
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('Failed to get recommendations: ${res.statusCode}');
  }
}
