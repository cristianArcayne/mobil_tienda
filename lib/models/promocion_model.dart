class PromocionModel {
  final int id;
  final String nombre;
  final String? descripcion;
  final double porcentajeDescuento;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final bool activo;
  final bool estaVigente;
  final String estadoCalculado;
  final int totalPrendas;

  PromocionModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.porcentajeDescuento,
    this.fechaInicio,
    this.fechaFin,
    required this.activo,
    required this.estaVigente,
    required this.estadoCalculado,
    this.totalPrendas = 0,
  });

  factory PromocionModel.fromJson(Map<String, dynamic> json) {
    return PromocionModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      nombre: json['nombre']?.toString() ?? 'Promoción Especial',
      descripcion: json['descripcion']?.toString(),
      porcentajeDescuento: (json['porcentaje_descuento'] != null)
          ? double.tryParse(json['porcentaje_descuento'].toString()) ?? 0.0
          : 0.0,
      fechaInicio: json['fecha_inicio'] != null ? DateTime.tryParse(json['fecha_inicio'].toString()) : null,
      fechaFin: json['fecha_fin'] != null ? DateTime.tryParse(json['fecha_fin'].toString()) : null,
      activo: json['activo'] == true || json['activo'] == 1,
      estaVigente: json['esta_vigente'] == true || json['esta_vigente'] == 1,
      estadoCalculado: json['estado_calculado']?.toString() ?? 'ACTIVA',
      totalPrendas: json['total_prendas_asociadas'] is int
          ? json['total_prendas_asociadas']
          : int.tryParse(json['total_prendas_asociadas']?.toString() ?? '0') ?? 0,
    );
  }
}

