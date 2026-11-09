import 'package:flutter/foundation.dart' show kIsWeb;

class Environment {
  // IP local de la máquina en la red Wi-Fi (para celular físico / emulador) y localhost para Web/PC
  static const String localLanIp = '192.168.1.12';
  static String? _customHost;

  static void setCustomHost(String host) {
    // Ignorar URLs de Render antiguas para forzar ejecución local si quedaron guardadas
    if (host.contains('onrender.com')) {
      _customHost = null;
      return;
    }
    _customHost = host;
  }

  // URL por defecto apuntando al backend local en puerto 8000
  static String get baseUrl {
    if (_customHost != null && _customHost!.isNotEmpty) {
      if (_customHost!.startsWith('http://') || _customHost!.startsWith('https://')) {
        return _customHost!;
      }
      return 'http://$_customHost:8000';
    }

    // En navegador Web / Desktop local usa 127.0.0.1:8000; en dispositivo móvil / APK usa la IP LAN local
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    return 'http://$localLanIp:8000';
  }

  // Claves de API para Vestidor Virtual (Intactas)
  static const List<String> decartApiKeys = [
    'dct_tienda-virtual_MFvQCKqLlCmcRVTfIGcoypZXfkiCWGeOrqgzFsbOKpCdEZhgJQERagVnPbbXqQzq',
    'dct_si2-parcial_qOCBWVtsCDmnrhLMjaIYMTjRJMnTqIOvtoCrcHWOepoDKFWkVSfgFowaeMznUrJw',
  ];
  static const String segmindApiKey = '';
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
  static String get stripePagos => '$apiV1/pagos/stripe';

  // Formatea URLs relativas (/static/uploads/...) a URLs absolutas hacia el backend local
  static String formatImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '$baseUrl$url';
    return '$baseUrl/$url';
  }
}
