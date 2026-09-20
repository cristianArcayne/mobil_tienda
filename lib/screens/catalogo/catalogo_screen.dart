import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/carrito_service.dart';
import '../../services/catalogo_service.dart';
import '../../services/notificaciones_service.dart';
import '../../widgets/guest_restriction_dialog.dart';
import '../../widgets/prenda_card.dart';
import '../auth/login_screen.dart';
import '../auth/perfil_screen.dart';
import '../carrito/carrito_screen.dart';
import '../notificaciones/notificaciones_screen.dart';
import '../vestidor/vestidor_virtual_screen.dart';
import 'detalle_producto_screen.dart';

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  final _searchController = TextEditingController();
  int? _selectedCategory;
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = Provider.of<CatalogoService>(context, listen: false);
      service.cargarCategorias();
      service.cargarCatalogo();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String val) {
    Provider.of<CatalogoService>(context, listen: false).cargarCatalogo(
      categoriaId: _selectedCategory,
      buscar: val.trim().isNotEmpty ? val.trim() : null,
    );
  }

  void _onSelectCat(int? catId) {
    setState(() => _selectedCategory = catId);
    Provider.of<CatalogoService>(context, listen: false).cargarCatalogo(
      categoriaId: catId,
      buscar: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
    );
  }

  void _abrirVestidorIA() {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (!auth.isAuthenticated) {
      GuestRestrictionDialog.show(
        context,
        featureName: 'el Vestidor Virtual IA y Modelado 3D',
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VestidorVirtualScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final catService = Provider.of<CatalogoService>(context);
    final auth = Provider.of<AuthService>(context);
    final cart = Provider.of<CarritoService>(context);

    // Lista de categorías para los pills horizontales
    final List<Map<String, dynamic>> categoriasUi = [
      {'id': null, 'nombre': 'TODOS'},
      {'id': -1, 'nombre': 'COLECCIÓN SS25'},
      {'id': -2, 'nombre': 'DENIM & JEANS'},
      {'id': -3, 'nombre': 'SASTRERÍA'},
      ...catService.categorias.map((c) => {'id': c.id, 'nombre': c.nombre.toUpperCase()}),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'F A S H I O N S T O R E',
          style: AppTheme.logoStyle.copyWith(fontSize: 17, letterSpacing: 4.0),
        ),
        centerTitle: true,
        actions: [
          Consumer<NotificacionesService>(
            builder: (context, notifService, _) => IconButton(
              icon: Badge(
                isLabelVisible: notifService.notificaciones.isNotEmpty,
                backgroundColor: const Color(0xFFE11D48),
                label: Text(
                  '${notifService.notificaciones.length}',
                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                child: const Icon(Icons.notifications_none_outlined, color: AppTheme.textPrimary, size: 22),
              ),
              tooltip: 'Centro de Notificaciones',
              onPressed: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificacionesScreen()),
                );
              },
            ),
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: cart.cantidadTotal > 0,
              backgroundColor: AppTheme.primaryColor,
              label: Text('${cart.cantidadTotal}'),
              child: const Icon(Icons.local_mall_outlined, color: AppTheme.textPrimary, size: 22),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).clearSnackBars();
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CarritoScreen()));
            },
          ),
          IconButton(
            icon: Icon(
              auth.isAuthenticated ? Icons.account_circle : Icons.account_circle_outlined,
              color: auth.isAuthenticated ? AppTheme.accentIndigo : AppTheme.textPrimary,
              size: 24,
            ),
            onPressed: () {
              if (!auth.isAuthenticated) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PerfilScreen()));
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await catService.cargarCategorias();
          await catService.cargarCatalogo(
            categoriaId: _selectedCategory,
            buscar: _searchController.text,
          );
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),

              // Barra de Búsqueda Pill (con icono de cámara y filtros)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      const Icon(Icons.search, size: 20, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearch,
                          onSubmitted: _onSearch,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Buscar por estilo, color o prenda...',
                            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF94A3B8)),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Color(0xFF94A3B8)),
                          tooltip: 'Borrar búsqueda',
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                            setState(() {});
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.camera_alt_outlined, size: 20, color: Color(0xFF64748B)),
                        tooltip: 'Búsqueda visual',
                        onPressed: () => _abrirVestidorIA(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.tune, size: 20, color: Color(0xFF64748B)),
                        tooltip: 'Limpiar filtros',
                        onPressed: () {
                          _searchController.clear();
                          _onSelectCat(null);
                        },
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Chips de Categorías Horizontales
              SizedBox(
                height: 38,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: categoriasUi.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final c = categoriasUi[i];
                    final isSelected = _selectedCategory == c['id'];

                    return GestureDetector(
                      onTap: () => _onSelectCat(c['id'] is int && c['id'] > 0 ? c['id'] : null),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            c['nombre'],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isSelected ? Colors.white : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Hero Banner: "Nueva Temporada: La Esencia del Denim"
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 190,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?auto=format&fit=crop&w=900&q=80',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.85),
                              Colors.black.withValues(alpha: 0.35),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      // Textos del Hero
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'CURADURÍA EXCLUSIVA',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                color: const Color(0xFF38BDF8),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Nueva Temporada: La Esencia del Denim',
                                        style: GoogleFonts.playfairDisplay(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Cortes rectos, lavados minerales e hilos premium',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: const Color(0xFFCBD5E1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.arrow_forward, size: 18, color: Colors.white),
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
              ),
              const SizedBox(height: 14),

              // Banner Interactivo: VESTIDOR VIRTUAL IA
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                        ),
                        child: const Center(
                          child: Icon(Icons.auto_awesome, size: 20, color: Color(0xFF38BDF8)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'VESTIDOR VIRTUAL IA',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF38BDF8),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Pruébate prendas en vivo con IA...',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _abrirVestidorIA,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                        ),
                        child: Text(
                          'PROBAR AHORA',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Encabezado Selección Esencial
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selección Esencial',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${catService.prendas.length} prendas disponibles para entrega hoy',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        _isGridView ? Icons.grid_view_outlined : Icons.view_agenda_outlined,
                        color: AppTheme.textPrimary,
                        size: 22,
                      ),
                      onPressed: () => setState(() => _isGridView = !_isGridView),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Grid de Productos
              if (catService.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                )
              else if (catService.prendas.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.checkroom_outlined, size: 54, color: Color(0xFFCBD5E1)),
                        const SizedBox(height: 14),
                        Text(
                          'No hay prendas en esta categoría',
                          style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: () => _onSelectCat(null),
                          child: const Text('Ver catálogo completo'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _isGridView ? 2 : 1,
                      childAspectRatio: _isGridView ? 0.62 : 1.3,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: catService.prendas.length,
                    itemBuilder: (ctx, i) {
                      final prenda = catService.prendas[i];
                      return PrendaCard(
                        prenda: prenda,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetalleProductoScreen(prendaId: prenda.id),
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
                  ),
                ),
              const SizedBox(height: 24),

              // Widget: RECOMENDADO POR TU ESTILISTA IA
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F7FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD6E8FE)),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Estilista
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0F172A),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(Icons.psychology_outlined, size: 18, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'RECOMENDADO POR TU ESTILISTA IA',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    'Look Completo: \'Urban Tailored Casual\'',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF93C5FD)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.auto_awesome, size: 12, color: Color(0xFF2563EB)),
                                const SizedBox(width: 4),
                                Text(
                                  '98% Match',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 3 Mini Prendas
                      Row(
                        children: [
                          _buildOutfitThumbnail(
                            'Blazer Lino',
                            '\$129.990',
                            'https://images.unsplash.com/photo-1598808503746-f34c53b9323e?auto=format&fit=crop&w=300&q=80',
                          ),
                          const SizedBox(width: 10),
                          _buildOutfitThumbnail(
                            'Polera Oversize',
                            '\$29.990',
                            'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?auto=format&fit=crop&w=300&q=80',
                          ),
                          const SizedBox(width: 10),
                          _buildOutfitThumbnail(
                            'Jeans Selvedge',
                            '\$64.990',
                            'https://images.unsplash.com/photo-1542272604-780c96856592?auto=format&fit=crop&w=300&q=80',
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Total y Botón Probar Conjunto
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SET COMPLETO (3 PRENDAS)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                '\$224.970',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: _abrirVestidorIA,
                            icon: const Icon(Icons.checkroom, size: 16),
                            label: Text(
                              'PROBAR CONJUNTO',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutfitThumbnail(String name, String price, String imgUrl) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  imgUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFF1F5F9),
                    child: const Icon(Icons.checkroom, color: Color(0xFF94A3B8)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.playfairDisplay(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              price,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
