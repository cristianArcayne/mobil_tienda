import 'package:flutter/material.dart';
import '../config/environment.dart';
import '../core/api_client.dart';
import '../core/storage_service.dart';
import '../models/usuario_model.dart';

class AuthService extends ChangeNotifier {
  UsuarioModel? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isGuest = false;
  String? _errorMessage;

  UsuarioModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isGuest => _isGuest;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthService() {
    init();
  }

  // Carga e inicialización de sesión guardada
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final token = await StorageService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        final userMap = await StorageService.getUser();
        if (userMap != null) {
          _currentUser = UsuarioModel.fromJson(userMap);
          _isGuest = false;
        }
      }
    } catch (_) {
      // Ignorar fallos de deserialización en arranque
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Entrar como invitado
  void enterAsGuest() {
    _currentUser = null;
    _isGuest = true;
    _errorMessage = null;
    notifyListeners();
  }

  // Iniciar Sesión con JWT
  Future<bool> login(String username, String password, {bool rememberMe = true}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        Environment.authLogin,
        {
          'username': username.trim(),
          'password': password.trim(),
        },
        requireAuth: false,
      );

      if (response != null && response is Map) {
        final accessToken = response['access_token'] ?? response['token'] ?? response['access'];
        final refreshToken = response['refresh_token'] ?? response['refresh'];

        if (accessToken != null) {
          await StorageService.saveTokens(access: accessToken, refresh: refreshToken);

          // Extraer datos de usuario (LoginResponse directo o anidado)
          final Map<String, dynamic> userData = response['usuario'] is Map 
              ? (response['usuario'] as Map<String, dynamic>)
              : (response['user'] is Map 
                  ? (response['user'] as Map<String, dynamic>) 
                  : (response as Map<String, dynamic>));

          _currentUser = UsuarioModel.fromJson(userData);
          await StorageService.saveUser(_currentUser!.toJson());
          await StorageService.saveRememberMe(rememberMe, username: username.trim());

          _isGuest = false;
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      throw Exception('Credenciales incorrectas o respuesta inválida del servidor');
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Registro de nuevo Cliente
  Future<bool> registro({
    required String username,
    required String email,
    required String password,
    required String nombre,
    required String apellido,
    String? telefono,
    String? ci,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        Environment.authRegistro,
        {
          'username': username.trim(),
          'email': email.trim(),
          'password': password.trim(),
          'nombre': nombre.trim(),
          'apellido': apellido.trim(),
          'telefono': telefono?.trim(),
          'ci': (ci != null && ci.isNotEmpty) ? ci.trim() : '0',
        },
        requireAuth: false,
      );

      _isLoading = false;
      notifyListeners();
      return response != null;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Solicitar código para recuperación de cuenta
  Future<Map<String, dynamic>?> solicitarCodigoRecuperacion(String usernameOrEmail) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        Environment.authRecuperarSolicitar,
        {
          'username_or_email': usernameOrEmail.trim(),
        },
        requireAuth: false,
      );

      _isLoading = false;
      notifyListeners();
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return {'success': true, 'mensaje': 'Código enviado correctamente.'};
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Verificar código de 6 dígitos
  Future<bool> verificarCodigoRecuperacion(String usernameOrEmail, String codigo) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        Environment.authRecuperarVerificar,
        {
          'username_or_email': usernameOrEmail.trim(),
          'codigo': codigo.trim(),
        },
        requireAuth: false,
      );

      _isLoading = false;
      notifyListeners();
      return response != null;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Cambiar contraseña por la nueva
  Future<bool> cambiarPasswordRecuperacion({
    required String usernameOrEmail,
    required String codigo,
    required String nuevaPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        Environment.authRecuperarCambiar,
        {
          'username_or_email': usernameOrEmail.trim(),
          'codigo': codigo.trim(),
          'nueva_contrasena': nuevaPassword.trim(),
        },
        requireAuth: false,
      );

      _isLoading = false;
      notifyListeners();
      return response != null;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Actualizar datos del perfil
  Future<bool> actualizarPerfil({
    required String nombre,
    required String apellido,
    required String direccion,
    String? email,
    String? telefono,
  }) async {
    if (_currentUser == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final id = _currentUser!.username.isNotEmpty ? _currentUser!.username : _currentUser!.id.toString();
      final response = await ApiClient.put(
        '${Environment.apiV1}/seguridad/perfil/$id',
        {
          'nombre': nombre.trim(),
          'apellido': apellido.trim(),
          'direccion': direccion.trim(),
          'email': (email ?? _currentUser!.email).trim(),
          'telefono': (telefono ?? _currentUser!.telefono ?? '').trim(),
        },
      );

      if (response != null && response is Map) {
        _currentUser = UsuarioModel(
          id: _currentUser!.id,
          username: _currentUser!.username,
          email: response['email'] ?? _currentUser!.email,
          nombre: response['nombre'] ?? nombre.trim(),
          apellido: response['apellido'] ?? apellido.trim(),
          telefono: response['telefono'] ?? telefono,
          direccion: response['direccion'] ?? direccion.trim(),
          clienteId: _currentUser!.clienteId,
          rol: _currentUser!.rol,
        );
        await StorageService.saveUser(_currentUser!.toJson());
        _isLoading = false;
        notifyListeners();
        return true;
      }
      throw Exception('Respuesta no válida del servidor.');
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Cerrar Sesión
  Future<void> logout() async {
    try {
      // Notificar al backend si es posible para auditoría en bitácora
      await ApiClient.post(Environment.authLogout, {}, requireAuth: true);
    } catch (_) {
      // Proceder con el cierre local incluso si el backend está desconectado
    }
    await StorageService.clearSession();
    _currentUser = null;
    _isGuest = true;
    notifyListeners();
  }

  String _cleanErrorMessage(dynamic error) {
    final msg = error.toString();
    if (msg.contains('ApiException:')) {
      return msg.replaceFirst('ApiException:', '').trim();
    }
    if (msg.contains('SocketException') || msg.contains('Failed host lookup') || msg.contains('Connection refused')) {
      return 'No se pudo conectar al servidor. Revisa tu conexión o la IP del servidor.';
    }
    if (msg.contains('TimeoutException')) {
      return 'El servidor tardó demasiado en responder. Intenta nuevamente.';
    }
    return msg;
  }
}
