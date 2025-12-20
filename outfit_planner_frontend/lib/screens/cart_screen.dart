import 'package:flutter/material.dart';
import 'package:outfit_planner_frontend/screens/outfit_result_screen.dart';
import 'package:outfit_planner_frontend/services/product_api.dart';
import 'package:outfit_planner_frontend/widgets/cart_provider.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';

/// Assigns a category to a product if missing.
Product autoAssignCategory(Product product) {
  final title = product.title.toLowerCase().trim();

  if (title.contains('shirt') || title.contains('tshirt') || title.contains('top')) {
    product.category = 'shirt';
  } else if (title.contains('pant') ||
      title.contains('jeans') ||
      title.contains('trouser') ||
      title.contains('short') ||
      title.contains('skirt')) {
    product.category = 'pant';
  } else if (title.contains('shoe') || title.contains('sneaker') || title.contains('boot')) {
    product.category = 'shoe';
  } else {
    // fallback: alternate top/bottom to ensure outfit generation
    product.category = ['shirt', 'pant'][DateTime.now().millisecond % 2];
  }

  debugPrint("Assigned category for '${product.title}': ${product.category}");
  return product;
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.orange.shade700,
        elevation: 1,
      ),
      body: cart.items.isEmpty
          ? const Center(
              child: Text(
                'Your cart is empty',
                style: TextStyle(fontSize: 18),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (_, index) {
                      final product = cart.items[index];
                      return ListTile(
                        leading: product.image.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  product.image,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.image_not_supported),
                                ),
                              )
                            : const Icon(Icons.image, size: 50),
                        title: Text(
                          product.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(product.brand),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => cart.remove(product),
                          tooltip: 'Remove from cart',
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: 250,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _buildOutfit(context, cart),
                      child: const Text(
                        'Build Outfit',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// Handles outfit building logic.
  void _buildOutfit(BuildContext context, CartProvider cart) async {
    if (cart.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to build an outfit')),
      );
      return;
    }

    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Your cart is empty!')));
      return;
    }

    // Assign categories
    final itemsWithCategory = cart.items.map(autoAssignCategory).toList();

    // Count tops and bottoms
    final topsCount =
        itemsWithCategory.where((p) => p.category.trim().toLowerCase() == 'shirt').length;
    final bottomsCount =
        itemsWithCategory.where((p) => p.category.trim().toLowerCase() == 'pant').length;

    debugPrint('Tops: $topsCount, Bottoms: $bottomsCount');

    if (topsCount == 0 || bottomsCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need at least one top and one bottom to build an outfit!'),
        ),
      );
      return;
    }

    final api = ProductApi();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await api.buildOutfit(
        itemsWithCategory,
        cart.userId!, // Firebase UID (safe now)
      );

      Navigator.pop(context); // close loader
      debugPrint('Outfit API result: $result');

      if (!result.containsKey('success')) {
        throw Exception('Unexpected outfit API response');
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OutfitResultScreen(outfitData: result),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to build outfit: $e')));
    }
  }
}
