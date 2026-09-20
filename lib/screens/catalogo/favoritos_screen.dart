import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/favoritos_service.dart';
import '../../widgets/prenda_card.dart';
import '../vestidor/vestidor_virtual_screen.dart';
import 'detalle_producto_screen.dart';

class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favService = Provider.of<FavoritosService>(context);
    final favoritos = favService.favoritos;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'M I S   F A V O R I T O S',
          style: AppTheme.logoStyle.copyWith(fontSize: 16, letterSpacing: 3.0),
        ),
        centerTitle: true,
        actions: [
          if (favoritos.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${favoritos.length} ${favoritos.length == 1 ? "prenda" : "prendas"}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => favService.cargarFavoritos(),
        color: AppTheme.primaryColor,
        child: favoritos.isEmpty
            ? _buildEmptyState(context)
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 18,
                        childAspectRatio: 0.58,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (ctx, index) {
                          final prenda = favoritos[index];
                          return PrendaCard(
                            prenda: prenda,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetalleProductoScreen(productoId: prenda.id),
                                ),
                              );
                            },
                            onProbarIA: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VestidorVirtualScreen(prendaInicial: prenda),
                                ),
                              );
                            },
                          );
                        },
                        childCount: favoritos.length,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFE4E6), width: 2),
              ),
              child: const Center(
                child: Icon(
                  Icons.favorite_rounded,
                  size: 44,
                  color: Color(0xFFF43F5E),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tu lista de deseos está vacía',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Guarda tus prendas favoritas tocando el icono de corazón en cualquier producto del catálogo para verlas aquí.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 0,
              ),
              child: Text(
                'EXPLORAR CATÁLOGO',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
