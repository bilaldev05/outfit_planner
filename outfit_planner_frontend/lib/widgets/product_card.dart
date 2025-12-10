import 'package:flutter/material.dart';
import '../models/product.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  // Fix URLs starting with "//"
  String fixUrl(String url) {
    if (url.startsWith("//")) return "https:$url";
    return url;
  }

  Future<void> _openLink(BuildContext context) async {
    if (product.link.isNotEmpty) {
      final uri = Uri.tryParse(product.link);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cannot open link")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No link available")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: product.image.isNotEmpty
                ? Image.network(
                    fixUrl(product.image),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/placeholder.png',
                        fit: BoxFit.cover,
                        width: double.infinity,
                      );
                    },
                  )
                : Image.asset(
                    'assets/placeholder.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
          ),

          // Product Details
          Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),

                // Price
                if (product.price.isNotEmpty)
                  Text(
                    product.price,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                const SizedBox(height: 2),

                // Brand
                if (product.brand.isNotEmpty)
                  Text(
                    product.brand,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                const SizedBox(height: 2),

                // Source
                if (product.source.isNotEmpty)
                  Text(
                    product.source,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                const SizedBox(height: 4),

                // "View Product" Button
                ElevatedButton(
                  onPressed: () => _openLink(context),
                  child: const Text("View Product"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(30),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
