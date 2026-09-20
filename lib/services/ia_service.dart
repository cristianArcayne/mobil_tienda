import 'package:flutter/material.dart';
import '../config/environment.dart';
import '../core/api_client.dart';
import '../models/recomendacion_ia_model.dart';
import '../models/prenda_model.dart';

class IAService extends ChangeNotifier {
  final List<ChatMessageModel> _mensajes = [];
  bool _isLoading = false;
  OutfitRecomendadoModel? _outfitActual;

  List<ChatMessageModel> get mensajes => _mensajes;
  bool get isLoading => _isLoading;
  OutfitRecomendadoModel? get outfitActual => _outfitActual;

  IAService() {
    _iniciarChatbot();
  }

  void _iniciarChatbot() {
    if (_mensajes.isEmpty) {
      _mensajes.add(
        ChatMessageModel(
          text: '¡Hola! Soy tu asistente inteligente de moda FashionStore ✨. ¿Buscas un look para una ocasión especial o consejos para combinar alguna prenda?',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  // Enviar mensaje al Asistente de Moda
  Future<void> enviarMensaje(String texto) async {
    _mensajes.add(
      ChatMessageModel(
        text: texto,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        '${Environment.iaRecomendador}/chat',
        {
          'mensaje': texto,
        },
        requireAuth: false,
      );

      String respuestaIA = 'Excelente elección. Te recomiendo combinar prendas con tonos neutros para un estilo equilibrado.';
      List<PrendaModel> sugerencias = [];

      if (response != null && response is Map) {
        respuestaIA = response['respuesta_texto'] ??
            response['respuesta'] ??
            response['mensaje'] ??
            response['texto'] ??
            respuestaIA;

        if (response.containsKey('prendas_sugeridas') && response['prendas_sugeridas'] != null) {
          final list = response['prendas_sugeridas'] as List? ?? [];
          sugerencias = list.map((p) => PrendaModel.fromJson(p as Map<String, dynamic>)).toList();
        } else if (response.containsKey('outfit_recomendado') && response['outfit_recomendado'] != null) {
          final outMap = response['outfit_recomendado'] as Map<String, dynamic>?;
          if (outMap != null && outMap.containsKey('prendas')) {
            final pList = outMap['prendas'] as List? ?? [];
            sugerencias = pList.map((p) => PrendaModel.fromJson(p as Map<String, dynamic>)).toList();
          }
        }
      }

      _mensajes.add(
        ChatMessageModel(
          text: respuestaIA,
          isUser: false,
          timestamp: DateTime.now(),
          prendasSugeridas: sugerencias.isNotEmpty ? sugerencias : null,
        ),
      );
    } catch (_) {
      // Respuesta de fallback amigable si no hay backend activo
      _mensajes.add(
        ChatMessageModel(
          text: 'Te sugiero combinar tonos oscuros con accesorios metálicos o calzado minimalista para un estilo moderno.',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  // Generar un Outfit inteligente completo
  Future<OutfitRecomendadoModel?> generarOutfit({String estilo = 'Casual'}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        '${Environment.iaRecomendador}/generar-outfit',
        {
          'estilo': estilo,
        },
        requireAuth: false,
      );

      if (response != null && response is Map) {
        _outfitActual = OutfitRecomendadoModel.fromJson(response as Map<String, dynamic>);
      }
    } catch (_) {
      // Fallback
    }

    _isLoading = false;
    notifyListeners();
    return _outfitActual;
  }
}

