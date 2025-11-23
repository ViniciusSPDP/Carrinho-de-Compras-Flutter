import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/products_service.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _priceFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();

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
  void didChangeDependencies() {
    if (_isInit) {
      final productId = ModalRoute.of(context)?.settings.arguments;
      if (productId != null && productId is Product) {
        _editedProduct = productId;
        _initValues = {
          'name': _editedProduct.name,
          'price': _editedProduct.price.toString(),
          'stock': _editedProduct.stock.toString(), // NOVO
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
                  ? 'Criado com sucesso!'
                  : 'Atualizado com sucesso!',
            ),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Ocorreu um erro!'),
            content: const Text('Erro ao salvar produto.'),
            actions: [
              TextButton(
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
      appBar: AppBar(
        title: Text(
          _editedProduct.id.isEmpty ? 'Cadastrar Produto' : 'Editar Produto',
        ),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveForm),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      initialValue: _initValues['name'],
                      decoration: const InputDecoration(
                        labelText: 'Nome do Produto',
                      ),
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_priceFocusNode);
                      },
                      validator: (value) {
                        if (value!.isEmpty) return 'Informe um nome.';
                        return null;
                      },
                      onSaved: (value) {
                        _editedProduct = Product(
                          id: _editedProduct.id,
                          name: value!,
                          price: _editedProduct.price,
                          image: _editedProduct.image,
                          category: _editedProduct.category,
                        );
                      },
                    ),

                    TextFormField(
                      initialValue: _initValues['price'],
                      decoration: const InputDecoration(
                        labelText: 'Preço (R\$)',
                      ),
                      textInputAction: TextInputAction.next,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      focusNode: _priceFocusNode,
                      validator: (value) {
                        if (value!.isEmpty) return 'Informe um preço.';
                        if (double.tryParse(value) == null)
                          return 'Informe um número válido.';
                        if (double.parse(value) <= 0)
                          return 'Informe um número maior que zero.';
                        return null;
                      },
                      onSaved: (value) {
                        _editedProduct = Product(
                          id: _editedProduct.id,
                          name: _editedProduct.name,
                          price: double.parse(value!),
                          image: _editedProduct.image,
                          category: _editedProduct.category,
                        );
                      },
                    ),

                    TextFormField(
                      initialValue: _initValues['stock'],
                      decoration: const InputDecoration(labelText: 'Quantidade em Estoque'),
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) return 'Informe o estoque.';
                        if (int.tryParse(value) == null) return 'Número inteiro válido.';
                        return null;
                      },
                      onSaved: (value) {
                        _editedProduct = Product(
                          id: _editedProduct.id,
                          name: _editedProduct.name,
                          price: _editedProduct.price,
                          stock: int.parse(value!), // Salva aqui
                          image: _editedProduct.image,
                          category: _editedProduct.category,
                        );
                      },
                    ),

                    TextFormField(
                      initialValue: _initValues['category'],
                      decoration: const InputDecoration(labelText: 'Categoria'),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value!.isEmpty) return 'Informe uma categoria.';
                        return null;
                      },
                      onSaved: (value) {
                        _editedProduct = Product(
                          id: _editedProduct.id,
                          name: _editedProduct.name,
                          price: _editedProduct.price,
                          image: _editedProduct.image,
                          category: value!,
                        );
                      },
                    ),

                    TextFormField(
                      initialValue: _initValues['image'],
                      decoration: const InputDecoration(
                        labelText: 'URL da Imagem',
                      ),
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Informe uma URL de imagem.';
                        }
                        if (!_isValidImageUrl(value)) {
                          return 'Informe uma URL válida (png, jpg ou jpeg).';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _editedProduct = Product(
                          id: _editedProduct.id,
                          name: _editedProduct.name,
                          price: _editedProduct.price,
                          image: value!,
                          category: _editedProduct.category,
                        );
                      },
                      onFieldSubmitted: (_) => _saveForm(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
