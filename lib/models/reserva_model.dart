class DetalleReservaModel {
  final int id;
  final int varianteId;
  final int cantidad;
  final String prendaNombre;
  final String? imagenUrl;
  final String talla;
  final String color;
  final double precioUnitario;
  final double subtotal;

  DetalleReservaModel({
    required this.id,
    required this.varianteId,
    required this.cantidad,
    required this.prendaNombre,
    this.imagenUrl,
    required this.talla,
    required this.color,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory DetalleReservaModel.fromJson(Map<String, dynamic> json) {
    return DetalleReservaModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      varianteId: json['variante_id'] is int ? json['variante_id'] : int.tryParse(json['variante_id'].toString()) ?? 0,
      cantidad: json['cantidad'] is int ? json['cantidad'] : int.tryParse(json['cantidad'].toString()) ?? 1,
      prendaNombre: json['prenda_nombre']?.toString() ?? 'Prenda',
      imagenUrl: json['imagen_url']?.toString() ?? json['imagen_principal']?.toString(),
      talla: json['talla']?.toString() ?? 'Única',
      color: json['color']?.toString() ?? 'Estándar',
      precioUnitario: double.tryParse(json['precio_unitario']?.toString() ?? '0') ?? 0.0,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class ReservaModel {
  final int id;
  final String fecha;
  final String fechaLimite;
  final String estado; // PENDIENTE, CONFIRMADA, ENTREGADA, CANCELADA, EXPIRADA
  final String sucursalNombre;
  final String? sucursalDireccion;
  final String clienteNombre;
  final double montoTotalEstimado;
  final List<DetalleReservaModel> detalles;

  ReservaModel({
    required this.id,
    required this.fecha,
    required this.fechaLimite,
    required this.estado,
    required this.sucursalNombre,
    this.sucursalDireccion,
    required this.clienteNombre,
    required this.montoTotalEstimado,
    required this.detalles,
  });

  bool get estaActiva => estado == 'PENDIENTE' || estado == 'CONFIRMADA';

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
  String get fechaLimiteFormateada => formatFechaLimpia(fechaLimite);

  factory ReservaModel.fromJson(Map<String, dynamic> json) {
    var rawDetalles = json['detalles'] as List? ?? [];
    return ReservaModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      fecha: json['fecha']?.toString() ?? '',
      fechaLimite: json['fecha_limite']?.toString() ?? '',
      estado: json['estado']?.toString() ?? 'PENDIENTE',
      sucursalNombre: json['sucursal_nombre']?.toString() ?? 'Tienda Central',
      sucursalDireccion: json['sucursal_direccion']?.toString(),
      clienteNombre: json['cliente_nombre']?.toString() ?? json['cliente_id']?.toString() ?? 'Cliente Registrado',
      montoTotalEstimado: double.tryParse(json['total_estimado']?.toString() ?? json['monto_total_estimado']?.toString() ?? '0') ?? 0.0,
      detalles: rawDetalles.map((d) => DetalleReservaModel.fromJson(d as Map<String, dynamic>)).toList(),
    );
  }
}

