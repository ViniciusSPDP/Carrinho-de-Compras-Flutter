import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';
import 'order_success_screen.dart'; 

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _cupomController = TextEditingController();
  final _cepController = TextEditingController();
  bool _isLoading = false; 

  Future<void> _processarPedido(CartProvider cart) async {
    if (cart.itemCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seu carrinho está vazio!'))
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await cart.finalizarPedido();
      
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (ctx) => const OrderSuccessScreen()),
        );
      }
    } catch (error) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Problema no Estoque'),
            content: Text(error.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final cartItems = cart.items.values.toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Carrinho'),
        actions: [
          IconButton(
            icon: const Icon(Icons.remove_shopping_cart),
            onPressed: () {
              cart.clear();
              _cepController.clear();
              _cupomController.clear();
            },
            tooltip: 'Limpar Carrinho Inteiro',
          )
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(15),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal', style: TextStyle(fontSize: 16)),
                      Text('R\$ ${cart.totalAmount.toStringAsFixed(2)}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Frete', style: TextStyle(fontSize: 16)),
                      Text(
                        cart.frete == 0 ? 'Grátis' : 'R\$ ${cart.frete.toStringAsFixed(2)}',
                        style: TextStyle(color: cart.frete == 0 ? Colors.green : Colors.red),
                      ),
                    ],
                  ),
                  if (cart.descontoPorcentagem > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Desconto (${cart.cupomAplicado})', style: const TextStyle(fontSize: 16, color: Colors.green)),
                        Text(
                          '- ${cart.descontoPorcentagem.toStringAsFixed(0)}%', 
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)
                        ),
                      ],
                    ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Final', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Chip(
                        label: Text(
                          'R\$ ${cart.totalFinal.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          ExpansionTile(
            title: const Text("Calcular Frete e Cupom"),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cepController,
                        decoration: const InputDecoration(
                          labelText: 'CEP (Ex: 15600000)',
                          helperText: 'Fernandópolis: Grátis | SP: 25 | Outros: 50'
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calculate), 
                      onPressed: () {
                        cart.calcularFrete(_cepController.text);
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Frete atualizado para o CEP ${_cepController.text}'))
                        );
                      }
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cupomController,
                        decoration: const InputDecoration(labelText: 'Cupom de Desconto'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.confirmation_number), 
                      onPressed: () {
                        bool sucesso = cart.aplicarCupom(_cupomController.text);
                        if (sucesso) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cupom aplicado com sucesso!')));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cupom inválido!')));
                        }
                      }
                    ),
                  ],
                ),
              ),
            ],
          ),

          Expanded(
            child: ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (ctx, i) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(cartItems[i].image),
                    onBackgroundImageError: (_,__) {},
                    child: const Icon(Icons.shopping_bag, size: 20),
                  ),
                  title: Text(cartItems[i].name),
                  subtitle: Text(
                    'Total: R\$ ${(cartItems[i].price * cartItems[i].quantity).toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  
                  trailing: SizedBox(
                    width: 160,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.blue),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(), 
                          onPressed: () => cart.removeSingleItem(cartItems[i].id),
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('${cartItems[i].quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => cart.addItem(Product(
                            id: cartItems[i].id,
                            name: cartItems[i].name,
                            price: cartItems[i].price,
                            image: cartItems[i].image,
                            category: 'Cart',
                          )),
                        ),
                        
                        const SizedBox(width: 10),
                        
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Remover Item',
                          onPressed: () {
                            cart.removeItem(cartItems[i].id); 
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(15),
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: _isLoading ? null : () => _processarPedido(cart),
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('FINALIZAR PEDIDO'),
            ),
          ),
        ],
      ),
    );
  }
}