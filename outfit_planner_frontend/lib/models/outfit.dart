class Outfit {
  final String id;
  final String name;
  final List<String> itemIds;

  Outfit({required this.id, required this.name, required this.itemIds});

  factory Outfit.fromJson(Map<String, dynamic> json) {
    return Outfit(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Outfit',
      itemIds: List<String>.from(json['items'] ?? []),
    );
  }
}
