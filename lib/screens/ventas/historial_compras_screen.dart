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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFE9E3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.local_mall_outlined, color: AppTheme.primaryColor, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pedido #${venta.id}',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              venta.numeroFactura ?? 'FAC-ECOM-2026',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        venta.estado.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(color: Color(0xFFF1F5F9)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${venta.detalles.length} ${venta.detalles.length == 1 ? "artículo" : "artículos"}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    Text(
                      'Bs. ${venta.montoTotal.toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Ver seguimiento y QR',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: AppTheme.primaryColor),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

