import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyAccessToken = 'fs_access_token';
  static const String _keyRefreshToken = 'fs_refresh_token';
  static const String _keyUserData = 'fs_user_data';
  static const String _keyOfflineCart = 'fs_offline_cart';
  static const String _keyClienteId = 'fs_cliente_id';
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
    if (user.containsKey('cliente_id')) {
      await prefs.setString(_keyClienteId, user['cliente_id'].toString());
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

  static Future<String?> getClienteId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyClienteId) ?? '1'; // Default fallback cliente
  }

  // Guardar carrito offline local
  static Future<void> saveOfflineCart(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyOfflineCart, jsonEncode(items));
  }

  // Obtener carrito offline
  static Future<List<Map<String, dynamic>>> getOfflineCart() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyOfflineCart);
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

  // Cerrar sesión
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyUserData);
  }
}

