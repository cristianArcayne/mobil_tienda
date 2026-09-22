import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import '../core/api_client.dart';
import '../models/prenda_model.dart';

class VestidorService extends ChangeNotifier {
  bool _isLoading = false;
  String? _loadingStatus;
  String? _errorMessage;
  String? _resultadoImageBase64;
  List<PrendaModel> _prendasAR = [];

  bool get isLoading => _isLoading;
  String? get loadingStatus => _loadingStatus;
  String? get errorMessage => _errorMessage;
  String? get resultadoImageBase64 => _resultadoImageBase64;
  List<PrendaModel> get prendasAR => _prendasAR;

  // Cargar prendas compatibles con vestidor virtual desde el backend
  Future<void> cargarPrendasVestidor() async {
    try {
      final response = await ApiClient.get(
        '${Environment.vestidorAr}/catalogo-3d',
        requireAuth: false,
      );

      if (response is List) {
        _prendasAR = response.map((json) => PrendaModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      notifyListeners();
    } catch (_) {
      // Si falla, el catálogo general también sirve
    }
  }

  // Ejecutar prueba virtual (llama al backend FastAPI /try-on-ia, Segmind IDM-VTON o Gemini)
  Future<String?> probarPrendaGemini({
    required Uint8List personaBytes,
    required String personaMimeType,
    required Uint8List prendaBytes,
    required String prendaMimeType,
    String? customInstructions,
    String category = 'upper_body',
    int? ropaId,
  }) async {
    _isLoading = true;
    _loadingStatus = 'Generando prueba virtual...';
    _errorMessage = null;
    _resultadoImageBase64 = null;
    notifyListeners();

    // 1. Intentar primero con el backend FastAPI (/api/v1/ar/try-on-ia) que garantiza la superposición de la prenda
    if (ropaId != null) {
      final res = await _probarConBackend(ropaId: ropaId, personaBytes: personaBytes);
      if (res != null) return res;
    }

    // 2. Si no hay ropaId o el backend falló, intentar vía Segmind directo
    if (Environment.segmindApiKey.isNotEmpty) {
      return _probarConSegmind(
        personaBytes: personaBytes,
        personaMimeType: personaMimeType,
        prendaBytes: prendaBytes,
        prendaMimeType: prendaMimeType,
        category: category,
        ropaId: ropaId,
      );
    }

    return _probarConGemini(
      personaBytes: personaBytes,
      personaMimeType: personaMimeType,
      prendaBytes: prendaBytes,
      prendaMimeType: prendaMimeType,
      customInstructions: customInstructions,
    );
  }

  Future<String?> _probarConBackend({
    required int ropaId,
    required Uint8List personaBytes,
  }) async {
    try {
      _loadingStatus = 'El servidor está adaptando la prenda a tu cuerpo...';
      notifyListeners();

      final uri = Uri.parse('${Environment.vestidorAr}/try-on-ia');
      final request = http.MultipartRequest('POST', uri);
      request.fields['ropa_id'] = ropaId.toString();
      request.files.add(
        http.MultipartFile.fromBytes(
          'foto_usuario',
          personaBytes,
          filename: 'foto_usuario.jpg',
        ),
      );

      final streamedResponse = await request.send().timeout(const Duration(seconds: 90));
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Vestidor Backend /try-on-ia status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['success'] == true && data['imagen_resultado'] != null) {
          String imgRes = data['imagen_resultado'].toString();
          if (imgRes.contains(',')) {
            imgRes = imgRes.split(',').last;
          }
          _resultadoImageBase64 = imgRes;
          _isLoading = false;
          _loadingStatus = null;
          _errorMessage = null;
          notifyListeners();
          return imgRes;
        }
      }
    } catch (e) {
      debugPrint('Vestidor: Error llamando a backend /try-on-ia: $e');
    }
    return null;
  }

