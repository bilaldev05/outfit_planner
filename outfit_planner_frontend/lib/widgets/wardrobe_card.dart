import 'package:flutter/material.dart';
import 'package:outfit_planner_frontend/models/wardrobe.dart';
import 'package:outfit_planner_frontend/services/api_service.dart';

class WardrobeCard extends StatelessWidget {
  final WardrobeItem item;
  final bool selected;
  final ApiService _api = ApiService();

  WardrobeCard({
    super.key,
    required this.item,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = _api.resolveImageUrl(item.image);

    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: imageUrl.isNotEmpty
                        ? FadeInImage.assetNetwork(
                            placeholder: 'assets/placeholder.png',
                            image: imageUrl,
                            fit: BoxFit.cover,
                          )
                        : Image.asset('assets/placeholder.png',
                            fit: BoxFit.cover),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    item.category.isNotEmpty ? item.category : 'Unknown Item',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
            if (selected)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.check_circle, color: Colors.indigo, size: 26),
              ),
          ],
        ),
      ),
    );
  }
}
