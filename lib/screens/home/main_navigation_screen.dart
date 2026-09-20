import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/carrito_service.dart';
import '../../services/notificaciones_service.dart';
import '../../widgets/guest_restriction_dialog.dart';
import '../catalogo/catalogo_screen.dart';
import '../vestidor/vestidor_virtual_screen.dart';
import '../ia/asistente_moda_screen.dart';
import '../carrito/carrito_screen.dart';
import '../auth/perfil_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<NotificacionesService>(context, listen: false).iniciarPolling(context);
      }
    });
  }

  final List<Widget> _screens = const [
    CatalogoScreen(),
    VestidorVirtualScreen(),
    AsistenteModaScreen(),
    CarritoScreen(),
    PerfilScreen(),
  ];

  void _onTabSelected(int index) {
    ScaffoldMessenger.of(context).clearSnackBars();
    // Si intenta acceder a Vestidor IA (index 1) y es invitado, bloquear y mostrar diálogo
    if (index == 1) {
      final auth = Provider.of<AuthService>(context, listen: false);
      if (!auth.isAuthenticated) {
        GuestRestrictionDialog.show(
          context,
          featureName: 'el Vestidor Virtual IA y Modelado 3D',
        );
        return;
      }
    }

    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CarritoService>(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabSelected,
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          items: [
            const BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.grid_view_outlined, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.grid_view, size: 22),
              ),
              label: 'CATÁLOGO',
            ),
            const BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.checkroom_outlined, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.checkroom, size: 22),
              ),
              label: 'VESTIDOR',
            ),
            const BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.auto_awesome_outlined, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.auto_awesome, size: 22),
              ),
              label: 'ESTILISTA',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Badge(
                  isLabelVisible: cart.cantidadTotal > 0,
                  backgroundColor: AppTheme.primaryColor,
                  label: Text(
                    '${cart.cantidadTotal}',
                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  child: const Icon(Icons.local_mall_outlined, size: 22),
                ),
              ),
              activeIcon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Badge(
                  isLabelVisible: cart.cantidadTotal > 0,
                  backgroundColor: AppTheme.primaryColor,
                  label: Text(
                    '${cart.cantidadTotal}',
                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  child: const Icon(Icons.local_mall, size: 22),
                ),
              ),
              label: 'BOLSA',
            ),
            const BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.person_outline, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.person, size: 22),
              ),
              label: 'PERFIL',
            ),
          ],
        ),
      ),
    );
  }
}
