class DetalleVentaModel {
  final int id;
  final int varianteId;
  final int? ropaId;
  final String prendaNombre;
  final String? imagenUrl;
  final String talla;
  final String color;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  DetalleVentaModel({
    required this.id,
    this.varianteId = 0,
    this.ropaId,
    required this.prendaNombre,
    this.imagenUrl,
    required this.talla,
    required this.color,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory DetalleVentaModel.fromJson(Map<String, dynamic> json) {
    final pNom = (json['prenda_nombre'] ?? json['nombre'] ?? json['ropa_nombre'] ?? 'Prenda').toString();
    final pTalla = (json['talla'] ?? json['medida'] ?? 'M').toString();
    final pColor = (json['color'] ?? json['color_nombre'] ?? 'Estándar').toString();
    final pCant = json['cantidad'] is int ? json['cantidad'] as int : int.tryParse(json['cantidad']?.toString() ?? '') ?? 1;
    final pPrec = double.tryParse((json['precio_unitario'] ?? json['precio'] ?? '0').toString()) ?? 0.0;
    double pSub = double.tryParse((json['subtotal'] ?? '0').toString()) ?? 0.0;
    if (pSub <= 0 && pPrec > 0) {
      pSub = pPrec * pCant;
    }

    return DetalleVentaModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      varianteId: json['variante_id'] is int ? json['variante_id'] as int : int.tryParse(json['variante_id']?.toString() ?? '') ?? 0,
      ropaId: json['ropa_id'] is int ? json['ropa_id'] as int : int.tryParse(json['ropa_id']?.toString() ?? ''),
      prendaNombre: pNom.isNotEmpty ? pNom : 'Prenda',
      imagenUrl: json['imagen_url']?.toString() ?? json['imagen_principal']?.toString(),
      talla: pTalla.isNotEmpty ? pTalla : 'M',
      color: pColor.isNotEmpty ? pColor : 'Estándar',
      cantidad: pCant,
      precioUnitario: pPrec,
      subtotal: pSub,
    );
  }
}

class VentaModel {
  final int id;
  final String fecha;
  final double montoTotal;
  final String estado; // COMPLETADA, PENDIENTE, PENDIENTE_SYNC, CANCELADA
  final String? metodoPago;
  final String? numeroFactura;
  final String? direccionEnvio;
  final String sucursalNombre;
  final String clienteNombre;
  final List<DetalleVentaModel> detalles;

  VentaModel({
    required this.id,
    required this.fecha,
    required this.montoTotal,
    required this.estado,
    this.metodoPago,
    this.numeroFactura,
    this.direccionEnvio,
    required this.sucursalNombre,
    required this.clienteNombre,
    required this.detalles,
  });

  /// Calcula las horas transcurridas desde la compra para validar la Garantía Legal de 7 Días (168h - RN-01)
  double get horasTranscurridas {
    if (fecha.isEmpty) return 0.0;
    try {
      final dt = DateTime.parse(fecha).toUtc();
      final ahora = DateTime.now().toUtc();
      final diff = ahora.difference(dt).inMinutes / 60.0;
      return diff < 0 ? 0.0 : diff;
    } catch (_) {
      return 0.0;
    }
  }

  /// RN-01: Elegible dentro de los 7 días calendario (168 horas) posteriores a la compra
  bool get esElegibleGarantia7Dias => horasTranscurridas <= 168.0;

  double get diasRestantesGarantia {
    final restHoras = 168.0 - horasTranscurridas;
    return restHoras <= 0 ? 0.0 : (restHoras / 24.0);
  }

  static String formatFechaLimpia(String rawIso) {
    if (rawIso.isEmpty) return '';
    try {
      final dt = DateTime.parse(rawIso).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$day/$month/$year $hour:$min hs';
    } catch (_) {
      return rawIso.replaceAll('T', ' ').split('.').first;
    }
  }

  String get fechaFormateada => formatFechaLimpia(fecha);

  // ============================================================================
  // CASOS DE USO CU-10 y CU-11: Ventas Digitales Stripe y Cobros QR Simple
  // Identifica el metodo de pago aplicado y calcula la cantidad total de prendas
  // adquiridas para trazabilidad fiscal y control de garantias a 7 dias (CU-12).
  // ============================================================================
  bool get esPagoQR => metodoPago?.toLowerCase().contains('qr') ?? false;
  bool get esPagoStripe =>
      (metodoPago?.toLowerCase().contains('stripe') ?? false) ||
      (metodoPago?.toLowerCase().contains('tarjeta') ?? false);
  bool get estaCompletada =>
      estado == 'COMPLETADA' || estado == 'PAGADO' || estado == 'PAGADA';
  int get cantidadTotalPrendas => detalles.fold(0, (sum, d) => sum + d.cantidad);

  factory VentaModel.fromJson(Map<String, dynamic> json) {
    var rawDetalles = json['detalles'] as List? ?? [];
    String? nroFactura = json['numero_factura']?.toString();
    if (nroFactura == null && json['factura'] is Map) {
      nroFactura = json['factura']['nro_factura']?.toString();
    }

    final rawMonto = json['total'] ?? json['monto_total'] ?? json['monto_neto'] ?? json['precio_total'] ?? 0;
    final double parsedMonto = double.tryParse(rawMonto.toString()) ?? 0.0;

    return VentaModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      fecha: json['fecha']?.toString() ?? '',
      montoTotal: parsedMonto,
      estado: json['estado_pago']?.toString() ?? json['estado']?.toString() ?? 'COMPLETADA',
      metodoPago: json['metodo_pago_nombre']?.toString() ?? json['metodo_pago']?.toString() ?? 'QR Simple',
      numeroFactura: nroFactura ?? 'FAC-ECOM-2026',
      direccionEnvio: json['direccion_envio']?.toString() ?? 'Entrega a domicilio',
      sucursalNombre: json['sucursal_nombre']?.toString() ?? 'Sucursal Central (Av. Principal)',
      clienteNombre: json['cliente_nombre']?.toString() ?? json['cliente_id']?.toString() ?? 'Cliente Registrado',
      detalles: rawDetalles.map((d) => DetalleVentaModel.fromJson(d as Map<String, dynamic>)).toList(),
    );
  }
}
