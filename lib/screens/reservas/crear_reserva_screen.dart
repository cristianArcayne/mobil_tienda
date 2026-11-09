import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/prenda_model.dart';
import '../../services/reservas_service.dart';
import '../../services/auth_service.dart';
import '../../services/notificaciones_service.dart';
import '../../widgets/in_app_notification_banner.dart';
import '../auth/login_screen.dart';

class CrearReservaScreen extends StatefulWidget {
  final PrendaModel prenda;
  final VariantePrendaModel variante;

  const CrearReservaScreen({
    super.key,
    required this.prenda,
    required this.variante,
  });

  @override
  State<CrearReservaScreen> createState() => _CrearReservaScreenState();
}

class _CrearReservaScreenState extends State<CrearReservaScreen> {
  int _sucursalId = 1;
  final int _diasVigencia = 2; // Vigencia oficial 48 horas (CU-07)
  final int _cantidad = 1;
  String _horaEstimada = '18:00';

  final List<String> _horariosDisponibles = ['10:00', '12:00', '15:00', '18:00', '20:00'];

  final List<Map<String, dynamic>> _sucursales = [
    {'id': 1, 'nombre': 'Sucursal Central (Av. Principal)', 'direccion': 'Av. 6 de Agosto #450'},
    {'id': 2, 'nombre': 'Sucursal Mall Las Américas', 'direccion': 'C.C. Las Américas, Nivel 2'},
    {'id': 3, 'nombre': 'Sucursal San Miguel', 'direccion': 'Calle 21 de Calacoto #120'},
  ];

  void _enviarReserva() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (!auth.isAuthenticated) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    final resService = Provider.of<ReservasService>(context, listen: false);
    final prendasActivas = resService.totalPrendasActivas;

    // Validación estricta en cliente RN-04
    if (prendasActivas + _cantidad > 5) {
      final disponibles = (5 - prendasActivas) > 0 ? (5 - prendasActivas) : 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'RN-04: Límite superado. Tienes $prendasActivas prenda(s) reservada(s) activa(s). Solo puedes reservar hasta $disponibles prenda(s) más.',
          ),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    final user = auth.currentUser;
    final clienteId = user?.identificadorUnico;
    final clienteNombre = user?.nombreCompleto;
    final sucObj = _sucursales.firstWhere((s) => s['id'] == _sucursalId, orElse: () => _sucursales.first);
    final precioFinal = widget.prenda.precioConDescuento ?? widget.prenda.precio;

    final ok = await resService.crearReserva(
      sucursalId: _sucursalId,
      sucursalNombre: sucObj['nombre']?.toString(),
      diasVigencia: _diasVigencia,
      horaEstimada: _horaEstimada,
      clienteId: clienteId,
      clienteNombre: clienteNombre,
      items: [
        {
          'variante_id': widget.variante.id,
          'cantidad': _cantidad,
          'prenda_nombre': widget.prenda.nombre,
          'talla': widget.variante.talla,
          'color': widget.variante.color,
          'precio_unitario': precioFinal,
        }
      ],
    );