  // Prueba Virtual con Segmind (IDM-VTON) - Fotorrealista
  Future<String?> _probarConSegmind({
    required Uint8List personaBytes,
    required String personaMimeType,
    required Uint8List prendaBytes,
    required String prendaMimeType,
    required String category,
    int? ropaId,
  }) async {
    try {
      // Detectar mime type real de la prenda por magic bytes
      String prendaMimeReal = prendaMimeType;
      if (prendaBytes.length > 4) {
        if (prendaBytes[0] == 0xFF && prendaBytes[1] == 0xD8) {
          prendaMimeReal = 'image/jpeg';
        } else if (prendaBytes[0] == 0x89 && prendaBytes[1] == 0x50) {
          prendaMimeReal = 'image/png';
        }
      }

      final personaDataUrl = 'data:$personaMimeType;base64,${base64Encode(personaBytes)}';
      final prendaDataUrl = 'data:$prendaMimeReal;base64,${base64Encode(prendaBytes)}';

      final intentos = [
        {'crop': true, 'desc': 'con crop=true'},
        {'crop': false, 'desc': 'con crop=false'},
      ];

      for (int i = 0; i < intentos.length; i++) {
        final intento = intentos[i];
        _loadingStatus = 'Segmind IDM-VTON procesando la prenda...';
        notifyListeners();

        final requestBody = {
          'human_img': personaDataUrl,
          'garm_img': prendaDataUrl,
          'category': category,
          'crop': intento['crop'],
          'seed': 42,
          'steps': 30,
          'garment_des': 'clothing item'
        };

        try {
          final response = await http.post(
            Uri.parse('https://api.segmind.com/v1/idm-vton'),
            headers: {
              'x-api-key': Environment.segmindApiKey.trim(),
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestBody),
          ).timeout(const Duration(seconds: 120));

          if (response.statusCode >= 200 && response.statusCode < 300) {
            final contentType = response.headers['content-type'] ?? '';
            if (response.bodyBytes.length > 1000 || contentType.contains('image')) {
              final b64Result = base64Encode(response.bodyBytes);
              _resultadoImageBase64 = b64Result;
              _isLoading = false;
              _loadingStatus = null;
              _errorMessage = null;
              notifyListeners();
              return b64Result;
            }
          }
        } catch (e) {
          debugPrint('Vestidor Segmind error: $e');
        }
      }

      // Si falla Segmind y hay ropaId, forzar llamada al backend
      if (ropaId != null) {
        final resBackend = await _probarConBackend(ropaId: ropaId, personaBytes: personaBytes);
        if (resBackend != null) return resBackend;
      }

      _errorMessage = 'No se pudo conectar con la IA de prueba virtual. Asegúrate de tener conexión a internet.';
      _isLoading = false;
      _loadingStatus = null;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Error procesando imagen en vestidor virtual.';
      _isLoading = false;
      _loadingStatus = null;
      notifyListeners();
      return null;
    }
  }

  // Fallback con Google Gemini
  Future<String?> _probarConGemini({
    required Uint8List personaBytes,
    required String personaMimeType,
    required Uint8List prendaBytes,
    required String prendaMimeType,
    String? customInstructions,
  }) async {
    const apiKey = Environment.geminiApiKey;
    if (apiKey.isEmpty) {
      _errorMessage = 'Configura tu clave de Segmind o Gemini en lib/config/environment.dart';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _loadingStatus = 'Preparando imágenes para IA...';
    _errorMessage = null;
    _resultadoImageBase64 = null;
    notifyListeners();

    try {
      final String personaB64 = base64Encode(personaBytes);
      final String prendaB64 = base64Encode(prendaBytes);

      _loadingStatus = 'IA procesando imagen...';
      notifyListeners();

      const endpoint = 'https://generativelanguage.googleapis.com/v1beta/models/${Environment.geminiModel}:generateContent?key=$apiKey';

      final requestBody = {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {
                'text': customInstructions ??
                    'Virtual try-on task: Dress the person in the first image with the garment shown in the second image. '
                    'Fit the garment realistically to their body pose and contours, preserving person facial features, identity, '
                    'hands, hair and background intact. Provide a photorealistic high resolution result image.'
              },
              {
                'inlineData': {
                  'mimeType': personaMimeType,
                  'data': personaB64,
                }
              },
              {
                'inlineData': {
                  'mimeType': prendaMimeType,
                  'data': prendaB64,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'responseModalities': ['TEXT', 'IMAGE']
        }
      };

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final candidate = data['candidates']?[0];
        final parts = candidate?['content']?['parts'] as List? ?? [];

        final imagePart = parts.firstWhere(
          (p) => p['inlineData'] != null && p['inlineData']['data'] != null,
          orElse: () => null,
        );

        if (imagePart != null) {
          final b64Result = imagePart['inlineData']['data'];
          _resultadoImageBase64 = b64Result;
          _isLoading = false;
          _loadingStatus = null;
          _errorMessage = null;
          notifyListeners();
          return b64Result;
        } else {
          throw Exception('La IA respondió pero no generó la imagen.');
        }
      } else {
        throw Exception('Error en API Gemini: ${response.body}');
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      _loadingStatus = null;
      notifyListeners();
      return null;
    }
  }

  void limpiarResultado() {
    _resultadoImageBase64 = null;
    _errorMessage = null;
    notifyListeners();
  }
}
