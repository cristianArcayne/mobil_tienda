import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../core/storage_service.dart';
import '../../services/auth_service.dart';
import '../home/main_navigation_screen.dart';
import 'recuperar_cuenta_screen.dart';
import 'registro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _obscureText = true;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  void _loadSavedCredentials() async {
    final remember = await StorageService.getRememberMe();
    final savedUsername = await StorageService.getSavedUsername();
    if (mounted) {
      setState(() {
        _rememberMe = remember;
        if (savedUsername != null && savedUsername.isNotEmpty) {
          _userController.text = savedUsername;
        }
      });
    }
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<AuthService>(context, listen: false);
      final ok = await auth.login(
        _userController.text.trim(),
        _passController.text.trim(),
        rememberMe: _rememberMe,
      );

      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '¡Bienvenido a FashionStore Atelier!',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (route) => false,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    auth.errorMessage ?? 'Error al iniciar sesión',
                    style: GoogleFonts.plusJakartaSans(),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _continuarComoInvitado() {
    final auth = Provider.of<AuthService>(context, listen: false);
    auth.enterAsGuest();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F5), // Tono atelier suave y cálido idéntico al mockup
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),

                // Encabezado de la marca (SIN botón de volver atrás, conforme a la maqueta)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40), // Espacio equilibrado
                    Column(
                      children: [
                        Text(
                          'F A S H I O N S T O R E',
                          style: AppTheme.logoStyle.copyWith(fontSize: 18, letterSpacing: 3.8),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ATELIER PRIVÉ',
                          style: AppTheme.atelierSubStyle.copyWith(fontSize: 9, letterSpacing: 3.5),
                        ),
                      ],
                    ),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(Icons.lock_outline, size: 18, color: AppTheme.primaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Badge "ACCESO EXCLUSIVO"
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFFD6C7BE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF6B3019),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ACCESO EXCLUSIVO',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.0,
                            color: const Color(0xFF6B3019),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Título Editorial
                Text(
                  'Iniciar Sesión',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ingrese a su cuenta de moda exclusiva',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Tarjeta principal del formulario
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFEFE9E3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Label: Correo Electrónico
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 16, color: Color(0xFF6B3019)),
                          const SizedBox(width: 8),
                          Text(
                            'CORREO ELECTRÓNICO O USUARIO',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: const Color(0xFF6B3019),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _userController,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'nombre@fashionstore.com o usuario',
                          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFFCBD5E1)),
                          prefixIcon: const Icon(Icons.alternate_email, size: 18, color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: const Color(0xFFFAF7F5),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE8DFD8)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE8DFD8)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.8),
                          ),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese su usuario o correo' : null,
                      ),
                      const SizedBox(height: 20),

                      // Label: Contraseña + ¿Olvidó su contraseña?
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.vpn_key_outlined, size: 16, color: Color(0xFF6B3019)),
                              const SizedBox(width: 8),
                              Text(
                                'CONTRASEÑA',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: const Color(0xFF6B3019),
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () async {
                              final returnedUser = await Navigator.push<String>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RecuperarCuentaScreen(
                                    initialUsername: _userController.text.trim(),
                                  ),
                                ),
                              );
                              if (returnedUser != null && returnedUser.isNotEmpty && mounted) {
                                _userController.text = returnedUser;
                              }
                            },
                            child: Text(
                              '¿Olvidó su contraseña?',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6B3019),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passController,
                        obscureText: _obscureText,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          hintText: '••••••••••••',
                          hintStyle: const TextStyle(letterSpacing: 4, color: Color(0xFFCBD5E1)),
                          prefixIcon: const Icon(Icons.lock_outline, size: 18, color: Color(0xFF94A3B8)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 19,
                              color: const Color(0xFF64748B),
                            ),
                            onPressed: () => setState(() => _obscureText = !_obscureText),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFFAF7F5),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE8DFD8)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE8DFD8)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.8),
                          ),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese su contraseña' : null,
                      ),
                      const SizedBox(height: 16),

                      // Checkbox Recordar mis datos + Atelier Seguro
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: Checkbox(
                                  value: _rememberMe,
                                  activeColor: AppTheme.primaryColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  onChanged: (val) {
                                    setState(() => _rememberMe = val ?? true);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Recordar mis datos',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.verified_user_outlined, size: 14, color: Color(0xFF6B3019)),
                              const SizedBox(width: 4),
                              Text(
                                'Atelier Seguro',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6B3019),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Botón Primario: INICIAR SESIÓN ➔
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.vpn_key_outlined, size: 18),
                                    const SizedBox(width: 10),
                                    Text(
                                      'INICIAR SESIÓN',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward, size: 16),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Divisor O BIEN
                      Row(
                        children: [
                          const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'O BIEN',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Botón Secundario: ENTRAR COMO INVITADO
                      SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _continuarComoInvitado,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFD6C7BE), width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            foregroundColor: AppTheme.primaryColor,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.storefront_outlined, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'ENTRAR COMO INVITADO',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Footer: ¿Desea una membresía privada? Solicitar Acceso
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿Desea una membresía privada? ',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegistroScreen()),
                        );
                      },
                      child: Text(
                        'Solicitar Acceso',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF6B3019),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
