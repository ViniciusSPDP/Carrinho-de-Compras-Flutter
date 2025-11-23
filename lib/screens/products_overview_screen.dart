import 'package:flutter/material.dart';
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

class _ProductsOverviewScreenState extends State<ProductsOverviewScreen> {
  final ProductsService _productsService = ProductsService();
  late Future<List<Product>> _productsFuture;
  
  String _searchQuery = "";
  String _selectedCategory = 'Todas';
  double _maxPriceFilter = 10000.0;
  bool _filtersInitialized = false;

  @override
  void initState() {
    super.initState();
    _productsFuture = _productsService.fetchProducts();
  }

  Future<void> _seedDatabase(BuildContext context) async {
    final List<Product> dummyProducts = [
      Product(id: '', name: 'Notebook Gamer', price: 4500.00, stock: 5, category: 'Eletrônicos', image: 'https://placehold.co/400/png?text=Notebook'),
      Product(id: '', name: 'Smartphone Pro', price: 2800.00, stock: 8, category: 'Eletrônicos', image: 'https://placehold.co/400/png?text=Smartphone'),
      Product(id: '', name: 'Tênis de Corrida', price: 299.90, stock: 12, category: 'Calçados', image: 'https://placehold.co/400/png?text=Tenis'),
      Product(id: '', name: 'Cafeteira Express', price: 450.00, stock: 3, category: 'Eletro', image: 'https://placehold.co/400/png?text=Cafe'),
      Product(id: '', name: 'Kit Ferramentas', price: 120.00, stock: 20, category: 'Utilidades', image: 'https://placehold.co/400/png?text=Ferramentas'),
    ];

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gerando produtos com estoque... aguarde!')),
    );

    for (var prod in dummyProducts) {
      await _productsService.addProduct(prod);
    }

    setState(() {
      _productsFuture = _productsService.fetchProducts();
    });

    if (context.mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('5 Produtos gerados com sucesso!')),
      );
      Navigator.of(context).pop(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fatec Shop'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const CartScreen()),
                  );
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: Colors.red,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '${cart.itemCount}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              )
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.shop),
              title: const Text('Loja'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Administrativo'),
              onTap: () {
                Navigator.of(context).pop(); 
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const AdminScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.download_for_offline, color: Colors.green),
              title: const Text('Gerar Produtos (Teste)'),
              subtitle: const Text('Cria 5 itens com estoque'),
              onTap: () => _seedDatabase(context),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.error != null) {
            return const Center(child: Text('Erro ao carregar produtos'));
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

            return Column(
              children: [
                ExpansionTile(
                  title: const Text('Filtros e Pesquisa'),
                  leading: const Icon(Icons.filter_list),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Pesquisar por nome',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          const Text('Categoria: '),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: categories.contains(_selectedCategory) ? _selectedCategory : 'Todas',
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
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Preço Máximo: R\$ ${_maxPriceFilter.toStringAsFixed(2)}'),
                          Slider(
                            value: _maxPriceFilter,
                            min: 0,
                            max: maxProductPrice > 0 ? maxProductPrice : 10000,
                            divisions: 20,
                            label: _maxPriceFilter.toStringAsFixed(2),
                            onChanged: (double value) {
                              setState(() {
                                _maxPriceFilter = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: filteredProducts.isEmpty 
                    ? const Center(child: Text('Nenhum produto encontrado.'))
                    : GridView.builder(
                    padding: const EdgeInsets.all(10.0),
                    itemCount: filteredProducts.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, 
                      childAspectRatio: 3 / 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (ctx, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: GridTile(
                        footer: GridTileBar(
                          backgroundColor: Colors.black87,
                          leading: IconButton(
                            icon: const Icon(Icons.shopping_bag_outlined),
                            color: Theme.of(context).colorScheme.secondary,
                            onPressed: () {
                              cart.addItem(filteredProducts[i]);
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${filteredProducts[i].name} adicionado!'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          title: Text(
                            filteredProducts[i].name,
                            textAlign: TextAlign.center,
                          ),
                          subtitle: Text(
                            'Estoque: ${filteredProducts[i].stock}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: filteredProducts[i].stock > 0 ? Colors.greenAccent : Colors.redAccent,
                              fontSize: 12
                            ),
                          ),
                          trailing: Text(
                            'R\$ ${filteredProducts[i].price.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        child: InkWell(
                          onTap: () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) => ProductDetailScreen(product: filteredProducts[i]),
                              ),
                            );
                            
                            if (result == true) {
                              setState(() {
                                _productsFuture = _productsService.fetchProducts();
                                _filtersInitialized = false; 
                              });
                            }
                          },
                          child: Image.network(
                            filteredProducts[i].image,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, error, stackTrace) => 
                                const Center(child: Icon(Icons.image_not_supported, size: 50)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
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
}