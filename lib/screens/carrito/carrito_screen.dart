import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/carrito_service.dart';
import '../ventas/checkout_screen.dart';

class CarritoScreen extends StatelessWidget {
  const CarritoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CarritoService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Carrito de Compras'),
        actions: [
          if (cart.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Color(0xFFEF4444)),
              tooltip: 'Vaciar Carrito',
              onPressed: () => _confirmVaciar(context, cart),
            ),
        ],
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEEF2FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shopping_cart_outlined, size: 64, color: Color(0xFF4F46E5)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tu carrito está vacío',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Explora nuestro catálogo y agrega tus prendas favoritas.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Banner Carrito Persistente Sincronizado
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: const Color(0xFFECFDF5),
                  child: const Row(
                    children: [
                      Icon(Icons.cloud_done_outlined, size: 16, color: Color(0xFF059669)),
                      SizedBox(width: 8),
                      Text(
                        'Carrito sincronizado y guardado en tu dispositivo',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF059669)),
                      ),
                    ],
                  ),
                ),

                // Lista de Items
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final item = cart.items[i];

                      return Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Miniatura
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: item.imagenUrl != null && item.imagenUrl!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(item.imagenUrl!, fit: BoxFit.cover),
                                      )
                                    : const Icon(Icons.checkroom, color: Color(0xFF94A3B8)),
                              ),
                              const SizedBox(width: 14),

                              // Info Prenda
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.prendaNombre,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Talla: ${item.talla} • Color: ${item.color}',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Bs. ${item.precioUnitario.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                                    ),
                                  ],
                                ),
                              ),

                              // Controles Cantidad
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFEF4444)),
                                    onPressed: () => cart.eliminarItem(item.varianteId),
                                  ),
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () => cart.actualizarCantidad(item.varianteId, -1),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                                          child: const Icon(Icons.remove, size: 14),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Text('${item.cantidad}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                      InkWell(
                                        onTap: () => cart.actualizarCantidad(item.varianteId, 1),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                                          child: const Icon(Icons.add, size: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Resumen de Compra y Botón Checkout
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -3)),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total (${cart.cantidadTotal} artículos):',
                              style: const TextStyle(fontSize: 15, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Bs. ${cart.totalMonto.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            backgroundColor: const Color(0xFF4F46E5),
                          ),
                          icon: const Icon(Icons.payment),
                          label: const Text('Continuar al Checkout'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _confirmVaciar(BuildContext context, CarritoService cart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vaciar Carrito'),
        content: const Text('¿Deseas remover todos los productos de tu carrito?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              cart.limpiarCarrito();
              Navigator.pop(ctx);
            },
            child: const Text('Vaciar', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }
}

