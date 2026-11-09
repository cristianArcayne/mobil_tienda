import 'package:flutter/material.dart';
import '../config/environment.dart';
import '../core/api_client.dart';
import '../core/sqlite_service.dart';
import '../models/prenda_model.dart';

class CategoriaModel {
  final int id;
  final String nombre;

  CategoriaModel({required this.id, required this.nombre});

  factory CategoriaModel.fromJson(Map<String, dynamic> json) {
    return CategoriaModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      nombre: json['nombre']?.toString() ?? '',
    );
  }
}

class CatalogoService extends ChangeNotifier {
  List<PrendaModel> _prendas = [];
  List<CategoriaModel> _categorias = [];
  bool _isLoading = false;
  bool _isOfflineMode = false;
  String? _errorMessage;
  int? _categoriaFiltro;
  String? _busqueda;

  List<PrendaModel> get prendas => _prendas;
  List<CategoriaModel> get categorias => _categorias;
  bool get isLoading => _isLoading;
  bool get isOfflineMode => _isOfflineMode;
  String? get errorMessage => _errorMessage;
  int? get categoriaFiltro => _categoriaFiltro;
  String? get busqueda => _busqueda;

  // Cargar categorías reales desde la base de datos o reconstruir desde caché SQLite
  Future<void> cargarCategorias() async {
    try {
      final response = await ApiClient.get(
        '${Environment.baseUrl}/api/categorias/',
        requireAuth: false,
      );
      if (response is List) {
        _categorias = response.map((json) => CategoriaModel.fromJson(json as Map<String, dynamic>)).toList();
        notifyListeners();
        return;
      }
    } catch (_) {
      // Si no hay conexión, reconstruir categorías a partir de las prendas en SQLite
      final cached = await SqliteService.obtenerPrendasOffline();
      final nombresUnicos = <String>{};
      for (final p in cached) {
        if (p.categoriaNombre != null && p.categoriaNombre!.isNotEmpty) {
          nombresUnicos.add(p.categoriaNombre!);
        }
      }
      int idx = 1;
      _categorias = nombresUnicos.map((n) => CategoriaModel(id: idx++, nombre: n)).toList();
      notifyListeners();
    }
  }

  // Cargar catálogo con disponibilidad omnicanal en tiempo real + Respaldo SQLite (CU-05 / RF-13)
  Future<void> cargarCatalogo({int? categoriaId, String? buscar, bool soloConStock = false}) async {
    _isLoading = true;
    _errorMessage = null;
    _categoriaFiltro = categoriaId;
    _busqueda = buscar;
    notifyListeners();

    try {
      final Map<String, String> queryParams = {};
      if (categoriaId != null) queryParams['id_categoria'] = categoriaId.toString();
      if (buscar != null && buscar.isNotEmpty) queryParams['buscar'] = buscar;
      if (soloConStock) queryParams['solo_con_stock'] = 'true';

      final response = await ApiClient.get(
        Environment.catalogoDisponibilidad,
        requireAuth: false,
        queryParams: queryParams,
      );

      if (response is List) {
        _prendas = response.map((json) => PrendaModel.fromJson(json as Map<String, dynamic>)).toList();
      } else if (response is Map && response.containsKey('results')) {
        final list = response['results'] as List;
        _prendas = list.map((json) => PrendaModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        _prendas = [];
      }

      _isOfflineMode = false;

      // Persistir en SQLite local si es carga general para uso offline futuro
      if (categoriaId == null && (buscar == null || buscar.isEmpty)) {
        await SqliteService.guardarCatalogoEnCache(_prendas);
      } else if (_prendas.isNotEmpty) {
        await SqliteService.guardarCatalogoEnCache(_prendas);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Fallback inmediato a SQLite local (CU-05 / RF-13)
      String? catNombre;
      if (categoriaId != null) {
        final catMatch = _categorias.where((c) => c.id == categoriaId);
        if (catMatch.isNotEmpty) catNombre = catMatch.first.nombre;
      }

      final cachedPrendas = await SqliteService.obtenerPrendasOffline(
        buscar: buscar,
        categoriaNombre: catNombre,
        soloConStock: soloConStock,
      );

      if (cachedPrendas.isNotEmpty) {
        _prendas = cachedPrendas;
        _isOfflineMode = true;
        _errorMessage = null;
      } else {
        _isOfflineMode = true;
        _errorMessage = 'Sin conexión a Internet y sin datos previos en caché local SQLite.';
      }

      _isLoading = false;
      notifyListeners();
    }
  }

  // Obtener detalle de prenda específica por ID (Online + Fallback SQLite)
  Future<PrendaModel?> obtenerPrendaDetalle(int id) async {
    try {
      final response = await ApiClient.get(
        '${Environment.apiV1}/catalogo-disponibilidad/$id',
        requireAuth: false,
      );
      if (response != null && response is Map) {
        return PrendaModel.fromJson(response as Map<String, dynamic>);
      }
    } catch (_) {
      final match = _prendas.where((p) => p.id == id);
      if (match.isNotEmpty) return match.first;

      final cached = await SqliteService.obtenerPrendasOffline();
      final matchSql = cached.where((p) => p.id == id);
      if (matchSql.isNotEmpty) return matchSql.first;
    }
    return null;
  }

  // ============================================================================
  // CASO DE USO CU-05: Consultar Catálogo y Disponibilidad en Modo Offline
  // Permite al usuario continuar explorando prendas cargadas previamente en
  // memoria y aplicar filtros de talla o categoría sin requerir enlace activo.
  // ============================================================================
  bool get isModoOffline => _prendas.isNotEmpty && _errorMessage != null;

  List<PrendaModel> filtrarEnMemoriaOffline({String? query, int? categoriaId}) {
    return _prendas.where((p) {
      final coincideCat = categoriaId == null || p.categoriaId == categoriaId;
      final coincideTexto = query == null ||
          query.isEmpty ||
          p.nombre.toLowerCase().contains(query.toLowerCase()) ||
          p.descripcion.toLowerCase().contains(query.toLowerCase());
      return coincideCat && coincideTexto;
    }).toList();
  }
}
