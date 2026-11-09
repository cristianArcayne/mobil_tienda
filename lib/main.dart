import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'services/auth_service.dart';
import 'services/catalogo_service.dart';
import 'services/carrito_service.dart';
import 'services/reservas_service.dart';
import 'services/ventas_service.dart';
import 'services/vestidor_service.dart';
import 'services/ia_service.dart';
import 'services/resenas_service.dart';
import 'services/promociones_service.dart';
import 'services/notificaciones_service.dart';
import 'services/favoritos_service.dart';
import 'services/sync_service.dart';
import 'screens/home/main_navigation_screen.dart';
import 'screens/auth/login_screen.dart';
import 'core/storage_service.dart';
import 'config/environment.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar host personalizado si fue configurado previamente
  final savedHost = await StorageService.getServerHost();
  if (savedHost != null && savedHost.isNotEmpty) {
    Environment.setCustomHost(savedHost);
  }

  // Instanciar servicios con aislamiento estricto por usuario
  final authService = AuthService();
  final favoritosService = FavoritosService();
  final carritoService = CarritoService();
  final reservasService = ReservasService();
  final ventasService = VentasService();
  final notificacionesService = NotificacionesService();
  final syncService = SyncService();

  // Escuchar cambios de sesión (Login, Cambio de Usuario, Invitado o Logout)
  // para limpiar inmediatamente datos del usuario anterior y cargar únicamente los del nuevo usuario
  authService.addSessionChangeListener((user) {
    final uidStr = user?.identificadorUnico ?? 'guest';
    favoritosService.cambiarUsuarioActivo(uidStr);
    carritoService.cambiarUsuarioActivo(uidStr);
    reservasService.cambiarUsuarioActivo(user?.identificadorUnico);
    ventasService.cambiarUsuarioActivo(user?.identificadorUnico);
    notificacionesService.cambiarUsuarioActivo(user?.id);
    syncService.cambiarUsuarioActivo(uidStr);
  });

  // Precargar sesión de usuario para evitar saltos o parpadeos en pantalla
  await authService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ChangeNotifierProvider(create: (_) => CatalogoService()),
        ChangeNotifierProvider<FavoritosService>.value(value: favoritosService),
        ChangeNotifierProvider(create: (_) => PromocionesService()),
        ChangeNotifierProvider<CarritoService>.value(value: carritoService),
        ChangeNotifierProvider<ReservasService>.value(value: reservasService),
        ChangeNotifierProvider<VentasService>.value(value: ventasService),
        ChangeNotifierProvider(create: (_) => VestidorService()),
        ChangeNotifierProvider(create: (_) => IAService()),
        ChangeNotifierProvider(create: (_) => ResenasService()),
        ChangeNotifierProvider<NotificacionesService>.value(value: notificacionesService),
        ChangeNotifierProvider<SyncService>.value(value: syncService),
      ],
      child: const FashionStoreApp(),
    ),
  );
}

class FashionStoreApp extends StatelessWidget {
  const FashionStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FashionStore Atelier Móvil',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        // En emuladores anchos o navegadores web, centra la aplicación simulando pantalla de smartphone
        return Container(
          color: const Color(0xFF0F172A),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: child != null ? ClipRect(child: child) : const SizedBox.shrink(),
            ),
          ),
        );
      },
      home: const RootScreenDecider(),
    );
  }
}

class RootScreenDecider extends StatelessWidget {
  const RootScreenDecider({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    // Si está autenticado o decidió entrar como invitado, entra al Home
    if (auth.isAuthenticated || auth.isGuest) {
      return const MainNavigationScreen();
    }

    // Por defecto, muestra la pantalla de inicio de sesión exclusivo
    return const LoginScreen();
  }
}
