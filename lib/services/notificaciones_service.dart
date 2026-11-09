import 'dart:async';
import 'package:flutter/material.dart';
import '../config/environment.dart';
import '../core/api_client.dart';
import '../core/storage_service.dart';
import '../models/notificacion_model.dart';
import '../screens/notificaciones/notificaciones_screen.dart';
import '../widgets/in_app_notification_banner.dart';

class NotificacionesService extends ChangeNotifier {
  static GlobalKey<NavigatorState>? globalNavigatorKey;

  List<NotificacionModel> _notificaciones = [];
  bool _isLoading = false;
  String? _errorMessage;

  Timer? _pollingTimer;
  final Set<int> _notificacionesVistas = {};
  bool _isFirstLoad = true;
  BuildContext? _currentContext;
  int? _usuarioActivoId;

  List<NotificacionModel> get notificaciones => _notificaciones;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Obtiene un contexto activo para mostrar el Overlay del banner emergente
  BuildContext? _obtenerContextoActivo() {
    if (_currentContext != null && _currentContext!.mounted) {
      return _currentContext;
    }
    if (globalNavigatorKey?.currentContext != null && globalNavigatorKey!.currentContext!.mounted) {
      return globalNavigatorKey!.currentContext;
    }
    return null;
  }

  /// Cambia el usuario activo y limpia las notificaciones del usuario anterior
  /// garantizando aislamiento estricto de notificaciones PUSH / In-App.
  Future<void> cambiarUsuarioActivo(int? nuevoUsuarioId) async {
    _usuarioActivoId = nuevoUsuarioId;
    _notificaciones = [];
    _notificacionesVistas.clear();
    _isFirstLoad = true;
    notifyListeners();
    await cargarNotificaciones(mostrarPopupSiHayNueva: true);
  }

  void limpiarNotificaciones() {
    _usuarioActivoId = null;
    _notificaciones = [];
    _notificacionesVistas.clear();
    _isFirstLoad = true;
    notifyListeners();
    cargarNotificaciones(mostrarPopupSiHayNueva: false);
  }

