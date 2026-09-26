import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/ventas_service.dart';
import '../../models/venta_model.dart';
import 'detalle_compra_screen.dart';

class HistorialComprasScreen extends StatefulWidget {
  const HistorialComprasScreen({super.key});

  @override
  State<HistorialComprasScreen> createState() => _HistorialComprasScreenState();
}

class _HistorialComprasScreenState extends State<HistorialComprasScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        Provider.of<VentasService>(context, listen: false).cargarHistorialCompras();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ventasService = Provider.of<VentasService>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Mis Compras Digitales',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ventasService.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : ventasService.compras.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.receipt_long_outlined, size: 56, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aún no tienes compras registradas',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Explora el catálogo y realiza tu primer pedido.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ventasService.cargarHistorialCompras(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: ventasService.compras.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (ctx, index) {
                      final v = ventasService.compras[index];
                      return _buildVentaCard(context, v);
                    },
                  ),
                ),
    );
  }

  Widget _buildVentaCard(BuildContext context, VentaModel venta) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetalleCompraScreen(venta: venta)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera Venta / Compra
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Compra #${venta.id}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      venta.estado.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Cliente, Sucursal y Fecha
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: Color(0xFF4F46E5)),
                  const SizedBox(width: 6),
                  Text(
                    'Cliente: ${venta.clienteNombre}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.storefront, size: 16, color: Color(0xFF4F46E5)),
                  const SizedBox(width: 6),
                  Text(
                    venta.sucursalNombre,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF0D9488)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Fecha de compra: ${venta.fechaFormateada.isNotEmpty ? venta.fechaFormateada : venta.fecha}',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0D9488)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Factura: ${venta.numeroFactura ?? "FAC-ECOM-2026"} • Pago: ${venta.metodoPago ?? "QR Simple"}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Items / Prendas de la venta
              if (venta.detalles.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Artículos adquiridos en tienda física / e-commerce',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                )
              else
                ...venta.detalles.map((d) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: (d.imagenUrl != null && d.imagenUrl!.isNotEmpty)
                                ? Image.network(
                                    d.imagenUrl!,
                                    width: 46,
                                    height: 46,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 46,
                                      height: 46,
                                      color: const Color(0xFFE2E8F0),
                                      child: const Icon(Icons.checkroom, color: Color(0xFF64748B)),
                                    ),
                                  )
                                : Container(
                                    width: 46,
                                    height: 46,
                                    color: const Color(0xFFEEF2FF),
                                    child: const Icon(Icons.checkroom, color: Color(0xFF4F46E5)),
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.prendaNombre,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Talla: ${d.talla} • Color: ${d.color} • Cant: ${d.cantidad}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Bs. ${d.subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                    )),

              const Divider(height: 16),

              // Monto total y Acción
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total pagado: Bs. ${venta.montoTotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                  ),
                  const Row(
                    children: [
                      Text(
                        'Ver Detalle / Reembolso',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                      ),
                      Icon(Icons.chevron_right, size: 18, color: Color(0xFF4F46E5)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

