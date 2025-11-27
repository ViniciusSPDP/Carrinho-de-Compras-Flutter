import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ProductsService {
  // Verifique se esta URL está correta para o seu MockAPI
  final String _baseUrl = 'https://6922888209df4a492322ab04.mockapi.io/products';

  Future<List<Product>> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<Product> products = body.map((dynamic item) => Product.fromJson(item)).toList();
        return products;
      } else {
        throw Exception('Falha ao carregar produtos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  Future<void> addProduct(Product product) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(product.toJson()),
    );

    // AQUI ESTÁ A CORREÇÃO: Verificar se deu certo
    if (response.statusCode != 200 && response.statusCode != 201) {
      print("ERRO AO SALVAR: ${response.body}"); // Mostra no console o motivo
      throw Exception('Erro ao salvar produto: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> updateProduct(Product product) async {
    final url = '$_baseUrl/${product.id}'; 
    final response = await http.put(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(product.toJson()),
    );

    // VERIFICAÇÃO DE ERRO
    if (response.statusCode != 200) {
      print("ERRO AO ATUALIZAR: ${response.body}");
      throw Exception('Erro ao atualizar: ${response.statusCode}');
    }
  }

  Future<void> deleteProduct(String id) async {
    final url = '$_baseUrl/$id';
    final response = await http.delete(Uri.parse(url));

    // VERIFICAÇÃO DE ERRO
    if (response.statusCode != 200) {
      throw Exception('Erro ao excluir: ${response.statusCode}');
    }
  }
}