import 'package:flutter/material.dart';

class StockBadge extends StatelessWidget {
  final String estado;
  final int? unidades;

  const StockBadge({
    super.key,
    required this.estado,
    this.unidades,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (estado.toUpperCase()) {
      case 'DISPONIBLE':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        label = unidades != null ? '$unidades en stock' : 'Disponible';
        icon = Icons.check_circle_outline;
        break;
      case 'ULTIMAS_UNIDADES':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        label = unidades != null ? '¡Solo $unidades!' : 'Últimas unidades';
        icon = Icons.warning_amber_rounded;
        break;
      case 'AGOTADO':
      default:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        label = 'Agotado';
        icon = Icons.cancel_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

