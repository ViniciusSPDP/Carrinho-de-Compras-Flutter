import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  final _cupomController = TextEditingController();
  final _porcentagemController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  String? _editingCouponCode;

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
  void dispose() {
    _animationController.dispose();
    _cupomController.dispose();
    _porcentagemController.dispose();
    super.dispose();
  }

  void _editCoupon(String code, double percentage) {
    setState(() {
      _editingCouponCode = code;
      _cupomController.text = code;
      _porcentagemController.text = percentage.toString();
    });
  }

  void _clearForm() {
    setState(() {
      _editingCouponCode = null;
      _cupomController.clear();
      _porcentagemController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        title: const Text(
          'Administrativo',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card de Cadastro/Edição de Cupom
              _buildCouponFormCard(cartProvider),
              
              const SizedBox(height: 24),
              
              // Lista de Cupons
              _buildCouponsList(cartProvider),
              
              const SizedBox(height: 24),
              
              // Card de Regras de Frete
              _buildShippingRulesCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCouponFormCard(CartProvider cartProvider) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
                    Icons.confirmation_number_outlined,
                    color: Color(0xFF6366F1),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  _editingCouponCode == null ? 'Novo Cupom' : 'Editar Cupom',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _cupomController,
              enabled: _editingCouponCode == null,
              decoration: InputDecoration(
                labelText: 'Código do Cupom',
                hintText: 'Ex: PROMO50',
                prefixIcon: const Icon(Icons.local_offer_outlined),
                suffixIcon: _editingCouponCode != null
                    ? const Icon(Icons.lock_outline, size: 20)
                    : null,
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _porcentagemController,
              decoration: const InputDecoration(
                labelText: 'Desconto',
                hintText: 'Ex: 10',
                prefixIcon: Icon(Icons.percent_outlined),
                suffixText: '%',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (_editingCouponCode != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _clearForm,
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      final codigo = _cupomController.text.trim().toUpperCase();
                      final porcentagem = double.tryParse(_porcentagemController.text);

                      if (codigo.isEmpty || porcentagem == null || porcentagem <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Preencha os dados corretamente!'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      cartProvider.cadastrarCupom(codigo, porcentagem);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _editingCouponCode == null
                                ? 'Cupom $codigo criado com sucesso!'
                                : 'Cupom $codigo atualizado!',
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      
                      _clearForm();
                    },
                    child: Text(
                      _editingCouponCode == null ? 'CRIAR CUPOM' : 'ATUALIZAR',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponsList(CartProvider cartProvider) {
    final cupons = cartProvider.coupons;
    
    if (cupons.isEmpty) {
      return Card(
        elevation: 2,
        shadowColor: Colors.black12,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(
                Icons.discount_outlined,
                size: 64,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhum cupom cadastrado',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Cupons Ativos (${cupons.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cupons.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final entry = cupons.entries.toList()[index];
                return _buildCouponItem(entry.key, entry.value, cartProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponItem(String code, double percentage, CartProvider cartProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.local_offer,
            color: Color(0xFF10B981),
            size: 24,
          ),
        ),
        title: Text(
          code,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
        subtitle: Text(
          '${percentage.toStringAsFixed(0)}% de desconto',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: const Color(0xFF6366F1),
              onPressed: () => _editCoupon(code, percentage),
              tooltip: 'Editar',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.redAccent,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text('Excluir Cupom?'),
                    content: Text('Deseja realmente excluir o cupom $code?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          cartProvider.removerCupom(code);
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Cupom $code removido!'),
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: const Text('Excluir'),
                      ),
                    ],
                  ),
                );
              },
              tooltip: 'Excluir',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingRulesCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
                    Icons.local_shipping_outlined,
                    color: Color(0xFF10B981),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Regras de Frete',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildShippingRule(
              icon: Icons.location_city_outlined,
              color: const Color(0xFF10B981),
              title: 'Fernandópolis',
              subtitle: 'CEP 15600-000 a 15614-999',
              price: 'Frete Grátis',
            ),
            const SizedBox(height: 12),
            _buildShippingRule(
              icon: Icons.map_outlined,
              color: const Color(0xFF6366F1),
              title: 'Estado de São Paulo',
              subtitle: 'CEP 01000-000 a 19999-999',
              price: 'R\$ 25,00',
            ),
            const SizedBox(height: 12),
            _buildShippingRule(
              icon: Icons.public_outlined,
              color: const Color(0xFFF59E0B),
              title: 'Outros Estados',
              subtitle: 'Demais regiões do Brasil',
              price: 'R\$ 50,00',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingRule({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String price,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: price.contains('Grátis') ? const Color(0xFF10B981) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}