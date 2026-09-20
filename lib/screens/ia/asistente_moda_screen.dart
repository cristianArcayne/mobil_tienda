import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/ia_service.dart';
import '../catalogo/detalle_producto_screen.dart';

class AsistenteModaScreen extends StatefulWidget {
  const AsistenteModaScreen({super.key});

  @override
  State<AsistenteModaScreen> createState() => _AsistenteModaScreenState();
}

class _AsistenteModaScreenState extends State<AsistenteModaScreen> {
  final _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _sugerenciasRapidas = [
    '👗 Outfit para una boda de noche',
    '✨ Ropa casual para fin de semana',
    '🔥 Prendas en descuento hoy',
    '👖 ¿Qué me pongo con un pantalón negro?',
    '💎 Look elegante para graduación',
    '🌸 Vestidos frescos de temporada',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _enviar(String msg) {
    if (msg.trim().isEmpty) return;
    _textController.clear();
    final ia = Provider.of<IAService>(context, listen: false);
    ia.enviarMensaje(msg.trim());

    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ia = Provider.of<IAService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B4B),
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 12),
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFF6366F1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'FashionStore AI Assistant',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'En línea • Personal Shopper & Estilista',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: const Color(0xFFA5B4FC),
                          fontWeight: FontWeight.w500,
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
      body: Column(
        children: [
          // Mensajes de la conversación
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              itemCount: ia.mensajes.length,
              itemBuilder: (ctx, i) {
                final m = ia.mensajes[i];
                final timeStr = "${m.timestamp.hour.toString().padLeft(2, '0')}:${m.timestamp.minute.toString().padLeft(2, '0')}";

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: m.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!m.isUser) ...[
                        Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.only(right: 8, top: 2),
                          decoration: const BoxDecoration(
                            color: Color(0xFF4F46E5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                        ),
                      ],
                      Flexible(
                        child: Column(
                          crossAxisAlignment: m.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                              decoration: BoxDecoration(
                                color: m.isUser ? const Color(0xFF4F46E5) : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(18),
                                  topRight: const Radius.circular(18),
                                  bottomLeft: m.isUser ? const Radius.circular(18) : const Radius.circular(4),
                                  bottomRight: m.isUser ? const Radius.circular(4) : const Radius.circular(18),
                                ),
                                border: m.isUser ? null : Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.text,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: m.isUser ? Colors.white : const Color(0xFF1E293B),
                                      fontSize: 13.5,
                                      height: 1.45,
                                      fontWeight: m.isUser ? FontWeight.w500 : FontWeight.w400,
                                    ),
                                  ),
                                  if (m.prendasSugeridas != null && m.prendasSugeridas!.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Prendas Recomendadas del Catálogo:',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF4F46E5),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    ...m.prendasSugeridas!.map((p) => Container(
                                      margin: const EdgeInsets.only(top: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.checkroom, color: Color(0xFF4F46E5), size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  p.nombre,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                ),
                                                Text(
                                                  'Bs. ${p.precio.toStringAsFixed(2)}',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                    color: const Color(0xFF059669),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF4F46E5)),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (_) => DetalleProductoScreen(prendaId: p.id)),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    )),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeStr,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (m.isUser) ...[
                        Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.only(left: 8, top: 2),
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F172A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, color: Colors.white, size: 17),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          // Indicador de "Escribiendo..."
          if (ia.isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'El asistente está respondiendo...',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Sugerencias Rápidas Desplazables (Chips estilo web)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: Text(
                    'Sugerencias rápidas:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _sugerenciasRapidas.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final s = _sugerenciasRapidas[i];
                      return InkWell(
                        onTap: () => _enviar(s),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFC7D2FE)),
                          ),
                          child: Text(
                            s,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4338CA),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Barra de entrada de texto
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: TextField(
                        controller: _textController,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                        decoration: InputDecoration(
                          hintText: 'Pregunta sobre prendas, ocasiones o precios...',
                          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: InputBorder.none,
                        ),
                        onSubmitted: _enviar,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4F46E5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: () => _enviar(_textController.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
