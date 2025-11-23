import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/products_service.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> 
    with SingleTickerProviderStateMixin {
  final _priceFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  var _editedProduct = Product(
    id: '',
    name: '',
    price: 0,
    image: '',
    category: '',
  );

  var _initValues = {
    'name': '',
    'price': '',
    'stock': '',
    'category': '',
    'image': '',
  };

  var _isInit = true;
  var _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      final productId = ModalRoute.of(context)?.settings.arguments;
      if (productId != null && productId is Product) {
        _editedProduct = productId;
        _initValues = {
          'name': _editedProduct.name,
          'price': _editedProduct.price.toString(),
          'stock': _editedProduct.stock.toString(),
          'category': _editedProduct.category,
          'image': _editedProduct.image,
        };
      }
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _priceFocusNode.dispose();
    super.dispose();
  }

  bool _isValidImageUrl(String url) {
    return (url.startsWith('http') || url.startsWith('https')) &&
        (url.endsWith('.png') || url.endsWith('.jpg') || url.endsWith('.jpeg'));
  }

  Future<void> _saveForm() async {
    final isValid = _formKey.currentState?.validate();
    if (isValid == null || !isValid) {
      return;
    }

    _formKey.currentState?.save();

    setState(() {
      _isLoading = true;
    });

    try {
      if (_editedProduct.id.isEmpty) {
        await ProductsService().addProduct(_editedProduct);
      } else {
        await ProductsService().updateProduct(_editedProduct);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editedProduct.id.isEmpty
                  ? '✓ Produto criado com sucesso!'
                  : '✓ Produto atualizado!',
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Color(0xFFEF4444)),
                SizedBox(width: 12),
                Text('Erro'),
              ],
            ),
            content: const Text('Não foi possível salvar o produto.'),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Ok'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Text(
          _editedProduct.id.isEmpty ? 'Novo Produto' : 'Editar Produto',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveForm,
              tooltip: 'Salvar',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF6366F1),
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
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
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.info_outline,
                                    color: Color(0xFF6366F1),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Text(
                                  'Informações Básicas',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              initialValue: _initValues['name'],
                              decoration: const InputDecoration(
                                labelText: 'Nome do Produto',
                                hintText: 'Ex: Notebook Gamer',
                                prefixIcon: Icon(Icons.shopping_bag_outlined),
                              ),
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) {
                                FocusScope.of(context).requestFocus(_priceFocusNode);
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Informe o nome do produto';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _editedProduct = Product(
                                  id: _editedProduct.id,
                                  name: value!,
                                  price: _editedProduct.price,
                                  stock: _editedProduct.stock,
                                  image: _editedProduct.image,
                                  category: _editedProduct.category,
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: _initValues['category'],
                              decoration: const InputDecoration(
                                labelText: 'Categoria',
                                hintText: 'Ex: Eletrônicos',
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Informe a categoria';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _editedProduct = Product(
                                  id: _editedProduct.id,
                                  name: _editedProduct.name,
                                  price: _editedProduct.price,
                                  stock: _editedProduct.stock,
                                  image: _editedProduct.image,
                                  category: value!,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(24),
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
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.attach_money,
                                    color: Color(0xFF10B981),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Text(
                                  'Preço e Estoque',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              initialValue: _initValues['price'],
                              decoration: const InputDecoration(
                                labelText: 'Preço',
                                hintText: 'Ex: 1500.00',
                                prefixIcon: Icon(Icons.price_change_outlined),
                                prefixText: 'R\$ ',
                              ),
                              textInputAction: TextInputAction.next,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              focusNode: _priceFocusNode,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Informe o preço';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Informe um número válido';
                                }
                                if (double.parse(value) <= 0) {
                                  return 'Informe um valor maior que zero';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _editedProduct = Product(
                                  id: _editedProduct.id,
                                  name: _editedProduct.name,
                                  price: double.parse(value!),
                                  stock: _editedProduct.stock,
                                  image: _editedProduct.image,
                                  category: _editedProduct.category,
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: _initValues['stock'],
                              decoration: const InputDecoration(
                                labelText: 'Quantidade em Estoque',
                                hintText: 'Ex: 10',
                                prefixIcon: Icon(Icons.inventory_outlined),
                              ),
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Informe o estoque';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Informe um número válido';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _editedProduct = Product(
                                  id: _editedProduct.id,
                                  name: _editedProduct.name,
                                  price: _editedProduct.price,
                                  stock: int.parse(value!),
                                  image: _editedProduct.image,
                                  category: _editedProduct.category,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(24),
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
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.image_outlined,
                                    color: Color(0xFFF59E0B),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Text(
                                  'Imagem do Produto',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              initialValue: _initValues['image'],
                              decoration: const InputDecoration(
                                labelText: 'URL da Imagem',
                                hintText: 'https://exemplo.com/imagem.jpg',
                                prefixIcon: Icon(Icons.link),
                              ),
                              keyboardType: TextInputType.url,
                              textInputAction: TextInputAction.done,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Informe a URL da imagem';
                                }
                                if (!_isValidImageUrl(value)) {
                                  return 'URL inválida (use .png, .jpg ou .jpeg)';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _editedProduct = Product(
                                  id: _editedProduct.id,
                                  name: _editedProduct.name,
                                  price: _editedProduct.price,
                                  stock: _editedProduct.stock,
                                  image: value!,
                                  category: _editedProduct.category,
                                );
                              },
                              onFieldSubmitted: (_) => _saveForm(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _saveForm,
                        child: Text(
                          _editedProduct.id.isEmpty ? 'CRIAR PRODUTO' : 'SALVAR ALTERAÇÕES',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}