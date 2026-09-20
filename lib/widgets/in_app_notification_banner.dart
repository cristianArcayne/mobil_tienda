import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

class InAppNotificationBanner {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    String? tipo,
    VoidCallback? onTap,
  }) {
    // Si ya hay una visible, removerla
    _dismissTimer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;

    final overlayState = Overlay.of(context, rootOverlay: true);

    _currentEntry = OverlayEntry(
      builder: (context) => _NotificationPopupWidget(
        title: title,
        message: message,
        tipo: tipo ?? 'PROMOCION',
        onDismiss: () {
          _dismissTimer?.cancel();
          _currentEntry?.remove();
          _currentEntry = null;
        },
        onTap: () {
          _dismissTimer?.cancel();
          _currentEntry?.remove();
          _currentEntry = null;
          if (onTap != null) onTap();
        },
      ),
    );

    overlayState.insert(_currentEntry!);

    // Auto ocultar después de 4.5 segundos
    _dismissTimer = Timer(const Duration(milliseconds: 4500), () {
      _currentEntry?.remove();
      _currentEntry = null;
    });
  }
}

class _NotificationPopupWidget extends StatefulWidget {
  final String title;
  final String message;
  final String tipo;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _NotificationPopupWidget({
    required this.title,
    required this.message,
    required this.tipo,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  State<_NotificationPopupWidget> createState() => _NotificationPopupWidgetState();
}

class _NotificationPopupWidgetState extends State<_NotificationPopupWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInQuad,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.forward();
  }

  void _cerrarConAnimacion() {
    _animController.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  IconData _getIcon() {
    final t = widget.tipo.toUpperCase();
    if (t.contains('COMPRA') || t.contains('VENTA')) return Icons.shopping_bag_outlined;
    if (t.contains('RESERVA')) return Icons.storefront_outlined;
    if (t.contains('PROMO') || t.contains('DESCUENTO')) return Icons.local_offer_outlined;
    return Icons.notifications_active_outlined;
  }

  Color _getBadgeColor() {
    final t = widget.tipo.toUpperCase();
    if (t.contains('COMPRA')) return const Color(0xFF0D9488);
    if (t.contains('RESERVA')) return const Color(0xFFD97706);
    if (t.contains('PROMO')) return const Color(0xFFE11D48);
    return AppTheme.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 8,
      left: 14,
      right: 14,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: widget.onTap,
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta != null && details.primaryDelta! < -5) {
                  _cerrarConAnimacion();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.08), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icono avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getBadgeColor().withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIcon(),
                        color: _getBadgeColor(),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Contenido del mensaje (WhatsApp / Heads-Up style)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'FashionStore',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textMuted,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              Text(
                                'Ahora',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.message,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Botón de cerrar
                    InkWell(
                      onTap: _cerrarConAnimacion,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
