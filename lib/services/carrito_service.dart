import 'package:flutter/material.dart';
import '../config/environment.dart';
import '../core/api_client.dart';
import '../core/storage_service.dart';
import '../models/carrito_model.dart';
import '../models/prenda_model.dart';

class CarritoService extends ChangeNotifier {
  List<ItemCarritoModel> _items = [];
  bool _isLoading = false;

  List<ItemCarritoModel> get items => _items;
  bool get isLoading => _isLoading;
  int get cantidadTotal => _items.fold(0, (sum, i) => sum + i.cantidad);
  double get totalMonto => _items.fold(0.0, (sum, i) => sum + i.subtotal);

  CarritoService() {
    cargarCarrito();
  }

  // Cargar carrito (primero local offline, luego sincroniza con backend)
  Future<void> cargarCarrito() async {
    _isLoading = true;
    notifyListeners();

    // 1. Cargar offline
    final offlineItems = await StorageService.getOfflineCart();
    if (offlineItems.isNotEmpty) {
      _items = offlineItems.map((e) => ItemCarritoModel.fromJson(e)).toList();
    }

    // 2. Sincronizar con backend si hay sesión
    try {
      final token = await StorageService.getAccessToken();
      if (token != null) {
        final response = await ApiClient.get(Environment.carritoPersistente);
        if (response != null && response is Map && response.containsKey('detalles')) {
          final backendCarrito = CarritoModel.fromJson(response as Map<String, dynamic>);
          if (backendCarrito.items.isNotEmpty) {
            _items = backendCarrito.items;
            _persistirLocal();
          }
        }
      }
    } catch (_) {
      // Usar modo offline silenciosamente si no hay conexión
    }

    _isLoading = false;
    notifyListeners();
  }

  // Agregar prenda al carrito
  Future<void> agregarPrenda({
    required PrendaModel prenda,
    required VariantePrendaModel variante,
    int cantidad = 1,
  }) async {
    final index = _items.indexWhere((i) => i.varianteId == variante.id);

    if (index >= 0) {
      _items[index].cantidad += cantidad;
    } else {
      _items.add(
        ItemCarritoModel(
          varianteId: variante.id,
          prendaId: prenda.id,
          prendaNombre: prenda.nombre,
          imagenUrl: prenda.imagenPrincipal,
          talla: variante.talla,
          color: variante.color,
          precioUnitario: prenda.precioConDescuento ?? prenda.precio,
          cantidad: cantidad,
        ),
      );
    }

    _persistirLocal();
    notifyListeners();

    // Sincronizar en segundo plano con backend
    try {
      final token = await StorageService.getAccessToken();
      if (token != null) {
        await ApiClient.post(
          '${Environment.carritoPersistente}/items',
          {
            'variante_id': variante.id,
            'cantidad': cantidad,
          },
        );
      }
    } catch (_) {}
  }

  // Cambiar cantidad
  void actualizarCantidad(int varianteId, int delta) {
    final index = _items.indexWhere((i) => i.varianteId == varianteId);
    if (index >= 0) {
      final nuevaCantidad = _items[index].cantidad + delta;
      if (nuevaCantidad > 0) {
        _items[index].cantidad = nuevaCantidad;
      } else {
        _items.removeAt(index);
      }
      _persistirLocal();
      notifyListeners();
    }
  }

  // Eliminar item
  void eliminarItem(int varianteId) {
    _items.removeWhere((i) => i.varianteId == varianteId);
    _persistirLocal();
    notifyListeners();
  }

  // Vaciar carrito
  void limpiarCarrito() {
    _items.clear();
    _persistirLocal();
    notifyListeners();
  }

  void _persistirLocal() {
    StorageService.saveOfflineCart(_items.map((i) => i.toJson()).toList());
  }
}

