class Environment {
  // IP o Host personalizado configurable (ej: '192.168.1.50' para celular físico)
  static String? _customHost;

  static void setCustomHost(String host) {
    _customHost = host;
  }

  // URL por defecto del backend desplegado en Render (o customHost si se especifica)
  static String get baseUrl {
    if (_customHost != null && _customHost!.isNotEmpty) {
      if (_customHost!.startsWith('http://') || _customHost!.startsWith('https://')) {
        return _customHost!;
      }
      return 'http://$_customHost:8000';
    }

    // Por defecto se conecta al backend en la nube en Render
    return 'https://tienda-backend-kvfk.onrender.com';
  }
  
  // Clave de API de Segmind (IDM-VTON) y Google Gemini para pruebas virtuales
  static const String segmindApiKey = 'SG_6197dc2bb848ae07';
  static const String geminiApiKey = '';
  static const String geminiModel = 'gemini-2.5-flash-image';

  // Rutas base de la API FastAPI
  static String get apiV1 => '$baseUrl/api/v1';
  
  // Endpoints específicos de Autenticación y Seguridad
  static String get authLogin => '$apiV1/login/';
  static String get authRegistro => '$apiV1/usuarios/registrar_cliente/';
  static String get authLogout => '$apiV1/logout/';
  static String get authPerfil => '$apiV1/seguridad/perfil';
  static String get authRefresh => '$apiV1/seguridad/refresh';
  static String get authRecuperarSolicitar => '$apiV1/recuperar-password/solicitar/';
  static String get authRecuperarVerificar => '$apiV1/recuperar-password/verificar/';
  static String get authRecuperarCambiar => '$apiV1/recuperar-password/cambiar/';

  static String get catalogoDisponibilidad => '$apiV1/catalogo-disponibilidad';
  static String get reservas => '$apiV1/reservas';
  static String get carritoPersistente => '$apiV1/carrito-persistente';
  static String get ventas => '$apiV1/ventas';
  static String get promociones => '$apiV1/promociones';
  static String get notificaciones => '$apiV1/notificaciones/feed';
  static String get vestidorAr => '$apiV1/ar';
  static String get iaRecomendador => '$apiV1/ia';
  static String get resenas => '$apiV1/resenas';

  // Formatea URLs relativas (/static/uploads/...) a URLs absolutas (http://127.0.0.1:8000/static/uploads/...)
  static String formatImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '$baseUrl$url';
    return '$baseUrl/$url';
  }
}
