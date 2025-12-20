import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

const String BACKEND_BASE = "http://127.0.0.1:8000";

class ProductApi {
  final String base;

  ProductApi({this.base = BACKEND_BASE});

  // 🔍 SEARCH PRODUCTS
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

  // 🤖 BUILD OUTFIT FROM CART
  Future<Map<String, dynamic>> buildOutfit(List<Product> items, String userId) async {
  final uri = Uri.parse('$base/build_outfit');

  final body = jsonEncode({
    "items": items.map((p) => p.toJson()).toList(),
    "userId": userId, // send userId for backend storage
  });

  final res = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: body,
  );

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    // Ensure 'success' key exists
    if (!data.containsKey('success')) {
      return {"success": false, "outfits": []};
    }
    return data;
  } else {
    throw Exception('Outfit generation failed: ${res.statusCode}');
  }
}


  // ----------------- Cart API -----------------
  Future<void> addToCart(String userId, Product product) async {
    final uri = Uri.parse('$base/cart/add');
    final body = jsonEncode({"user_id": userId, "product": product.toJson()});
    final res = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: body);
    if (res.statusCode != 200) throw Exception('Add to cart failed');
  }

  Future<void> removeFromCart(String userId, String productLink) async {
    final uri = Uri.parse('$base/cart/$userId/$productLink');
    final res = await http.delete(uri);
    if (res.statusCode != 200) throw Exception('Remove from cart failed');
  }

  Future<List<Product>> getCart(String userId) async {
    final uri = Uri.parse('$base/cart/$userId');
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final List items = data['items'] ?? [];
      return items.map((e) => Product.fromJson(Map<String, dynamic>.from(e['product']))).toList();
    } else {
      throw Exception('Fetch cart failed');
    }
  }

  // ----------------- Fetch outfits -----------------
  Future<List<Map<String, dynamic>>> getOutfits(String userId) async {
    final uri = Uri.parse('$base/outfit/$userId');
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final List outfits = data['outfits'] ?? [];
      return outfits.map((e) => Map<String, dynamic>.from(e['outfit'])).toList();
    } else {
      throw Exception('Fetch outfits failed');
    }
  }
}
