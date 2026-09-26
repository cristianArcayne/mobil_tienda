import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/venta_model.dart';
import '../../services/ventas_service.dart';

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

            const SizedBox(height: 20),

            // Botón Solicitar Devolución / Reembolso (24h)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE11D48),
                  side: const BorderSide(color: Color(0xFFFDA4AF), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _mostrarModalDevolucion(context),
                icon: const Icon(Icons.assignment_return_outlined, size: 20),
                label: Text(
                  'Solicitar Devolución / Reembolso (24h)',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 14),

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

  void _mostrarModalDevolucion(BuildContext context) {
    final motivoCtrl = TextEditingController();
    final cuentaCtrl = TextEditingController();
    String? prendaSeleccionada = venta.detalles.isNotEmpty ? venta.detalles.first.prendaNombre : 'Pedido Completo #${venta.id}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                              color: const Color(0xFFFFE4E6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.assignment_return_outlined, color: Color(0xFFE11D48), size: 22),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Solicitar Reembolso (24h)',
                            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(modalCtx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Puedes solicitar el reembolso de tu pedido #${venta.id} dentro de las 24 horas posteriores a la compra.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // Selección de prenda a devolver
                  Text(
                    'Prenda / Item a Devolver:',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  if (venta.detalles.isNotEmpty)
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: prendaSeleccionada,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'Pedido Completo #${venta.id}',
                          child: Text(
                            'Todo el Pedido #${venta.id} (Bs. ${venta.montoTotal.toStringAsFixed(2)})',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        ...venta.detalles.map(
                          (d) => DropdownMenuItem(
                            value: d.prendaNombre,
                            child: Text(
                              '${d.cantidad}x ${d.prendaNombre} (${d.talla}/${d.color}) - Bs. ${d.subtotal.toStringAsFixed(2)}',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setModalState(() => prendaSeleccionada = val);
                      },
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text('Pedido #${venta.id} - Total Bs. ${venta.montoTotal.toStringAsFixed(2)}'),
                    ),
                  const SizedBox(height: 14),

                  // Motivo de reembolso
                  Text(
                    'Motivo de la Devolución:',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: motivoCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Ej. La talla no me quedó bien / Defecto en costura',
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Datos bancarios / QR para transferencia
                  Text(
                    'Cuenta Bancaria o Alias QR para Reembolso (Opcional):',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: cuentaCtrl,
                    decoration: InputDecoration(
                      hintText: 'Ej. Banco Mercantil Cta 1000... / Alias QR',
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Botón enviar
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE11D48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (motivoCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Por favor ingresa el motivo del reembolso.')),
                          );
                          return;
                        }

                        final motivoCompleto = 'Prenda: $prendaSeleccionada. Motivo: ${motivoCtrl.text.trim()}';
                        final service = Provider.of<VentasService>(context, listen: false);
                        final ok = await service.solicitarDevolucion(
                          ventaId: venta.id,
                          motivo: motivoCompleto,
                          cuentaBancariaQr: cuentaCtrl.text.trim().isNotEmpty ? cuentaCtrl.text.trim() : null,
                        );

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          if (ok) {
                            showDialog(
                              context: context,
                              builder: (dialogCtx) => AlertDialog(
                                title: const Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Color(0xFF059669)),
                                    SizedBox(width: 8),
                                    Text('Solicitud Enviada'),
                                  ],
                                ),
                                content: Text(
                                  'Tu solicitud de devolución para el pedido #${venta.id} fue registrada exitosamente.\n\nEl equipo de administración revisará la solicitud y procesará la devolución dentro del panel web.',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogCtx),
                                    child: const Text('Entendido'),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(service.errorMessage ?? 'No se pudo enviar la solicitud de devolución.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: Text(
                        'Enviar Solicitud de Reembolso',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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

