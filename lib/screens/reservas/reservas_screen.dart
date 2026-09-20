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
      Provider.of<ReservasService>(context, listen: false).cargarReservas();
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

                              // Sucursal y Fecha Límite
                              Row(
                                children: [
                                  const Icon(Icons.store, size: 16, color: Color(0xFF4F46E5)),
                                  const SizedBox(width: 6),
                                  Text(
                                    r.sucursalNombre,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.schedule, size: 16, color: Color(0xFFF59E0B)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Retirar antes de: ${r.fechaLimite}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),

                              // Items de la reserva
                              ...r.detalles.map((d) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${d.cantidad}x ${d.prendaNombre} (${d.talla}, ${d.color})',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        Text(
                                          'Bs. ${d.subtotal.toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  )),

                              const Divider(height: 20),

                              // Monto y Cancelar
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total estimado: Bs. ${r.montoTotalEstimado.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                                  ),
                                  if (activa)
                                    TextButton(
                                      onPressed: () => _confirmarCancelar(context, resService, r.id),
                                      child: const Text('Cancelar', style: TextStyle(color: Color(0xFFEF4444))),
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

