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
  });

  String get nombreCompleto {
    if (nombre != null && apellido != null) {
      return '$nombre $apellido';
    }
    return nombre ?? username;
  }

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['usuario_id'] ?? json['id'] ?? 0;
    final int parsedId = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;

    String? parsedRol = json['rol'] ?? json['tipo_rol'];
    if (parsedRol == null && json['roles'] is List && (json['roles'] as List).isNotEmpty) {
      parsedRol = (json['roles'] as List).first.toString();
    }

    return UsuarioModel(
      id: parsedId,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      nombre: json['nombre'],
      apellido: json['apellido'],
      telefono: json['telefono'],
      direccion: json['direccion'],
      clienteId: json['cliente_id'] != null ? int.tryParse(json['cliente_id'].toString()) : null,
      rol: parsedRol ?? 'Cliente',
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
    };
  }
}

