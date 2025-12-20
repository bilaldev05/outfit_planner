class Product {
  final String title;
  final String price;
  final String image;
  final String link;
  final String brand;
  String category;

  Product({
    required this.title,
    required this.price,
    required this.image,
    required this.link,
    required this.brand,
    this.category = "",
  }) {
    _autoAssignCategory();
  }

  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "price": price,
      "image": image,
      "link": link,
      "brand": brand,
      "category": category.toLowerCase(), 
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      title: json['title'] ?? '',
      price: json['price'] ?? '',
      image: json['image'] ?? '',
      link: json['link'] ?? '',
      brand: json['brand'] ?? '',
      category: json['category'] ?? '',
    );
  }

  void _autoAssignCategory() {
    final t = title.toLowerCase();

    if (t.contains("shirt") || t.contains("tshirt") || t.contains("top")) {
      category = "shirt";
    } else if (t.contains("pant") || t.contains("jeans") || t.contains("trouser")) {
      category = "pant";
    } else if (t.contains("shoe") || t.contains("sneaker") || t.contains("boot")) {
      category = "shoe";
    } else {
      category = "shirt"; 
    }
  }
}
