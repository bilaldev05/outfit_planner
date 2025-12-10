class Product {
  final String title;
  final String price;
  final String image;
  final String link;
  final String brand;
  final String source;

  Product({
    required this.title,
    required this.price,
    required this.image,
    required this.link,
    required this.brand,
    required this.source,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      title: json['title'] ?? '',
      price: json['price'] ?? '',
      image: json['image'] ?? '',
      link: json['link'] ?? '',
      brand: json['brand'] ?? '',
      source: json['source'] ?? '',
    );
  }
}
