import 'package:flutter/material.dart';
import '../config/environment.dart';
import '../core/api_client.dart';
import '../models/reserva_model.dart';

class ReservasService extends ChangeNotifier {
  List<ReservaModel> _reservas = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ReservaModel> get reservas => _reservas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Listar reservas del cliente
  Future<void> cargarReservas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      dynamic response;
      try {
        response = await ApiClient.get(Environment.reservas);
      } catch (_) {
        response = await ApiClient.get('${Environment.reservas}/');
      }

      if (response is List) {
        _reservas = response.map((json) => ReservaModel.fromJson(json as Map<String, dynamic>)).toList();
      } else if (response is Map && response['results'] is List) {
        _reservas = (response['results'] as List).map((json) => ReservaModel.fromJson(json as Map<String, dynamic>)).toList();
      } else if (response is Map && response['reservas'] is List) {
        _reservas = (response['reservas'] as List).map((json) => ReservaModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        _reservas = [];
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Crear una nueva reserva Web-to-Store
  Future<bool> crearReserva({
    required int sucursalId,
    required List<Map<String, dynamic>> items, // [{'variante_id': 1, 'cantidad': 1}]
    int diasVigencia = 2,
    String? horaEstimada,
    String? clienteId,
    String? clienteNombre,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        Environment.reservas,
        {
          'sucursal_id': sucursalId,
          'items': items,
          'detalles': items,
          'dias_vigencia': diasVigencia,
          'hora_estimada': horaEstimada ?? '18:00',
          if (clienteId != null) 'cliente_id': clienteId,
          if (clienteNombre != null) 'cliente_nombre': clienteNombre,
        },
      );

      _isLoading = false;
      await cargarReservas();
      return response != null;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Cancelar una reserva
  Future<bool> cancelarReserva(int reservaId) async {
    try {
      await ApiClient.put('${Environment.reservas}/$reservaId/cancelar', {});
      await cargarReservas();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}

