import 'package:flutter/material.dart';

class OutfitResultScreen extends StatelessWidget {
  final Map<String, dynamic> outfitData;
  const OutfitResultScreen({super.key, required this.outfitData});

  @override
  Widget build(BuildContext context) {
    final success = outfitData['success'] == true;
    final List outfits = outfitData['outfits'] ?? [];

    if (!success || outfits.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.orange.shade700,
          title: const Text("Outfit Result", style: TextStyle(color: Colors.white),),
        ),
        body: const Center(
          child: Text(
            "No outfit generated",
            style: TextStyle(fontSize: 18, color: Colors.black54),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange.shade700,
        title: const Text("Outfit Result", style: TextStyle(color: Colors.white),),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: outfits.length,
        itemBuilder: (context, index) {
          final outfit = outfits[index];
          final List<Map<String, dynamic>> items = [];
          if (outfit['top'] != null) items.add(outfit['top']);
          if (outfit['bottom'] != null) items.add(outfit['bottom']);
          if (outfit['shoes'] != null) items.add(outfit['shoes']);

          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Outfit ${index + 1}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: items.map((item) {
                      final image = (item['image'] ?? '').toString();
                      final title = (item['title'] ?? 'Unknown Product').toString();
                      final brand = (item['brand'] ?? 'Unknown Brand').toString();
                      final price = (item['price'] ?? 'N/A').toString();

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: image.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(image, width: 50, height: 50, fit: BoxFit.cover),
                              )
                            : const Icon(Icons.image, size: 50),
                        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(brand, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Text(price),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