  // Iniciar monitoreo continuo en segundo plano
  void iniciarPolling(BuildContext context, {int? usuarioId}) {
    _currentContext = context;
    if (usuarioId != null) {
      _usuarioActivoId = usuarioId;
    }
    if (_pollingTimer != null && _pollingTimer!.isActive) return;

    // Cargar inmediatamente permitiendo el popup emergente si hay aviso nuevo del admin
    cargarNotificaciones(mostrarPopupSiHayNueva: true);

    // Polling cada 5 segundos para tiempo real
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      cargarNotificaciones(mostrarPopupSiHayNueva: true);
    });
  }

  void detenerPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void actualizarContexto(BuildContext context) {
    _currentContext = context;
  }

  // Cargar notificaciones desde el backend filtradas por usuario_id
  Future<void> cargarNotificaciones({bool mostrarPopupSiHayNueva = true}) async {
    try {
      int? uid = _usuarioActivoId;
      if (uid == null) {
        final savedUser = await StorageService.getUser();
        if (savedUser != null && savedUser['id'] != null) {
          uid = int.tryParse(savedUser['id'].toString());
          _usuarioActivoId = uid;
        }
      }

      final queryParam = (uid != null && uid > 0) ? '?usuario_id=$uid' : '';
      dynamic response;
      try {
        response = await ApiClient.get('${Environment.notificaciones}$queryParam');
      } catch (_) {
        response = await ApiClient.get('${Environment.notificaciones}/$queryParam');
      }

      List<NotificacionModel> listaNuevas = [];

      if (response is List) {
        listaNuevas = response
            .map((json) => NotificacionModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response is Map && response['results'] is List) {
        listaNuevas = (response['results'] as List)
            .map((json) => NotificacionModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response is Map && response['notificaciones'] is List) {
        listaNuevas = (response['notificaciones'] as List)
            .map((json) => NotificacionModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // Filtrado estricto en cliente: solo notificaciones propias o broadcast general (usuarioId == null)
      if (uid != null && uid > 0) {
        listaNuevas = listaNuevas
            .where((n) => n.usuarioId == null || n.usuarioId == uid)
            .toList();
      } else {
        // Si es invitado, solo mostrar avisos generales/broadcast (no compras de otros clientes)
        listaNuevas = listaNuevas.where((n) => n.usuarioId == null).toList();
      }

      final userKey = uid != null ? uid.toString() : 'guest';
      final ultimoIdVisto = await StorageService.getUltimoIdNotificacionVista(userKey: userKey);

      // =======================================================================
      // 1. PRIMERA CARGA (Al entrar o autenticarse en la app móvil)
      // =======================================================================
      if (_isFirstLoad) {
        _isFirstLoad = false;

        // Detectar notificaciones creadas por el admin mientras el usuario no estaba en la app
        final List<NotificacionModel> pendientes = [];
        for (final n in listaNuevas) {
          // Aislamiento: invitados no reciben popups transaccionales ajenos
          if (uid == null && (n.tipo == 'COMPRA' || n.tipo == 'RESERVA' || n.tipo == 'DEVOLUCION')) {
            continue;
          }
          if (ultimoIdVisto > 0) {
            if (n.id > ultimoIdVisto) {
              pendientes.add(n);
            }
          } else {
            // Primer uso del dispositivo: mostrar la más reciente si no está leída
            if (!n.leida) {
              pendientes.add(n);
            }
          }
        }

        // Registrar todas en el set de memoria para evitar duplicados en el polling posterior
        for (final n in listaNuevas) {
          _notificacionesVistas.add(n.id);
        }

        final maxId = listaNuevas.fold<int>(0, (prev, n) => n.id > prev ? n.id : prev);
        if (maxId > 0) {
          await StorageService.saveUltimoIdNotificacionVista(maxId, userKey: userKey);
        }

        // Si hay una notificación pendiente creada por el admin, mostrar el banner emergente tras 650ms
        if (pendientes.isNotEmpty && mostrarPopupSiHayNueva) {
          pendientes.sort((a, b) => b.id.compareTo(a.id));
          final notifDestacada = pendientes.first;

          Future.delayed(const Duration(milliseconds: 650), () {
            final ctx = _obtenerContextoActivo();
            if (ctx != null && ctx.mounted) {
              _mostrarBannerEmergente(ctx, notifDestacada);
            }
          });
        }
      }

      // =======================================================================
      // 2. CARGAS POSTERIORES EN TIEMPO REAL (Durante el uso de la app)
      // =======================================================================
      else if (mostrarPopupSiHayNueva) {
        for (final n in listaNuevas) {
          if (!_notificacionesVistas.contains(n.id)) {
            _notificacionesVistas.add(n.id);
            await StorageService.saveUltimoIdNotificacionVista(n.id, userKey: userKey);

            // Aislamiento: invitados no reciben avisos transaccionales ajenos
            if (uid == null && (n.tipo == 'COMPRA' || n.tipo == 'RESERVA' || n.tipo == 'DEVOLUCION')) {
              continue;
            }

            final ctx = _obtenerContextoActivo();
            if (ctx != null && ctx.mounted) {
              _mostrarBannerEmergente(ctx, n);
            }
          }
        }
      }

      _notificaciones = listaNuevas;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void _mostrarBannerEmergente(BuildContext ctx, NotificacionModel n) {
    try {
      InAppNotificationBanner.show(
        ctx,
        title: n.titulo,
        message: n.mensaje,
        tipo: n.tipo,
        onTap: () {
          final navCtx = _obtenerContextoActivo();
          if (navCtx != null && navCtx.mounted) {
            Navigator.push(
              navCtx,
              MaterialPageRoute(builder: (_) => const NotificacionesScreen()),
            );
          }
        },
      );
    } catch (e) {
      debugPrint('[Notificaciones] Error al desplegar banner emergente: $e');
    }
  }

  @override
  void dispose() {
    detenerPolling();
    super.dispose();
  }
}
