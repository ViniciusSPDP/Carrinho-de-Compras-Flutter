import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ProductsService {
  final String _baseUrl = 'https://6922888209df4a492322ab04.mockapi.io/products';

  Future<List<Product>> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<Product> products = body.map((dynamic item) => Product.fromJson(item)).toList();
        return products;
      } else {
        throw Exception('Falha ao carregar produtos');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  Future<void> addProduct(Product product) async {
    await http.post(
      Uri.parse(_baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(product.toJson()),
    );
  }

  Future<void> updateProduct(Product product) async {
    final url = '$_baseUrl/${product.id}'; 
    await http.put(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(product.toJson()),
    );
  }

  Future<void> deleteProduct(String id) async {
    final url = '$_baseUrl/$id';
    await http.delete(Uri.parse(url));
  }
}