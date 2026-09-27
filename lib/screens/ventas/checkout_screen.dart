import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/carrito_service.dart';
import '../../services/ventas_service.dart';
import '../../services/auth_service.dart';
import '../../services/notificaciones_service.dart';
import '../../widgets/in_app_notification_banner.dart';
import '../../models/venta_model.dart';
import 'detalle_compra_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late TextEditingController _nombreController;
  late TextEditingController _direccionController;
  late TextEditingController _nitController;
  late TextEditingController _notasController;
  String _metodoPago = 'STRIPE';

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;

    _nombreController = TextEditingController(text: user?.nombreCompleto ?? 'Cliente Atelier');
    _direccionController = TextEditingController(
      text: (user?.direccion != null && user!.direccion!.isNotEmpty)
          ? user.direccion!
          : 'Av. Las Palmas #240, Zona Sur',
    );
    _nitController = TextEditingController(
      text: user?.clienteId != null ? user!.clienteId.toString() : '11540380',
    );
    _notasController = TextEditingController();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _nitController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  void _iniciarProcesoPago() {
    final cart = Provider.of<CarritoService>(context, listen: false);
    if (cart.items.isEmpty) return;

    if (_direccionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa tu dirección de entrega.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_metodoPago == 'STRIPE') {
      _mostrarModalPagoStripe(cart.totalMonto);
    } else if (_metodoPago == 'QR_SIMPLE') {
      _mostrarModalPagoQR(cart.totalMonto);
    } else {
      _ejecutarPagoFinal();
    }
  }

  void _mostrarModalPagoStripe(double montoTotal) {
    final tarjetaCtrl = TextEditingController(text: '4242 4242 4242 4242');
    final expCtrl = TextEditingController(text: '12/28');
    final cvcCtrl = TextEditingController(text: '123');
    final titularCtrl = TextEditingController(
      text: _nombreController.text.trim().isNotEmpty ? _nombreController.text.trim() : 'Cliente FashionStore',
    );
    bool procesando = false;
    String? errorStripe;

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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabecera Stripe
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF635BFF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.lock, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'stripe',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Pasarela de Pagos Stripe',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: procesando ? null : () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Paga con tarjeta de débito o crédito de forma segura con cifrado bancario TLS 1.3.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),

                    // Tarjeta Visual Simulada
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF635BFF), Color(0xFF1E1B4B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF635BFF).withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Icon(Icons.nfc, color: Colors.white70, size: 28),
                              Row(
                                children: [
                                  Text(
                                    'stripe',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.credit_card, color: Colors.white, size: 22),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            tarjetaCtrl.text.isNotEmpty ? tarjetaCtrl.text : '•••• •••• •••• ••••',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('TITULAR', style: GoogleFonts.plusJakartaSans(color: Colors.white60, fontSize: 9)),
                                  Text(
                                    titularCtrl.text.isNotEmpty ? titularCtrl.text.toUpperCase() : 'CLIENTE FASHIONSTORE',
                                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('VENCE', style: GoogleFonts.plusJakartaSans(color: Colors.white60, fontSize: 9)),
                                  Text(
                                    expCtrl.text.isNotEmpty ? expCtrl.text : 'MM/AA',
                                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Botón para autorrellenar tarjeta de prueba Stripe
                    InkWell(
                      onTap: () {
                        setModalState(() {
                          tarjetaCtrl.text = '4242 4242 4242 4242';
                          expCtrl.text = '12/28';
                          cvcCtrl.text = '123';
                          titularCtrl.text = _nombreController.text.trim().isNotEmpty
                              ? _nombreController.text.trim()
                              : 'Cliente Stripe';
                          errorStripe = null;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.science_outlined, color: Color(0xFF635BFF), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tarjeta de Prueba Stripe Oficial (4242 4242...)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF4338CA),
                                ),
                              ),
                            ),
                            const Icon(Icons.touch_app, size: 16, color: Color(0xFF635BFF)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Formulario de Tarjeta
                    Text('Número de Tarjeta:', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: tarjetaCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.credit_card_outlined, size: 20),
                        hintText: '4242 4242 4242 4242',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Fecha Exp (MM/AA):', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: expCtrl,
                                keyboardType: TextInputType.datetime,
                                onChanged: (_) => setModalState(() {}),
                                decoration: InputDecoration(
                                  hintText: '12/28',
                                  prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('CVC / CVV:', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: cvcCtrl,
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                decoration: InputDecoration(
                                  hintText: '123',
                                  prefixIcon: const Icon(Icons.security_outlined, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Text('Nombre en la Tarjeta:', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titularCtrl,
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                        hintText: 'Nombre del titular',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (errorStripe != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorStripe!,
                                style: GoogleFonts.plusJakartaSans(color: const Color(0xFFB91C1C), fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Botón Procesar Pago con Stripe
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF635BFF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        icon: procesando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.lock, color: Colors.white, size: 20),
                        label: Text(
                          procesando
                              ? 'Procesando con Stripe...'
                              : 'Pagar Bs. ${montoTotal.toStringAsFixed(2)} con Stripe',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: procesando
                            ? null
                            : () async {
                                final numTarjeta = tarjetaCtrl.text.replaceAll(' ', '').trim();
                                if (numTarjeta.length < 14) {
                                  setModalState(() => errorStripe = 'Ingresa un número de tarjeta válido (mínimo 14 dígitos).');
                                  return;
                                }
                                if (cvcCtrl.text.trim().length < 3) {
                                  setModalState(() => errorStripe = 'Ingresa un código CVC válido de 3 o 4 dígitos.');
                                  return;
                                }

                                setModalState(() {
                                  procesando = true;
                                  errorStripe = null;
                                });

                                final cart = Provider.of<CarritoService>(context, listen: false);
                                final ventasService = Provider.of<VentasService>(context, listen: false);
                                final auth = Provider.of<AuthService>(context, listen: false);
                                final user = auth.currentUser;
                                final clienteId = user?.username.isNotEmpty == true ? user!.username : user?.id.toString();

                                final items = cart.items.map((i) => {
                                  'variante_id': i.varianteId,
                                  'cantidad': i.cantidad,
                                  'precio_unitario': i.precioUnitario,
                                }).toList();

                                // 1. Crear PaymentIntent en backend Stripe
                                final intento = await ventasService.crearIntentoPagoStripe(
                                  monto: montoTotal,
                                  clienteId: clienteId,
                                  descripcion: 'Compra FashionStore Móvil - Titular: ${titularCtrl.text.trim()}',
                                );

                                final piId = intento?['payment_intent_id'] ?? 'pi_stripe_${DateTime.now().millisecondsSinceEpoch}';

                                // 2. Confirmar la orden con Stripe
                                final venta = await ventasService.confirmarPagoStripe(
                                  paymentIntentId: piId,
                                  items: items,
                                  direccionEnvio: _direccionController.text.trim(),
                                  razonSocial: titularCtrl.text.trim().isNotEmpty ? titularCtrl.text.trim() : _nombreController.text.trim(),
                                  nitCliente: _nitController.text.trim(),
                                  notas: _notasController.text.trim().isNotEmpty ? _notasController.text.trim() : 'Pago con Pasarela Stripe',
                                  clienteId: clienteId,
                                );

                                if (venta != null && context.mounted) {
                                  Navigator.pop(modalCtx);
                                  cart.limpiarCarrito();
                                  InAppNotificationBanner.show(
                                    context,
                                    title: '¡Pago Exitoso con Stripe! 💳',
                                    message: 'Tu pago de Bs. ${venta.montoTotal.toStringAsFixed(2)} fue confirmado mediante Stripe.',
                                    tipo: 'COMPRA',
                                  );
                                  try {
                                    Provider.of<NotificacionesService>(context, listen: false).cargarNotificaciones(mostrarPopupSiHayNueva: false);
                                    ventasService.cargarHistorialCompras(clienteId: clienteId);
                                  } catch (_) {}

                                  _mostrarDialogoExitoStripe(venta, piId);
                                } else {
                                  setModalState(() {
                                    procesando = false;
                                    errorStripe = ventasService.errorMessage ?? 'Ocurrió un error al procesar el pago con Stripe.';
                                  });
                                }
                              },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified_user_outlined, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Text(
                          'Transacción protegida por Stripe Payments Inc. TLS 1.3',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarDialogoExitoStripe(VentaModel venta, String paymentIntentId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, size: 50, color: Color(0xFF635BFF)),
            ),
            const SizedBox(height: 16),
            Text(
              '¡Pago Exitoso con Stripe!',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tu pedido #${venta.id} ha sido procesado mediante la pasarela segura Stripe.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Pagado:', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted)),
                      Text(
                        'Bs. ${venta.montoTotal.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: const Color(0xFF10B981)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Factura Fiscal:', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted)),
                      Text(
                        venta.numeroFactura ?? 'FAC-ECOM-2026',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pasarela:', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted)),
                      Text(
                        'Stripe Payments Inc.',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF635BFF)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Ref Stripe:', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted)),
                      Expanded(
                        child: Text(
                          paymentIntentId,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 11, color: AppTheme.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF635BFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.qr_code_2, color: Colors.white, size: 20),
                  label: Text(
                    'Ver Seguimiento y QR de Retiro',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => DetalleCompraScreen(venta: venta)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Volver al Catálogo',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _mostrarModalPagoQR(double montoTotal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pago con QR Simple',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Escanea el código QR desde tu aplicación bancaria (BNB, BCP, Banco Unión, Mercantil o Bisa).',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),

            // Marco QR Digital
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.qr_code_2,
                          size: 160,
                          color: Color(0xFF0F172A),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.storefront,
                            size: 22,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Monto a transferir:',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
                  ),
                  Text(
                    'Bs. ${montoTotal.toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Botón Confirmar Pago
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                label: Text(
                  'Ya realicé el pago QR',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _ejecutarPagoFinal();
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _ejecutarPagoFinal() async {
    final cart = Provider.of<CarritoService>(context, listen: false);
    final ventasService = Provider.of<VentasService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;
    final clienteId = user?.username.isNotEmpty == true ? user!.username : user?.id.toString();

    final items = cart.items.map((i) => {
      'variante_id': i.varianteId,
      'cantidad': i.cantidad,
      'precio_unitario': i.precioUnitario,
    }).toList();

    final venta = await ventasService.procesarCheckout(
      items: items,
      metodoPago: _metodoPago,
      direccionEnvio: _direccionController.text.trim(),
      razonSocial: _nombreController.text.trim(),
      nitCliente: _nitController.text.trim(),
      notas: _notasController.text.trim(),
      clienteId: clienteId,
    );

    if (venta != null && mounted) {
      cart.limpiarCarrito();
      InAppNotificationBanner.show(
        context,
        title: '¡Compra Exitosa! 🛍️',
        message: 'Tu pedido #${venta.id} por Bs. ${venta.montoTotal.toStringAsFixed(2)} ha sido procesado correctamente.',
        tipo: 'COMPRA',
      );
      Provider.of<NotificacionesService>(context, listen: false).cargarNotificaciones(mostrarPopupSiHayNueva: false);
      ventasService.cargarHistorialCompras(clienteId: clienteId);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, size: 50, color: Color(0xFF10B981)),
              ),
              const SizedBox(height: 16),
              Text(
                '¡Compra Exitosa!',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tu pedido #${venta.id} ha sido procesado y registrado con éxito.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Pagado:', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted)),
                        Text(
                          'Bs. ${venta.montoTotal.toStringAsFixed(2)}',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: const Color(0xFF10B981)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Factura Fiscal:', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted)),
                        Text(
                          venta.numeroFactura ?? 'FAC-ECOM-2026',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Método:', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted)),
                        Text(
                          _metodoPago == 'QR_SIMPLE' ? 'QR Simple' : _metodoPago,
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.qr_code_2, color: Colors.white, size: 20),
                    label: Text(
                      'Ver Seguimiento y QR de Retiro',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx); // Cerrar diálogo
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => DetalleCompraScreen(venta: venta)),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx); // Cerrar diálogo
                      Navigator.pop(context); // Volver al catálogo/inicio
                    },
                    child: Text(
                      'Volver al Catálogo',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ventasService.errorMessage ?? 'Error al procesar el pago.'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CarritoService>(context);
    final ventasService = Provider.of<VentasService>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Checkout & Pago Digital',
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
            // Resumen de Orden
            Text(
              'RESUMEN DEL PEDIDO',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEFE9E3)),
              ),
              child: Column(
                children: [
                  ...cart.items.map(
                    (i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${i.cantidad}x ${i.prendaNombre} (${i.talla})',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            'Bs. ${i.subtotal.toStringAsFixed(2)}',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: Color(0xFFE2E8F0)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total a pagar:',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary),
                      ),
                      Text(
                        'Bs. ${cart.totalMonto.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w900,
                          fontSize: 19,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Dirección y Datos de Envío
            Text(
              'DATOS DE ENTREGA Y FACTURACIÓN',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEFE9E3)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _direccionController,
                    decoration: InputDecoration(
                      labelText: 'Dirección de Envío a Domicilio',
                      prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nombreController,
                          decoration: InputDecoration(
                            labelText: 'Razón Social / Nombre',
                            prefixIcon: const Icon(Icons.person_outline, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _nitController,
                          decoration: InputDecoration(
                            labelText: 'NIT / CI',
                            prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Métodos de Pago
            Text(
              'MÉTODO DE PAGO DIGITAL',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            _buildMetodoPagoOption(
              valor: 'STRIPE',
              titulo: 'Pasarela de Pagos Stripe',
              subtitulo: 'Visa, Mastercard, AMEX • Tarjeta Débito / Crédito',
              icono: Icons.credit_card,
              badge: 'RECOMENDADO',
            ),
            const SizedBox(height: 8),
            _buildMetodoPagoOption(
              valor: 'QR_SIMPLE',
              titulo: 'Pago Rápido QR Simple',
              subtitulo: 'Bancos de Bolivia (BNB, BCP, Banco Unión, Bisa)',
              icono: Icons.qr_code_2,
            ),
            const SizedBox(height: 8),
            _buildMetodoPagoOption(
              valor: 'TRANSFERENCIA',
              titulo: 'Transferencia Bancaria',
              subtitulo: 'Abono directo a cuenta corporativa',
              icono: Icons.account_balance,
            ),
            const SizedBox(height: 32),

            // Botón Pagar
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _metodoPago == 'STRIPE' ? const Color(0xFF635BFF) : const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.lock_outline, color: Colors.white),
                label: ventasService.isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _metodoPago == 'STRIPE'
                            ? 'Pagar con Stripe (Bs. ${cart.totalMonto.toStringAsFixed(2)})'
                            : 'Pagar Bs. ${cart.totalMonto.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                onPressed: (ventasService.isLoading || cart.items.isEmpty) ? null : _iniciarProcesoPago,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetodoPagoOption({
    required String valor,
    required String titulo,
    required String subtitulo,
    required IconData icono,
    String? badge,
  }) {
    final isSelected = _metodoPago == valor;
    final esStripe = valor == 'STRIPE';

    return GestureDetector(
      onTap: () => setState(() => _metodoPago = valor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (esStripe ? const Color(0xFFEEF2FF) : const Color(0xFFECFDF5))
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? (esStripe ? const Color(0xFF635BFF) : const Color(0xFF10B981))
                : const Color(0xFFEFE9E3),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (esStripe ? const Color(0xFF635BFF) : const Color(0xFF10B981))
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icono,
                color: isSelected
                    ? Colors.white
                    : (esStripe ? const Color(0xFF635BFF) : AppTheme.primaryColor),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          titulo,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF635BFF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitulo,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected
                  ? (esStripe ? const Color(0xFF635BFF) : const Color(0xFF10B981))
                  : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}
