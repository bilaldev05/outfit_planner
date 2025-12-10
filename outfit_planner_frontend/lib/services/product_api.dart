// services/product_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

const String BACKEND_BASE = "http://127.0.0.1:8000"; // Android emulator; change for device

class ProductApi {
  final String base;

  ProductApi({this.base = BACKEND_BASE});

  Future<List<Product>> searchProducts({
    required String category,
    String? color,
    int maxResults = 24,
  }) async {
   final uri = Uri.parse('$base/search_products');
final body = jsonEncode({
  "category": category,
  "color": color,
  "max_results": maxResults,
});

    final res = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: body);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final List items = data['products'] ?? [];
      return items.map((e) => Product.fromJson(Map<String, dynamic>.from(e))).toList();
    } else {
      throw Exception('Search failed: ${res.statusCode}');
    }
  }
}
