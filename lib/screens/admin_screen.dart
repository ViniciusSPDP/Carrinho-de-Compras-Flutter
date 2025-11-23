import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _cupomController = TextEditingController();
  final _porcentagemController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrativo'),
        backgroundColor: Colors.orange, 
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Cadastrar Novo Cupom',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _cupomController,
              decoration: const InputDecoration(
                labelText: 'Código do Cupom (Ex: PROMO50)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.confirmation_number),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _porcentagemController,
              decoration: const InputDecoration(
                labelText: 'Porcentagem de Desconto (Ex: 10)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.percent),
                suffixText: '%',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: () {
                final codigo = _cupomController.text;
                final porcentagem = double.tryParse(_porcentagemController.text);

                if (codigo.isEmpty || porcentagem == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preencha os dados corretamente!')),
                  );
                  return;
                }

                cartProvider.cadastrarCupom(codigo, porcentagem);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Cupom $codigo ($porcentagem%) cadastrado!')),
                );
                
                _cupomController.clear();
                _porcentagemController.clear();
              },
              child: const Text('CADASTRAR CUPOM', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 40),
            const Text(
              'Regras de Frete Ativas:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.location_city, color: Colors.green),
                      title: Text('Fernandópolis (CEP 15600...)'),
                      subtitle: Text('Frete Grátis'),
                    ),
                    ListTile(
                      leading: Icon(Icons.map, color: Colors.blue),
                      title: Text('Estado de SP'),
                      subtitle: Text('R\$ 25,00'),
                    ),
                    ListTile(
                      leading: Icon(Icons.public, color: Colors.red),
                      title: Text('Outros Estados'),
                      subtitle: Text('R\$ 50,00'),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}