import 'package:flutter/material.dart';
import '../config/environment.dart';
import '../core/api_client.dart';
import '../models/venta_model.dart';

class VentasService extends ChangeNotifier {
  List<VentaModel> _compras = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _ultimoClienteId;

  List<VentaModel> get compras => _compras;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void limpiarEstado() {
    _compras = [];
    _ultimoClienteId = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  // Cargar historial de compras del usuario
  Future<void> cargarHistorialCompras({String? clienteId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (clienteId != null && clienteId.isNotEmpty) {
      _ultimoClienteId = clienteId;
    }

    try {
      final endpoint = (_ultimoClienteId != null && _ultimoClienteId!.isNotEmpty)
          ? '${Environment.ventas}/mis-ventas?cliente_ci=$_ultimoClienteId'
          : '${Environment.ventas}/mis-ventas';
      final response = await ApiClient.get(endpoint);
      if (response is List) {
        _compras = response.map((json) => VentaModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        _compras = [];
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Procesar venta digital e-commerce con checkout
  Future<VentaModel?> procesarCheckout({
    required List<Map<String, dynamic>> items,
    required String metodoPago,
    required String direccionEnvio,
    String? razonSocial,
    String? nitCliente,
    String? notas,
    String? clienteId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final cid = clienteId ?? _ultimoClienteId;
    if (cid != null && cid.isNotEmpty) {
      _ultimoClienteId = cid;
    }

    try {
      final response = await ApiClient.post(
        '${Environment.ventas}/ecommerce',
        {
          'items': items,
          'metodo_pago': metodoPago,
          'direccion_envio': direccionEnvio,
          'razon_social': razonSocial ?? 'Sin Nombre',
          'nit_cliente': nitCliente ?? '0',
          'notas': notas ?? 'Venta móvil FashionStore',
          if (cid != null) 'cliente_id': cid,
        },
      );

      _isLoading = false;
      if (response != null && response is Map) {
        final venta = VentaModel.fromJson(response as Map<String, dynamic>);
        _compras.insert(0, venta);
        notifyListeners();
        return venta;
      }
      return null;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Solicitar devolución / reembolso (24h)
  Future<bool> solicitarDevolucion({
    required int ventaId,
    required String motivo,
    String? cuentaBancariaQr,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        '${Environment.baseUrl}/devoluciones/solicitar',
        {
          'venta_id': ventaId,
          'motivo': motivo,
          'cuenta_bancaria_qr': cuentaBancariaQr ?? 'Cuenta de origen / QR',
        },
      );
      _isLoading = false;
      notifyListeners();
      return response != null;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Verificar si la venta es elegible para devolución (menos de 24h)
  Future<Map<String, dynamic>?> verificarElegibilidadDevolucion(int ventaId) async {
    try {
      final response = await ApiClient.get(
        '${Environment.baseUrl}/devoluciones/verificar-elegibilidad/$ventaId',
      );
      if (response is Map) {
        return response as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

