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
  int _diasVigencia = 2;
  final int _cantidad = 1;

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

    final user = auth.currentUser;
    final clienteId = user?.username.isNotEmpty == true ? user!.username : user?.id.toString();
    final clienteNombre = user?.nombreCompleto;

    final resService = Provider.of<ReservasService>(context, listen: false);
    final ok = await resService.crearReserva(
      sucursalId: _sucursalId,
      diasVigencia: _diasVigencia,
      clienteId: clienteId,
      clienteNombre: clienteNombre,
      items: [
        {
          'variante_id': widget.variante.id,
          'cantidad': _cantidad,
        }
      ],
    );

    if (ok && mounted) {
      InAppNotificationBanner.show(
        context,
        title: '¡Reserva Registrada! 🏪',
        message: 'Tu reserva de "${widget.prenda.nombre}" fue procesada con éxito. Puedes pasar a retirar por tienda.',
        tipo: 'RESERVA',
      );
      Provider.of<NotificacionesService>(context, listen: false).cargarNotificaciones(mostrarPopupSiHayNueva: false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Reserva creada con éxito! Tu prenda te espera en tienda.'),
          backgroundColor: Color(0xFF10B981),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apartar en Tienda Física'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen de la Prenda
            Card(
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
                              child: Image.network(widget.prenda.imagenPrincipal!, fit: BoxFit.cover),
                            )
                          : const Icon(Icons.checkroom),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.prenda.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Talla: ${widget.variante.talla} • Color: ${widget.variante.color}',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                          Text('Bs. ${widget.prenda.precio.toStringAsFixed(2)}',
                              style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Selección de Sucursal
            const Text('Seleccionar Sucursal de Retiro:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ..._sucursales.map((s) => RadioListTile<int>(
                  value: s['id'],
                  groupValue: _sucursalId,
                  title: Text(s['nombre'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(s['direccion'], style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  activeColor: const Color(0xFF4F46E5),
                  onChanged: (val) => setState(() => _sucursalId = val!),
                )),
            const SizedBox(height: 20),

            // Días de vigencia
            const Text('Tiempo límite para recoger:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [1, 2, 3, 5].map((d) {
                final isSel = _diasVigencia == d;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('$d ${d == 1 ? 'día' : 'días'}'),
                    selected: isSel,
                    selectedColor: const Color(0xFF4F46E5),
                    labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87),
                    onSelected: (_) => setState(() => _diasVigencia = d),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Beneficios Web to store
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified, size: 18, color: Color(0xFF2563EB)),
                      SizedBox(width: 8),
                      Text('Garantía de Disponibilidad', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'La prenda quedará reservada a tu nombre para que puedas probártela sin compromiso y pagar directamente en caja.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Botón Confirmar
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              icon: const Icon(Icons.check_circle_outline),
              label: resService.isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Confirmar Reserva Web-to-Store'),
              onPressed: resService.isLoading ? null : _enviarReserva,
            ),
          ],
        ),
      ),
    );
  }
}

