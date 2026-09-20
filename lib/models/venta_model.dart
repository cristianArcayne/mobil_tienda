class DetalleVentaModel {
  final int id;
  final String prendaNombre;
  final String talla;
  final String color;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  DetalleVentaModel({
    required this.id,
    required this.prendaNombre,
    required this.talla,
    required this.color,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory DetalleVentaModel.fromJson(Map<String, dynamic> json) {
    return DetalleVentaModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      prendaNombre: json['prenda_nombre']?.toString() ?? 'Prenda',
      talla: json['talla']?.toString() ?? 'Única',
      color: json['color']?.toString() ?? 'Estándar',
      cantidad: json['cantidad'] is int ? json['cantidad'] : int.tryParse(json['cantidad'].toString()) ?? 1,
      precioUnitario: double.tryParse(json['precio_unitario']?.toString() ?? '0') ?? 0.0,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class VentaModel {
  final int id;
  final String fecha;
  final double montoTotal;
  final String estado; // COMPLETADA, PENDIENTE, CANCELADA
  final String? metodoPago;
  final String? numeroFactura;
  final String? direccionEnvio;
  final List<DetalleVentaModel> detalles;

  VentaModel({
    required this.id,
    required this.fecha,
    required this.montoTotal,
    required this.estado,
    this.metodoPago,
    this.numeroFactura,
    this.direccionEnvio,
    required this.detalles,
  });

  factory VentaModel.fromJson(Map<String, dynamic> json) {
    var rawDetalles = json['detalles'] as List? ?? [];
    String? nroFactura = json['numero_factura']?.toString();
    if (nroFactura == null && json['factura'] is Map) {
      nroFactura = json['factura']['nro_factura']?.toString();
    }

    final rawMonto = json['total'] ?? json['monto_total'] ?? json['monto_neto'] ?? 0;
    final double parsedMonto = double.tryParse(rawMonto.toString()) ?? 0.0;

    return VentaModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      fecha: json['fecha']?.toString() ?? '',
      montoTotal: parsedMonto,
      estado: json['estado_pago']?.toString() ?? json['estado']?.toString() ?? 'COMPLETADA',
      metodoPago: json['metodo_pago_nombre']?.toString() ?? json['metodo_pago']?.toString() ?? 'QR Simple',
      numeroFactura: nroFactura ?? 'FAC-ECOM-2026',
      direccionEnvio: json['direccion_envio']?.toString() ?? 'Entrega a domicilio',
      detalles: rawDetalles.map((d) => DetalleVentaModel.fromJson(d as Map<String, dynamic>)).toList(),
    );
  }
}

