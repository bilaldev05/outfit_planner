import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:outfit_planner_frontend/screens/cart_screen.dart';
import 'package:outfit_planner_frontend/screens/login_screen.dart';
import '../services/product_api.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';

class ProductSearchScreen extends StatefulWidget {
  const ProductSearchScreen({super.key});

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  final ProductApi api = ProductApi();

  final List<String> _categories = ['Formal', 'Casual', 'Shoes', 'Sports', 'Party'];
  final List<String> _colors = ['Red', 'Blue', 'Black', 'White', 'Green', 'Yellow'];

  String? _selectedCategory;
  String? _selectedColor;

  bool _loading = false;
  List<Product> _products = [];
  String? _error;

  Future<void> _search() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _products = [];
      _error = null;
    });

    try {
      final res = await api.searchProducts(
        category: _selectedCategory!.toLowerCase(),
        color: _selectedColor?.toLowerCase(),
      );
      setState(() => _products = res);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
    appBar:  AppBar(
  backgroundColor: Colors.orange.shade700,
  title: const Text(
    "Shop",
    style: TextStyle(color: Colors.white),
  ),
  centerTitle: true,
  elevation: 1,
  actions: [
    // 🛒 Cart Button
    IconButton(
      icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CartScreen()),
        );
      },
    ),

    // 🚪 Logout Button
    IconButton(
      icon: const Icon(Icons.logout, color: Colors.white),
      tooltip: 'Logout',
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Logout'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await FirebaseAuth.instance.signOut();

          if (!context.mounted) return;

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      },
    ),
  ],
),

      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.category_outlined),
                  hintText: "Select category",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
                onChanged: (val) => setState(() => _selectedCategory = val),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedColor,
                items: _colors
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.color_lens_outlined),
                  hintText: "Select color (optional)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
                onChanged: (val) => setState(() => _selectedColor = val),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.search),
                  label: const Text(
                    "Search Products",
                    style: TextStyle( fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _loading ? null : _search,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 50, color: Colors.red.shade400),
            const SizedBox(height: 8),
            Text(
              "Error: $_error",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            const Text(
              "No products found",
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _search,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _products.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.62,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (_, i) => ProductCard(product: _products[i]),
      ),
    );
  }
}
