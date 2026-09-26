import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/reservas_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class ReservasScreen extends StatefulWidget {
  const ReservasScreen({super.key});

  @override
  State<ReservasScreen> createState() => _ReservasScreenState();
}

class _ReservasScreenState extends State<ReservasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      final user = auth.currentUser;
      final clienteId = user?.username.isNotEmpty == true ? user!.username : user?.id.toString();
      Provider.of<ReservasService>(context, listen: false).cargarReservas(clienteId: clienteId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final resService = Provider.of<ReservasService>(context);

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reservas Web-to-Store')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.storefront_outlined, size: 64, color: Color(0xFF4F46E5)),
                const SizedBox(height: 16),
                const Text(
                  'Inicia sesión para gestionar tus reservas',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Aparta prendas desde la app y pruébatelas directamente en nuestras sucursales físicas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                  },
                  child: const Text('Iniciar Sesión'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reservas en Tienda'),
      ),
      body: resService.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : resService.reservas.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: Color(0xFFCBD5E1)),
                      SizedBox(height: 16),
                      Text(
                        'No tienes reservas activas',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Explora el catálogo y aparta tus prendas para recogerlas en tienda.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => resService.cargarReservas(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: resService.reservas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (ctx, i) {
                      final r = resService.reservas[i];
                      final activa = r.estaActiva;

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Cabecera Reserva
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Reserva #${r.id}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: activa ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      r.estado,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: activa ? const Color(0xFF15803D) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Cliente y Sucursal
                              Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 16, color: Color(0xFF4F46E5)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Cliente: ${r.clienteNombre}',
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
                                    r.sucursalNombre,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.timer_outlined, size: 16, color: Color(0xFFD97706)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Retirar antes de: ${r.fechaLimiteFormateada}',
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFFD97706)),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),

                              // Items / Prendas de la reserva
                              if (r.detalles.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Prenda en apartado presencial Web-to-Store',
                                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                  ),
                                )
                              else
                                ...r.detalles.map((d) => Container(
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

                              // Monto y Cancelar
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total estimado: Bs. ${r.montoTotalEstimado.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                                  ),
                                  if (activa)
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFFEF4444),
                                        side: const BorderSide(color: Color(0xFFFECDD3)),
                                      ),
                                      onPressed: () => _confirmarCancelar(context, resService, r.id),
                                      icon: const Icon(Icons.cancel_outlined, size: 16),
                                      label: const Text('Cancelar'),
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
    );
  }

  void _confirmarCancelar(BuildContext context, ReservasService service, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Reserva'),
        content: const Text('¿Deseas liberar los productos apartados de esta reserva?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Volver')),
          TextButton(
            onPressed: () {
              service.cancelarReserva(id);
              Navigator.pop(ctx);
            },
            child: const Text('Sí, Cancelar', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }
}

