import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
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

  @override
  void initState() {
    super.initState();
    _prendaSeleccionada = widget.prendaInicial;
    if (_prendaSeleccionada != null) {
      _cargarBytesPrenda(_prendaSeleccionada!);
    }
  }

  Future<void> _cargarBytesPrenda(PrendaModel prenda) async {
    final url = prenda.imagenPrincipal;
    if (url != null && url.startsWith('http')) {
      try {
        final res = await http.get(Uri.parse(url));
        if (res.statusCode == 200) {
          setState(() {
            _prendaBytes = res.bodyBytes;
            _prendaMime = 'image/png';
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _tomarFotoCamara() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 90,
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
      maxWidth: 1080,
      maxHeight: 1080,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _userPhotoBytes = bytes;
        _userPhotoMime = image.mimeType ?? 'image/jpeg';
      });
    }
  }

  void _ejecutarPruebaIA() {
    if (_userPhotoBytes == null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor tómate una foto o sube una imagen tuya.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_prendaBytes == null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una prenda para probar.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final vestidor = Provider.of<VestidorService>(context, listen: false);
    vestidor.probarPrendaGemini(
      personaBytes: _userPhotoBytes!,
      personaMimeType: _userPhotoMime,
      prendaBytes: _prendaBytes!,
      prendaMimeType: _prendaMime,
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
                      'Gemini AI está adaptando la prenda...',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      vestidor.loadingStatus ?? 'Ajustando prenda fotorrealista a tu cuerpo...',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            )
          : vestidor.resultadoImageBase64 != null
              ? _buildResultadoView(vestidor)
              : _buildSetupView(catalogo),
    );
  }

  Widget _buildSetupView(CatalogoService catalogo) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                      Text('Vestidor Inteligente Gemini 2.5',
                          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B))),
                      SizedBox(height: 2),
                      Text('Tómate una foto y visualiza cómo luce la prenda en tu cuerpo con IA generativa.',
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
          const Text('2. Seleccionar Prenda de Ropa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
                              ? Image.network(p.imagenPrincipal!, fit: BoxFit.contain)
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
            label: const Text('Probar Prenda con Gemini IA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
          const Text('Prenda integrada fotorrealistamente con Gemini 2.5 Flash Image.',
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

