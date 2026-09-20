import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _ciController = TextEditingController();

  bool _obscurePass = true;

  @override
  void dispose() {
    _userController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _ciController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<AuthService>(context, listen: false);
      final ok = await auth.registro(
        username: _userController.text.trim(),
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        telefono: _telefonoController.text.trim(),
        ci: _ciController.text.trim(),
      );

      if (ok && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              '¡Membresía Creada!',
              style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
            ),
            content: const Text(
              'Su cuenta ha sido creada exitosamente. Ya puede iniciar sesión para disfrutar de todos los beneficios exclusivos.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('INGRESAR A MI CUENTA'),
              ),
            ],
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Error al registrar usuario'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text('F A S H I O N S T O R E', style: AppTheme.logoStyle.copyWith(fontSize: 16)),
            Text('ATELIER PRIVÉ', style: AppTheme.atelierSubStyle.copyWith(fontSize: 8)),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                          'MEMBRESÍA PRIVADA',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: const Color(0xFF6B3019),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'Solicitar Acceso',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Complete sus datos para acceder al vestidor virtual, reservas exclusivas y catálogo de alta costura.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Form Container
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFEFE9E3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionTitle('DATOS PERSONALES'),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nombreController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre',
                                prefixIcon: Icon(Icons.person_outline, size: 18),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _apellidoController,
                              decoration: const InputDecoration(
                                labelText: 'Apellido',
                                prefixIcon: Icon(Icons.person_outline, size: 18),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ciController,
                              decoration: const InputDecoration(
                                labelText: 'C.I. / Documento',
                                prefixIcon: Icon(Icons.badge_outlined, size: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _telefonoController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Teléfono',
                                prefixIcon: Icon(Icons.phone_outlined, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      _buildSectionTitle('CREDENCIALES DE ACCESO'),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _userController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de Usuario',
                          prefixIcon: Icon(Icons.alternate_email, size: 18),
                        ),
                        validator: (v) => v == null || v.trim().length < 3 ? 'Mínimo 3 caracteres' : null,
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Correo Electrónico',
                          prefixIcon: Icon(Icons.email_outlined, size: 18),
                        ),
                        validator: (v) => v == null || !v.contains('@') ? 'Ingrese un email válido' : null,
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _passController,
                        obscureText: _obscurePass,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline, size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 19,
                            ),
                            onPressed: () => setState(() => _obscurePass = !_obscurePass),
                          ),
                        ),
                        validator: (v) => v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
                      ),
                      const SizedBox(height: 26),

                      // Botón Solicitar Membresía
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                    const Icon(Icons.verified_outlined, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'SOLICITAR MEMBRESÍA',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.arrow_forward, size: 16),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Link to Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿Ya tiene una cuenta privada? ',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Iniciar Sesión',
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
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
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
}
