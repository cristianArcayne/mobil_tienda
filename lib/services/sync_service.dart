import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/environment.dart';
import '../core/api_client.dart';
import '../core/sqlite_service.dart';
import '../core/storage_service.dart';
import '../widgets/in_app_notification_banner.dart';
import 'notificaciones_service.dart';
import 'reservas_service.dart';
import 'ventas_service.dart';

/// CU-14: Demonio de Sincronización Automática en Segundo Plano
/// Monitorea la conectividad y la cola `outbox_sync` en SQLite, transmite operaciones offline
/// (RESERVA, VENTA_PRELIMINAR, FAVORITO) con UUIDv4 de idempotencia al recuperar red,
/// actualiza automáticamente Compras y Reservas, y notifica cuando vuelve el internet.
class SyncService extends ChangeNotifier {
  static SyncService? instancia;

  Timer? _syncTimer;
  bool _isSyncing = false;
  bool _estabaOffline = false;
  int _pendientesCount = 0;
  String _usuarioActivoId = 'guest';
  BuildContext? _currentContext;
  final Set<String> _uuidsSincronizados = {};

  SyncService() {
    instancia = this;
  }

  bool get isSyncing => _isSyncing;
  bool get estabaOffline => _estabaOffline;
  int get pendientesCount => _pendientesCount;

