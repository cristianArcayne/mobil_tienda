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
  Future<void> enviarMensaje(String texto, {dynamic clienteId}) async {
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
      final Map<String, dynamic> body = {
        'mensaje': texto,
      };
      if (clienteId != null) {
        body['cliente_id'] = clienteId;
      }

      final response = await ApiClient.post(
        '${Environment.iaRecomendador}/chat',
        body,
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
        } 
        
        if (sugerencias.isEmpty && response.containsKey('outfit_recomendado') && response['outfit_recomendado'] != null) {
          final outMap = response['outfit_recomendado'] as Map<String, dynamic>?;
          if (outMap != null) {
            final List<dynamic> pList = [];
            if (outMap['prenda_principal'] != null) {
              pList.add(outMap['prenda_principal']);
            }
            if (outMap['prendas_complementarias'] is List) {
              pList.addAll(outMap['prendas_complementarias']);
            }
            if (outMap['prendas'] is List) {
              pList.addAll(outMap['prendas']);
            }
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
  Future<OutfitRecomendadoModel?> generarOutfit({String estilo = 'Casual', dynamic clienteId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final Map<String, dynamic> body = {
        'ocasion': estilo,
        'estilo_preferido': estilo,
      };
      if (clienteId != null) {
        body['cliente_id'] = clienteId;
      }

      final response = await ApiClient.post(
        '${Environment.iaRecomendador}/generar-outfit',
        body,
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

