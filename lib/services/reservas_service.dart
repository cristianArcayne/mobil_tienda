import 'package:flutter/material.dart';
import '../config/environment.dart';
import '../core/api_client.dart';
import '../models/reserva_model.dart';

class ReservasService extends ChangeNotifier {
  List<ReservaModel> _reservas = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _ultimoClienteId;

  List<ReservaModel> get reservas => _reservas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void limpiarEstado() {
    _reservas = [];
    _ultimoClienteId = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  // Listar reservas del cliente autenticado
  Future<void> cargarReservas({String? clienteId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (clienteId != null && clienteId.isNotEmpty) {
      _ultimoClienteId = clienteId;
    }

    try {
      final queryParam = (_ultimoClienteId != null && _ultimoClienteId!.isNotEmpty) ? '?cliente_ci=$_ultimoClienteId' : '';
      dynamic response;
      try {
        response = await ApiClient.get('${Environment.reservas}/mis-reservas$queryParam');
      } catch (_) {
        response = await ApiClient.get('${Environment.reservas}$queryParam');
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

    final cid = clienteId ?? _ultimoClienteId;

    try {
      final response = await ApiClient.post(
        Environment.reservas,
        {
          'sucursal_id': sucursalId,
          'items': items,
          'detalles': items,
          'dias_vigencia': diasVigencia,
          'hora_estimada': horaEstimada ?? '18:00',
          if (cid != null) 'cliente_id': cid,
          if (clienteNombre != null) 'cliente_nombre': clienteNombre,
        },
      );

      _isLoading = false;
      await cargarReservas(clienteId: cid);
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
      await cargarReservas(clienteId: _ultimoClienteId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}

