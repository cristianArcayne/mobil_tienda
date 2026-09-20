import 'package:flutter/material.dart';
import '../config/environment.dart';
import '../core/api_client.dart';
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
  String? _errorMessage;
  int? _categoriaFiltro;
  String? _busqueda;

  List<PrendaModel> get prendas => _prendas;
  List<CategoriaModel> get categorias => _categorias;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get categoriaFiltro => _categoriaFiltro;
  String? get busqueda => _busqueda;

  // Cargar categorías reales desde la base de datos
  Future<void> cargarCategorias() async {
    try {
      final response = await ApiClient.get(
        '${Environment.baseUrl}/api/categorias/',
        requireAuth: false,
      );
      if (response is List) {
        _categorias = response.map((json) => CategoriaModel.fromJson(json as Map<String, dynamic>)).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  // Cargar catálogo con disponibilidad omnicanal en tiempo real
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

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'No se pudo conectar a la base de datos en (${Environment.baseUrl}).\nError: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Obtener detalle de prenda específica por ID
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
      // Fallback buscar en lista local si ya está cargada
      final match = _prendas.where((p) => p.id == id);
      if (match.isNotEmpty) return match.first;
    }
    return null;
  }
}
