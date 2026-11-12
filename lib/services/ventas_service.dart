import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../config/environment.dart';
import '../core/api_client.dart';
import '../core/sqlite_service.dart';
import '../core/storage_service.dart';
import '../models/venta_model.dart';
import 'sync_service.dart';

class VentasService extends ChangeNotifier {
  List<VentaModel> _compras = [];
  bool _isLoading = false;
  bool _ultimaVentaFueOffline = false;
  String? _errorMessage;
  String? _ultimoClienteId;

  List<VentaModel> get compras => _compras;
  bool get isLoading => _isLoading;
  bool get ultimaVentaFueOffline => _ultimaVentaFueOffline;
  String? get errorMessage => _errorMessage;

  /// Cambia el usuario activo reseteando las compras en memoria y cargando solo las de ese usuario
  Future<void> cambiarUsuarioActivo(String? clienteId) async {
    _compras = [];
    _ultimoClienteId = (clienteId != null && clienteId.trim().isNotEmpty)
        ? clienteId.trim()
        : null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
    if (_ultimoClienteId != null) {
      await cargarHistorialCompras(clienteId: _ultimoClienteId);
    }
  }

  void limpiarEstado() {
    _compras = [];
    _ultimoClienteId = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  // Cargar historial de compras del usuario autenticado + Pedidos preliminares en SQLite Outbox
  Future<void> cargarHistorialCompras({String? clienteId, bool desdeAutoSync = false}) async {
    if (_compras.isEmpty) {
      _isLoading = true;
    }
    _errorMessage = null;
    notifyListeners();

    if (clienteId != null && clienteId.trim().isNotEmpty) {
      _ultimoClienteId = clienteId.trim();
    } else {
      _ultimoClienteId ??= await StorageService.getClienteId();
    }

    // Si es invitado o no hay sesión activa, jamás mostrar compras de otros clientes
    if (_ultimoClienteId == null || _ultimoClienteId!.isEmpty || _ultimoClienteId == 'guest') {
      _compras = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    List<VentaModel> construirListaOffline(List<Map<String, dynamic>> outbox) {
      final List<VentaModel> listaOff = [];
      final ventasOffline = outbox.where((o) => o['tipo_operacion'] == 'VENTA_PRELIMINAR').toList();
      for (final vOff in ventasOffline) {
        final payload = jsonDecode(vOff['payload_json'].toString()) as Map<String, dynamic>;
        final rawItems = (payload['items'] ?? []) as List;
        final detallesOff = rawItems.map((it) {
          final m = it as Map<String, dynamic>;
          final cant = m['cantidad'] is int ? m['cantidad'] as int : 1;
          final prec = (m['precio_unitario'] is num) ? (m['precio_unitario'] as num).toDouble() : 0.0;
          return DetalleVentaModel(
            id: 0,
            varianteId: m['variante_id'] is int ? m['variante_id'] as int : 0,
            ropaId: m['ropa_id'] is int ? m['ropa_id'] as int : null,
            prendaNombre: m['prenda_nombre']?.toString() ?? 'Prenda Pedido Offline',
            talla: m['talla']?.toString() ?? 'Única',
            color: m['color']?.toString() ?? 'Estándar',
            cantidad: cant,
            precioUnitario: prec,
            subtotal: prec * cant,
          );
        }).toList();

        final totalOff = detallesOff.fold(0.0, (s, d) => s + d.subtotal);
        final uuidShort = (vOff['uuid_transaccion']?.toString() ?? 'OFFLINE').split('-').first.toUpperCase();

        final estadoOp = vOff['estado']?.toString() ?? 'PENDIENTE_SYNC';
        final esConflicto = estadoOp == 'CONFLICTO_STOCK';

        listaOff.add(VentaModel(
          id: (vOff['id'] is int) ? (vOff['id'] as int) : 999,
          fecha: vOff['fecha_creacion']?.toString() ?? DateTime.now().toIso8601String(),
          montoTotal: totalOff,
          estado: esConflicto ? 'CONFLICTO_STOCK' : 'PENDIENTE_SYNC',
          metodoPago: payload['metodo_pago']?.toString() ?? 'OFFLINE',
          numeroFactura: esConflicto ? 'RECHAZADA (STOCK AGOTADO)' : 'PRE-OFF-$uuidShort',
          direccionEnvio: payload['direccion_envio']?.toString() ?? 'Entrega coordinada',
          sucursalNombre: 'Sucursal Central (Sincronización Pendiente)',
          clienteNombre: payload['razon_social']?.toString() ?? _ultimoClienteId!,
          detalles: detallesOff,
        ));
      }
      return listaOff;
    }

    List<VentaModel> listaCombinada = [];

    // 1. Cargar pedidos preliminares offline encolados en SQLite Outbox para este usuario
    try {
      var outbox = await SqliteService.obtenerOutboxPendientes(usuarioId: _ultimoClienteId, incluirConflictos: true);
      listaCombinada = construirListaOffline(outbox);
      if (listaCombinada.isNotEmpty) {
        _compras = List.from(listaCombinada);
        _isLoading = false;
        notifyListeners();
      }

      // Si hay operaciones offline pendientes y ya hay red, sincronizarlas antes de pedir la lista remota
      final hayPendientesSync = outbox.any((o) => o['estado'] == 'PENDIENTE_SYNC');
      if (!desdeAutoSync && hayPendientesSync) {
        await SyncService.instancia?.sincronizarPendientes(omitirRefreshCallback: true);
        outbox = await SqliteService.obtenerOutboxPendientes(usuarioId: _ultimoClienteId, incluirConflictos: true);
        listaCombinada = construirListaOffline(outbox);
      }
    } catch (_) {}

    // 2. Consultar compras confirmadas del usuario en el servidor
    try {
      final endpoint = '${Environment.ventas}/mis-ventas?cliente_ci=${Uri.encodeComponent(_ultimoClienteId!)}';
      final response = await ApiClient.get(endpoint);
      if (response is List) {
        final remotas = response.map((json) => VentaModel.fromJson(json as Map<String, dynamic>)).toList();
        listaCombinada.addAll(remotas);
      }
      _compras = listaCombinada;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _compras = listaCombinada;
      if (_compras.isEmpty) {
        _errorMessage = e.toString();
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  // Procesar venta digital e-commerce con checkout + Contingencia Offline UUIDv4
  Future<VentaModel?> procesarCheckout({
    required List<Map<String, dynamic>> items,
    required String metodoPago,
    required String direccionEnvio,
    String? razonSocial,
    String? nitCliente,
    String? notas,
    String? clienteId,
    String? tokenPasarela,
    bool forzarModoOffline = false,
  }) async {
    _isLoading = true;
    _ultimaVentaFueOffline = false;
    _errorMessage = null;
    notifyListeners();

    final cid = (clienteId != null && clienteId.isNotEmpty)
        ? clienteId
        : (_ultimoClienteId ?? await StorageService.getClienteId());
    if (cid != null && cid.isNotEmpty) {
      _ultimoClienteId = cid;
    }

    final uuidTx = const Uuid().v4();
    final payload = {
      'uuid_transaccion': uuidTx,
      'origen_offline': forzarModoOffline,
      'items': items,
      'metodo_pago': metodoPago,
      'direccion_envio': direccionEnvio,
      'razon_social': razonSocial ?? 'Sin Nombre',
      'nit_cliente': nitCliente ?? '0',
      'notas': notas ?? 'Venta móvil FashionStore',
      if (cid != null) 'cliente_id': cid,
      if (tokenPasarela != null) 'token_pasarela': tokenPasarela,
    };

    if (!forzarModoOffline) {
      try {
        final response = await ApiClient.post(
          '${Environment.ventas}/ecommerce',
          payload,
        );

        _isLoading = false;
        if (response != null && response is Map) {
          final venta = VentaModel.fromJson(response as Map<String, dynamic>);
          _compras.insert(0, venta);
          notifyListeners();
          return venta;
        }
      } catch (e) {
        // Si es error explícito de stock 400/409 del servidor, informar; si es caída de red, encolar en SQLite Outbox
        final msg = e.toString();
        final msgLow = msg.toLowerCase();
        if (msgLow.contains('stock') ||
            msgLow.contains('agotad') ||
            msgLow.contains('conflicto') ||
            msgLow.contains('400') ||
            msgLow.contains('409')) {
          _errorMessage = msg.replaceAll('Exception: ', '');
          _isLoading = false;
          notifyListeners();
          return null;
        }
      }
    }

    // Modo Offline: Encolar pedido preliminar con UUIDv4 en SQLite
    if (cid != null && cid.isNotEmpty) {
      payload['cliente_ci'] = cid;
    }
    await SqliteService.encolarOperacionOffline(
      uuidTransaccion: uuidTx,
      usuarioId: cid ?? 'guest',
      tipoOperacion: 'VENTA_PRELIMINAR',
      payload: payload,
    );
    await SyncService.instancia?.notificarOperacionOfflineEncolada(usuarioId: cid);

    final List<DetalleVentaModel> detallesPrelim = [];
    for (final it in items) {
      final vId = it['variante_id'] is int ? it['variante_id'] as int : 0;
      final cant = it['cantidad'] is int ? it['cantidad'] as int : 1;
      final prec = (it['precio_unitario'] is num) ? (it['precio_unitario'] as num).toDouble() : 0.0;
      if (vId > 0) {
        await SqliteService.descontarStockLocalProvisional(vId, cant);
      }
      detallesPrelim.add(DetalleVentaModel(
        id: 0,
        varianteId: vId,
        ropaId: it['ropa_id'] is int ? it['ropa_id'] as int : null,
        prendaNombre: it['prenda_nombre']?.toString() ?? 'Prenda',
        talla: it['talla']?.toString() ?? 'Única',
        color: it['color']?.toString() ?? 'Estándar',
        cantidad: cant,
        precioUnitario: prec,
        subtotal: prec * cant,
      ));
    }

    final montoTotal = detallesPrelim.fold(0.0, (s, d) => s + d.subtotal);
    final uuidShort = uuidTx.split('-').first.toUpperCase();
    final ventaPreliminar = VentaModel(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      fecha: DateTime.now().toIso8601String(),
      montoTotal: montoTotal,
      estado: 'PENDIENTE_SYNC',
      metodoPago: '$metodoPago (Offline)',
      numeroFactura: 'PRE-OFF-$uuidShort',
      direccionEnvio: direccionEnvio,
      sucursalNombre: 'Sucursal Central (Encolado en SQLite)',
      clienteNombre: razonSocial ?? (cid ?? 'Cliente'),
      detalles: detallesPrelim,
    );

    _ultimaVentaFueOffline = true;
    _compras.insert(0, ventaPreliminar);
    _isLoading = false;
    notifyListeners();
    return ventaPreliminar;
  }

  // ===========================================================================
  // CU-11: COBRO CON CÓDIGO QR SIMPLE DINÁMICO (180s)
  // ===========================================================================

  Future<Map<String, dynamic>?> generarCobroQRSimple({
    required double monto,
    String? glosa,
    String? clienteNombre,
    String? clienteNit,
    int sucursalId = 1,
  }) async {
    final payload = {
      'monto': monto,
      'moneda': 'BOB',
      'glosa': glosa ?? 'Compra App Móvil FashionStore',
      'cliente_nombre': clienteNombre ?? 'Cliente FashionStore',
      'cliente_nit': clienteNit ?? '0',
      'sucursal_id': sucursalId,
      'tiempo_expiracion_seg': 180,
    };

    try {
      dynamic response;
      try {
        response = await ApiClient.post(
          '${Environment.apiV1}/pagos/qr-simple/generar',
          payload,
        );
      } catch (_) {
        response = await ApiClient.post(
          '${Environment.baseUrl}/api/pagos/qr-simple/generar',
          payload,
        );
      }
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
    } catch (e) {
      debugPrint('Aviso QR Simple API (usando generador EMVCo local): $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> consultarEstadoQR(String qrId) async {
    try {
      final response = await ApiClient.get(
        '${Environment.apiV1}/pagos/qr-simple/estado/$qrId',
      );
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
    } catch (_) {}
    return null;
  }

  // ===========================================================================
  // CU-10: PASARELA STRIPE
  // ===========================================================================

  Future<Map<String, dynamic>?> crearIntentoPagoStripe({
    required double monto,
    String? clienteId,
    String? descripcion,
  }) async {
    try {
      final response = await ApiClient.post(
        '${Environment.stripePagos}/crear-intento',
        {
          'monto': monto,
          'moneda': 'bob',
          if (clienteId != null) 'cliente_id': clienteId,
          'descripcion': descripcion ?? 'Compra en FashionStore Móvil',
        },
      );

      if (response is Map) {
        return response as Map<String, dynamic>;
      }
      return {
        'payment_intent_id': 'pi_offline_${DateTime.now().millisecondsSinceEpoch}',
        'client_secret': 'simulated_secret',
        'status': 'requires_payment_method',
      };
    } catch (e) {
      _errorMessage = e.toString();
      return {
        'payment_intent_id': 'pi_offline_${DateTime.now().millisecondsSinceEpoch}',
        'client_secret': 'simulated_secret',
        'status': 'requires_payment_method',
      };
    }
  }

  Future<VentaModel?> confirmarPagoStripe({
    required String paymentIntentId,
    required List<Map<String, dynamic>> items,
    required String direccionEnvio,
    String? razonSocial,
    String? nitCliente,
    String? notas,
    String? clienteId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final cid = (clienteId != null && clienteId.isNotEmpty)
        ? clienteId
        : (_ultimoClienteId ?? await StorageService.getClienteId());
    if (cid != null && cid.isNotEmpty) {
      _ultimoClienteId = cid;
    }
    final payload = {
      'payment_intent_id': paymentIntentId,
      'items': items,
      'direccion_envio': direccionEnvio,
      'razon_social': razonSocial ?? 'Cliente FashionStore',
      'nit_cliente': nitCliente ?? '0',
      'notas': notas ?? 'Pago con Pasarela Stripe',
      if (cid != null) 'cliente_id': cid,
      if (cid != null) 'cliente_ci': cid,
    };

    try {
      if (paymentIntentId.startsWith('pi_offline_')) {
        throw Exception('Modo offline detectado en creación de intento Stripe');
      }
      final response = await ApiClient.post(
        '${Environment.stripePagos}/confirmar-pago',
        payload,
      );

      _isLoading = false;
      if (response != null && response is Map) {
        _ultimaVentaFueOffline = false;
        final venta = VentaModel.fromJson(response as Map<String, dynamic>);
        _compras.insert(0, venta);
        notifyListeners();
        return venta;
      }
      throw Exception('Respuesta inválida del servidor Stripe');
    } catch (e) {
      final msg = e.toString();
      final msgLow = msg.toLowerCase();
      if (msgLow.contains('stock') ||
          msgLow.contains('agotad') ||
          msgLow.contains('conflicto') ||
          msgLow.contains('409')) {
        _errorMessage = msg.replaceAll('Exception: ', '');
        _isLoading = false;
        notifyListeners();
        return null;
      }
      // Fallback de Contingencia Offline: Encolar venta con UUIDv4 en SQLite Outbox
      final uuidTx = const Uuid().v4();
      final offlinePayload = {
        'uuid_transaccion': uuidTx,
        'payment_intent_id': paymentIntentId,
        'origen_offline': true,
        'items': items,
        'metodo_pago': 'STRIPE',
        'direccion_envio': direccionEnvio,
        'razon_social': razonSocial ?? 'Cliente FashionStore',
        'nit_cliente': nitCliente ?? '0',
        'notas': notas ?? 'Pago con Tarjeta Stripe (Offline)',
        if (cid != null) 'cliente_id': cid,
        if (cid != null) 'cliente_ci': cid,
      };

      await SqliteService.encolarOperacionOffline(
        uuidTransaccion: uuidTx,
        usuarioId: cid ?? 'guest',
        tipoOperacion: 'VENTA_PRELIMINAR',
        payload: offlinePayload,
      );
      await SyncService.instancia?.notificarOperacionOfflineEncolada(usuarioId: cid);

      final List<DetalleVentaModel> detallesPrelim = [];
      for (final it in items) {
        final vId = it['variante_id'] is int ? it['variante_id'] as int : 0;
        final cant = it['cantidad'] is int ? it['cantidad'] as int : 1;
        final prec = (it['precio_unitario'] is num) ? (it['precio_unitario'] as num).toDouble() : 0.0;
        if (vId > 0) {
          await SqliteService.descontarStockLocalProvisional(vId, cant);
        }
        detallesPrelim.add(DetalleVentaModel(
          id: 0,
          varianteId: vId,
          ropaId: it['ropa_id'] is int ? it['ropa_id'] as int : null,
          prendaNombre: it['prenda_nombre']?.toString() ?? 'Prenda',
          talla: it['talla']?.toString() ?? 'Única',
          color: it['color']?.toString() ?? 'Estándar',
          cantidad: cant,
          precioUnitario: prec,
          subtotal: prec * cant,
        ));
      }

      final montoTotal = detallesPrelim.fold(0.0, (s, d) => s + d.subtotal);
      final uuidShort = uuidTx.split('-').first.toUpperCase();
      final ventaPreliminar = VentaModel(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        fecha: DateTime.now().toIso8601String(),
        montoTotal: montoTotal,
        estado: 'PENDIENTE_SYNC',
        metodoPago: 'Tarjeta Stripe (Offline)',
        numeroFactura: 'PRE-STRIPE-$uuidShort',
        direccionEnvio: direccionEnvio,
        sucursalNombre: 'Sucursal Central (Encolado en SQLite)',
        clienteNombre: razonSocial ?? (cid ?? 'Cliente'),
        detalles: detallesPrelim,
      );

      _ultimaVentaFueOffline = true;
      _compras.insert(0, ventaPreliminar);
      _isLoading = false;
      notifyListeners();
      return ventaPreliminar;
    }
  }

  // ===========================================================================
  // CU-12: DEVOLUCIONES Y CAMBIO DE TALLA (GARANTÍA LEGAL DE 7 DÍAS)
  // ===========================================================================

  Future<List<Map<String, dynamic>>> obtenerVariantesParaCambioTalla({int? ropaId, int? varianteId}) async {
    try {
      final params = <String>[];
      if (ropaId != null && ropaId > 0) params.add('ropa_id=$ropaId');
      if (varianteId != null && varianteId > 0) params.add('variante_id=$varianteId');
      final query = params.isNotEmpty ? '?${params.join("&")}' : '';
      final response = await ApiClient.get(
        '${Environment.apiV1}/devoluciones/variantes-disponibles$query',
      );
      if (response is List) {
        return response.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Procesa el Cambio de Talla bajo garantía de 7 días (Emisión de Nota de Cambio NC- sin anular factura)
  Future<Map<String, dynamic>?> solicitarCambioTalla7Dias({
    required int ventaId,
    required int varianteDevueltaId,
    required int nuevaVarianteId,
    required String motivo,
    int cantidad = 1,
    String metodoPagoDiferencia = 'QR',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final cid = _ultimoClienteId ?? await StorageService.getClienteId();
    final payload = {
      'venta_id': ventaId,
      'variante_devuelta_id': varianteDevueltaId,
      'nueva_variante_id': nuevaVarianteId,
      'cantidad': cantidad,
      'motivo': motivo,
      'metodo_pago_diferencia': metodoPagoDiferencia,
      if (cid != null) 'cliente_id': cid,
    };

    try {
      dynamic response;
      try {
        response = await ApiClient.post(
          '${Environment.apiV1}/devoluciones/cambio-talla',
          payload,
        );
      } catch (_) {
        response = await ApiClient.post(
          '${Environment.baseUrl}/devoluciones/cambio-talla',
          payload,
        );
      }
      _isLoading = false;
      notifyListeners();
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Solicitar devolución / reembolso dentro del plazo de garantía
  Future<bool> solicitarDevolucion({
    required int ventaId,
    required String motivo,
    String? cuentaBancariaQr,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final cid = _ultimoClienteId ?? await StorageService.getClienteId();
    final payload = {
      'venta_id': ventaId,
      'motivo': motivo,
      'cuenta_bancaria_qr': cuentaBancariaQr ?? 'Cuenta de origen / QR',
      if (cid != null) 'cliente_id': cid,
    };

    try {
      dynamic response;
      try {
        response = await ApiClient.post(
          '${Environment.apiV1}/devoluciones/solicitar',
          payload,
        );
      } catch (_) {
        try {
          response = await ApiClient.post(
            '${Environment.baseUrl}/devoluciones/solicitar',
            payload,
          );
        } catch (_) {
          response = await ApiClient.post(
            '${Environment.baseUrl}/api/devoluciones/solicitar',
            payload,
          );
        }
      }
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

  // Verificar si la venta es elegible para garantía (7 días = 168h)
  Future<Map<String, dynamic>?> verificarElegibilidadDevolucion(int ventaId) async {
    try {
      dynamic response;
      try {
        response = await ApiClient.get(
          '${Environment.apiV1}/devoluciones/verificar-elegibilidad/$ventaId',
        );
      } catch (_) {
        response = await ApiClient.get(
          '${Environment.baseUrl}/devoluciones/verificar-elegibilidad/$ventaId',
        );
      }
      if (response is Map) {
        return response as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Actualiza el estado de entrega o despacho del pedido (CU-14 / Seguimiento)
  Future<bool> actualizarEstadoPedido(int ventaId, String nuevoEstado) async {
    try {
      final response = await ApiClient.put(
        '${Environment.ventas}/$ventaId/estado',
        {'estado': nuevoEstado},
      );
      if (response != null) {
        final idx = _compras.indexWhere((c) => c.id == ventaId);
        if (idx >= 0) {
          final c = _compras[idx];
          _compras[idx] = VentaModel(
            id: c.id,
            fecha: c.fecha,
            montoTotal: c.montoTotal,
            estado: nuevoEstado,
            metodoPago: c.metodoPago,
            numeroFactura: c.numeroFactura,
            direccionEnvio: c.direccionEnvio,
            sucursalNombre: c.sucursalNombre,
            clienteNombre: c.clienteNombre,
            detalles: c.detalles,
          );
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
