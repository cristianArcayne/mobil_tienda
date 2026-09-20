import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/venta_model.dart';

class DetalleCompraScreen extends StatelessWidget {
  final VentaModel venta;

  const DetalleCompraScreen({super.key, required this.venta});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Seguimiento del Pedido #${venta.id}',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta Estado del Pedido y Tracking
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFEFE9E3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ESTADO DEL PEDIDO',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Listo para Retiro / En Despacho',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          venta.estado.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Línea de tiempo de estados
                  _buildTimelineStep(
                    titulo: '1. Pago Confirmado',
                    subtitulo: 'Transacción aprobada mediante ${venta.metodoPago ?? "QR Simple"}',
                    completado: true,
                    activo: false,
                  ),
                  _buildTimelineStep(
                    titulo: '2. En Preparación en Atelier',
                    subtitulo: 'Prendas empaquetadas y verificadas con control de calidad',
                    completado: true,
                    activo: true,
                  ),
                  _buildTimelineStep(
                    titulo: '3. Listo para Retiro / En Ruta',
                    subtitulo: 'Puedes recogerlo en tienda o esperar al repartidor',
                    completado: false,
                    activo: false,
                  ),
                  _buildTimelineStep(
                    titulo: '4. Entregado al Cliente',
                    subtitulo: 'Firma de conformidad y cierre de orden',
                    completado: false,
                    activo: false,
                    esUltimo: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Código QR para Retiro / Entrega
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFEFE9E3)),
              ),
              child: Column(
                children: [
                  Text(
                    'CÓDIGO QR DE RETIRO / RECEPCIÓN',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Muestra este código al recoger tu pedido o al recibir el paquete.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: const Center(
                      child: Icon(Icons.qr_code_2, size: 130, color: Color(0xFF0F172A)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Comprobante: #${venta.id} | ${venta.numeroFactura ?? "FAC-ECOM-2026"}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Factura y Datos de Compra
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFEFE9E3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DETALLE DE FACTURACIÓN Y PRENDAS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildFilaInfo('Factura Fiscal:', venta.numeroFactura ?? 'FAC-ECOM-2026'),
                  _buildFilaInfo('Dirección Entrega:', venta.direccionEnvio ?? 'Entrega a domicilio'),
                  _buildFilaInfo('Método de Pago:', venta.metodoPago ?? 'QR Simple'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(color: Color(0xFFE2E8F0)),
                  ),
                  Text(
                    'Prendas Incluidas:',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  if (venta.detalles.isEmpty)
                    Text('1x Prenda exclusiva FashionStore', style: GoogleFonts.plusJakartaSans(fontSize: 13))
                  else
                    ...venta.detalles.map(
                      (d) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${d.cantidad}x ${d.prendaNombre} (${d.talla} / ${d.color})',
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              'Bs. ${d.subtotal.toStringAsFixed(2)}',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(color: Color(0xFFE2E8F0)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Pagado:',
                        style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                      ),
                      Text(
                        'Bs. ${venta.montoTotal.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF10B981)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Botón Regresar
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Volver a la Tienda',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required String titulo,
    required String subtitulo,
    required bool completado,
    required bool activo,
    bool esUltimo = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: completado
                    ? const Color(0xFF10B981)
                    : (activo ? AppTheme.accentIndigo : const Color(0xFFCBD5E1)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                completado ? Icons.check : (activo ? Icons.radio_button_checked : Icons.circle),
                color: Colors.white,
                size: 13,
              ),
            ),
            if (!esUltimo)
              Container(
                width: 2,
                height: 34,
                color: completado ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: completado || activo ? AppTheme.textPrimary : AppTheme.textMuted,
                  ),
                ),
                Text(
                  subtitulo,
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilaInfo(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted)),
          Text(
            valor,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}

