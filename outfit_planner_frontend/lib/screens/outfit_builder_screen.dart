import 'package:flutter/material.dart';
import 'package:outfit_planner_frontend/models/wardrobe.dart';
import 'package:outfit_planner_frontend/services/api_service.dart';

class OutfitBuilderScreen extends StatefulWidget {
  const OutfitBuilderScreen({super.key});

  @override
  State<OutfitBuilderScreen> createState() => _OutfitBuilderScreenState();
}

class _OutfitBuilderScreenState extends State<OutfitBuilderScreen> {
  final ApiService _api = ApiService();
  List<WardrobeItem> items = [];
  String? topId, bottomId, shoesId;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => loading = true);
    try {
      final raw = await _api.getWardrobe();
      setState(() {
        items = raw.map((e) => WardrobeItem.fromJson(e)).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(12.0),
          child: Text(
            'Pick items and save your outfit',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, i) {
              final it = items[i];
              final selected =
                  it.id == topId || it.id == bottomId || it.id == shoesId;

              return GestureDetector(
                onTap: () => _showSelectDialog(it),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(2, 2),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                              child: it.image != null && it.image!.isNotEmpty
                                  ? FadeInImage.assetNetwork(
                                      placeholder: 'assets/placeholder.png',
                                      image:
                                          _api.resolveImageUrl(it.image!), // ✅
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    )
                                  : Image.asset(
                                      'assets/placeholder.png',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              it.category.isNotEmpty
                                  ? it.category
                                  : 'Unknown category',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      const Positioned(
                        top: 8,
                        right: 8,
                        child: Icon(Icons.check_circle,
                            color: Colors.indigo, size: 28),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showSelectDialog(WardrobeItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Select role for this item')),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Top'),
              onTap: () {
                setState(() => topId = item.id);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.view_column),
              title: const Text('Bottom'),
              onTap: () {
                setState(() => bottomId = item.id);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_run),
              title: const Text('Shoes'),
              onTap: () {
                setState(() => shoesId = item.id);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
