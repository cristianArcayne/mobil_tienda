import 'package:flutter/material.dart';
import '../config/environment.dart';
import '../core/api_client.dart';
import '../core/sqlite_service.dart';
import '../core/storage_service.dart';
import '../models/carrito_model.dart';
import '../models/prenda_model.dart';

class CarritoService extends ChangeNotifier {
  List<ItemCarritoModel> _items = [];
  bool _isLoading = false;
  String _usuarioActivoId = 'guest';

  List<ItemCarritoModel> get items => _items;
  bool get isLoading => _isLoading;
  int get cantidadTotal => _items.fold(0, (sum, i) => sum + i.cantidad);
  double get totalMonto => _items.fold(0.0, (sum, i) => sum + i.subtotal);

  CarritoService() {
    cargarCarrito();
  }

  /// Cambia el usuario activo garantizando persistencia y migración de carrito de invitado a usuario logueado
  Future<void> cambiarUsuarioActivo(String? usuarioId) async {
    final nuevoUsuarioId = (usuarioId != null && usuarioId.trim().isNotEmpty)
        ? usuarioId.trim()
        : 'guest';

    // Si había items en modo invitado y el usuario acaba de iniciar sesión, preservarlos para fusionarlos
    List<ItemCarritoModel> itemsInvitado = [];
    if (_usuarioActivoId == 'guest' && nuevoUsuarioId != 'guest' && _items.isNotEmpty) {
      itemsInvitado = List<ItemCarritoModel>.from(_items);
    }

    _items = [];
    _usuarioActivoId = nuevoUsuarioId;
    notifyListeners();

    // 1. Cargar el carrito persistido del nuevo usuario
    await cargarCarrito(usuarioId: _usuarioActivoId);

    // 2. Si había prendas agregadas como invitado, fusionarlas con el carrito del usuario
    if (itemsInvitado.isNotEmpty && _usuarioActivoId != 'guest') {
      for (final itemGuest in itemsInvitado) {
        final idx = _items.indexWhere((i) => i.varianteId == itemGuest.varianteId);
        if (idx >= 0) {
          _items[idx].cantidad += itemGuest.cantidad;
        } else {
          _items.add(itemGuest);
        }
        // Sincronizar prenda en backend para este usuario
        try {
          await ApiClient.post(
            '${Environment.carritoPersistente}/items',
            {
              'variante_id': itemGuest.varianteId,
              'cantidad': itemGuest.cantidad,
              'cliente_id': _usuarioActivoId,
            },
            requireAuth: false,
          );
        } catch (_) {}
      }
      // Persistir carrito unificado y limpiar carrito de invitado
      await _persistirLocal();
      await SqliteService.guardarCarritoUsuario('guest', []);
      await StorageService.saveOfflineCart([], userKey: 'guest');
      notifyListeners();
    }
  }

  void limpiarEstado() {
    _items = [];
    notifyListeners();
  }

  // Cargar carrito (primero local offline en SQLite / SharedPreferences, luego sincroniza con backend)
  Future<void> cargarCarrito({String? usuarioId}) async {
    _isLoading = true;
    notifyListeners();

    if (usuarioId != null && usuarioId.trim().isNotEmpty) {
      _usuarioActivoId = usuarioId.trim();
    } else {
      _usuarioActivoId = await StorageService.getActiveUserKey();
    }

    // 1. Cargar desde SQLite local o SharedPreferences del usuario
    final sqlItems = await SqliteService.obtenerCarritoUsuario(_usuarioActivoId);
    if (sqlItems.isNotEmpty) {
      _items = sqlItems;
    } else {
      final offlineItems = await StorageService.getOfflineCart(userKey: _usuarioActivoId);
      _items = offlineItems.map((e) => ItemCarritoModel.fromJson(e)).toList();
    }

    // 2. Sincronizar con backend si no es invitado y el carrito local está vacío
    if (_usuarioActivoId != 'guest' && _items.isEmpty) {
      try {
        final response = await ApiClient.get(
          '${Environment.carritoPersistente}/$_usuarioActivoId',
          requireAuth: false,
        );
        if (response != null && response is Map && response.containsKey('detalles')) {
          final backendCarrito = CarritoModel.fromJson(response as Map<String, dynamic>);
          if (backendCarrito.items.isNotEmpty) {
            _items = backendCarrito.items;
            await _persistirLocal();
          }
        }
      } catch (e) {
        debugPrint('[Carrito] Modo offline o aviso al sincronizar carrito backend: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // Agregar prenda al carrito (CU-08)
  Future<void> agregarPrenda({
    required PrendaModel prenda,
    required VariantePrendaModel variante,
    int cantidad = 1,
  }) async {
    _usuarioActivoId = await StorageService.getActiveUserKey();
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

    await _persistirLocal();
    notifyListeners();

    // Sincronizar en segundo plano con backend si el usuario está identificado
    if (_usuarioActivoId != 'guest') {
      try {
        await ApiClient.post(
          '${Environment.carritoPersistente}/items',
          {
            'variante_id': variante.id,
            'cantidad': cantidad,
            'cliente_id': _usuarioActivoId,
          },
          requireAuth: false,
        );
      } catch (_) {}
    }
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

  // Eliminar ítem
  void eliminarItem(int varianteId) {
    _items.removeWhere((i) => i.varianteId == varianteId);
    _persistirLocal();
    notifyListeners();

    if (_usuarioActivoId != 'guest') {
      try {
        ApiClient.delete(
          '${Environment.carritoPersistente}/items/$varianteId?cliente_id=$_usuarioActivoId',
          requireAuth: false,
        );
      } catch (_) {}
    }
  }

  // Vaciar carrito tras compra exitosa o acción explícita del usuario
  void limpiarCarrito() {
    _items.clear();
    _persistirLocal();
    notifyListeners();

    if (_usuarioActivoId != 'guest') {
      try {
        ApiClient.delete(
          '${Environment.carritoPersistente}/vaciar?cliente_id=$_usuarioActivoId',
          requireAuth: false,
        );
      } catch (_) {}
    }
  }

  Future<void> _persistirLocal() async {
    final uid = await StorageService.getActiveUserKey();
    _usuarioActivoId = uid;
    await SqliteService.guardarCarritoUsuario(uid, _items);
    final jsonList = _items.map((e) => e.toJson()).toList();
    await StorageService.saveOfflineCart(jsonList, userKey: uid);
  }

  // ============================================================================
  // CASO DE USO CU-08: Gestionar Carrito de Compras Persistente Omnicanal
  // Mantiene los articulos seleccionados en cache persistente local de forma
  // resiliente, garantizando que el comprador no pierda su seleccion aun tras
  // reinicios de la aplicacion o perdida momentanea de conectividad.
  // ============================================================================
  bool contieneVariante(int varianteId) {
    return _items.any((i) => i.varianteId == varianteId);
  }

  int obtenerCantidadPorVariante(int varianteId) {
    final item = _items.where((i) => i.varianteId == varianteId);
    return item.isNotEmpty ? item.first.cantidad : 0;
  }
}
