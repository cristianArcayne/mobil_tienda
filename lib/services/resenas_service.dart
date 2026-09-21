import 'package:flutter/material.dart';
import '../config/environment.dart';
import '../core/api_client.dart';
import '../models/resena_model.dart';

class ResenasService extends ChangeNotifier {
  List<ResenaModel> _resenas = [];
  bool _isLoading = false;

  List<ResenaModel> get resenas => _resenas;
  bool get isLoading => _isLoading;

  // Cargar reseñas de una prenda
  Future<void> cargarResenasPrenda(int ropaId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.get(
        '${Environment.resenas}/ropa/$ropaId',
        requireAuth: false,
      );

      if (response is List) {
        _resenas = response.map((json) => ResenaModel.fromJson(json as Map<String, dynamic>)).toList();
      } else if (response is Map && response.containsKey('results')) {
        final list = response['results'] as List;
        _resenas = list.map((json) => ResenaModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        _resenas = [];
      }
    } catch (_) {
      _resenas = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Agregar nueva reseña y calificación
  Future<bool> crearResena({
    required int ropaId,
    required int calificacion,
    required String comentario,
    String? clienteCi,
    String? clienteNombre,
  }) async {
    try {
      final payload = <String, dynamic>{
        'ropa_id': ropaId,
        'producto_id': ropaId,
        'calificacion': calificacion,
        'puntuacion_estrellas': calificacion,
        'comentario': comentario,
      };

      if (clienteCi != null && clienteCi.isNotEmpty) {
        payload['cliente_ci'] = clienteCi;
      }
      if (clienteNombre != null && clienteNombre.isNotEmpty) {
        payload['cliente_nombre'] = clienteNombre;
      }

      final response = await ApiClient.post(
        Environment.resenas,
        payload,
      );

      if (response != null) {
        await cargarResenasPrenda(ropaId);
        return true;
      }
    } catch (_) {}
    return false;
  }
}

