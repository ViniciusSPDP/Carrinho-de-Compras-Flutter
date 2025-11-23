import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/products_service.dart';

class CartItem {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final String image;

  CartItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.image,
  });
}

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};
  Map<String, double> _coupons = {'FATEC10': 10.0};

  double _frete = 0.0;
  double _descontoPorcentagem = 0.0;
  String? _cupomAplicado;

  Map<String, CartItem> get items => {..._items};
  Map<String, double> get coupons => {..._coupons};
  int get itemCount => _items.length;
  double get frete => _frete;
  double get descontoPorcentagem => _descontoPorcentagem;
  String? get cupomAplicado => _cupomAplicado;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  double get totalFinal {
    double subtotal = totalAmount;
    double valorDesconto = subtotal * (_descontoPorcentagem / 100);
    return subtotal + _frete - valorDesconto;
  }

  void cadastrarCupom(String codigo, double porcentagem) {
    _coupons[codigo.toUpperCase()] = porcentagem;
    notifyListeners();
  }

  void removerCupom(String codigo) {
    final key = codigo.toUpperCase();
    _coupons.remove(key);
    
    // Se o cupom removido era o aplicado, remove a aplicação
    if (_cupomAplicado == key) {
      _descontoPorcentagem = 0.0;
      _cupomAplicado = null;
    }
    
    notifyListeners();
  }

  bool aplicarCupom(String codigo) {
    final key = codigo.toUpperCase();
    if (_coupons.containsKey(key)) {
      _descontoPorcentagem = _coupons[key]!;
      _cupomAplicado = key;
      notifyListeners();
      return true;
    }
    return false;
  }

  void calcularFrete(String cep) {
    String cleanCep = cep.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanCep.length != 8) {
      _frete = 0.0;
      notifyListeners();
      return;
    }

    int cepInt = int.parse(cleanCep);

    if (cepInt >= 15600000 && cepInt <= 15614999) {
      _frete = 0.00;
    } else if (cepInt >= 01000000 && cepInt <= 19999999) {
      _frete = 25.00;
    } else {
      _frete = 50.00;
    }
    notifyListeners();
  }

  void addItem(Product product) {
    if (_items.containsKey(product.id)) {
      _items.update(
        product.id,
        (existingItem) => CartItem(
          id: existingItem.id,
          name: existingItem.name,
          quantity: existingItem.quantity + 1,
          price: existingItem.price,
          image: existingItem.image,
        ),
      );
    } else {
      _items.putIfAbsent(
        product.id,
        () => CartItem(
          id: product.id,
          name: product.name,
          quantity: 1,
          price: product.price,
          image: product.image,
        ),
      );
    }
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) return;
    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          name: existingCartItem.name,
          quantity: existingCartItem.quantity - 1,
          price: existingCartItem.price,
          image: existingCartItem.image,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items = {};
    _frete = 0.0;
    _descontoPorcentagem = 0.0;
    _cupomAplicado = null;
    notifyListeners();
  }

  Future<void> finalizarPedido() async {
    final service = ProductsService();

    List<Product> serverProducts = await service.fetchProducts();

    for (var cartItem in _items.values) {
      Product? serverProduct;
      try {
        serverProduct = serverProducts.firstWhere((p) => p.id == cartItem.id);
      } catch (e) {
        throw Exception('O produto ${cartItem.name} não existe mais na loja.');
      }

      if (serverProduct.stock < cartItem.quantity) {
        throw Exception(
          'Estoque insuficiente para ${cartItem.name}.\nDisponível: ${serverProduct.stock}, Solicitado: ${cartItem.quantity}',
        );
      }
    }

    for (var cartItem in _items.values) {
      final serverProduct = serverProducts.firstWhere(
        (p) => p.id == cartItem.id,
      );

      serverProduct.stock -= cartItem.quantity;

      await service.updateProduct(serverProduct);
    }

    clear();
  }
}