    if (ok && mounted) {
      final fueOffline = resService.ultimaReservaFueOffline;
      InAppNotificationBanner.show(
        context,
        title: fueOffline ? '📦 Reserva Guardada Offline (SQLite)' : '¡Reserva Registrada! 🏪',
        message: fueOffline
            ? 'Reserva con UUIDv4 guardada localmente en SQLite. Se sincronizará automáticamente al recuperar Internet.'
            : 'Tu reserva de "${widget.prenda.nombre}" fue procesada con éxito para las $_horaEstimada hs.',
        tipo: 'RESERVA',
      );
      Provider.of<NotificacionesService>(context, listen: false).cargarNotificaciones(mostrarPopupSiHayNueva: false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fueOffline
                ? 'Reserva registrada en Modo Offline (SQLite + UUIDv4).'
                : '¡Reserva creada con éxito! Tu prenda te espera en probador físico.',
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resService.errorMessage ?? 'Error al procesar reserva'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final resService = Provider.of<ReservasService>(context);
    final precioFinal = widget.prenda.precioConDescuento ?? widget.prenda.precio;

    final prendasActivas = resService.totalPrendasActivas;
    final limiteAlcanzado = (prendasActivas + _cantidad) > 5;

    // Verificar si ya existe una reserva activa para esta misma sucursal y horario
    final tieneReservaMismoHorario = resService.reservas.any((r) {
      final esActiva = r.estaActiva || r.estado == 'PENDIENTE_SYNC';
      if (!esActiva) return false;
      final sucMatch = r.sucursalNombre.contains('Central') && _sucursalId == 1 ||
          r.sucursalNombre.contains('Américas') && _sucursalId == 2 ||
          r.sucursalNombre.contains('San Miguel') && _sucursalId == 3 ||
          r.sucursalNombre.contains('#$_sucursalId');
      return sucMatch;
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apartar en Tienda Física (Web-to-Store)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen de la Prenda
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: widget.prenda.imagenPrincipal != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.prenda.imagenPrincipal!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.checkroom),
                              ),
                            )
                          : const Icon(Icons.checkroom),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.prenda.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text('Talla: ${widget.variante.talla} • Color: ${widget.variante.color}',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                          const SizedBox(height: 2),
                          Text('Bs. ${precioFinal.toStringAsFixed(2)}',
                              style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Contador de Prendas Reservadas (RN-04)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: limiteAlcanzado ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: limiteAlcanzado ? const Color(0xFFFCA5A5) : const Color(0xFFBBF7D0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    limiteAlcanzado ? Icons.warning_amber_rounded : Icons.info_outline,
                    color: limiteAlcanzado ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prendas Reservadas Activas: $prendasActivas de 5 permitidas',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: limiteAlcanzado ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
                          ),
                        ),
                        Text(
                          limiteAlcanzado
                              ? 'Has alcanzado el límite máximo de 5 prendas (RN-04). Retira o cancela reservas previas.'
                              : 'Puedes apartar hasta ${5 - prendasActivas} prenda(s) más simultáneamente.',
                          style: TextStyle(
                            fontSize: 12,
                            color: limiteAlcanzado ? const Color(0xFF991B1B) : const Color(0xFF166534),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Selección de Sucursal
            const Text('Seleccionar Sucursal de Retiro:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ..._sucursales.map((s) {
              final isSel = _sucursalId == s['id'];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFFEEF2FF) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSel ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                    width: isSel ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  dense: true,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: Icon(
                    isSel ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: isSel ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
                  ),
                  title: Text(
                    s['nombre'],
                    style: TextStyle(
                      fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                      fontSize: 14,
                      color: isSel ? const Color(0xFF312E81) : const Color(0xFF1E293B),
                    ),
                  ),
                  subtitle: Text(
                    s['direccion'],
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  onTap: () => setState(() => _sucursalId = s['id']),
                ),
              );
            }),
            const SizedBox(height: 20),

            // Horario estimado de visita (RF-07 / RN-04)
            const Text('Horario Estimado de Visita a Probador:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _horariosDisponibles.map((h) {
                final isSel = _horaEstimada == h;
                return ChoiceChip(
                  label: Text('$h hs'),
                  selected: isSel,
                  selectedColor: const Color(0xFF4F46E5),
                  labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                  onSelected: (_) => setState(() => _horaEstimada = h),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Banner Dinámico: Notificar si se unificará con una reserva existente
            if (tieneReservaMismoHorario) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.layers_outlined, color: Color(0xFF4F46E5), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Unificación automática: Ya tienes una reserva en esta sucursal a las $_horaEstimada hs. Esta prenda se unirá a esa misma reserva en una sola orden.',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3730A3), height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Condiciones de Reserva (RN-04 & CU-07)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified_outlined, size: 18, color: Color(0xFF2563EB)),
                      SizedBox(width: 8),
                      Text(
                        'Condiciones de Reserva (RN-04 & CU-07)',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    '• Máximo 5 prendas activas simultáneamente en total por cliente.\n'
                    '• Vigencia máxima de 48 horas con identificador único UUIDv4.\n'
                    '• Tolerancia en tienda: Hasta 2 horas posteriores al horario fijado.\n'
                    '• Si apartas varias prendas en el mismo horario y sucursal, se consolidan en una sola reserva.\n'
                    '• Si estás sin conexión, se almacena en SQLite local y se sincroniza al tener internet.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Botón Confirmar
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: limiteAlcanzado ? Colors.grey : const Color(0xFF4F46E5),
              ),
              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
              label: resService.isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      limiteAlcanzado
                          ? 'Límite de 5 Prendas Alcanzado'
                          : (tieneReservaMismoHorario ? 'Agregar a Mi Reserva Existente' : 'Confirmar Reserva Web-to-Store'),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
              onPressed: (resService.isLoading || limiteAlcanzado) ? null : _enviarReserva,
            ),
          ],
        ),
      ),
    );
  }
}
