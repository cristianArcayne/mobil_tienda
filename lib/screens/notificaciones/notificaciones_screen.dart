import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/ventas_service.dart';
import '../../services/reservas_service.dart';
import '../../services/promociones_service.dart';
import '../../services/notificaciones_service.dart';
import '../ventas/detalle_compra_screen.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() {
      _cargarDatos();
    });
  }

  void _cargarDatos() {
    Provider.of<NotificacionesService>(context, listen: false).cargarNotificaciones();
    Provider.of<PromocionesService>(context, listen: false).cargarPromociones();
    Provider.of<VentasService>(context, listen: false).cargarHistorialCompras();
    Provider.of<ReservasService>(context, listen: false).cargarReservas();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifService = Provider.of<NotificacionesService>(context);
    final promocionesService = Provider.of<PromocionesService>(context);
    final ventasService = Provider.of<VentasService>(context);
    final reservasService = Provider.of<ReservasService>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Centro de Notificaciones',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
            tooltip: 'Actualizar notificaciones',
            onPressed: _cargarDatos,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.primaryColor,
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.campaign_outlined, size: 20), text: 'Avisos & Promos'),
            Tab(icon: Icon(Icons.local_shipping_outlined, size: 20), text: 'Mis Compras'),
            Tab(icon: Icon(Icons.storefront_outlined, size: 20), text: 'Reservas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Avisos y Promociones
          _buildAvisosYPromocionesTab(notifService, promocionesService),

          // 2. Estado de Compras Físicas y Digitales
          _buildComprasTab(ventasService),

          // 3. Estado de Reservas Web-to-Store
          _buildReservasTab(reservasService),
        ],
      ),
    );
  }

  Widget _buildAvisosYPromocionesTab(
    NotificacionesService notifService,
    PromocionesService promoService,
  ) {
    final bool isLoading = (notifService.isLoading && notifService.notificaciones.isEmpty) ||
        (promoService.isLoading && promoService.promociones.isEmpty);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }

    final notificaciones = notifService.notificaciones.where((n) {
      final t = n.tipo.toUpperCase();
      return !t.contains('COMPRA') &&
             !t.contains('VENTA') &&
             !t.contains('RESERVA') &&
             !t.contains('DEVOLUCION');
    }).toList();
    final promociones = promoService.promociones;

    if (notificaciones.isEmpty && promociones.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => _cargarDatos(),
        color: AppTheme.primaryColor,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.campaign_outlined, size: 55, color: AppTheme.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      'No hay avisos ni promociones por el momento',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Los avisos enviados desde la administración web aparecerán aquí en tiempo real.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _cargarDatos,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Actualizar'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _cargarDatos(),
      color: AppTheme.primaryColor,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Avisos del Sistema / Administrador
          if (notificaciones.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 4),
              child: Row(
                children: [
                  const Icon(Icons.mark_email_unread_outlined, size: 18, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Mensajes y Notificaciones Recientes',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            ...notificaciones.map((n) {
              final isPromo = n.tipo.toUpperCase().contains('PROMO');
              final isCompra = n.tipo.toUpperCase().contains('COMPRA');
              final isReserva = n.tipo.toUpperCase().contains('RESERVA');

              Color badgeColor = const Color(0xFF4338CA);
              IconData badgeIcon = Icons.campaign_outlined;

              if (isPromo) {
                badgeColor = const Color(0xFFE11D48);
                badgeIcon = Icons.local_offer_outlined;
              } else if (isCompra) {
                badgeColor = const Color(0xFF0D9488);
                badgeIcon = Icons.shopping_bag_outlined;
              } else if (isReserva) {
                badgeColor = const Color(0xFFD97706);
                badgeIcon = Icons.storefront_outlined;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(badgeIcon, color: badgeColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: badgeColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  n.tipo.toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: badgeColor,
                                  ),
                                ),
                              ),
                              Text(
                                '${n.fechaCreacion.day}/${n.fechaCreacion.month} ${n.fechaCreacion.hour.toString().padLeft(2, '0')}:${n.fechaCreacion.minute.toString().padLeft(2, '0')}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            n.titulo,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            n.mensaje,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              color: AppTheme.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
          ],

          // Promociones y Descuentos del Catálogo
          if (promociones.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 4),
              child: Row(
                children: [
                  const Icon(Icons.local_offer_outlined, size: 18, color: Color(0xFFE11D48)),
                  const SizedBox(width: 8),
                  Text(
                    'Promociones Activas en Catálogo',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            ...promociones.map((p) {
              final descuentoInt = p.porcentajeDescuento.toInt();
              final badgeTexto = descuentoInt > 0 ? '$descuentoInt% DESCUENTO' : 'OFERTA';
              final badgeColor = descuentoInt >= 30 ? const Color(0xFFE11D48) : const Color(0xFF1E3A8A);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badgeTexto,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: badgeColor,
                            ),
                          ),
                        ),
                        Text(
                          p.estaVigente ? '🔥 Vigente Ahora' : p.estadoCalculado,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: p.estaVigente ? const Color(0xFF059669) : AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      p.nombre,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (p.descripcion != null && p.descripcion!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        p.descripcion!,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Text(
                            'Código: PROMO-${p.id}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Ver en Catálogo',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildComprasTab(VentasService service) {
    if (service.isLoading && service.compras.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }

    if (service.compras.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => service.cargarHistorialCompras(),
        color: AppTheme.primaryColor,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 50, color: AppTheme.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      'No tienes compras registradas',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tus compras en tienda física o app aparecerán aquí.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => service.cargarHistorialCompras(),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Actualizar'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => service.cargarHistorialCompras(),
      color: AppTheme.primaryColor,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: service.compras.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (ctx, i) {
          final c = service.compras[i];

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetalleCompraScreen(venta: c),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          c.estado.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0D9488),
                          ),
                        ),
                      ),
                      Text(
                        '#${c.id}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Total: Bs. ${c.montoTotal.toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${c.detalles.length} artículo(s) • Método: ${c.metodoPago ?? "Efectivo / QR"}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            c.fecha,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'Ver Factura',
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReservasTab(ReservasService service) {
    if (service.isLoading && service.reservas.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }

    if (service.reservas.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => service.cargarReservas(),
        color: AppTheme.primaryColor,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.storefront_outlined, size: 50, color: AppTheme.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      'No tienes reservas activas',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Reserva prendas online y recógelas en tienda.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => service.cargarReservas(),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Actualizar'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => service.cargarReservas(),
      color: AppTheme.primaryColor,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: service.reservas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (ctx, i) {
          final r = service.reservas[i];
          final isPending = r.estado.toUpperCase() == 'PENDIENTE';

          return InkWell(
            onTap: () => _mostrarModalDetalleReserva(context, r, service),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPending
                              ? const Color(0xFFD97706).withValues(alpha: 0.1)
                              : const Color(0xFF059669).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          r.estado.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isPending ? const Color(0xFFD97706) : const Color(0xFF059669),
                          ),
                        ),
                      ),
                      Text(
                        'Reserva #${r.id}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    r.sucursalNombre,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${r.detalles.length} prenda(s) reservada(s) • Total estimado: Bs. ${r.montoTotalEstimado.toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 14, color: Color(0xFFD97706)),
                          const SizedBox(width: 4),
                          Text(
                            'Límite: ${r.fechaLimiteFormateada}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'Ver Detalle',
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _mostrarModalDetalleReserva(BuildContext context, dynamic r, ReservasService service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detalle Reserva #${r.id}',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: r.estaActiva ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      r.estado,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: r.estaActiva ? const Color(0xFF15803D) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 16, color: Color(0xFF4F46E5)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Cliente: ${r.clienteNombre}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.storefront, size: 16, color: Color(0xFF4F46E5)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(r.sucursalNombre, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF4F46E5), fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 16, color: Color(0xFFD97706)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Límite retiro: ${r.fechaLimiteFormateada}', style: const TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.w600, fontSize: 12.5)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Prendas Apartadas (${r.detalles.length}):',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 10),
              if (r.detalles.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Text(
                    'Prenda en apartado presencial Web-to-Store (Reserva registrada)',
                    style: TextStyle(color: Color(0xFFB45309), fontSize: 13),
                  ),
                )
              else
                ...r.detalles.map<Widget>((d) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: (d.imagenUrl != null && d.imagenUrl!.isNotEmpty)
                                ? Image.network(
                                    d.imagenUrl!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 50,
                                      height: 50,
                                      color: const Color(0xFFE2E8F0),
                                      child: const Icon(Icons.checkroom, color: Color(0xFF64748B)),
                                    ),
                                  )
                                : Container(
                                    width: 50,
                                    height: 50,
                                    color: const Color(0xFFEEF2FF),
                                    child: const Icon(Icons.checkroom, color: Color(0xFF4F46E5)),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.prendaNombre,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Talla: ${d.talla} • Color: ${d.color}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                                Text(
                                  '${d.cantidad}x Bs. ${d.precioUnitario.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF4F46E5), fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Bs. ${d.subtotal.toStringAsFixed(2)}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w900, color: const Color(0xFF10B981)),
                          ),
                        ],
                      ),
                    )),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total a Pagar en Tienda:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Text(
                    'Bs. ${r.montoTotalEstimado.toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF10B981)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (r.estaActiva)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFFECDD3)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      service.cancelarReserva(r.id);
                    },
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancelar Esta Reserva'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
