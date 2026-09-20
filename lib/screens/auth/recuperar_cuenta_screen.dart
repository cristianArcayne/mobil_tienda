import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';

class RecuperarCuentaScreen extends StatefulWidget {
  final String? initialUsername;
  const RecuperarCuentaScreen({super.key, this.initialUsername});

  @override
  State<RecuperarCuentaScreen> createState() => _RecuperarCuentaScreenState();
}

class _RecuperarCuentaScreenState extends State<RecuperarCuentaScreen> {
  int _currentStep = 1; // 1: Usuario/Email, 2: Código 6 dígitos, 3: Nueva Contraseña
  final _formKeyPaso1 = GlobalKey<FormState>();
  final _formKeyPaso2 = GlobalKey<FormState>();
  final _formKeyPaso3 = GlobalKey<FormState>();

  final _userOrEmailController = TextEditingController();
  final _codigoController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;
  String? _serverMessage;

  // Temporizador para reenvío (15 minutos = 900s)
  int _secondsLeft = 900;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.initialUsername != null && widget.initialUsername!.isNotEmpty) {
      _userOrEmailController.text = widget.initialUsername!;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _userOrEmailController.dispose();
    _codigoController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = 900;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        if (mounted) setState(() => _secondsLeft--);
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTimer() {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Paso 1: Solicitar código
  void _solicitarCodigo() async {
    if (!_formKeyPaso1.currentState!.validate()) return;
    final auth = Provider.of<AuthService>(context, listen: false);

    final res = await auth.solicitarCodigoRecuperacion(_userOrEmailController.text.trim());

    if (res != null && mounted) {
      setState(() {
        _currentStep = 2;
        _serverMessage = res['mensaje']?.toString();
      });
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_serverMessage ?? 'Código enviado a su correo exitosamente'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'No se encontró la cuenta ingresada'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  // Paso 2: Verificar código
  void _verificarCodigo() async {
    if (!_formKeyPaso2.currentState!.validate()) return;
    final auth = Provider.of<AuthService>(context, listen: false);

    final ok = await auth.verificarCodigoRecuperacion(
      _userOrEmailController.text.trim(),
      _codigoController.text.trim(),
    );

    if (ok && mounted) {
      setState(() {
        _currentStep = 3;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código verificado con éxito. Ahora define tu nueva contraseña.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Código inválido o expirado'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  // Paso 3: Cambiar contraseña
  void _cambiarPassword() async {
    if (!_formKeyPaso3.currentState!.validate()) return;
    final auth = Provider.of<AuthService>(context, listen: false);

    final ok = await auth.cambiarPasswordRecuperacion(
      usernameOrEmail: _userOrEmailController.text.trim(),
      codigo: _codigoController.text.trim(),
      nuevaPassword: _newPasswordController.text.trim(),
    );

    if (ok && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            '¡Contraseña Actualizada!',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'Tu contraseña se ha restablecido correctamente. Ya puedes iniciar sesión con tu nueva credencial.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context, _userOrEmailController.text.trim());
              },
              child: const Text('IR A INICIAR SESIÓN'),
            ),
          ],
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Error al actualizar la contraseña'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
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
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.accentIndigo,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'RECUPERACIÓN SEGURA',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Recuperar Cuenta',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Restablezca el acceso a su cuenta exclusiva en tres simples pasos.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Indicador de Pasos
              _buildStepIndicator(),
              const SizedBox(height: 24),

              // Contenedor según paso
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(22),
                child: _buildCurrentStepForm(auth),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepBadge(1, 'Usuario'),
        _buildStepDivider(_currentStep >= 2),
        _buildStepBadge(2, 'Código'),
        _buildStepDivider(_currentStep >= 3),
        _buildStepBadge(3, 'Contraseña'),
      ],
    );
  }

  Widget _buildStepBadge(int step, String label) {
    final isDone = _currentStep > step;
    final isCurrent = _currentStep == step;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCurrent
                ? AppTheme.primaryColor
                : (isDone ? const Color(0xFF10B981) : const Color(0xFFF1F5F9)),
            border: Border.all(
              color: isCurrent
                  ? AppTheme.primaryColor
                  : (isDone ? const Color(0xFF10B981) : const Color(0xFFCBD5E1)),
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '$step',
                    style: GoogleFonts.plusJakartaSans(
                      color: isCurrent ? Colors.white : AppTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: isCurrent ? AppTheme.textPrimary : AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(bool isActive) {
    return Container(
      width: 36,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      color: isActive ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
    );
  }

  Widget _buildCurrentStepForm(AuthService auth) {
    switch (_currentStep) {
      case 1:
        return Form(
          key: _formKeyPaso1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'CORREO ELECTRÓNICO O USUARIO',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _userOrEmailController,
                decoration: const InputDecoration(
                  hintText: 'nombre@fashionstore.com o usuario',
                  prefixIcon: Icon(Icons.alternate_email, size: 20, color: AppTheme.textMuted),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese su usuario o correo' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: auth.isLoading ? null : _solicitarCodigo,
                child: auth.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text('ENVIAR CÓDIGO', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
              ),
            ],
          ),
        );

      case 2:
        return Form(
          key: _formKeyPaso2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'CÓDIGO DE VERIFICACIÓN (6 DÍGITOS)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _codigoController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  letterSpacing: 8,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '000000',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    letterSpacing: 8,
                    color: const Color(0xFFCBD5E1),
                  ),
                  prefixIcon: const Icon(Icons.pin_outlined, size: 20, color: AppTheme.textMuted),
                ),
                validator: (v) {
                  if (v == null || v.trim().length != 6) return 'Ingrese el código de 6 dígitos';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mark_email_read_outlined, size: 18, color: AppTheme.accentIndigo),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Hemos enviado el código a su correo. Revise su bandeja de entrada o spam.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Expira en: ${_formatTimer()}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  TextButton(
                    onPressed: _secondsLeft == 0 ? _solicitarCodigo : null,
                    child: Text(
                      'Reenviar código',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _secondsLeft == 0 ? AppTheme.accentIndigo : AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: auth.isLoading ? null : _verificarCodigo,
                child: auth.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 18),
                          const SizedBox(width: 8),
                          Text('VERIFICAR CÓDIGO', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
              ),
            ],
          ),
        );

      case 3:
        return Form(
          key: _formKeyPaso3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'NUEVA CONTRASEÑA',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPass,
                decoration: InputDecoration(
                  hintText: 'Mínimo 6 caracteres',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppTheme.textMuted),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNewPass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                    onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().length < 6) return 'Debe tener al menos 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'CONFIRMAR NUEVA CONTRASEÑA',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPass,
                decoration: InputDecoration(
                  hintText: 'Repita la nueva contraseña',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppTheme.textMuted),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                    onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                  ),
                ),
                validator: (v) {
                  if (v != _newPasswordController.text) return 'Las contraseñas no coinciden';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: auth.isLoading ? null : _cambiarPassword,
                child: auth.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.key, size: 18),
                          const SizedBox(width: 8),
                          Text('ACTUALIZAR CONTRASEÑA', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

