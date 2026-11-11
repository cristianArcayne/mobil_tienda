import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../config/environment.dart';
import '../core/api_client.dart';
import '../core/sqlite_service.dart';
import '../core/storage_service.dart';
import '../models/reserva_model.dart';
import 'sync_service.dart';

class ReservasService extends ChangeNotifier {
  List<ReservaModel> _reservas = [];
  bool _isLoading = false;
  bool _ultimaReservaFueOffline = false;
  String? _errorMessage;
  String? _ultimoClienteId;

  List<ReservaModel> get reservas => _reservas;
  bool get isLoading => _isLoading;
  bool get ultimaReservaFueOffline => _ultimaReservaFueOffline;
  String? get errorMessage => _errorMessage;

  /// Cambia el usuario activo reseteando la lista en memoria y cargando solo sus reservas
  Future<void> cambiarUsuarioActivo(String? clienteId) async {
    _reservas = [];
    _ultimoClienteId = (clienteId != null && clienteId.trim().isNotEmpty)
        ? clienteId.trim()
        : null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
    if (_ultimoClienteId != null) {
      await cargarReservas(clienteId: _ultimoClienteId);
    }
  }

  void limpiarEstado() {
    _reservas = [];
    _ultimoClienteId = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Retorna el total de prendas activas (PENDIENTE, CONFIRMADA o PENDIENTE_SYNC)
  int get totalPrendasActivas {
    final activas = _reservas.where((r) => r.estaActiva || r.estado == 'PENDIENTE_SYNC');
    return activas.fold<int>(
      0,
      (sum, r) => sum + r.detalles.fold<int>(0, (s, d) => s + d.cantidad),
    );
  }

  // Listar reservas del cliente autenticado + Reservas locales encoladas en SQLite Outbox
  Future<void> cargarReservas({String? clienteId, bool desdeAutoSync = false}) async {
    if (_reservas.isEmpty) {
      _isLoading = true;
    }
    _errorMessage = null;
    notifyListeners();

    if (clienteId != null && clienteId.trim().isNotEmpty) {
      _ultimoClienteId = clienteId.trim();
    } else {
      _ultimoClienteId ??= await StorageService.getClienteId();
    }

    // Si es invitado o no hay usuario autenticado, nunca mostrar reservas ajenas
    if (_ultimoClienteId == null || _ultimoClienteId!.isEmpty || _ultimoClienteId == 'guest') {
      _reservas = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    List<ReservaModel> construirListaOffline(List<Map<String, dynamic>> outbox) {
      final reservasOffline = outbox.where((o) => o['tipo_operacion'] == 'RESERVA').toList();
      final Map<String, ReservaModel> agrupadas = {};

      for (final rOff in reservasOffline) {
        final payload = jsonDecode(rOff['payload_json'].toString()) as Map<String, dynamic>;
        final rawItems = (payload['items'] ?? payload['detalles'] ?? []) as List;
        final sucId = payload['sucursal_id'] ?? 1;
        final hora = (payload['hora_estimada']?.toString() ?? '18:00').trim();
        final keyAgrupacion = '$sucId-$hora';

        final detallesOff = rawItems.map((it) {
          final m = it as Map<String, dynamic>;
          final cant = m['cantidad'] is int ? m['cantidad'] as int : 1;
          final prec = (m['precio_unitario'] is num) ? (m['precio_unitario'] as num).toDouble() : 0.0;
          return DetalleReservaModel(
            id: 0,
            varianteId: m['variante_id'] is int ? m['variante_id'] as int : 0,
            cantidad: cant,
            prendaNombre: m['prenda_nombre']?.toString() ?? 'Prenda Reservada Offline',
            talla: m['talla']?.toString() ?? 'Única',
            color: m['color']?.toString() ?? 'Estándar',
            precioUnitario: prec,
            subtotal: prec * cant,
          );
        }).toList();

        if (agrupadas.containsKey(keyAgrupacion)) {
          final existente = agrupadas[keyAgrupacion]!;
          final detallesCombinados = List<DetalleReservaModel>.from(existente.detalles);
          for (final d in detallesOff) {
            final idx = detallesCombinados.indexWhere((x) => x.varianteId == d.varianteId);
            if (idx >= 0) {
              final prev = detallesCombinados[idx];
              detallesCombinados[idx] = DetalleReservaModel(
                id: prev.id,
                varianteId: prev.varianteId,
                cantidad: prev.cantidad + d.cantidad,
                prendaNombre: prev.prendaNombre,
                talla: prev.talla,
                color: prev.color,
                precioUnitario: prev.precioUnitario,
                subtotal: (prev.cantidad + d.cantidad) * prev.precioUnitario,
              );
            } else {
              detallesCombinados.add(d);
            }
          }
          final totalCombinado = detallesCombinados.fold(0.0, (s, d) => s + d.subtotal);
          agrupadas[keyAgrupacion] = ReservaModel(
            id: existente.id,
            fecha: existente.fecha,
            fechaLimite: existente.fechaLimite,
            estado: 'PENDIENTE_SYNC',
            sucursalNombre: existente.sucursalNombre,
            clienteNombre: existente.clienteNombre,
            montoTotalEstimado: totalCombinado,
            detalles: detallesCombinados,
          );
        } else {
          final totalOff = detallesOff.fold(0.0, (s, d) => s + d.subtotal);
          final fechaStr = rOff['fecha_creacion']?.toString() ?? DateTime.now().toIso8601String();
          final fechaLim = DateTime.now().add(const Duration(hours: 48)).toIso8601String();
          agrupadas[keyAgrupacion] = ReservaModel(
            id: (rOff['id'] is int) ? (rOff['id'] as int) : 999,
            fecha: fechaStr,
            fechaLimite: fechaLim,
            estado: 'PENDIENTE_SYNC',
            sucursalNombre: payload['sucursal_nombre']?.toString() ?? 'Sucursal #$sucId (Offline)',
            clienteNombre: payload['cliente_nombre']?.toString() ?? _ultimoClienteId!,
            montoTotalEstimado: totalOff,
            detalles: detallesOff,
          );
        }
      }
      return agrupadas.values.toList();
    }

    List<ReservaModel> listaCombinada = [];

    // 1. Cargar reservas offline pendientes en SQLite Outbox para este usuario
    try {
      var outbox = await SqliteService.obtenerOutboxPendientes(usuarioId: _ultimoClienteId);
      listaCombinada = construirListaOffline(outbox);
      if (listaCombinada.isNotEmpty) {
        _reservas = List.from(listaCombinada);
        _isLoading = false;
        notifyListeners();
      }

      // Si hay reservas offline pendientes y ya hay red, sincronizarlas antes de pedir la lista remota
      if (!desdeAutoSync && outbox.isNotEmpty) {
        final syncCount = await SyncService.instancia?.sincronizarPendientes(omitirRefreshCallback: true) ?? 0;
        if (syncCount > 0) {
          outbox = await SqliteService.obtenerOutboxPendientes(usuarioId: _ultimoClienteId);
          listaCombinada = construirListaOffline(outbox);
        }
      }
    } catch (_) {}

    // 2. Consultar reservas sincronizadas en el servidor para este cliente específico
    try {
      final queryParam = '?cliente_ci=${Uri.encodeComponent(_ultimoClienteId!)}';
      dynamic response;
      try {
        response = await ApiClient.get('${Environment.reservas}/mis-reservas$queryParam');
      } catch (_) {
        response = await ApiClient.get('${Environment.reservas}$queryParam');
      }

      List<ReservaModel> remotas = [];
      if (response is List) {
        remotas = response.map((json) => ReservaModel.fromJson(json as Map<String, dynamic>)).toList();
      } else if (response is Map && response['results'] is List) {
        remotas = (response['results'] as List).map((json) => ReservaModel.fromJson(json as Map<String, dynamic>)).toList();
      } else if (response is Map && response['reservas'] is List) {
        remotas = (response['reservas'] as List).map((json) => ReservaModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      listaCombinada.addAll(remotas);
      _reservas = listaCombinada;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // En modo offline mantenemos las reservas encoladas localmente en SQLite
      _reservas = listaCombinada;
      if (_reservas.isEmpty) {
        _errorMessage = e.toString();
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  // Crear una nueva reserva Web-to-Store con soporte Offline UUIDv4 (CU-07)
  Future<bool> crearReserva({
    required int sucursalId,
    required List<Map<String, dynamic>> items,
    int diasVigencia = 2,
    String? horaEstimada,
    String? clienteId,
    String? clienteNombre,
    String? sucursalNombre,
  }) async {
    _isLoading = true;
    _ultimaReservaFueOffline = false;
    _errorMessage = null;
    notifyListeners();

    // 1. VALIDACIÓN ESTRICTA: Máximo 5 prendas activas simultáneas en total
    final nuevasPrendas = items.fold<int>(
      0,
      (sum, item) => sum + ((item['cantidad'] is int) ? (item['cantidad'] as int) : 1),
    );

    if (nuevasPrendas > 5) {
      _errorMessage = 'Solo puedes reservar un máximo de 5 prendas simultáneas por visita (seleccionaste $nuevasPrendas).';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final activas = _reservas.where((r) => r.estaActiva || r.estado == 'PENDIENTE_SYNC').toList();
    final prendasActivasActuales = activas.fold<int>(
      0,
      (sum, r) => sum + r.detalles.fold<int>(0, (s, d) => s + d.cantidad),
    );

    if (prendasActivasActuales + nuevasPrendas > 5) {
      final disponibles = (5 - prendasActivasActuales) > 0 ? (5 - prendasActivasActuales) : 0;
      _errorMessage = 'Límite de 5 prendas alcanzado. Actualmente tienes $prendasActivasActuales prenda(s) reservada(s) activa(s). Solo puedes reservar hasta $disponibles prenda(s) adicional(es).';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final cid = (clienteId != null && clienteId.isNotEmpty)
        ? clienteId
        : (_ultimoClienteId ?? await StorageService.getClienteId());
    if (cid != null && cid.isNotEmpty) {
      _ultimoClienteId = cid;
    }

    final horaLimpia = (horaEstimada ?? '18:00').trim();

    // Identificador UUIDv4 único local (CU-07)
    final uuidReserva = const Uuid().v4();
    final payload = {
      'uuid_transaccion': uuidReserva,
      'sucursal_id': sucursalId,
      if (sucursalNombre != null) 'sucursal_nombre': sucursalNombre,
      'items': items,
      'detalles': items,
      'dias_vigencia': diasVigencia,
      'hora_estimada': horaLimpia,
      if (cid != null) 'cliente_id': cid,
      if (cid != null) 'cliente_ci': cid,
      if (clienteNombre != null) 'cliente_nombre': clienteNombre,
    };

    try {
      final response = await ApiClient.post(
        '${Environment.reservas}/crear',
        payload,
      );

      _isLoading = false;
      await cargarReservas(clienteId: cid);
      return response != null;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Stock insuficiente') || msg.contains('Límite de 5 prendas')) {
        _errorMessage = msg.replaceAll('Exception: ', '');
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 2. MODO OFFLINE: Consolidar si ya existía una reserva PENDIENTE_SYNC para la misma sucursal y horario
      Map<String, dynamic>? outboxReservaExistente;
      try {
        final outbox = await SqliteService.obtenerOutboxPendientes(usuarioId: cid);
        for (final o in outbox) {
          if (o['tipo_operacion'] == 'RESERVA') {
            final p = jsonDecode(o['payload_json'].toString()) as Map<String, dynamic>;
            if (p['sucursal_id'] == sucursalId && (p['hora_estimada']?.toString().trim() ?? '18:00') == horaLimpia) {
              outboxReservaExistente = o;
              break;
            }
          }
        }
      } catch (_) {}

      String uuidFinal = uuidReserva;
      Map<String, dynamic> payloadFinal = Map<String, dynamic>.from(payload);

      if (outboxReservaExistente != null) {
        uuidFinal = outboxReservaExistente['uuid_transaccion']?.toString() ?? uuidReserva;
        final payloadPrev = jsonDecode(outboxReservaExistente['payload_json'].toString()) as Map<String, dynamic>;
        final itemsPrev = List<Map<String, dynamic>>.from(payloadPrev['items'] ?? []);

        for (final nuevoIt in items) {
          final vId = nuevoIt['variante_id'];
          final matchIdx = itemsPrev.indexWhere((it) => it['variante_id'] == vId);
          if (matchIdx >= 0) {
            final cantPrev = itemsPrev[matchIdx]['cantidad'] is int ? itemsPrev[matchIdx]['cantidad'] as int : 1;
            final cantNueva = nuevoIt['cantidad'] is int ? nuevoIt['cantidad'] as int : 1;
            itemsPrev[matchIdx]['cantidad'] = cantPrev + cantNueva;
          } else {
            itemsPrev.add(Map<String, dynamic>.from(nuevoIt));
          }
        }
        payloadFinal = payloadPrev;
        payloadFinal['items'] = itemsPrev;
        payloadFinal['detalles'] = itemsPrev;
        payloadFinal['uuid_transaccion'] = uuidFinal;
      }

      // Encolar o actualizar en SQLite Outbox
      await SqliteService.encolarOperacionOffline(
        uuidTransaccion: uuidFinal,
        usuarioId: cid ?? 'guest',
        tipoOperacion: 'RESERVA',
        payload: payloadFinal,
      );
      await SyncService.instancia?.notificarOperacionOfflineEncolada(usuarioId: cid);

      // Descontar stock local provisionalmente en SQLite
      for (final it in items) {
        final vId = it['variante_id'] is int ? it['variante_id'] as int : 0;
        final cant = it['cantidad'] is int ? it['cantidad'] as int : 1;
        if (vId > 0) {
          await SqliteService.descontarStockLocalProvisional(vId, cant);
        }
      }

      _ultimaReservaFueOffline = true;
      _isLoading = false;

      // Recargar para que en memoria aparezca inmediatamente consolidada en una sola reserva
      await cargarReservas(clienteId: cid);
      return true;
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
