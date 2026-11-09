class UsuarioModel {
  final int id;
  final String username;
  final String email;
  final String? nombre;
  final String? apellido;
  final String? telefono;
  final String? direccion;
  final int? clienteId;
  final String? rol;
  final int empresaId;

  UsuarioModel({
    required this.id,
    required this.username,
    required this.email,
    this.nombre,
    this.apellido,
    this.telefono,
    this.direccion,
    this.clienteId,
    this.rol,
    this.empresaId = 1,
  });

  String get nombreCompleto {
    if (nombre != null && apellido != null && nombre!.isNotEmpty) {
      return '$nombre $apellido'.trim();
    }
    if (nombre != null && nombre!.isNotEmpty) {
      return nombre!;
    }
    return username;
  }

  /// Identificador único para aislar compras, reservas, carrito y favoritos por usuario
  String get identificadorUnico {
    if (username.trim().isNotEmpty) return username.trim();
    if (clienteId != null && clienteId! > 0) return clienteId.toString();
    if (email.trim().isNotEmpty) return email.trim();
    return id.toString();
  }

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['usuario_id'] ?? json['id'] ?? 0;
    final int parsedId = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;

    String? parsedRol = json['rol'] ?? json['tipo_rol'];
    if (parsedRol == null && json['roles'] is List && (json['roles'] as List).isNotEmpty) {
      parsedRol = (json['roles'] as List).first.toString();
    }

    final rawEmp = json['empresa_id'] ?? json['tenant_id'] ?? 1;
    final int parsedEmp = rawEmp is int ? rawEmp : int.tryParse(rawEmp.toString()) ?? 1;

    return UsuarioModel(
      id: parsedId,
      username: json['username']?.toString() ?? json['nombre_usuario']?.toString() ?? '',
      email: json['email']?.toString() ?? json['correo']?.toString() ?? '',
      nombre: json['nombre']?.toString(),
      apellido: (json['apellido'] ?? json['apellido_pat'])?.toString(),
      telefono: json['telefono']?.toString(),
      direccion: json['direccion']?.toString(),
      clienteId: json['cliente_id'] != null ? int.tryParse(json['cliente_id'].toString()) : null,
      rol: parsedRol ?? 'Cliente',
      empresaId: parsedEmp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'nombre': nombre,
      'apellido': apellido,
      'telefono': telefono,
      'direccion': direccion,
      'cliente_id': clienteId,
      'rol': rol,
      'empresa_id': empresaId,
    };
  }
}
