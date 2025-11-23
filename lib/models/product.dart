class Product {
  final String id;
  final String name;
  final double price;
  final String image;
  final String category;
  int stock; 

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.category,
    this.stock = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      image: json['image'] ?? '',
      category: json['category'] ?? 'Geral',
      stock: int.tryParse(json['stock'].toString()) ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'image': image,
      'category': category,
      'stock': stock, 
    };
  }
}