import 'dart:async';
import 'package:flutter/material.dart';
import '../config/environment.dart';
import '../core/api_client.dart';
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

  List<NotificacionModel> get notificaciones => _notificaciones;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Iniciar monitoreo continuo en segundo plano
  void iniciarPolling(BuildContext context) {
    _currentContext = context;
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

  // Cargar notificaciones desde el backend
  Future<void> cargarNotificaciones({bool mostrarPopupSiHayNueva = false}) async {
    try {
      final response = await ApiClient.get(Environment.notificaciones);

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

      // Si es la primera carga y no se fuerza el popup, registrar existentes silenciosamente
      if (_isFirstLoad && !mostrarPopupSiHayNueva) {
        for (final n in listaNuevas) {
          _notificacionesVistas.add(n.id);
        }
        _isFirstLoad = false;
      } else if (_currentContext != null) {
        // Detectar si hay alguna notificación nueva que no hayamos visto
        for (final n in listaNuevas) {
          if (!_notificacionesVistas.contains(n.id)) {
            _notificacionesVistas.add(n.id);
            // Mostrar banner emergente estilo WhatsApp
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

