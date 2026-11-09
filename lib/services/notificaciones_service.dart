import 'dart:async';
import 'package:flutter/material.dart';
import '../config/environment.dart';
import '../core/api_client.dart';
import '../core/storage_service.dart';
import '../models/notificacion_model.dart';
import '../screens/notificaciones/notificaciones_screen.dart';
import '../widgets/in_app_notification_banner.dart';

class NotificacionesService extends ChangeNotifier {
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

  /// Cambia el usuario activo y limpia las notificaciones del usuario anterior
  /// garantizando aislamiento estricto de notificaciones PUSH / In-App.
  Future<void> cambiarUsuarioActivo(int? nuevoUsuarioId) async {
    _usuarioActivoId = nuevoUsuarioId;
    _notificaciones = [];
    _notificacionesVistas.clear();
    _isFirstLoad = true;
    notifyListeners();
    await cargarNotificaciones(mostrarPopupSiHayNueva: false);
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

    // Cargar inmediatamente
    cargarNotificaciones(mostrarPopupSiHayNueva: false);

    // Polling cada 5 segundos
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
  Future<void> cargarNotificaciones({bool mostrarPopupSiHayNueva = false}) async {
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

      // Si es la primera carga (arranque de app o cambio de usuario), registrar TODAS silenciosamente
      if (_isFirstLoad) {
        for (final n in listaNuevas) {
          _notificacionesVistas.add(n.id);
        }
        _isFirstLoad = false;
      } else if (mostrarPopupSiHayNueva && _currentContext != null) {
        // En cargas posteriores en tiempo real, solo mostrar popup para notificaciones no vistas
        for (final n in listaNuevas) {
          if (!_notificacionesVistas.contains(n.id)) {
            _notificacionesVistas.add(n.id);

            // Regla de aislamiento: un invitado nunca debe recibir popups de COMPRA, RESERVA o DEVOLUCION ajenas
            if (uid == null && (n.tipo == 'COMPRA' || n.tipo == 'RESERVA' || n.tipo == 'DEVOLUCION')) {
              continue;
            }

            try {
              if (_currentContext!.mounted) {
                InAppNotificationBanner.show(
                  _currentContext!,
                  title: n.titulo,
                  message: n.mensaje,
                  tipo: n.tipo,
                  onTap: () {
                    if (_currentContext != null && _currentContext!.mounted) {
                      Navigator.push(
                        _currentContext!,
                        MaterialPageRoute(builder: (_) => const NotificacionesScreen()),
                      );
                    }
                  },
                );
              }
            } catch (e) {
              debugPrint('[Notificaciones] Error al mostrar banner emergente: $e');
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

  @override
  void dispose() {
    detenerPolling();
    super.dispose();
  }
}
