import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyAccessToken = 'fs_access_token';
  static const String _keyRefreshToken = 'fs_refresh_token';
  static const String _keyUserData = 'fs_user_data';
  static const String _keyOfflineCartPrefix = 'fs_offline_cart_u_';
  static const String _keyClienteId = 'fs_cliente_id';
  static const String _keyTenantId = 'fs_tenant_id';
  static const String _keyServerHost = 'fs_server_host';
  static const String _keyRememberMe = 'fs_remember_me';
  static const String _keySavedUsername = 'fs_saved_username';

  // Guardar preferencia de Recordar Datos
  static Future<void> saveRememberMe(bool remember, {String? username}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberMe, remember);
    if (username != null && username.isNotEmpty) {
      await prefs.setString(_keySavedUsername, username);
    } else if (!remember) {
      await prefs.remove(_keySavedUsername);
    }
  }

  static Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRememberMe) ?? true;
  }

  static Future<String?> getSavedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySavedUsername);
  }

  // Guardar IP/Host del servidor
  static Future<void> saveServerHost(String host) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServerHost, host);
  }

  // Obtener IP/Host del servidor
  static Future<String?> getServerHost() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyServerHost);
  }

  // Guardar Tenant / Empresa ID (RN-05 Multitenancy)
  static Future<void> saveTenantId(String tenantId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTenantId, tenantId);
  }

  static Future<String> getTenantId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTenantId) ?? '1';
  }

  // Guardar token JWT
  static Future<void> saveTokens({required String access, String? refresh}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, access);
    if (refresh != null) {
      await prefs.setString(_keyRefreshToken, refresh);
    }
  }

  // Obtener Token de Acceso
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  // Obtener Refresh Token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  // Guardar datos de usuario
  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserData, jsonEncode(user));
    final cid = user['username'] ?? user['nombre_usuario'] ?? user['cliente_id'] ?? user['id'];
    if (cid != null && cid.toString().trim().isNotEmpty) {
      await prefs.setString(_keyClienteId, cid.toString().trim());
    }
    final empId = user['empresa_id'] ?? user['tenant_id'];
    if (empId != null) {
      await prefs.setString(_keyTenantId, empId.toString());
    }
  }

  // Obtener datos de usuario
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyUserData);
    if (data != null) {
      try {
        return jsonDecode(data) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Obtiene el identificador único del usuario actual sin fallback estático a '1'
  static Future<String?> getClienteId() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_keyClienteId);
    if (saved != null && saved.trim().isNotEmpty) {
      return saved.trim();
    }
    final user = await getUser();
    if (user != null) {
      final uname = user['username']?.toString();
      if (uname != null && uname.isNotEmpty) return uname;
      final uid = user['id']?.toString();
      if (uid != null && uid.isNotEmpty && uid != '0') return uid;
    }
    return null;
  }

  /// Obtiene una clave de usuario aislada para almacenamiento local
  static Future<String> getActiveUserKey() async {
    final cid = await getClienteId();
    return (cid != null && cid.isNotEmpty) ? cid : 'guest';
  }

  // Guardar carrito offline local aislado por usuario
  static Future<void> saveOfflineCart(List<Map<String, dynamic>> items, {String? userKey}) async {
    final prefs = await SharedPreferences.getInstance();
    final uk = userKey ?? await getActiveUserKey();
    await prefs.setString('$_keyOfflineCartPrefix$uk', jsonEncode(items));
  }

  // Obtener carrito offline aislado por usuario
  static Future<List<Map<String, dynamic>>> getOfflineCart({String? userKey}) async {
    final prefs = await SharedPreferences.getInstance();
    final uk = userKey ?? await getActiveUserKey();
    final data = prefs.getString('$_keyOfflineCartPrefix$uk');
    if (data != null) {
      try {
        final list = jsonDecode(data) as List;
        return list.map((e) => e as Map<String, dynamic>).toList();
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  // Cerrar sesión limpiando únicamente la sesión activa
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyUserData);
    await prefs.remove(_keyClienteId);
    // Eliminar llaves globales heredadas antiguas para evitar contaminación entre cuentas
    await prefs.remove('fs_offline_cart');
    await prefs.remove('fs_favoritos_prendas');
  }
}
