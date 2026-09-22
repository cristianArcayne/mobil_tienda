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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Uint8List? _userPhotoBytes;
  String _userPhotoMime = 'image/jpeg';

  PrendaModel? _prendaSeleccionada;
  Uint8List? _prendaBytes;
  String _prendaMime = 'image/png';
  bool _cargandoPrenda = false;

  static final List<PrendaModel> _demoPrendas = [
    PrendaModel(
      id: 21,
      nombre: 'Polera CAT Original Gris',
      descripcion: 'Polera de algodón gris Caterpillar edición especial',
      precio: 120.0,
      categoriaNombre: 'Poleras',
      imagenPrincipal: '/static/uploads/polera_cat_gris.png',
      imagenes: ['/static/uploads/polera_cat_gris.png'],
      stockTotalDisponible: 15,
      estadoGlobalStock: 'DISPONIBLE',
      variantes: [],
    ),
    PrendaModel(
      id: 22,
      nombre: 'Chamarra Térmica RACCO Negra',
      descripcion: 'Chamarra térmica negra acolchada RACCO',
      precio: 280.0,
      categoriaNombre: 'Chamarras',
      imagenPrincipal: '/static/uploads/chamarra_racco_negra.png',
      imagenes: ['/static/uploads/chamarra_racco_negra.png'],
      stockTotalDisponible: 12,
      estadoGlobalStock: 'DISPONIBLE',
      variantes: [],
    ),
    PrendaModel(
      id: -1,
      nombre: 'Polera Blanca Algodón',
      descripcion: 'Polera básica de algodón ideal para vestir con IA',
      precio: 89.0,
      categoriaNombre: 'Superior',
      imagenPrincipal: '/static/uploads/polera_blanca_algodon.jpg',
      imagenes: ['/static/uploads/polera_blanca_algodon.jpg'],
      stockTotalDisponible: 10,
      estadoGlobalStock: 'DISPONIBLE',
      variantes: [],
    ),
    PrendaModel(
      id: -2,
      nombre: 'Sudadera Roja Casual',
      descripcion: 'Sudadera roja casual con cierre',
      precio: 159.0,
      categoriaNombre: 'Superior',
      imagenPrincipal: '/static/uploads/sudadera_roja_casual.jpg',
      imagenes: ['/static/uploads/sudadera_roja_casual.jpg'],
      stockTotalDisponible: 10,
      estadoGlobalStock: 'DISPONIBLE',
      variantes: [],
    ),
    PrendaModel(
      id: -3,
      nombre: 'Chaqueta Denim Clásica',
      descripcion: 'Chaqueta vaquera denim clásica azul',
      precio: 220.0,
      categoriaNombre: 'Superior',
      imagenPrincipal: '/static/uploads/chaqueta_denim_clasica.jpg',
      imagenes: ['/static/uploads/chaqueta_denim_clasica.jpg'],
      stockTotalDisponible: 10,
      estadoGlobalStock: 'DISPONIBLE',
      variantes: [],
    ),
    PrendaModel(
      id: -4,
      nombre: 'Pantalón Jean Slim',
      descripcion: 'Pantalón jean azul slim fit',
      precio: 180.0,
      categoriaNombre: 'Inferior',
      imagenPrincipal: '/static/uploads/jean_slim_azul.jpg',
      imagenes: ['/static/uploads/jean_slim_azul.jpg'],
      stockTotalDisponible: 10,
      estadoGlobalStock: 'DISPONIBLE',
      variantes: [],
    ),
    PrendaModel(
      id: -5,
      nombre: 'Vestido Estampado Floral',
      descripcion: 'Vestido de verano estampado floral',
      precio: 210.0,
      categoriaNombre: 'Vestidos',
      imagenPrincipal: '/static/uploads/vestido_estampado_floral.jpg',
      imagenes: ['/static/uploads/vestido_estampado_floral.jpg'],
      stockTotalDisponible: 10,
      estadoGlobalStock: 'DISPONIBLE',
      variantes: [],
    ),
  ];

  List<PrendaModel> _getPrendas(CatalogoService catalogo) {
    // Priorizar prendas reales del catálogo (ya cargadas del backend)
    List<PrendaModel> list = [];
    
    // Primero agregar todas las prendas reales del catálogo
    for (var p in catalogo.prendas) {
      if (!list.any((element) => element.id == p.id)) {
        list.add(p);
      }
    }
    
    // Si el catálogo está vacío, agregar las prendas demo como respaldo
    if (list.isEmpty) {
      list.addAll(_demoPrendas);
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((p) {
        final nom = p.nombre.toLowerCase();
        final cat = (p.categoriaNombre ?? '').toLowerCase();
        final desc = p.descripcion.toLowerCase();
        return nom.contains(q) || cat.contains(q) || desc.contains(q);
      }).toList();
    }

    return list;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _prendaSeleccionada = widget.prendaInicial;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final catalogo = Provider.of<CatalogoService>(context, listen: false);
      if (catalogo.prendas.isEmpty) {
        await catalogo.cargarCatalogo();
      }
      // Auto-seleccionar la primera prenda del catálogo real si no hay prendaInicial
      if (_prendaSeleccionada == null && catalogo.prendas.isNotEmpty) {
        setState(() {
          _prendaSeleccionada = catalogo.prendas.first;
        });
        _cargarBytesPrenda(_prendaSeleccionada!);
      } else if (_prendaSeleccionada == null && _demoPrendas.isNotEmpty) {
        setState(() {
          _prendaSeleccionada = _demoPrendas.first;
        });
        _cargarBytesPrenda(_prendaSeleccionada!);
      } else if (_prendaSeleccionada != null) {
        _cargarBytesPrenda(_prendaSeleccionada!);
      }
    });
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
      maxHeight: 1368,
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
      maxHeight: 1368,
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
      ropaId: _prendaSeleccionada?.id,
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
                const Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 6),
                    Text('Cargando...', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Buscador de prendas
          TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o categoría (ej: CAT, Polera, RACCO)...',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: Color(0xFF64748B)),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Prenda actualmente elegida (Resumen destacado)
          if (_prendaSeleccionada != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Elegida: ${_prendaSeleccionada!.nombre}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),

          // Lista vertical de prendas
          Builder(
            builder: (context) {
              final prendasDisponibles = _getPrendas(catalogo);

              if (prendasDisponibles.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.search_off, color: Color(0xFF94A3B8), size: 36),
                        const SizedBox(height: 8),
                        Text(
                          'No se encontraron prendas para "$_searchQuery"',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Container(
                constraints: const BoxConstraints(maxHeight: 340),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(8),
                  itemCount: prendasDisponibles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final p = prendasDisponibles[i];
                    final isSel = _prendaSeleccionada?.id == p.id;

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() => _prendaSeleccionada = p);
                        _cargarBytesPrenda(p);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFFEEF2FF) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSel ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                            width: isSel ? 2 : 1,
                          ),
                          boxShadow: isSel
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF4F46E5).withOpacity(0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            // Miniatura de prenda (70x70)
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: p.imagenPrincipal != null && p.imagenPrincipal!.isNotEmpty
                                    ? Image.network(
                                        Environment.formatImageUrl(p.imagenPrincipal!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.checkroom, color: Color(0xFF94A3B8), size: 30),
                                      )
                                    : const Icon(Icons.checkroom, color: Color(0xFF94A3B8), size: 30),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Info de la prenda
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.nombre,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                      color: isSel ? const Color(0xFF1E1B4B) : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isSel ? const Color(0xFFC7D2FE) : const Color(0xFFE2E8F0),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          p.categoriaNombre ?? 'Prenda',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isSel ? const Color(0xFF3730A3) : const Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Bs ${p.precio.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF16A34A),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (p.descripcion.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      p.descripcion,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Icono de selección (Radio / Check)
                            Icon(
                              isSel ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: isSel ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
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

  void _visualizarImagenAmpliada(Uint8List bytes) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Visualizar Resultado IA', style: TextStyle(color: Colors.white, fontSize: 16)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            Flexible(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _guardarFotoResultado() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '¡Imagen guardada exitosamente en el historial del vestidor!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
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
                    InkWell(
                      onTap: () => _visualizarImagenAmpliada(bytes),
                      child: Stack(
                        children: [
                          Container(
                            height: 260,
                            width: double.infinity,
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
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.fullscreen, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Acciones: Guardar y Visualizar Ampliada
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.save_alt),
                  label: const Text('Guardar Imagen', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _guardarFotoResultado,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.zoom_in),
                  label: const Text('Visualizar XL', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _visualizarImagenAmpliada(bytes),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

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
