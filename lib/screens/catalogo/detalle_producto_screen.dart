import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/prenda_model.dart';
import '../../services/auth_service.dart';
import '../../services/carrito_service.dart';
import '../../services/catalogo_service.dart';
import '../../services/favoritos_service.dart';
import '../../services/resenas_service.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/stock_badge.dart';
import '../resenas/resenas_list_screen.dart';
import '../vestidor/vestidor_virtual_screen.dart';
import '../live_ar_screen.dart';

import '../reservas/crear_reserva_screen.dart';

class DetalleProductoScreen extends StatefulWidget {
  final int prendaId;

  const DetalleProductoScreen({
    super.key,
    int? prendaId,
    int? productoId,
  }) : prendaId = prendaId ?? productoId ?? 0;

  int get productoId => prendaId;

  @override
  State<DetalleProductoScreen> createState() => _DetalleProductoScreenState();
}

class _DetalleProductoScreenState extends State<DetalleProductoScreen> {
  PrendaModel? _prenda;
  bool _isLoading = true;
  VariantePrendaModel? _selectedVariante;
  String? _selectedImageOverride;
  int _cantidad = 1;

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  String _getDisplayImageUrl(PrendaModel? p) {
    if (p == null) return '';

    // 1. Si el usuario hizo clic explícito en una foto de la galería
    if (_selectedImageOverride != null && _selectedImageOverride!.trim().isNotEmpty) {
      return _selectedImageOverride!.trim();
    }

    // 2. Si la variante seleccionada tiene su propia foto subida desde la web
    if (_selectedVariante != null &&
        _selectedVariante!.imagenUrl != null &&
        _selectedVariante!.imagenUrl!.trim().isNotEmpty) {
      return _selectedVariante!.imagenUrl!.trim();
    }

    // 3. Buscar si otra variante con el MISMO COLOR tiene foto asignada (ej: misma prenda en otro talle)
    if (_selectedVariante != null && p.variantes.isNotEmpty) {
      final colorTarget = _selectedVariante!.color.trim().toLowerCase();
      final mismaVarianteConFoto = p.variantes.where((v) =>
          v.color.trim().toLowerCase() == colorTarget &&
          v.imagenUrl != null &&
          v.imagenUrl!.trim().isNotEmpty);
      if (mismaVarianteConFoto.isNotEmpty) {
        return mismaVarianteConFoto.first.imagenUrl!.trim();
      }
    }

    // 4. Buscar coincidencia por nombre de color en las imágenes del producto
    if (_selectedVariante != null && p.imagenes.isNotEmpty) {
      final colorNom = _selectedVariante!.color.toLowerCase().trim();
      if (colorNom != 'estándar' && colorNom != 'estandar' && colorNom != 'única' && colorNom != 'unica') {
        for (final img in p.imagenes) {
          if (img.toLowerCase().contains(colorNom)) {
            return img;
          }
        }

        final keywords = <String>[];
        if (colorNom.contains('negro') || colorNom.contains('black') || colorNom.contains('oscuro')) {
          keywords.addAll(['negro', 'black', 'dark']);
        } else if (colorNom.contains('azul') || colorNom.contains('blue') || colorNom.contains('denim')) {
          keywords.addAll(['azul', 'blue', 'denim']);
        } else if (colorNom.contains('rojo') || colorNom.contains('red')) {
          keywords.addAll(['rojo', 'red']);
        } else if (colorNom.contains('blanco') || colorNom.contains('white') || colorNom.contains('claro')) {
          keywords.addAll(['blanco', 'white']);
        } else if (colorNom.contains('verde') || colorNom.contains('green')) {
          keywords.addAll(['verde', 'green']);
        } else if (colorNom.contains('gris') || colorNom.contains('gray') || colorNom.contains('grey')) {
          keywords.addAll(['gris', 'gray', 'grey']);
        } else if (colorNom.contains('amarillo') || colorNom.contains('yellow')) {
          keywords.addAll(['amarillo', 'yellow']);
        } else if (colorNom.contains('rosa') || colorNom.contains('pink') || colorNom.contains('rosado')) {
          keywords.addAll(['rosa', 'pink', 'rosado']);
        } else if (colorNom.contains('cafe') || colorNom.contains('café') || colorNom.contains('brown') || colorNom.contains('marron')) {
          keywords.addAll(['cafe', 'brown', 'marron']);
        }

        for (final kw in keywords) {
          for (final img in p.imagenes) {
            if (img.toLowerCase().contains(kw)) {
              return img;
            }
          }
        }
      }
    }

    // 5. Fallback garantizado a imagen principal o primera de la lista
    return p.imagenPrincipal ?? (p.imagenes.isNotEmpty ? p.imagenes.first : '');
  }

