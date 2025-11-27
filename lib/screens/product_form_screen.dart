import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
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
  final _imageUrlController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ImagePicker _picker = ImagePicker();

  String? _selectedImageBase64;
  bool _useImageFromDevice = false;

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
        _imageUrlController.text = _editedProduct.image;

        // Verifica se a imagem é base64
        if (_editedProduct.image.startsWith('data:image')) {
          _useImageFromDevice = true;
          _selectedImageBase64 = _editedProduct.image;
        }
      }
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _priceFocusNode.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 400, // Reduzi de 800 para 400
        maxHeight: 400, // Reduzi de 800 para 400
        imageQuality: 50, // Reduzi a qualidade para 50%
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);
        final extension = image.path.split('.').last.toLowerCase();

        String mimeType = 'image/jpeg';
        if (extension == 'png') {
          mimeType = 'image/png';
        } else if (extension == 'jpg' || extension == 'jpeg') {
          mimeType = 'image/jpeg';
        }

        setState(() {
          _selectedImageBase64 = 'data:$mimeType;base64,$base64Image';
          _useImageFromDevice = true;
          _imageUrlController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Imagem selecionada!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao selecionar imagem: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Escolher Imagem',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt, color: Color(0xFF6366F1)),
              ),
              title: const Text('Câmera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF10B981),
                ),
              ),
              title: const Text('Galeria'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_useImageFromDevice || _imageUrlController.text.isNotEmpty)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFEF4444),
                  ),
                ),
                title: const Text('Remover Imagem'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImageBase64 = null;
                    _useImageFromDevice = false;
                    _imageUrlController.clear();
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  bool _isValidImageUrl(String url) {
    if (url.startsWith('data:image')) return true; // Aceita base64
    return (url.startsWith('http') || url.startsWith('https')) &&
        (url.endsWith('.png') || url.endsWith('.jpg') || url.endsWith('.jpeg'));
  }

  String _getImageForProduct() {
    if (_useImageFromDevice && _selectedImageBase64 != null) {
      return _selectedImageBase64!;
    }
    return _imageUrlController.text;
  }

  Future<void> _saveForm() async {
    // Valida se tem imagem (URL ou do dispositivo)
    if (!_useImageFromDevice && _imageUrlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, adicione uma imagem do produto!'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final isValid = _formKey.currentState?.validate();
    if (isValid == null || !isValid) {
      return;
    }

    _formKey.currentState?.save();

    // Define a imagem final (base64 ou URL)
    _editedProduct = Product(
      id: _editedProduct.id,
      name: _editedProduct.name,
      price: _editedProduct.price,
      stock: _editedProduct.stock,
      image: _getImageForProduct(),
      category: _editedProduct.category,
    );

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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
                                    color: const Color(
                                      0xFF6366F1,
                                    ).withOpacity(0.1),
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
                                FocusScope.of(
                                  context,
                                ).requestFocus(_priceFocusNode);
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
                                    color: const Color(
                                      0xFF10B981,
                                    ).withOpacity(0.1),
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
                              keyboardType:
                                  const TextInputType.numberWithOptions(
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
                                    color: const Color(
                                      0xFFF59E0B,
                                    ).withOpacity(0.1),
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

                            // Preview da imagem
                            if (_useImageFromDevice &&
                                _selectedImageBase64 != null)
                              Center(
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      base64Decode(
                                        _selectedImageBase64!.split(',')[1],
                                      ),
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              )
                            else if (_imageUrlController.text.isNotEmpty &&
                                _isValidImageUrl(_imageUrlController.text))
                              Center(
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      _imageUrlController.text,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        height: 200,
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            size: 50,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Botão para selecionar imagem do dispositivo
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _showImageSourceDialog,
                              icon: const Icon(Icons.add_photo_alternate),
                              label: Text(
                                _useImageFromDevice ||
                                        _imageUrlController.text.isNotEmpty
                                    ? 'Alterar Imagem'
                                    : 'Selecionar Imagem',
                              ),
                            ),

                            const SizedBox(height: 16),
                            const Row(
                              children: [
                                Expanded(child: Divider()),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'OU',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _imageUrlController,
                              enabled: !_useImageFromDevice,
                              decoration: InputDecoration(
                                labelText: 'URL da Imagem',
                                hintText: 'https://exemplo.com/imagem.jpg',
                                prefixIcon: const Icon(Icons.link),
                                suffixIcon: _useImageFromDevice
                                    ? IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () {
                                          setState(() {
                                            _useImageFromDevice = false;
                                            _selectedImageBase64 = null;
                                          });
                                        },
                                        tooltip:
                                            'Usar URL ao invés de imagem local',
                                      )
                                    : null,
                              ),
                              keyboardType: TextInputType.url,
                              textInputAction: TextInputAction.done,
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  setState(() {});
                                }
                              },
                              validator: (value) {
                                if (_useImageFromDevice) return null;
                                if (value == null || value.isEmpty) {
                                  return 'Informe a URL ou selecione uma imagem';
                                }
                                if (!_isValidImageUrl(value)) {
                                  return 'URL inválida (use .png, .jpg ou .jpeg)';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                if (!_useImageFromDevice) {
                                  _editedProduct = Product(
                                    id: _editedProduct.id,
                                    name: _editedProduct.name,
                                    price: _editedProduct.price,
                                    stock: _editedProduct.stock,
                                    image: value!,
                                    category: _editedProduct.category,
                                  );
                                }
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
                          _editedProduct.id.isEmpty
                              ? 'CRIAR PRODUTO'
                              : 'SALVAR ALTERAÇÕES',
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
