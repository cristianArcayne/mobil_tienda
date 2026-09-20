import 'package:flutter/material.dart';
import '../config/environment.dart';
import '../core/api_client.dart';
import '../models/promocion_model.dart';

class PromocionesService extends ChangeNotifier {
  List<PromocionModel> _promociones = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PromocionModel> get promociones => _promociones;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Cargar promociones activas desde el backend
  Future<void> cargarPromociones() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.get(Environment.promociones);
      if (response is List) {
        _promociones = response
            .map((json) => PromocionModel.fromJson(json as Map<String, dynamic>))
            .where((p) => p.activo)
            .toList();
      } else if (response is Map && response['results'] is List) {
        _promociones = (response['results'] as List)
            .map((json) => PromocionModel.fromJson(json as Map<String, dynamic>))
            .where((p) => p.activo)
            .toList();
      } else {
        _promociones = [];
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}

