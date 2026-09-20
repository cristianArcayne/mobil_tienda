import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/usuario_model.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';
import 'recuperar_cuenta_screen.dart';
import 'registro_screen.dart';
import '../reservas/reservas_screen.dart';
import '../ventas/historial_compras_screen.dart';
import '../ia/asistente_moda_screen.dart';
import '../catalogo/favoritos_screen.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          children: [
            Text('F A S H I O N S T O R E', style: AppTheme.logoStyle.copyWith(fontSize: 17)),
            Text('ATELIER PRIVÉ', style: AppTheme.atelierSubStyle.copyWith(fontSize: 8)),
          ],
        ),
        centerTitle: true,
        actions: [
          if (auth.isAuthenticated)
            IconButton(
              tooltip: 'Cerrar Sesión',
              icon: const Icon(Icons.logout, color: AppTheme.errorColor),
              onPressed: () => _confirmLogout(context, auth),
            ),
        ],
      ),
      body: auth.isAuthenticated && user != null
          ? _buildUserProfile(context, auth, user)
          : _buildGuestView(context),
    );
  }

  Widget _buildUserProfile(BuildContext context, AuthService auth, dynamic user) {
    final initials = user.nombreCompleto.isNotEmpty
        ? user.nombreCompleto.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'U';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero Profile Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEFE9E3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFD6C7BE), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user.nombreCompleto,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars, size: 14, color: AppTheme.accentIndigo),
                      const SizedBox(width: 6),
                      Text(
                        (user.rol ?? 'MEMBRESÍA VIP').toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (user.clienteId != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'ID Cliente: #${user.clienteId}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sección de Actividad
          _buildSectionHeader('ACTIVIDAD EXCLUSIVA'),
          const SizedBox(height: 10),
          _buildMenuTile(
            icon: Icons.favorite_outline,
            title: 'Mis Favoritos',
            subtitle: 'Prendas y looks guardados en su lista de deseos',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritosScreen()));
            },
          ),
          const SizedBox(height: 8),
          _buildMenuTile(
            icon: Icons.storefront_outlined,
            title: 'Mis Reservas Web-to-Store',
            subtitle: 'Prendas reservadas para retiro y pago en sucursal',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ReservasScreen()));
            },
          ),
          const SizedBox(height: 8),
          _buildMenuTile(
            icon: Icons.receipt_long_outlined,
            title: 'Historial de Compras Digitales',
            subtitle: 'Facturas electrónicas y pedidos en línea',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistorialComprasScreen()),
              );
            },
          ),
          const SizedBox(height: 24),

          // Sección Seguridad & Preferencias
          _buildSectionHeader('INFORMACIÓN PERSONAL Y CUENTA'),
          const SizedBox(height: 10),
          _buildMenuTile(
            icon: Icons.person_outline,
            title: 'Mis Datos Personales y Dirección',
            subtitle: 'Actualizar nombre, apellidos y dirección de entrega',
            onTap: () => _mostrarEditarPerfilModal(context, auth, user),
          ),
          const SizedBox(height: 8),
          _buildMenuTile(
            icon: Icons.lock_reset_outlined,
            title: 'Cambiar o Recuperar Contraseña',
            subtitle: 'Actualizar la clave secreta de su cuenta',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecuperarCuentaScreen(initialUsername: user.username),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _buildMenuTile(
            icon: Icons.auto_awesome_outlined,
            title: 'Asistente y Ayuda de Estilo IA',
            subtitle: 'Recomendaciones de outfits y estilismo inteligente',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AsistenteModaScreen()),
              );
            },
          ),
          const SizedBox(height: 32),

          // Botón Cerrar Sesión Destacado
          SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: () => _confirmLogout(context, auth),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.errorColor, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                foregroundColor: AppTheme.errorColor,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout, size: 18, color: AppTheme.errorColor),
                  const SizedBox(width: 8),
                  Text(
                    'CERRAR SESIÓN',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.person_outline, size: 40, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 24),
            Text(
              'Bienvenido a FashionStore',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Inicia sesión o crea una cuenta para acceder a tu historial de compras, guardar reservas en tienda física y desbloquear el Vestidor Virtual IA.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.vpn_key_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'INICIAR SESIÓN',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistroScreen()));
                },
                child: Text(
                  'SOLICITAR MEMBRESÍA',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    fontSize: 13,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 3, height: 14, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEFE9E3)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          title: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20),
          onTap: onTap,
        ),
      ),
    );
  }

  void _mostrarEditarPerfilModal(BuildContext context, AuthService auth, UsuarioModel user) {
    final nombreCtrl = TextEditingController(text: user.nombre ?? '');
    final apellidoCtrl = TextEditingController(text: user.apellido ?? '');
    final direccionCtrl = TextEditingController(text: user.direccion ?? '');
    final telefonoCtrl = TextEditingController(text: user.telefono ?? '');
    final emailCtrl = TextEditingController(text: user.email);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mis Datos Personales',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Text(
                  'Actualiza tus datos para tus pedidos y entregas a domicilio.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 20),

                // Nombres y Apellidos
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: nombreCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon: const Icon(Icons.person_outline, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: apellidoCtrl,
                        decoration: InputDecoration(
                          labelText: 'Apellido',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Dirección de entrega
                TextField(
                  controller: direccionCtrl,
                  decoration: InputDecoration(
                    labelText: 'Dirección de Entrega',
                    hintText: 'Ej. Av. San Martín #450, Equipetrol',
                    prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                // Teléfono de contacto
                TextField(
                  controller: telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Teléfono / WhatsApp',
                    hintText: 'Ej. +591 71234567',
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                // Correo electrónico
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico',
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),

                // Botón Guardar
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (nombreCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Por favor ingresa tu nombre.')),
                        );
                        return;
                      }

                      final ok = await auth.actualizarPerfil(
                        nombre: nombreCtrl.text.trim(),
                        apellido: apellidoCtrl.text.trim(),
                        direccion: direccionCtrl.text.trim(),
                        telefono: telefonoCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                      );

                      if (ok && ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('¡Datos de perfil actualizados exitosamente!'),
                            backgroundColor: Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(milliseconds: 1500),
                          ),
                        );
                      } else if (ctx.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(auth.errorMessage ?? 'Error al actualizar perfil'),
                            backgroundColor: const Color(0xFFEF4444),
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Guardar Cambios',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cerrar Sesión',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
        ),
        content: const Text('¿Está seguro de que desea salir de su cuenta exclusiva?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.logout();
            },
            child: Text(
              'Salir',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
