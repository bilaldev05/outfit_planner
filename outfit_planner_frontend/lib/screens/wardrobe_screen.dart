import 'package:flutter/material.dart';
import 'package:outfit_planner_frontend/models/wardrobe.dart';
import 'package:outfit_planner_frontend/services/api_service.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  final ApiService _api = ApiService();
  List<WardrobeItem> items = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadWardrobe();
  }

  Future<void> _loadWardrobe() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final List<Map<String, dynamic>> resList = await _api.getWardrobe();

      // Debug: check structure
      print("Decoded wardrobe list: $resList");

      final List<WardrobeItem> wardrobeItems =
          resList.map((e) => WardrobeItem.fromJson(e)).toList();

      setState(() {
        items = wardrobeItems;
      });
    } catch (e) {
      print("Error fetching wardrobe: $e");
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                'Error loading wardrobe:\n$error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadWardrobe,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.checkroom, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No items yet. Tap + to add new wardrobe items.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWardrobe,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) {
            final item = items[index]; // ✅ index is int
            final imageUrl = _api.resolveImageUrl(item.image);

            return Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {},
                child: Column(
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
                                width: double.infinity,
                                imageErrorBuilder:
                                    (context, error, stackTrace) => Image.asset(
                                  'assets/placeholder.png',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : Image.asset(
                                'assets/placeholder.png',
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        item.name.isNotEmpty ? item.name : 'Unknown Item',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        item.category.isNotEmpty ? item.category : '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
