import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/prenda_model.dart';
import '../services/auth_service.dart';
import '../services/carrito_service.dart';
import '../services/favoritos_service.dart';
import 'guest_restriction_dialog.dart';

class PrendaCard extends StatefulWidget {
  final PrendaModel prenda;
  final VoidCallback onTap;
  final VoidCallback onProbarIA;

  const PrendaCard({
    super.key,
    required this.prenda,
    required this.onTap,
    required this.onProbarIA,
  });

  @override
  State<PrendaCard> createState() => _PrendaCardState();
}

class _PrendaCardState extends State<PrendaCard> {
  String? _cardImagePreview;

  Widget _buildFallbackCard() {
    IconData icon = Icons.checkroom_rounded;
    final nom = widget.prenda.nombre.toLowerCase();
    if (nom.contains('chaqueta') || nom.contains('chamarra') || nom.contains('cuero') || nom.contains('denim')) {
      icon = Icons.dry_cleaning_rounded;
    } else if (nom.contains('lentes') || nom.contains('gafas')) {
      icon = Icons.visibility_rounded;
    } else if (nom.contains('zapato') || nom.contains('zapatilla') || nom.contains('calzado') || nom.contains('runner')) {
      icon = Icons.snowshoeing_rounded;
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF8FAFC),
            Color(0xFFE2E8F0),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 28, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          Text(
            widget.prenda.categoriaNombre ?? 'Colección',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.prenda.nombre,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  void _handleIA3DTap(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (!auth.isAuthenticated) {
      GuestRestrictionDialog.show(
        context,
        featureName: 'el Vestidor Virtual IA y Modelado 3D de esta prenda',
      );
    } else {
      widget.onProbarIA();
    }
  }

  void _handleAddToCart(BuildContext context) {
    final cart = Provider.of<CarritoService>(context, listen: false);
    final VariantePrendaModel variante = widget.prenda.variantes.isNotEmpty
        ? widget.prenda.variantes.first
        : VariantePrendaModel(
            id: widget.prenda.id,
            talla: 'M',
            color: 'Estándar',
            codBarra: 'SKU-${widget.prenda.id}',
            stockDisponible: widget.prenda.stockTotalDisponible > 0 ? widget.prenda.stockTotalDisponible : 10,
            estadoStock: 'DISPONIBLE',
          );

    cart.agregarPrenda(
      prenda: widget.prenda,
      variante: variante,
      cantidad: 1,
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${widget.prenda.nombre} añadida a la bolsa',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 75, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFF0F172A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determinar badge editorial dinámico
    final String badgeText = widget.prenda.stockTotalDisponible <= 3
        ? 'ÚLTIMAS PIEZAS'
        : (widget.prenda.id % 2 == 0 ? 'NUEVO' : 'ICONIC');

    // Tallas formateadas
    String tallasStr = 'S · M · L · XL';
    if (widget.prenda.variantes.isNotEmpty) {
      final tallas = widget.prenda.variantes
          .map((v) => v.talla)
          .where((t) => t.isNotEmpty)
          .toSet()
          .toList();
      if (tallas.isNotEmpty) {
        tallasStr = tallas.join(' · ');
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFE9E3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del Producto con Badges
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: const Color(0xFFF6F6F6),
                    child: (_cardImagePreview ?? widget.prenda.imagenPrincipal) != null &&
                            (_cardImagePreview ?? widget.prenda.imagenPrincipal)!.isNotEmpty
                        ? Image.network(
                            (_cardImagePreview ?? widget.prenda.imagenPrincipal)!,
                            key: ValueKey(_cardImagePreview ?? widget.prenda.imagenPrincipal),
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFC5A059),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => _buildFallbackCard(),
                          )
                        : _buildFallbackCard(),
                  ),

                  // Badge Superior Izquierdo: ICONIC / NUEVO
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        badgeText,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),

                  // Botón Superior Derecho: Favoritos (Corazón)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Consumer<FavoritosService>(
                      builder: (context, favService, _) {
                        final bool isFav = favService.esFavorito(widget.prenda.id);

                        return GestureDetector(
                          onTap: () async {
                            final nuevoEstado = await favService.toggleFavorito(widget.prenda);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        nuevoEstado ? Icons.favorite : Icons.favorite_border,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          nuevoEstado
                                              ? '${widget.prenda.nombre} guardada en Favoritos'
                                              : '${widget.prenda.nombre} eliminada de Favoritos',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                  duration: const Duration(milliseconds: 1200),
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.only(bottom: 75, left: 20, right: 20),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  backgroundColor: nuevoEstado ? const Color(0xFFE11D48) : const Color(0xFF0F172A),
                                ),
                              );
                            }
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                size: 16,
                                color: isFav ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Badge Inferior Derecho: ✨ IA 3D
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _handleIA3DTap(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome, size: 11, color: Color(0xFF38BDF8)),
                            const SizedBox(width: 4),
                            Text(
                              'IA 3D',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido Textual Inferior
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categoría Azul
                  Text(
                    (widget.prenda.categoriaNombre ?? 'COLECCIÓN').toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Título Serif
                  Text(
                    widget.prenda.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Tallas disponibles
                  Text(
                    tallasStr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.prenda.variantes.any((v) => v.color != 'Estándar' && v.color.isNotEmpty)) ...[
                    const SizedBox(height: 3),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: widget.prenda.variantes
                            .where((v) => v.color != 'Estándar' && v.color.isNotEmpty)
                            .map((v) {
                          final isSel = (v.imagenUrl != null && _cardImagePreview == v.imagenUrl) ||
                              (_cardImagePreview == null && v == widget.prenda.variantes.first);
                          return GestureDetector(
                            onTap: () {
                              if (v.imagenUrl != null && v.imagenUrl!.isNotEmpty) {
                                setState(() => _cardImagePreview = v.imagenUrl);
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isSel ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                v.color,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 8.5,
                                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                  color: isSel ? Colors.white : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),

                  // Fila Precio + Botón Negro [+]
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${widget.prenda.precio.toStringAsFixed(0)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _handleAddToCart(context),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F172A),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.add, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
