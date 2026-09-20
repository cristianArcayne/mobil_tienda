import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/environment.dart';
import '../core/api_client.dart';
import '../models/prenda_model.dart';

class FavoritosService extends ChangeNotifier {
  static const String _keyFavoritos = 'fs_favoritos_prendas';

  List<PrendaModel> _favoritos = [];
  final Set<int> _favoritosIds = {};
  bool _isLoading = false;

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

  // Cargar favoritos desde almacenamiento local y sincronizar con backend
  Future<void> cargarFavoritos() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_keyFavoritos);
      if (savedJson != null && savedJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(savedJson);
        _favoritos = decoded.map((item) => PrendaModel.fromJson(item as Map<String, dynamic>)).toList();
        _favoritosIds.clear();
        for (var p in _favoritos) {
          _favoritosIds.add(p.id);
        }
      }
    } catch (e) {
      debugPrint('Error al cargar favoritos locales: $e');
    }

    _isLoading = false;
    notifyListeners();

    // Sincronización en segundo plano con backend
    _sincronizarConBackend();
  }

  Future<void> _guardarLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listMap = _favoritos.map((p) => {
        'id': p.id,
        'nombre': p.nombre,
        'descripcion': p.descripcion,
        'precio': p.precio,
        'precio_con_descuento': p.precioConDescuento,
        'categoria_nombre': p.categoriaNombre,
        'imagen_principal': p.imagenPrincipal,
        'imagenes': p.imagenes,
        'modelo_3d_uri': p.modelo3dUri,
        'stock_total_disponible': p.stockTotalDisponible,
        'estado_global_stock': p.estadoGlobalStock,
        'calificacion_promedio': p.calificacionPromedio,
        'total_resenas': p.totalResenas,
        'variantes': p.variantes.map((v) => {
          'id': v.id,
          'talla': v.talla,
          'color': v.color,
          'cod_barra': v.codBarra,
          'stock_disponible': v.stockDisponible,
          'estado_stock': v.estadoStock,
        }).toList(),
      }).toList();
      await prefs.setString(_keyFavoritos, jsonEncode(listMap));
    } catch (e) {
      debugPrint('Error al guardar favoritos locales: $e');
    }
  }

  Future<void> _sincronizarConBackend() async {
    try {
      final response = await ApiClient.get(
        '${Environment.baseUrl}/api/v1/favoritos/?page_size=100',
        requireAuth: false,
      );
      if (response != null && response is Map && response.containsKey('results')) {
        final List results = response['results'] as List;
        for (var item in results) {
          final prodId = item['producto_id'] is int ? item['producto_id'] : int.tryParse(item['producto_id']?.toString() ?? '0') ?? 0;
          if (prodId > 0 && !_favoritosIds.contains(prodId)) {
            _favoritosIds.add(prodId);
            _favoritos.add(PrendaModel(
              id: prodId,
              nombre: item['producto_nombre']?.toString() ?? 'Prenda',
              descripcion: '',
              precio: (item['producto_precio'] is num) ? (item['producto_precio'] as num).toDouble() : 0.0,
              imagenPrincipal: item['producto_imagen']?.toString(),
              imagenes: item['producto_imagen'] != null ? [item['producto_imagen'].toString()] : [],
              stockTotalDisponible: 10,
              estadoGlobalStock: 'DISPONIBLE',
              variantes: [],
            ));
          }
        }
        await _guardarLocal();
        notifyListeners();
      }
    } catch (_) {}
  }

  // Alternar favorito (agregar / eliminar)
  Future<bool> toggleFavorito(PrendaModel prenda) async {
    final bool yaEsFavorito = _favoritosIds.contains(prenda.id);

    if (yaEsFavorito) {
      _favoritosIds.remove(prenda.id);
      _favoritos.removeWhere((p) => p.id == prenda.id);
      await _guardarLocal();
      notifyListeners();

      // Notificar backend
      try {
        await ApiClient.delete(
          '${Environment.baseUrl}/api/v1/favoritos/${prenda.id}/',
          requireAuth: false,
        );
      } catch (_) {}

      return false; // Ya no es favorito
    } else {
      _favoritosIds.add(prenda.id);
      _favoritos.insert(0, prenda);
      await _guardarLocal();
      notifyListeners();

      // Notificar backend
      try {
        await ApiClient.post(
          '${Environment.baseUrl}/api/v1/favoritos/',
          {
            'producto_id': prenda.id,
            'ropa_id': prenda.id,
          },
          requireAuth: false,
        );
      } catch (_) {}

      return true; // Ahora es favorito
    }
  }

  Future<void> eliminarFavorito(int prendaId) async {
    if (_favoritosIds.contains(prendaId)) {
      _favoritosIds.remove(prendaId);
      _favoritos.removeWhere((p) => p.id == prendaId);
      await _guardarLocal();
      notifyListeners();

      try {
        await ApiClient.delete(
          '${Environment.baseUrl}/api/v1/favoritos/$prendaId/',
          requireAuth: false,
        );
      } catch (_) {}
    }
  }
}

