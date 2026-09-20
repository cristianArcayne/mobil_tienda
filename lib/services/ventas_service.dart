import 'package:flutter/material.dart';
import '../config/environment.dart';
import '../core/api_client.dart';
import '../models/venta_model.dart';

class VentasService extends ChangeNotifier {
  List<VentaModel> _compras = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<VentaModel> get compras => _compras;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Cargar historial de compras del usuario
  Future<void> cargarHistorialCompras() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.get(Environment.ventas);
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
    required List<Map<String, dynamic>> items, // [{'variante_id': 1, 'cantidad': 1, 'precio_unitario': 150}]
    required String metodoPago, // 'QR_SIMPLE', 'TARJETA', 'TRANSFERENCIA'
    required String direccionEnvio,
    String? razonSocial,
    String? nitCliente,
    String? notas,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

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
}

