import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/venta_model.dart';
import '../../services/ventas_service.dart';
import '../../services/notificaciones_service.dart';
import '../../widgets/in_app_notification_banner.dart';

class DetalleCompraScreen extends StatefulWidget {
  final VentaModel venta;

  const DetalleCompraScreen({super.key, required this.venta});

  @override
  State<DetalleCompraScreen> createState() => _DetalleCompraScreenState();
}

class _DetalleCompraScreenState extends State<DetalleCompraScreen> {
  late String _estadoActual;
  bool _actualizandoEstado = false;

  @override
  void initState() {
    super.initState();
    _estadoActual = widget.venta.estado.toUpperCase();
  }

  VentaModel get venta => widget.venta;

  // Lógica de avance de estados de entrega para pruebas y demostración
  Future<void> _avanzarEstadoPedido() async {
    setState(() => _actualizandoEstado = true);
    String nuevoEstado = 'EN_PREPARACION';
    if (_estadoActual == 'PENDIENTE_SYNC' || _estadoActual == 'PENDIENTE' || _estadoActual == 'PAGO_CONFIRMADO') {
      nuevoEstado = 'EN_PREPARACION';
    } else if (_estadoActual == 'EN_PREPARACION') {
      nuevoEstado = 'LISTO_RETIRO';
    } else if (_estadoActual == 'LISTO_RETIRO' || _estadoActual == 'EN_RUTA') {
      nuevoEstado = 'ENTREGADO';
    } else if (_estadoActual == 'ENTREGADO' || _estadoActual == 'COMPLETADA' || _estadoActual == 'PAGADA') {
      nuevoEstado = 'EN_PREPARACION'; // Reiniciar ciclo para demostración
    } else {
      nuevoEstado = 'EN_PREPARACION';
    }

    try {
      final service = Provider.of<VentasService>(context, listen: false);
      if (venta.id > 0) {
        await service.actualizarEstadoPedido(venta.id, nuevoEstado);
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _estadoActual = nuevoEstado;
        _actualizandoEstado = false;
      });

      String msj = 'Estado actualizado a $nuevoEstado';
      if (nuevoEstado == 'LISTO_RETIRO') msj = '📦 Tu pedido #${venta.id} está listo para retiro en tienda con código QR.';
      if (nuevoEstado == 'ENTREGADO') msj = '🎉 ¡Pedido #${venta.id} entregado y cerrado conforme!';

      InAppNotificationBanner.show(
        context,
        title: '🚚 Seguimiento de Entrega',
        message: msj,
        tipo: 'COMPRA',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final elegible7Dias = venta.esElegibleGarantia7Dias;
    final diasRestantes = venta.diasRestantesGarantia;

    // Cálculo dinámico de pasos completados y activos
    final esCompletado = _estadoActual == 'ENTREGADO' || _estadoActual == 'COMPLETADA' || _estadoActual == 'PAGADA';
    final esListoRetiro = _estadoActual == 'LISTO_RETIRO' || _estadoActual == 'EN_RUTA';
    final esEnPrep = _estadoActual == 'EN_PREPARACION';
    final esPagoConf = _estadoActual == 'PAGO_CONFIRMADO';
    final esPendienteSync = _estadoActual == 'PENDIENTE_SYNC' || _estadoActual == 'PENDIENTE';

    final paso1Completo = !esPendienteSync;
    final paso1Activo = esPendienteSync;

    final paso2Completo = esEnPrep || esListoRetiro || esCompletado;
    final paso2Activo = esPagoConf;

    final paso3Completo = esListoRetiro || esCompletado;
    final paso3Activo = esEnPrep;

    final paso4Completo = esCompletado;
    final paso4Activo = esListoRetiro;

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
            // Banner Garantía Legal de 7 Días (CU-12 / RN-01 / RN-02)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: elegible7Dias ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: elegible7Dias ? const Color(0xFFC7D2FE) : const Color(0xFFCBD5E1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    elegible7Dias ? Icons.verified_outlined : Icons.history_toggle_off,
                    color: elegible7Dias ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          elegible7Dias ? 'Garantía Legal Vigente (7 Días)' : 'Plazo de Garantía Expirado',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: elegible7Dias ? const Color(0xFF3730A3) : const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          elegible7Dias
                              ? 'Tienes ${diasRestantes.toStringAsFixed(1)} día(s) para gestionar Cambio de Talla (RN-02) o Reembolso (RN-01).'
                              : 'Han transcurrido más de 168 horas desde la emisión de tu factura.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: elegible7Dias ? const Color(0xFF4338CA) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tarjeta Estado del Pedido
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFEFE9E3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                            esCompletado
                                ? 'Entregado al Cliente • Concluido'
                                : (esListoRetiro
                                    ? 'Listo para Retiro en Tienda'
                                    : (esEnPrep
                                        ? 'En Preparación en Atelier'
                                        : (esPendienteSync ? 'Encolado en SQLite (Offline)' : 'Pago Confirmado'))),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: esCompletado ? const Color(0xFF059669) : (esListoRetiro
                                      ? const Color(0xFF2563EB)
                                      : (esPendienteSync ? const Color(0xFFD97706) : const Color(0xFF10B981))),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: esCompletado ? const Color(0xFFECFDF5) : (esListoRetiro ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _estadoActual,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: esCompletado ? const Color(0xFF059669) : (esListoRetiro ? const Color(0xFF2563EB) : const Color(0xFF475569)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Línea de tiempo de estados dinámica
                  _buildTimelineStep(
                    titulo: '1. Pago Confirmado',
                    subtitulo: 'Transacción aprobada mediante ${venta.metodoPago ?? "Stripe / QR"}',
                    completado: paso1Completo,
                    activo: paso1Activo,
                  ),
                  _buildTimelineStep(
                    titulo: '2. En Preparación en Atelier',
                    subtitulo: 'Prendas empaquetadas y verificadas con control de calidad',
                    completado: paso2Completo,
                    activo: paso2Activo,
                  ),
                  _buildTimelineStep(
                    titulo: '3. Listo para Retiro / En Ruta',
                    subtitulo: 'Disponible para retirar en tienda o con repartidor en camino',
                    completado: paso3Completo,
                    activo: paso3Activo,
                  ),
                  _buildTimelineStep(
                    titulo: '4. Entregado al Cliente',
                    subtitulo: 'Validación de código QR y firma de conformidad de entrega',
                    completado: paso4Completo,
                    activo: paso4Activo,
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
                    'Muestra este código al recoger tu paquete en la sucursal.',
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
                    child: Center(
                      child: Icon(
                        esCompletado ? Icons.verified : Icons.qr_code_2,
                        size: esCompletado ? 90 : 130,
                        color: esCompletado ? const Color(0xFF10B981) : const Color(0xFF0F172A),
                      ),
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
                  const SizedBox(height: 14),

                  // Botón para avanzar el estado del pedido (Funcional para pruebas / defensa)
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: esCompletado ? const Color(0xFF059669) : const Color(0xFF4F46E5),
                        side: BorderSide(
                          color: esCompletado ? const Color(0xFF6EE7B7) : const Color(0xFFC7D2FE),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _actualizandoEstado ? null : _avanzarEstadoPedido,
                      icon: _actualizandoEstado
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(esCompletado ? Icons.refresh : Icons.sync, size: 18),
                      label: Text(
                        _actualizandoEstado
                            ? 'Actualizando estado...'
                            : (esCompletado
                                  ? 'Reiniciar Ciclo de Despacho (Demo)'
                                  : (esListoRetiro
                                      ? 'Confirmar Entrega al Cliente (QR)'
                                      : (esEnPrep ? 'Avanzar a: Listo para Retiro' : 'Avanzar a: En Preparación'))),
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
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
                  _buildFilaInfo('Método de Pago:', venta.metodoPago ?? 'Stripe / QR Simple'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(color: Color(0xFFE2E8F0)),
                  ),
                  Text(
                    'Prendas Incluidas en la Orden:',
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
                                '${d.cantidad}x ${d.prendaNombre.isNotEmpty ? d.prendaNombre : "Prenda"} (${d.talla} / ${d.color})',
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
            const SizedBox(height: 24),

            // UN SOLO BOTÓN DE GARANTÍA LEGAL (Solicitado por el usuario)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: elegible7Dias ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: elegible7Dias ? 2 : 0,
                ),
                onPressed: elegible7Dias ? () => _mostrarModalGarantiaUnificado(context) : null,
                icon: const Icon(Icons.verified_user_outlined, color: Colors.white, size: 22),
                label: Text(
                  'Gestionar Garantía de 7 Días (Cambio o Reembolso)',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
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

  // ===========================================================================
  // MODAL UNIFICADO CON PESTAÑAS: CAMBIO DE TALLA Y DEVOLUCIÓN / REEMBOLSO
  // ===========================================================================
  void _mostrarModalGarantiaUnificado(BuildContext context) async {
    final service = Provider.of<VentasService>(context, listen: false);
    final elegible7Dias = venta.esElegibleGarantia7Dias;
    final diasRestantes = venta.diasRestantesGarantia;

    // 1. Datos iniciales para Cambio de Talla
    DetalleVentaModel? detalleCambioActual = venta.detalles.isNotEmpty ? venta.detalles.first : null;
    
    // Consultar variantes disponibles filtradas por ropa_id y variante_id
    List<Map<String, dynamic>> rawVariantes = await service.obtenerVariantesParaCambioTalla(
      ropaId: detalleCambioActual?.ropaId,
      varianteId: detalleCambioActual?.varianteId,
    );

    // Deduplicación estricta por talla para evitar que salgan repetidas
    final Set<String> tallasVistas = {};
    List<Map<String, dynamic>> variantesDisponibles = [];
    for (final v in rawVariantes) {
      final t = v['talla']?.toString() ?? 'M';
      if (!tallasVistas.contains(t)) {
        tallasVistas.add(t);
        variantesDisponibles.add(v);
      }
    }

    if (variantesDisponibles.isEmpty) {
      variantesDisponibles = [
        {'variante_id': 1, 'talla': 'S', 'color': detalleCambioActual?.color ?? 'Negro', 'precio': venta.montoTotal, 'stock_disponible': 5},
        {'variante_id': 2, 'talla': 'M', 'color': detalleCambioActual?.color ?? 'Negro', 'precio': venta.montoTotal, 'stock_disponible': 8},
        {'variante_id': 3, 'talla': 'L', 'color': detalleCambioActual?.color ?? 'Negro', 'precio': venta.montoTotal, 'stock_disponible': 6},
        {'variante_id': 4, 'talla': 'XL', 'color': detalleCambioActual?.color ?? 'Negro', 'precio': venta.montoTotal, 'stock_disponible': 4},
      ];
    }

    int varianteNuevaSeleccionada = int.tryParse(variantesDisponibles.first['variante_id']?.toString() ?? '1') ?? 1;
    String tallaNuevaTexto = variantesDisponibles.first['talla']?.toString() ?? 'M';
    final motivoCambioCtrl = TextEditingController(text: 'Cambio por talla más adecuada');

    // 2. Datos iniciales para Devolución / Reembolso
    final motivoDevolucionCtrl = TextEditingController();
    final cuentaBancariaCtrl = TextEditingController();
    
    // Valor inicial de la prenda a devolver
    final String pedidoCompletoKey = 'Pedido Completo #${venta.id > 0 ? venta.id : "1"}';
    String prendaDevolucionSeleccionada = pedidoCompletoKey;
    if (venta.detalles.isNotEmpty) {
      final f = venta.detalles.first;
      final fNom = f.prendaNombre.isNotEmpty ? f.prendaNombre : 'Prenda Exclusiva';
      final fTalla = f.talla.isNotEmpty ? f.talla : 'M';
      final fColor = f.color.isNotEmpty ? f.color : 'Estándar';
      final fSub = f.subtotal > 0 ? f.subtotal : (f.precioUnitario * f.cantidad);
      prendaDevolucionSeleccionada = '${f.cantidad}x $fNom ($fTalla/$fColor) - Bs. ${fSub.toStringAsFixed(2)}';
    }

    int pestanaActiva = 0;
    bool enviandoAccion = false;

    if (!context.mounted) return;

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
                top: 18,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header común con icono y botón cerrar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: pestanaActiva == 0 ? const Color(0xFFEEF2FF) : const Color(0xFFFFE4E6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                pestanaActiva == 0 ? Icons.swap_horiz_rounded : Icons.assignment_return_outlined,
                                color: pestanaActiva == 0 ? const Color(0xFF4F46E5) : const Color(0xFFE11D48),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Garantía Legal (7 Días)',
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

                    // Barra de pestañas (Tabs): Cambio de Talla vs Devolución / Reembolso
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => pestanaActiva = 0),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: pestanaActiva == 0 ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: pestanaActiva == 0
                                      ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))]
                                      : [],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.swap_horiz_rounded,
                                      size: 16,
                                      color: pestanaActiva == 0 ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Cambio de Talla',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: pestanaActiva == 0 ? FontWeight.w800 : FontWeight.w600,
                                        color: pestanaActiva == 0 ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => pestanaActiva = 1),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: pestanaActiva == 1 ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: pestanaActiva == 1
                                      ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))]
                                      : [],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.assignment_return_outlined,
                                      size: 16,
                                      color: pestanaActiva == 1 ? const Color(0xFFE11D48) : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Devolución',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: pestanaActiva == 1 ? FontWeight.w800 : FontWeight.w600,
                                        color: pestanaActiva == 1 ? const Color(0xFFE11D48) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // =========================================================
                    // CONTENIDO PESTAÑA 0: CAMBIO DE TALLA (RN-02)
                    // =========================================================
                    if (pestanaActiva == 0) ...[
                      // Aviso RN-02
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.swap_horiz_rounded, size: 16, color: Color(0xFF4F46E5)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'RN-02 (Mantenimiento del Crédito Original): No se anula tu factura original (${venta.numeroFactura ?? "FAC-ECOM"}). Se emitirá una Nota de Cambio (NC-) ajustando el inventario físico (+1 devolución, -1 nueva talla).',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary, height: 1.35),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Selector de prenda a cambiar
                      Text(
                        'Prenda a Cambiar:',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      if (venta.detalles.isNotEmpty)
                        DropdownButtonFormField<DetalleVentaModel>(
                          value: detalleCambioActual,
                          isExpanded: true,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.checkroom_outlined, size: 20, color: Color(0xFF64748B)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                          selectedItemBuilder: (BuildContext ctx) {
                            return venta.detalles.map<Widget>((d) {
                              final pNom = d.prendaNombre.isNotEmpty ? d.prendaNombre : 'Prenda Exclusiva';
                              final pTalla = d.talla.isNotEmpty ? d.talla : 'M';
                              final pColor = d.color.isNotEmpty ? d.color : 'Estándar';
                              final pSub = d.subtotal > 0 ? d.subtotal : (d.precioUnitario * d.cantidad);
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${d.cantidad}x $pNom ($pTalla/$pColor) - Bs. ${pSub.toStringAsFixed(2)}',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                ),
                              );
                            }).toList();
                          },
                          items: venta.detalles
                              .map(
                                (d) {
                                  final pNom = d.prendaNombre.isNotEmpty ? d.prendaNombre : 'Prenda Exclusiva';
                                  final pTalla = d.talla.isNotEmpty ? d.talla : 'M';
                                  final pColor = d.color.isNotEmpty ? d.color : 'Estándar';
                                  final pSub = d.subtotal > 0 ? d.subtotal : (d.precioUnitario * d.cantidad);
                                  return DropdownMenuItem<DetalleVentaModel>(
                                    value: d,
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: Text(
                                        '${d.cantidad}x $pNom ($pTalla/$pColor) - Bs. ${pSub.toStringAsFixed(2)}',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  );
                                },
                              )
                              .toList(),
                          onChanged: (val) async {
                            setModalState(() => detalleCambioActual = val);
                            if (val != null) {
                              final varsRaw = await service.obtenerVariantesParaCambioTalla(
                                ropaId: val.ropaId,
                                varianteId: val.varianteId,
                              );
                              final Set<String> vistas = {};
                              final List<Map<String, dynamic>> varsClean = [];
                              for (final item in varsRaw) {
                                final t = item['talla']?.toString() ?? 'M';
                                if (!vistas.contains(t)) {
                                  vistas.add(t);
                                  varsClean.add(item);
                                }
                              }
                              if (varsClean.isNotEmpty) {
                                setModalState(() {
                                  variantesDisponibles = varsClean;
                                  varianteNuevaSeleccionada = int.tryParse(varsClean.first['variante_id']?.toString() ?? '1') ?? 1;
                                  tallaNuevaTexto = varsClean.first['talla']?.toString() ?? 'M';
                                });
                              }
                            }
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
                          child: Text(
                            'Pedido #${venta.id} - Total Bs. ${venta.montoTotal.toStringAsFixed(2)}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      const SizedBox(height: 14),

                      Text(
                        'Selecciona la Nueva Talla Disponible:',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: variantesDisponibles.map((v) {
                          final vId = int.tryParse(v['variante_id']?.toString() ?? '0') ?? 0;
                          final talla = v['talla']?.toString() ?? 'M';
                          final stock = v['stock_disponible'] ?? v['stock'] ?? 5;
                          final selected = varianteNuevaSeleccionada == vId && tallaNuevaTexto == talla;

                          return ChoiceChip(
                            label: Text(
                              'Talla $talla • Stock: $stock',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : AppTheme.textPrimary,
                              ),
                            ),
                            selected: selected,
                            selectedColor: const Color(0xFF4F46E5),
                            backgroundColor: const Color(0xFFF1F5F9),
                            onSelected: (_) {
                              setModalState(() {
                                varianteNuevaSeleccionada = vId;
                                tallaNuevaTexto = talla;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      Text(
                        'Motivo del Cambio de Talla:',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: motivoCambioCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Ej. La prenda me queda muy ajustada, solicito cambio de talla',
                          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                          contentPadding: const EdgeInsets.all(12),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                        ),
                      ),
                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: enviandoAccion
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.verified_outlined, color: Colors.white, size: 18),
                          label: Text(
                            enviandoAccion ? 'Procesando Cambio...' : 'Confirmar Cambio a Talla $tallaNuevaTexto',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 14),
                          ),
                          onPressed: enviandoAccion
                              ? null
                              : () async {
                                  setModalState(() => enviandoAccion = true);
                                  final resp = await service.solicitarCambioTalla7Dias(
                                    ventaId: venta.id,
                                    varianteDevueltaId: detalleCambioActual?.varianteId ?? 0,
                                    nuevaVarianteId: varianteNuevaSeleccionada,
                                    cantidad: 1,
                                    motivo: 'Cambio a Talla $tallaNuevaTexto: ${motivoCambioCtrl.text.trim()}',
                                  );

                                  if (!context.mounted) return;
                                  Navigator.pop(modalCtx);

                                  final notaCambio = resp?['nota_cambio'] ?? 'NC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                                  final mensaje = resp?['mensaje'] ?? 'Se emitió la Nota de Cambio $notaCambio reingresando tu prenda y descontando la nueva talla sin anular la factura original.';

                                  InAppNotificationBanner.show(
                                    context,
                                    title: '🔄 Nota de Cambio Emitida ($notaCambio)',
                                    message: mensaje,
                                    tipo: 'CAMBIO_TALLA',
                                  );

                                  try {
                                    Provider.of<NotificacionesService>(context, listen: false).cargarNotificaciones(mostrarPopupSiHayNueva: false);
                                    service.cargarHistorialCompras();
                                  } catch (_) {}

                                  showDialog(
                                    context: context,
                                    builder: (dialogCtx) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: const Row(
                                        children: [
                                          Icon(Icons.check_circle, color: Color(0xFF4F46E5)),
                                          SizedBox(width: 8),
                                          Text('Cambio Confirmado (RN-02)'),
                                        ],
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(mensaje, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEEF2FF),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              'Código de Nota de Cambio: $notaCambio\nFactura Mantenida: ${venta.numeroFactura ?? "FAC-ECOM"}',
                                              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF4338CA)),
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(dialogCtx),
                                          child: const Text('Entendido'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                        ),
                      ),
                    ]

                    // =========================================================
                    // CONTENIDO PESTAÑA 1: DEVOLUCIÓN / REEMBOLSO
                    // =========================================================
                    else ...[
                      // Aviso de Garantía Legal
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.shield_outlined, size: 16, color: Color(0xFFE11D48)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Garantía Legal de 7 Días (168 Horas): Puedes solicitar el reembolso de tu pedido #${venta.id} (${venta.numeroFactura ?? "FAC-ECOM"}) eligiendo la prenda específica o la orden completa.',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary, height: 1.35),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Selección de prenda a devolver (Total o por prenda específica)
                      Text(
                        'Prenda / Item a Devolver:',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: prendaDevolucionSeleccionada,
                        isExpanded: true,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.checkroom_outlined, size: 20, color: Color(0xFF64748B)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE11D48), width: 1.5)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                        ),
                        selectedItemBuilder: (BuildContext ctx) {
                          final listaTxt = [
                            'Todo el Pedido #${venta.id > 0 ? venta.id : "1"} (Bs. ${(venta.montoTotal > 0 ? venta.montoTotal : 0.0).toStringAsFixed(2)})',
                            ...venta.detalles.map((d) {
                              final pNom = d.prendaNombre.isNotEmpty ? d.prendaNombre : 'Prenda Exclusiva';
                              final pTalla = d.talla.isNotEmpty ? d.talla : 'M';
                              final pColor = d.color.isNotEmpty ? d.color : 'Estándar';
                              final pSub = d.subtotal > 0 ? d.subtotal : (d.precioUnitario * d.cantidad);
                              return '${d.cantidad}x $pNom ($pTalla/$pColor) - Bs. ${pSub.toStringAsFixed(2)}';
                            }),
                          ];
                          return listaTxt.map<Widget>((String txt) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                txt,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                              ),
                            );
                          }).toList();
                        },
                        items: [
                          DropdownMenuItem<String>(
                            value: 'Pedido Completo #${venta.id > 0 ? venta.id : "1"}',
                            child: SizedBox(
                              width: double.infinity,
                              child: Text(
                                'Todo el Pedido #${venta.id > 0 ? venta.id : "1"} (Bs. ${(venta.montoTotal > 0 ? venta.montoTotal : 0.0).toStringAsFixed(2)})',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          ...venta.detalles.map((d) {
                            final pNom = d.prendaNombre.isNotEmpty ? d.prendaNombre : 'Prenda Exclusiva';
                            final pTalla = d.talla.isNotEmpty ? d.talla : 'M';
                            final pColor = d.color.isNotEmpty ? d.color : 'Estándar';
                            final pSub = d.subtotal > 0 ? d.subtotal : (d.precioUnitario * d.cantidad);
                            final labelItem = '${d.cantidad}x $pNom ($pTalla/$pColor) - Bs. ${pSub.toStringAsFixed(2)}';
                            return DropdownMenuItem<String>(
                              value: labelItem,
                              child: SizedBox(
                                width: double.infinity,
                                child: Text(
                                  labelItem,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => prendaDevolucionSeleccionada = val);
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // Motivo de reembolso
                      Text(
                        'Motivo de la Devolución:',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: motivoDevolucionCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Ej. La prenda no me quedó bien o presenta defecto en costura',
                          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE11D48), width: 1.5)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
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
                        controller: cuentaBancariaCtrl,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.account_balance_outlined, size: 20, color: Color(0xFF64748B)),
                          hintText: 'Ej. Banco Mercantil Cta 1000... / Alias QR',
                          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE11D48), width: 1.5)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Botón enviar
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE11D48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: enviandoAccion
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.assignment_turned_in_outlined, color: Colors.white, size: 18),
                          label: Text(
                            enviandoAccion ? 'Enviando Solicitud...' : 'Enviar Solicitud de Reembolso',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 14),
                          ),
                          onPressed: (!elegible7Dias || enviandoAccion)
                              ? null
                              : () async {
                                  if (!elegible7Dias) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'La garantía de 7 días ya venció para este pedido (quedan ${diasRestantes.toStringAsFixed(0)} días).',
                                        ),
                                        backgroundColor: const Color(0xFFEF4444),
                                      ),
                                    );
                                    return;
                                  }
                                  if (motivoDevolucionCtrl.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Por favor ingresa el motivo del reembolso.')),
                                    );
                                    return;
                                  }

                                  setModalState(() => enviandoAccion = true);
                                  final motivoCompleto = 'Prenda: $prendaDevolucionSeleccionada. Motivo: ${motivoDevolucionCtrl.text.trim()}';
                                  final ok = await service.solicitarDevolucion(
                                    ventaId: venta.id,
                                    motivo: motivoCompleto,
                                    cuentaBancariaQr: cuentaBancariaCtrl.text.trim().isNotEmpty ? cuentaBancariaCtrl.text.trim() : null,
                                  );

                                  if (context.mounted) {
                                    Navigator.pop(modalCtx);
                                    if (ok) {
                                      InAppNotificationBanner.show(
                                        context,
                                        title: '🚨 Solicitud de Devolución Enviada',
                                        message: 'Tu solicitud para el pedido #${venta.id} por Bs. ${venta.montoTotal.toStringAsFixed(2)} ha sido enviada.',
                                        tipo: 'DEVOLUCION',
                                      );

                                      try {
                                        Provider.of<NotificacionesService>(context, listen: false)
                                            .cargarNotificaciones(mostrarPopupSiHayNueva: false);
                                        service.cargarHistorialCompras();
                                      } catch (_) {}

                                      showDialog(
                                        context: context,
                                        builder: (dialogCtx) => AlertDialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          title: const Row(
                                            children: [
                                              Icon(Icons.check_circle, color: Color(0xFF059669)),
                                              SizedBox(width: 8),
                                              Text('Solicitud Enviada'),
                                            ],
                                          ),
                                          content: Text(
                                            'Tu solicitud de devolución dentro de la Garantía de 7 Días para el pedido #${venta.id} fue registrada exitosamente.',
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
                        ),
                      ),
                    ],
                  ],
                ),
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
