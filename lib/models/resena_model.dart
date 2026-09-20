class ResenaModel {
  final int id;
  final int ropaId;
  final String clienteNombre;
  final int calificacion; // 1 a 5 estrellas
  final String? comentario;
  final String fecha;

  ResenaModel({
    required this.id,
    required this.ropaId,
    required this.clienteNombre,
    required this.calificacion,
    this.comentario,
    required this.fecha,
  });

  factory ResenaModel.fromJson(Map<String, dynamic> json) {
    return ResenaModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      ropaId: json['ropa_id'] is int ? json['ropa_id'] : int.tryParse(json['ropa_id'].toString()) ?? 0,
      clienteNombre: json['cliente_nombre']?.toString() ?? 'Cliente FashionStore',
      calificacion: json['calificacion'] is int 
          ? json['calificacion'] 
          : int.tryParse(json['calificacion'].toString()) ?? 5,
      comentario: json['comentario']?.toString(),
      fecha: json['fecha']?.toString() ?? '',
    );
  }
}

