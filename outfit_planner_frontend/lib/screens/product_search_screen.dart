// screens/product_search_screen.dart
import 'package:flutter/material.dart';
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
  final TextEditingController _categoryCtrl = TextEditingController();
  final TextEditingController _colorCtrl = TextEditingController();
  bool _loading = false;
  List<Product> _products = [];
  String? _error;

  Future<void> _search() async {
    final category = _categoryCtrl.text.trim();
    if (category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter category')));
      return;
    }
    setState(() {
      _loading = true;
      _products = [];
      _error = null;
    });
    try {
      final res = await api.searchProducts(category: category, color: _colorCtrl.text.trim().isEmpty ? null : _colorCtrl.text.trim());
      setState(() => _products = res);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _categoryCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Products (Brands)')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          TextField(controller: _categoryCtrl, decoration: const InputDecoration(labelText: 'Category (e.g., formal, shirt, shoes)')),
          const SizedBox(height: 8),
          TextField(controller: _colorCtrl, decoration: const InputDecoration(labelText: 'Color (optional)')),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _loading ? null : _search, child: _loading ? const CircularProgressIndicator() : const Text('Search')),
          const SizedBox(height: 12),
          Expanded(child: _buildResults())
        ]),
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Error: $_error'));
    if (_products.isEmpty) return const Center(child: Text('No products found'));
    return GridView.builder(
      itemCount: _products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 0.66, crossAxisSpacing: 8, mainAxisSpacing: 8
      ),
      itemBuilder: (context, i) => ProductCard(product: _products[i]),
    );
  }
}
