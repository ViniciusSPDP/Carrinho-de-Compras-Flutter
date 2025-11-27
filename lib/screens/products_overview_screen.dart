import 'package:flutter/material.dart';
import 'dart:convert'; // Necessário para base64Decode
import 'package:provider/provider.dart';
import '../services/products_service.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import 'cart_screen.dart';
import 'product_form_screen.dart';
import 'product_detail_screen.dart';
import 'admin_screen.dart';

class ProductsOverviewScreen extends StatefulWidget {
  const ProductsOverviewScreen({super.key});

  @override
  State<ProductsOverviewScreen> createState() => _ProductsOverviewScreenState();
}

class _ProductsOverviewScreenState extends State<ProductsOverviewScreen> 
    with SingleTickerProviderStateMixin {
  final ProductsService _productsService = ProductsService();
  late Future<List<Product>> _productsFuture;
  late AnimationController _animationController;
  
  String _searchQuery = "";
  String _selectedCategory = 'Todas';
  double _maxPriceFilter = 10000.0;
  bool _filtersInitialized = false;
  bool _isFilterExpanded = false;

  @override
  void initState() {
    super.initState();
    _productsFuture = _productsService.fetchProducts();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _seedDatabase(BuildContext context) async {
    final List<Product> dummyProducts = [
      Product(id: '', name: 'Notebook Gamer', price: 4500.00, stock: 5, category: 'Eletrônicos', image: 'https://placehold.co/400/6366F1/FFFFFF/png?text=Notebook'),
      Product(id: '', name: 'Smartphone Pro', price: 2800.00, stock: 8, category: 'Eletrônicos', image: 'https://placehold.co/400/10B981/FFFFFF/png?text=Smartphone'),
      Product(id: '', name: 'Tênis de Corrida', price: 299.90, stock: 12, category: 'Calçados', image: 'https://placehold.co/400/F59E0B/FFFFFF/png?text=Tenis'),
      Product(id: '', name: 'Cafeteira Express', price: 450.00, stock: 3, category: 'Eletro', image: 'https://placehold.co/400/EF4444/FFFFFF/png?text=Cafeteira'),
      Product(id: '', name: 'Kit Ferramentas', price: 120.00, stock: 20, category: 'Utilidades', image: 'https://placehold.co/400/8B5CF6/FFFFFF/png?text=Ferramentas'),
    ];

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gerando produtos... aguarde!'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    for (var prod in dummyProducts) {
      await _productsService.addProduct(prod);
    }

    setState(() {
      _productsFuture = _productsService.fetchProducts();
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ 5 Produtos gerados com sucesso!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Fatec Shop',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const CartScreen()),
                  );
                },
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0xFFEF4444),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${cart.itemCount}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(context),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF6366F1),
              ),
            );
          } else if (snapshot.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar produtos',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          } else {
            final allProducts = snapshot.data!;
            final categories = ['Todas', ...allProducts.map((e) => e.category).toSet().toList()];
            
            double maxProductPrice = 0.0;
            if (allProducts.isNotEmpty) {
              maxProductPrice = allProducts.map((e) => e.price).reduce((a, b) => a > b ? a : b);
            }

            if (!_filtersInitialized && maxProductPrice > 0) {
              _maxPriceFilter = maxProductPrice;
              _filtersInitialized = true;
            }

            final filteredProducts = allProducts.where((prod) {
              final matchesSearch = prod.name.toLowerCase().contains(_searchQuery);
              final matchesCategory = _selectedCategory == 'Todas' || prod.category == _selectedCategory;
              final matchesPrice = prod.price <= _maxPriceFilter;
              return matchesSearch && matchesCategory && matchesPrice;
            }).toList();

            // CORREÇÃO 1: Trocado Column por ListView para permitir rolagem com teclado
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildFiltersCard(categories, maxProductPrice),
                filteredProducts.isEmpty 
                  ? SizedBox(
                      height: 400, // Altura fixa para centralizar visualmente
                      child: _buildEmptyState(),
                    )
                  : _buildProductGrid(filteredProducts, cart),
              ],
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 2,
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => const ProductFormScreen()),
          );
          if (result == true) {
            setState(() {
              _productsFuture = _productsService.fetchProducts();
              _filtersInitialized = false;
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.store, color: Colors.white, size: 48),
                SizedBox(height: 12),
                Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(
                  icon: Icons.store_outlined,
                  title: 'Loja',
                  onTap: () => Navigator.of(context).pop(),
                ),
                _buildDrawerItem(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Administrativo',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => const AdminScreen()),
                    );
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(),
                ),
                _buildDrawerItem(
                  icon: Icons.science_outlined,
                  title: 'Gerar Produtos (Teste)',
                  subtitle: 'Cria 5 itens com estoque',
                  color: const Color(0xFF10B981),
                  onTap: () => _seedDatabase(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      onTap: onTap,
    );
  }

  Widget _buildFiltersCard(List<String> categories, double maxProductPrice) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isFilterExpanded = !_isFilterExpanded;
              });
              if (_isFilterExpanded) {
                _animationController.forward();
              } else {
                _animationController.reverse();
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.tune,
                      color: Color(0xFF6366F1),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Filtros',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  RotationTransition(
                    turns: Tween(begin: 0.0, end: 0.5).animate(_animationController),
                    child: const Icon(Icons.expand_more),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isFilterExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Pesquisar produtos...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: categories.contains(_selectedCategory) ? _selectedCategory : 'Todas',
                          decoration: InputDecoration(
                            labelText: 'Categoria',
                            prefixIcon: const Icon(Icons.category_outlined),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          items: categories.map((String cat) {
                            return DropdownMenuItem<String>(
                              value: cat,
                              child: Text(cat),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _selectedCategory = newValue!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Preço Máximo',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'R\$ ${_maxPriceFilter.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF6366F1),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _maxPriceFilter,
                              min: 0,
                              max: maxProductPrice > 0 ? maxProductPrice : 10000,
                              activeColor: const Color(0xFF6366F1),
                              onChanged: (double value) {
                                setState(() {
                                  _maxPriceFilter = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Nenhum produto encontrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tente ajustar os filtros',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products, CartProvider cart) {
    return GridView.builder(
      // CORREÇÃO 2: Ajustes para funcionar dentro do ListView
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (ctx, i) => _buildProductCard(products[i], cart),
    );
  }

  Widget _buildProductCard(Product product, CartProvider cart) {
    return Hero(
      tag: 'product-${product.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => ProductDetailScreen(product: product),
              ),
            );
            if (result == true) {
              setState(() {
                _productsFuture = _productsService.fetchProducts();
                _filtersInitialized = false;
              });
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        // CORREÇÃO 3: Lógica da Imagem Base64 vs Network
                        child: product.image.startsWith('data:image')
                            ? Image.memory(
                                base64Decode(product.image.split(',').last),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (ctx, error, stackTrace) => Container(
                                  color: Colors.grey[100],
                                  child: const Center(child: Icon(Icons.broken_image, size: 50)),
                                ),
                              )
                            : Image.network(
                                product.image,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (ctx, error, stackTrace) => Container(
                                  color: Colors.grey[100],
                                  child: const Center(
                                    child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                                  ),
                                ),
                              ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: product.stock > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Estoque: ${product.stock}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.category,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'R\$ ${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              cart.addItem(product);
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✓ ${product.name} adicionado!'),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: const Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.add_shopping_cart,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}