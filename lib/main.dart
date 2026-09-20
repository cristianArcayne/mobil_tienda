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

  // Precargar sesión de usuario para evitar saltos o parpadeos en pantalla
  final authService = AuthService();
  await authService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ChangeNotifierProvider(create: (_) => CatalogoService()),
        ChangeNotifierProvider(create: (_) => FavoritosService()),
        ChangeNotifierProvider(create: (_) => PromocionesService()),
        ChangeNotifierProvider(create: (_) => CarritoService()),
        ChangeNotifierProvider(create: (_) => ReservasService()),
        ChangeNotifierProvider(create: (_) => VentasService()),
        ChangeNotifierProvider(create: (_) => VestidorService()),
        ChangeNotifierProvider(create: (_) => IAService()),
        ChangeNotifierProvider(create: (_) => ResenasService()),
        ChangeNotifierProvider(create: (_) => NotificacionesService()),
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
