class NotificacionModel {
  final int id;
  final String titulo;
  final String mensaje;
  final String tipo; // PROMOCION, COMPRA, RESERVA, BROADCAST, SISTEMA, DEVOLUCION
  final bool leida;
  final DateTime fechaCreacion;
  final String? datosAdicionales;
  final int? usuarioId;

  NotificacionModel({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    this.leida = false,
    required this.fechaCreacion,
    this.datosAdicionales,
    this.usuarioId,
  });

  factory NotificacionModel.fromJson(Map<String, dynamic> json) {
    return NotificacionModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      titulo: json['titulo']?.toString() ?? json['title']?.toString() ?? 'Aviso FashionStore',
      mensaje: json['mensaje']?.toString() ?? json['message']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? json['type']?.toString() ?? 'PROMOCION',
      leida: json['leida'] == true || json['read'] == true,
      fechaCreacion: json['fecha_creacion'] != null
          ? (DateTime.tryParse(json['fecha_creacion'].toString()) ?? DateTime.now())
          : (json['created_at'] != null ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()) : DateTime.now()),
      datosAdicionales: json['datos_adicionales']?.toString(),
      usuarioId: json['usuario_id'] != null ? int.tryParse(json['usuario_id'].toString()) : null,
    );
  }
}