  Future<void> _cargarDetalle() async {
    final service = Provider.of<CatalogoService>(context, listen: false);
    final p = await service.obtenerPrendaDetalle(widget.prendaId);
    if (mounted) {
      setState(() {
        _prenda = p;
        _isLoading = false;
        _selectedImageOverride = null; // Iniciar sin override para que mande la variante
        if (p != null && p.variantes.isNotEmpty) {
          _selectedVariante = p.variantes.first;
        }
      });
    }
  }

  void _abrirDialogoAgregarResena(PrendaModel prenda) {
    int calificacion = 5;
    final comentarioCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.rate_review, color: Color(0xFF4F46E5)),
              SizedBox(width: 8),
              Text('Calificar y Opinar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prenda.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                const SizedBox(height: 12),
                const Text('Tu Puntuación en Estrellas:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starVal = index + 1;
                    return IconButton(
                      icon: Icon(
                        starVal <= calificacion ? Icons.star : Icons.star_border,
                        color: const Color(0xFFF59E0B),
                        size: 32,
                      ),
                      onPressed: () => setDialogState(() => calificacion = starVal),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                const Text('Tu Opinión o Comentario:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                const SizedBox(height: 6),
                TextField(
                  controller: comentarioCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Escribe tu opinión sobre la tela, el talle o la comodidad...',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
              icon: const Icon(Icons.send, size: 16),
              label: const Text('Publicar Reseña'),
              onPressed: () async {
                final auth = Provider.of<AuthService>(context, listen: false);
                final clienteNombre = auth.currentUser?.nombreCompleto ?? auth.currentUser?.username ?? 'Cliente App';
                final clienteCi = auth.currentUser?.username ?? '1001';

                final service = Provider.of<ResenasService>(context, listen: false);
                final ok = await service.crearResena(
                  ropaId: prenda.id,
                  calificacion: calificacion,
                  comentario: comentarioCtrl.text.trim(),
                  clienteCi: clienteCi,
                  clienteNombre: clienteNombre,
                );
                if (ok && ctx.mounted) {
                  Navigator.pop(ctx);
                  _cargarDetalle();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('¡Gracias por tu reseña! Ha sido publicada exitosamente.'),
                      backgroundColor: Color(0xFF16A34A),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _agregarAlCarrito() {
    if (_prenda == null) return;
    final cart = Provider.of<CarritoService>(context, listen: false);

    final variante = _selectedVariante ??
        VariantePrendaModel(
          id: _prenda!.id,
          talla: 'M',
          color: 'Estándar',
          stockDisponible: _prenda!.stockTotalDisponible,
          estadoStock: _prenda!.estadoGlobalStock,
        );

    cart.agregarPrenda(prenda: _prenda!, variante: variante, cantidad: _cantidad);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '¡${_prenda!.nombre} agregado!',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5))),
      );
    }

    if (_prenda == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Prenda no encontrada')),
      );
    }

    final p = _prenda!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Imagen con SliverAppBar
          SliverAppBar(
            expandedHeight: 380,
            pinned: true,
            actions: [
              Consumer<FavoritosService>(
                builder: (context, favService, _) {
                  final isFav = favService.esFavorito(p.id);
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
                      ),
                      onPressed: () async {
                        final nuevoEstado = await favService.toggleFavorito(p);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                nuevoEstado ? '¡Guardado en tus favoritos!' : 'Eliminado de tus favoritos',
                                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                              backgroundColor: nuevoEstado ? const Color(0xFFE11D48) : const Color(0xFF0F172A),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(milliseconds: 1400),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Builder(
                    builder: (context) {
                      final currentImg = _getDisplayImageUrl(p);
                      if (currentImg.isNotEmpty) {
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Image.network(
                            currentImg,
                            key: ValueKey(currentImg),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) {
                              if (p.imagenPrincipal != null && p.imagenPrincipal!.isNotEmpty && currentImg != p.imagenPrincipal) {
                                return Image.network(
                                  p.imagenPrincipal!,
                                  key: ValueKey('fallback_${p.imagenPrincipal}'),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFFF1F5F9),
                                    child: const Icon(Icons.checkroom, size: 80, color: Color(0xFF94A3B8)),
                                  ),
                                );
                              }
                              return Container(
                                color: const Color(0xFFF1F5F9),
                                child: const Icon(Icons.checkroom, size: 80, color: Color(0xFF94A3B8)),
                              );
                            },
                          ),
                        );
                      }
                      return Container(
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(Icons.checkroom, size: 80, color: Color(0xFF94A3B8)),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StockBadge(
                              estado: _selectedVariante?.estadoStock ?? p.estadoGlobalStock,
                              unidades: _selectedVariante?.stockDisponible ?? p.stockTotalDisponible,
                            ),
                            if (_selectedVariante != null && _selectedVariante!.color != 'Estándar') ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.82),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.palette_outlined, size: 14, color: Colors.white),
                                    const SizedBox(width: 5),
                                    Text(
                                      _selectedVariante!.color,
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (_selectedImageOverride != null || (_selectedVariante != null && _getDisplayImageUrl(p) != p.imagenPrincipal))
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImageOverride = p.imagenPrincipal;
                                if (p.variantes.isNotEmpty) {
                                  _selectedVariante = p.variantes.first;
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.undo_rounded, size: 14, color: Color(0xFF0F172A)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Foto Principal',
                                    style: TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contenido
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categoría y Título
                  if (p.categoriaNombre != null)
                    Text(
                      p.categoriaNombre!.toUpperCase(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5)),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    p.nombre,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),

                  // Calificación y Reseñas
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ResenasListScreen(ropaId: p.id, prendaNombre: p.nombre)),
                      );
                    },
                    child: Row(
                      children: [
                        RatingStars(rating: p.calificacionPromedio ?? 0, totalResenas: p.totalResenas, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'Ver opiniones >',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4F46E5)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Precio
                  Row(
                    children: [
                      Text(
                        'Bs. ${p.precio.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                      ),
                      if (p.precioConDescuento != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          'Bs. ${p.precioConDescuento!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            decoration: TextDecoration.lineThrough,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Divider(height: 32),

                  // Galería de fotos / Colores disponibles
                  if (p.imagenes.length > 1) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Fotos y Variantes de Color:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                        if (_selectedImageOverride != null || (_selectedVariante != null && _getDisplayImageUrl(p) != p.imagenPrincipal))
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImageOverride = p.imagenPrincipal;
                                if (p.variantes.isNotEmpty) {
                                  _selectedVariante = p.variantes.first;
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.undo, size: 12, color: Color(0xFF4F46E5)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Volver a principal',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: p.imagenes.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (ctx, idx) {
                          final imgUrl = p.imagenes[idx];
                          final isCurrent = _getDisplayImageUrl(p) == imgUrl;
                          final isPrincipal = imgUrl == p.imagenPrincipal;

                          return GestureDetector(
                            onTap: () {
                              final vMatch = p.variantes.where((v) => v.imagenUrl == imgUrl);
                              setState(() {
                                if (vMatch.isNotEmpty) {
                                  _selectedVariante = vMatch.first;
                                }
                                _selectedImageOverride = imgUrl;
                              });
                            },
                            child: Container(
                              width: 68,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isCurrent ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
                                  width: isCurrent ? 2.5 : 1,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    imgUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(Icons.broken_image, size: 24, color: Color(0xFF94A3B8)),
                                    ),
                                  ),
                                  if (isPrincipal)
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        color: const Color(0xFF0F172A).withValues(alpha: 0.75),
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: const Text(
                                          'Principal',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Variantes (Tallas y Colores)
                  if (p.variantes.isNotEmpty) ...[
                    const Text('Seleccionar Talla y Color:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: p.variantes.map((v) {
                        final isSel = _selectedVariante?.id == v.id;
                        final agotado = v.stockDisponible <= 0;

                        return ChoiceChip(
                          avatar: v.imagenUrl != null && v.imagenUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    v.imagenUrl!,
                                    width: 20,
                                    height: 20,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.circle, size: 14),
                                  ),
                                )
                              : null,
                          label: Text('${v.talla} • ${v.color} (${v.stockDisponible})'),
                          selected: isSel,
                          selectedColor: const Color(0xFF4F46E5),
                          disabledColor: const Color(0xFFE2E8F0),
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : (agotado ? const Color(0xFF94A3B8) : const Color(0xFF1E293B)),
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          ),
                          onSelected: agotado
                              ? null
                              : (_) => setState(() {
                                    _selectedVariante = v;
                                    _selectedImageOverride = null; // Limpiar override para que mande el color de la variante
                                  }),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  
                  // Botón Principal: Probar en Vestidor Google IA Cloud
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.auto_awesome, color: Colors.white),
                      label: const Text(
                        'Probar en Vestidor Google IA Cloud',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () {
                        final imgActual = _getDisplayImageUrl(p);
                        final prendaConVariante = PrendaModel(
                          id: p.id,
                          nombre: _selectedVariante != null ? '${p.nombre} (${_selectedVariante!.color})' : p.nombre,
                          descripcion: p.descripcion,
                          precio: p.precio,
                          precioConDescuento: p.precioConDescuento,
                          categoriaNombre: p.categoriaNombre,
                          imagenPrincipal: imgActual,
                          imagenes: [imgActual, ...p.imagenes.where((img) => img != imgActual)],
                          modelo3dUri: p.modelo3dUri,
                          stockTotalDisponible: _selectedVariante?.stockDisponible ?? p.stockTotalDisponible,
                          estadoGlobalStock: _selectedVariante?.estadoStock ?? p.estadoGlobalStock,
                          calificacionPromedio: p.calificacionPromedio,
                          totalResenas: p.totalResenas,
                          variantes: p.variantes,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VestidorVirtualScreen(prendaInicial: prendaConVariante),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Botón Secundario: Probar en Vivo (Cámara AR Tiempo Real)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('Probar en Vivo (Cámara AR Tiempo Real)'),
                    onPressed: () {
                      List<String> colores = p.variantes
                          .map((v) => v.color)
                          .where((c) => c != 'Estándar' && c != 'Única' && c.isNotEmpty)
                          .toSet()
                          .toList();
                      if (_selectedVariante != null && colores.contains(_selectedVariante!.color)) {
                        colores.remove(_selectedVariante!.color);
                        colores.insert(0, _selectedVariante!.color);
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LiveArScreen(
                            prendaUrl: _getDisplayImageUrl(p),
                            prendaNombre: _selectedVariante != null ? '${p.nombre} (${_selectedVariante!.color})' : p.nombre,
                            coloresDisponibles: colores,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Botón Reservar Web-to-Store
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    icon: const Icon(Icons.storefront_outlined),
                    label: const Text('Apartar y Retirar en Tienda Física'),
                    onPressed: _selectedVariante != null
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CrearReservaScreen(
                                  prenda: p,
                                  variante: _selectedVariante!,
                                ),
                              ),
                            );
                          }
                        : null,
                  ),
                  const SizedBox(height: 24),

                  // Descripción
                  const Text('Descripción de la prenda', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    p.descripcion.isNotEmpty ? p.descripcion : 'Prenda confeccionada con telas de primera calidad para garantizar confort y estilo duradero.',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5),
                  ),
                  const SizedBox(height: 28),

                  // Sección CU19: Reseñas y Calificaciones de Clientes
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Reseñas y Calificaciones ⭐',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            RatingStars(rating: p.calificacionPromedio ?? 5.0, totalResenas: p.totalResenas, size: 20),
                            const Spacer(),
                            Text(
                              '${p.calificacionPromedio ?? 5.0} / 5.0',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFFD97706)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F46E5),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: const Icon(Icons.rate_review, size: 18),
                                label: const Text('Calificar y Opinar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                onPressed: () => _abrirDialogoAgregarResena(p),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: const Icon(Icons.comment_outlined, size: 18),
                                label: const Text('Ver Opiniones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => ResenasListScreen(ropaId: p.id, prendaNombre: p.nombre)),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      // Barra inferior fija con botón de compra / carrito
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -3)),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Selector cantidad
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: _cantidad > 1 ? () => setState(() => _cantidad--) : null,
                    ),
                    Text('$_cantidad', style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: () => setState(() => _cantidad++),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Botón Agregar al Carrito
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Agregar al Carrito'),
                  onPressed: _selectedVariante != null && _selectedVariante!.stockDisponible > 0
                      ? _agregarAlCarrito
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