  void iniciarDemonioSync(BuildContext context, {String? usuarioId}) {
    instancia = this;
    _currentContext = context;
    if (usuarioId != null && usuarioId.trim().isNotEmpty) {
      _usuarioActivoId = usuarioId.trim();
    }
    _actualizarConteoPendientes();

    _syncTimer?.cancel();
    // Ejecutar verificación cada 4 segundos en segundo plano para respuesta inmediata al volver internet
    _syncTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      sincronizarPendientes();
    });
  }

  void detenerDemonioSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Llamado desde VentasService o ReservasService cuando una compra o reserva cae en contingencia offline
  Future<void> notificarOperacionOfflineEncolada({String? usuarioId}) async {
    _estabaOffline = true;
    if (usuarioId != null && usuarioId.trim().isNotEmpty && usuarioId.trim() != 'guest') {
      _usuarioActivoId = usuarioId.trim();
    }
    await _actualizarConteoPendientes();
  }

  Future<void> cambiarUsuarioActivo(String? nuevoUsuarioId) async {
    _usuarioActivoId = (nuevoUsuarioId != null && nuevoUsuarioId.trim().isNotEmpty)
        ? nuevoUsuarioId.trim()
        : 'guest';
    await _actualizarConteoPendientes();
    sincronizarPendientes();
  }

  Future<String> _resolverUsuarioEfectivo() async {
    if (_usuarioActivoId.isNotEmpty && _usuarioActivoId != 'guest') {
      return _usuarioActivoId;
    }
    final stored = await StorageService.getClienteId();
    if (stored != null && stored.trim().isNotEmpty) {
      _usuarioActivoId = stored.trim();
      return _usuarioActivoId;
    }
    return 'guest';
  }

  Future<void> _actualizarConteoPendientes() async {
    final uid = await _resolverUsuarioEfectivo();
    final pendientes = await SqliteService.obtenerOutboxPendientes(usuarioId: uid);
    _pendientesCount = pendientes.length;
    if (_pendientesCount > 0) {
      _estabaOffline = true;
    }
    notifyListeners();
  }

  /// Refresca las listas en memoria de Compras, Reservas y Notificaciones tras recuperar red
  Future<void> _refrescarServiciosEnLinea(String uid) async {
    final ctx = _currentContext;
    if (ctx == null || !ctx.mounted) return;
    final clienteParam = (uid.isNotEmpty && uid != 'guest') ? uid : null;
    final ventasSvc = Provider.of<VentasService>(ctx, listen: false);
    final reservasSvc = Provider.of<ReservasService>(ctx, listen: false);
    final notifSvc = Provider.of<NotificacionesService>(ctx, listen: false);

    try {
      await ventasSvc.cargarHistorialCompras(
        clienteId: clienteParam,
        desdeAutoSync: true,
      );
    } catch (_) {}
    try {
      await reservasSvc.cargarReservas(
        clienteId: clienteParam,
        desdeAutoSync: true,
      );
    } catch (_) {}
    try {
      await notifSvc.cargarNotificaciones(mostrarPopupSiHayNueva: false);
    } catch (_) {}
  }

  /// Ejecuta la sincronización de la cola `outbox_sync` hacia el servidor central
  Future<int> sincronizarPendientes({bool omitirRefreshCallback = false}) async {
    if (_isSyncing) return 0;

    final uid = await _resolverUsuarioEfectivo();
    final pendientes = await SqliteService.obtenerOutboxPendientes(usuarioId: uid);
    _pendientesCount = pendientes.length;

    // Si no hay pendientes pero estábamos en modo offline, verificar si ya volvió el internet
    if (pendientes.isEmpty) {
      if (_estabaOffline) {
        try {
          await ApiClient.get('${Environment.apiV1}/sucursales');
          _estabaOffline = false;
          notifyListeners();
          await _refrescarServiciosEnLinea(uid);
          if (_currentContext != null && _currentContext!.mounted) {
            InAppNotificationBanner.show(
              _currentContext!,
              title: '🌐 Conexión a Internet Restablecida',
              message: 'Volviste a tener internet. Tus compras y reservas están actualizadas en línea.',
              tipo: 'SISTEMA',
            );
          }
        } catch (_) {
          // Aún sin conexión
        }
      } else {
        notifyListeners();
      }
      return 0;
    }

    _isSyncing = true;
    notifyListeners();

    int sincronizadosExito = 0;
    int conflictosDetectados = 0;
    bool huboErrorRed = false;

    try {
      for (final op in pendientes) {
        final uuid = op['uuid_transaccion']?.toString() ?? '';
        final tipo = op['tipo_operacion']?.toString() ?? '';
        final payloadStr = op['payload_json']?.toString() ?? '{}';
        if (uuid.isEmpty) continue;

        if (_uuidsSincronizados.contains(uuid)) {
          await SqliteService.marcarOutboxSincronizado(uuid, uid);
          continue;
        }

        Map<String, dynamic> payload = {};
        try {
          payload = Map<String, dynamic>.from(jsonDecode(payloadStr) as Map);
        } catch (_) {}

        // Garantizar que cliente_id / cliente_ci esté presente en el payload al sincronizar
        if (uid != 'guest') {
          payload['cliente_id'] ??= uid;
          payload['cliente_ci'] ??= uid;
        } else if (payload['cliente_id'] != null) {
          payload['cliente_ci'] ??= payload['cliente_id'];
        }

        bool exitoOp = false;

        try {
          if (tipo == 'RESERVA') {
            final res = await ApiClient.post('${Environment.reservas}/crear', payload);
            if (res != null) exitoOp = true;
          } else if (tipo == 'VENTA_PRELIMINAR') {
            // 1. Intentar lote de sincronización idempotente (CU-14)
            bool huboConflictoStock = false;
            String mensajeConflicto = '';

            try {
              final opItem = {
                'uuid_offline': uuid,
                'offline_uuid': uuid,
                'codigo_transaccion': uuid,
                'tipo': 'VENTA',
                'detalles': payload['items'] ?? [],
                ...payload,
              };
              final resLote = await ApiClient.post(
                '${Environment.ventas}/sincronizar-lote',
                {
                  'ventas': [opItem],
                  'operaciones': [opItem],
                },
              );
              if (resLote is Map && ((resLote['total_exitosas'] as num?) ?? 0) > 0) {
                exitoOp = true;
              } else if (resLote is Map && resLote.containsKey('resultados')) {
                final listRes = resLote['resultados'] as List;
                if (listRes.isNotEmpty) {
                  final primerRes = listRes.first as Map;
                  final statusRes = primerRes['status']?.toString() ?? '';
                  final detRes = primerRes['detalle']?.toString() ?? '';
                  if (statusRes == 'CONFLICTO_STOCK' ||
                      statusRes == 'EN_CONFLICTO' ||
                      ((resLote['total_conflictos'] as num?) ?? 0) > 0 ||
                      detRes.toLowerCase().contains('conflicto') ||
                      detRes.toLowerCase().contains('stock') ||
                      detRes.toLowerCase().contains('agotad')) {
                    huboConflictoStock = true;
                    mensajeConflicto = detRes.isNotEmpty ? detRes : 'Existencias agotadas para esta prenda.';
                  }
                }
              }
            } catch (errLote) {
              final errLoteStr = errLote.toString().toLowerCase();
              if (errLoteStr.contains('409') ||
                  errLoteStr.contains('conflicto') ||
                  errLoteStr.contains('stock') ||
                  errLoteStr.contains('agotad')) {
                huboConflictoStock = true;
                mensajeConflicto = 'Conflicto de stock: la última unidad ya fue vendida por otro dispositivo.';
              }
            }

            if (!exitoOp && !huboConflictoStock) {
              // 2. Fallback a /ecommerce únicamente si NO fue un conflicto de stock
              try {
                final resEcom = await ApiClient.post('${Environment.ventas}/ecommerce', payload);
                if (resEcom != null) exitoOp = true;
              } catch (errEcom) {
                final errEcomStr = errEcom.toString().toLowerCase();
                if (errEcomStr.contains('409') ||
                    errEcomStr.contains('conflicto') ||
                    errEcomStr.contains('stock') ||
                    errEcomStr.contains('agotad')) {
                  huboConflictoStock = true;
                  mensajeConflicto = 'Conflicto de stock: la última unidad ya fue vendida por otro dispositivo.';
                }
              }
            }

            if (huboConflictoStock) {
              conflictosDetectados++;
              await SqliteService.marcarOutboxSincronizado(
                uuid,
                uid,
                nuevoEstado: 'CONFLICTO_STOCK',
                error: mensajeConflicto,
              );
              if (_currentContext != null && _currentContext!.mounted) {
                InAppNotificationBanner.show(
                  _currentContext!,
                  title: '⚠️ Conflicto de Stock Offline',
                  message: 'No se pudo completar la venta: la última unidad ya fue vendida por otro dispositivo mientras estabas offline.',
                  tipo: 'DEVOLUCION',
                );
                showDialog(
                  context: _currentContext!,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    title: Row(
                      children: const [
                        Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 28),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Conflicto de Stock Offline',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF991B1B)),
                          ),
                        ),
                      ],
                    ),
                    content: Text(
                      'Error al procesar la compra offline:\n\nLa última unidad disponible de la prenda ya fue comprada y sincronizada primero por otro dispositivo.\n\nDetalle: $mensajeConflicto',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
                    ),
                    actions: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Entendido'),
                      ),
                    ],
                  ),
                );
              }
            }
          } else if (tipo == 'FAVORITO') {
            final ropaId = payload['ropa_id'];
            if (ropaId != null) {
              await ApiClient.post('/api/v1/favoritos/', {'ropa_id': ropaId});
              exitoOp = true;
            }
          }
        } catch (e) {
          final errStr = e.toString().toLowerCase();
          final esCaidaRed = errStr.contains('socketexception') ||
              errStr.contains('clientexception') ||
              errStr.contains('failed host lookup') ||
              errStr.contains('xmlhttprequest') ||
              errStr.contains('connection refused') ||
              errStr.contains('network') ||
              errStr.contains('tiempo de espera') ||
              errStr.contains('timeout');

          if (esCaidaRed) {
            huboErrorRed = true;
            _estabaOffline = true;
            debugPrint('[SyncService CU-14] Aún sin red para $uuid ($tipo): $e');
            break;
          } else {
            debugPrint('[SyncService CU-14] Error de validación en $uuid ($tipo): $e');
          }
        }

        if (exitoOp) {
          _uuidsSincronizados.add(uuid);
          await SqliteService.marcarOutboxSincronizado(uuid, uid);
          sincronizadosExito++;
        }
      }
    } finally {
      _isSyncing = false;
      final restantes = await SqliteService.obtenerOutboxPendientes(usuarioId: uid);
      _pendientesCount = restantes.length;
      if (!huboErrorRed && _pendientesCount == 0) {
        _estabaOffline = false;
      }
      notifyListeners();
    }

    if (sincronizadosExito > 0 || conflictosDetectados > 0) {
      if (!omitirRefreshCallback) {
        await _refrescarServiciosEnLinea(uid);
      }
      if (sincronizadosExito > 0 && conflictosDetectados == 0 && _currentContext != null && _currentContext!.mounted) {
        InAppNotificationBanner.show(
          _currentContext!,
          title: '🌐 Conexión Restablecida • Sincronización Completada',
          message: 'Volviste a tener internet: se sincronizaron $sincronizadosExito operación(es) offline y se actualizaron tus compras y reservas.',
          tipo: 'SISTEMA',
        );
      }
    }

    return sincronizadosExito;
  }

  @override
  void dispose() {
    detenerDemonioSync();
    super.dispose();
  }
}
