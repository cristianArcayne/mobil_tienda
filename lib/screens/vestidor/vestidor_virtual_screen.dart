import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../config/environment.dart';
import '../../models/prenda_model.dart';
import '../../services/vestidor_service.dart';
import '../../services/catalogo_service.dart';

class VestidorVirtualScreen extends StatefulWidget {
  final PrendaModel? prendaInicial;

  const VestidorVirtualScreen({super.key, this.prendaInicial});

  @override
  State<VestidorVirtualScreen> createState() => _VestidorVirtualScreenState();
}

class _VestidorVirtualScreenState extends State<VestidorVirtualScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _userPhotoBytes;
  String _userPhotoMime = 'image/jpeg';

  PrendaModel? _prendaSeleccionada;
  Uint8List? _prendaBytes;
  String _prendaMime = 'image/png';
  bool _cargandoPrenda = false;

  @override
  void initState() {
    super.initState();
    _prendaSeleccionada = widget.prendaInicial;
    if (_prendaSeleccionada != null) {
      _cargarBytesPrenda(_prendaSeleccionada!);
    }
  }

  Future<void> _cargarBytesPrenda(PrendaModel prenda) async {
    setState(() {
      _cargandoPrenda = true;
      _prendaBytes = null;
    });

    // Recopilar todas las URLs posibles de imagen
    List<String> urlsToTry = [];
    
    if (prenda.imagenPrincipal != null && prenda.imagenPrincipal!.isNotEmpty) {
      urlsToTry.add(prenda.imagenPrincipal!);
    }
    for (final img in prenda.imagenes) {
      if (img.isNotEmpty && !urlsToTry.contains(img)) {
        urlsToTry.add(img);
      }
    }

    for (final url in urlsToTry) {
      final formattedUrl = Environment.formatImageUrl(url);
      debugPrint('Vestidor: Intentando descargar prenda desde: $formattedUrl');
      try {
        final res = await http.get(Uri.parse(formattedUrl)).timeout(const Duration(seconds: 15));
        debugPrint('Vestidor: Respuesta ${res.statusCode}, Content-Type: ${res.headers['content-type']}, bytes: ${res.bodyBytes.length}');
        
        if (res.statusCode == 200 && res.bodyBytes.length > 100) {
          // Verificar que no sea HTML (un error de servidor)
          final contentType = res.headers['content-type'] ?? '';
          final primeros = String.fromCharCodes(res.bodyBytes.take(20));
          if (primeros.contains('<!DOCTYPE') || primeros.contains('<html')) {
            debugPrint('Vestidor: La respuesta es HTML, no una imagen. Saltando...');
            continue;
          }

          // Detectar mime type por magic bytes
          String mime = 'image/jpeg';
          if (res.bodyBytes.length > 4) {
            if (res.bodyBytes[0] == 0xFF && res.bodyBytes[1] == 0xD8) {
              mime = 'image/jpeg';
            } else if (res.bodyBytes[0] == 0x89 && res.bodyBytes[1] == 0x50) {
              mime = 'image/png';
            } else if (res.bodyBytes[0] == 0x52 && res.bodyBytes[1] == 0x49) {
              mime = 'image/webp';
            }
          }
          
          if (contentType.contains('image') || mime != 'image/jpeg' || (res.bodyBytes[0] == 0xFF && res.bodyBytes[1] == 0xD8)) {
            setState(() {
              _prendaBytes = res.bodyBytes;
              _prendaMime = mime;
              _cargandoPrenda = false;
            });
            debugPrint('Vestidor: Prenda descargada OK - ${res.bodyBytes.length} bytes, mime: $mime');
            return;
          }
        }
      } catch (e) {
        debugPrint('Vestidor: Error descargando imagen de prenda desde $formattedUrl: $e');
      }
    }
    
    debugPrint('Vestidor: No se pudo descargar ninguna imagen válida de la prenda');
    setState(() => _cargandoPrenda = false);
  }

  Future<void> _tomarFotoCamara() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (photo != null) {
      final bytes = await photo.readAsBytes();
      setState(() {
        _userPhotoBytes = bytes;
        _userPhotoMime = photo.mimeType ?? 'image/jpeg';
      });
    }
  }

  Future<void> _seleccionarFotoGaleria() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _userPhotoBytes = bytes;
        _userPhotoMime = image.mimeType ?? 'image/jpeg';
      });
    }
  }

  Future<void> _ejecutarPruebaIA() async {
    if (_userPhotoBytes == null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor tómate una foto o sube una imagen tuya.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_prendaBytes == null) {
      if (_prendaSeleccionada != null) {
        await _cargarBytesPrenda(_prendaSeleccionada!);
      }
      if (_prendaBytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_prendaSeleccionada != null
                ? 'No se pudo descargar la imagen de "${_prendaSeleccionada!.nombre}". Intenta con otra prenda que tenga imagen.'
                : 'Por favor selecciona una prenda del catálogo.'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
    }

    String category = 'upper_body';
    final nom = (_prendaSeleccionada?.nombre ?? '').toLowerCase();
    final catNom = (_prendaSeleccionada?.categoriaNombre ?? '').toLowerCase();
    if (nom.contains('jean') || nom.contains('pantalon') || nom.contains('falda') || nom.contains('short') || catNom.contains('inferior')) {
      category = 'lower_body';
    } else if (nom.contains('vestido') || catNom.contains('vestido')) {
      category = 'dresses';
    }

    if (!mounted) return;
    final vestidor = Provider.of<VestidorService>(context, listen: false);
    vestidor.probarPrendaGemini(
      personaBytes: _userPhotoBytes!,
      personaMimeType: _userPhotoMime,
      prendaBytes: _prendaBytes!,
      prendaMimeType: _prendaMime,
      category: category,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vestidor = Provider.of<VestidorService>(context);
    final catalogo = Provider.of<CatalogoService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vestidor Virtual IA'),
      ),
      body: vestidor.isLoading
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(color: Color(0xFF4F46E5), strokeWidth: 3),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Generando Prueba Virtual...',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      vestidor.loadingStatus ?? 'Adaptando prenda con Segmind IDM-VTON...',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            )
          : vestidor.resultadoImageBase64 != null
              ? _buildResultadoView(vestidor)
              : _buildSetupView(catalogo, vestidor),
    );
  }

  Widget _buildSetupView(CatalogoService catalogo, VestidorService vestidor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner de error si ocurrió alguno
          if (vestidor.errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Aviso en la Generación',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF991B1B), fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    vestidor.errorMessage!,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF7F1D1D)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '💡 Consejo: Puedes usar fotos de cara, medio cuerpo o cuerpo entero. Asegúrate de tener buena iluminación y que la prenda tenga imagen válida.',
                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF991B1B)),
                  ),
                ],
              ),
            ),

          // Banner explicativo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEEF2FF), Color(0xFFF5F3FF)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC7D2FE)),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFF4F46E5), size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vestidor Fotorrealista Segmind IA',
                          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B))),
                      SizedBox(height: 2),
                      Text('Tómate una foto (cara, medio cuerpo o completo) y visualiza la prenda adaptada con precisión fotorrealista.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF4338CA))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Paso 1: Tu Foto
          const Text('1. Tu Foto Personal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: _userPhotoBytes != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(_userPhotoBytes!, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                            onPressed: () => setState(() => _userPhotoBytes = null),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_outline, size: 54, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.photo_camera, size: 18),
                              label: const Text('Tomar Foto'),
                              onPressed: _tomarFotoCamara,
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.photo_library, size: 18),
                              label: const Text('Galería'),
                              onPressed: _seleccionarFotoGaleria,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 24),

          // Paso 2: Prenda seleccionada
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('2. Seleccionar Prenda de Ropa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              if (_cargandoPrenda)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: catalogo.prendas.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (ctx, i) {
                final p = catalogo.prendas[i];
                final isSel = _prendaSeleccionada?.id == p.id;

                return InkWell(
                  onTap: () {
                    setState(() => _prendaSeleccionada = p);
                    _cargarBytesPrenda(p);
                  },
                  child: Container(
                    width: 90,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFFEEF2FF) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSel ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                        width: isSel ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: p.imagenPrincipal != null
                              ? Image.network(
                                  Environment.formatImageUrl(p.imagenPrincipal!),
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.checkroom),
                                )
                              : const Icon(Icons.checkroom),
                        ),
                        Text(
                          p.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),

          // Botón Probar con IA
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: const Color(0xFF4F46E5),
            ),
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Probar Prenda en Vestidor IA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            onPressed: _ejecutarPruebaIA,
          ),
        ],
      ),
    );
  }

  Widget _buildResultadoView(VestidorService vestidor) {
    final bytes = base64Decode(vestidor.resultadoImageBase64!);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('✨ Resultado del Vestidor Virtual', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('Prenda adaptada fotorrealistamente con Segmind IDM-VTON.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          const SizedBox(height: 16),

          // Comparativa Antes / Después
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text('Antes (Tu Foto)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    Container(
                      height: 260,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _userPhotoBytes != null ? Image.memory(_userPhotoBytes!, fit: BoxFit.cover) : Container(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    const Text('Después (IA)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF4F46E5))),
                    const SizedBox(height: 6),
                    Container(
                      height: 260,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF4F46E5), width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(bytes, fit: BoxFit.cover),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          OutlinedButton.icon(
            icon: const Icon(Icons.replay),
            label: const Text('Probar con Otra Prenda'),
            onPressed: () => vestidor.limpiarResultado(),
          ),
        ],
      ),
    );
  }
}
