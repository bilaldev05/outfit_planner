import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_api.dart';

class CartProvider extends ChangeNotifier {
  final ProductApi api = ProductApi();

  String? get userId => FirebaseAuth.instance.currentUser?.uid;

  List<Product> _items = [];
  List<Product> get items => _items;

  bool get isLoggedIn => userId != null;

  /// Fetch cart from backend
  Future<void> fetchCart() async {
    if (!isLoggedIn) return;
    _items = await api.getCart(userId!);
    notifyListeners();
  }

  /// Add to cart
  Future<void> add(Product product) async {
    if (!isLoggedIn) return;
    await api.addToCart(userId!, product);
    _items.add(product);
    notifyListeners();
  }

  /// Remove from cart
  Future<void> remove(Product product) async {
    if (!isLoggedIn) return;
    await api.removeFromCart(userId!, product.link);
    _items.removeWhere((p) => p.link == product.link);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
