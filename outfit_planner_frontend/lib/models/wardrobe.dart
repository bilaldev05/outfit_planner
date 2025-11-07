class WardrobeItem {
  final String id;
  final String name;
  final String category;
  final String color;
  final String? season;
  final String? image; // path from backend

  WardrobeItem({
    required this.id,
    required this.name,
    required this.category,
    required this.color,
    this.season,
    this.image,
  });

  factory WardrobeItem.fromJson(Map<String, dynamic> json) {
    return WardrobeItem(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      color: json['color'] ?? '',
      season: json['season'],
      image: json['image'],
    );
  }
}
