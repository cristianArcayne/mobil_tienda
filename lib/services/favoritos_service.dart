import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../config/environment.dart';
import '../core/api_client.dart';
import '../core/sqlite_service.dart';
import '../core/storage_service.dart';
import '../models/prenda_model.dart';

class FavoritosService extends ChangeNotifier {
  List<PrendaModel> _favoritos = [];
  final Set<int> _favoritosIds = {};
  bool _isLoading = false;
  String _usuarioActivoId = 'guest';

  List<PrendaModel> get favoritos => List.unmodifiable(_favoritos);
  Set<int> get favoritosIds => Set.unmodifiable(_favoritosIds);
  int get totalFavoritos => _favoritos.length;
  bool get isLoading => _isLoading;

  FavoritosService() {
    cargarFavoritos();
  }

  bool esFavorito(int prendaId) {
    return _favoritosIds.contains(prendaId);
  }

  /// Cambia el usuario activo aislando estrictamente su lista de favoritos en memoria y SQLite
  Future<void> cambiarUsuarioActivo(String? usuarioId) async {
    _favoritos = [];
    _favoritosIds.clear();
    _usuarioActivoId = (usuarioId != null && usuarioId.trim().isNotEmpty)
        ? usuarioId.trim()
        : 'guest';
    notifyListeners();
    await cargarFavoritos(usuarioId: _usuarioActivoId);
  }

  void limpiarFavoritos() {
    _favoritos = [];
    _favoritosIds.clear();
    notifyListeners();
  }

  // Cargar favoritos desde SQLite local aislado por usuario
  Future<void> cargarFavoritos({String? usuarioId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (usuarioId != null && usuarioId.trim().isNotEmpty) {
        _usuarioActivoId = usuarioId.trim();
      } else {
        _usuarioActivoId = await StorageService.getActiveUserKey();
      }

      final guardados = await SqliteService.obtenerFavoritosUsuario(_usuarioActivoId);
      _favoritos = guardados;
      _favoritosIds.clear();
      for (final p in _favoritos) {
        _favoritosIds.add(p.id);
      }
    } catch (e) {
      debugPrint('Error al cargar favoritos locales en SQLite: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Alternar favorito (agregar / eliminar) con soporte offline SQLite e idempotencia UUIDv4
  Future<bool> toggleFavorito(PrendaModel prenda) async {
    final uid = await StorageService.getActiveUserKey();
    _usuarioActivoId = uid;
    final bool yaEsFavorito = _favoritosIds.contains(prenda.id);

    if (yaEsFavorito) {
      _favoritosIds.remove(prenda.id);
      _favoritos.removeWhere((p) => p.id == prenda.id);
      await SqliteService.eliminarFavoritoUsuario(uid, prenda.id);
      notifyListeners();

      try {
        await ApiClient.delete(
          '${Environment.baseUrl}/api/v1/favoritos/${prenda.id}/?usuario_id=$uid',
          requireAuth: false,
        );
      } catch (_) {}

      return false; // Ya no es favorito
    } else {
      _favoritosIds.add(prenda.id);
      _favoritos.insert(0, prenda);
      await SqliteService.guardarFavoritoUsuario(uid, prenda, pendienteSync: false);
      notifyListeners();

      try {
        await ApiClient.post(
          '${Environment.baseUrl}/api/v1/favoritos/',
          {
            'producto_id': prenda.id,
            'ropa_id': prenda.id,
            'usuario_id': uid,
          },
          requireAuth: false,
        );
      } catch (_) {
        // Sin red: marcar pendiente y encolar en Outbox SQLite con UUIDv4
        await SqliteService.guardarFavoritoUsuario(uid, prenda, pendienteSync: true);
        await SqliteService.encolarOperacionOffline(
          uuidTransaccion: const Uuid().v4(),
          usuarioId: uid,
          tipoOperacion: 'FAVORITO',
          payload: {
            'producto_id': prenda.id,
            'ropa_id': prenda.id,
            'usuario_id': uid,
          },
        );
      }

      return true; // Ahora es favorito
    }
  }

  Future<void> eliminarFavorito(int prendaId) async {
    final uid = await StorageService.getActiveUserKey();
    _usuarioActivoId = uid;
    if (_favoritosIds.contains(prendaId)) {
      _favoritosIds.remove(prendaId);
      _favoritos.removeWhere((p) => p.id == prendaId);
      await SqliteService.eliminarFavoritoUsuario(uid, prendaId);
      notifyListeners();

      try {
        await ApiClient.delete(
          '${Environment.baseUrl}/api/v1/favoritos/$prendaId/?usuario_id=$uid',
          requireAuth: false,
        );
      } catch (_) {}
    }
  }
}
