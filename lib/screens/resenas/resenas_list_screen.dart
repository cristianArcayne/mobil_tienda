import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/resenas_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/rating_stars.dart';
import '../auth/login_screen.dart';

class ResenasListScreen extends StatefulWidget {
  final int ropaId;
  final String prendaNombre;

  const ResenasListScreen({
    super.key,
    required this.ropaId,
    required this.prendaNombre,
  });

  @override
  State<ResenasListScreen> createState() => _ResenasListScreenState();
}

class _ResenasListScreenState extends State<ResenasListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ResenasService>(context, listen: false).cargarResenasPrenda(widget.ropaId);
    });
  }

  void _abrirDialogoAgregarResena() {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (!auth.isAuthenticated) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    int calificacion = 5;
    final comentarioCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Calificar Prenda'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.prendaNombre, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Tu Calificación:'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starVal = index + 1;
                  return IconButton(
                    icon: Icon(
                      starVal <= calificacion ? Icons.star : Icons.star_border,
                      color: const Color(0xFFF59E0B),
                      size: 32,
                    ),
                    onPressed: () => setDialogState(() => calificacion = starVal),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: comentarioCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Escribe tu opinión sobre la tela, el talle o la comodidad...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final auth = Provider.of<AuthService>(context, listen: false);
                final clienteNombre = auth.currentUser?.nombreCompleto ?? auth.currentUser?.username ?? 'Cliente App';
                final clienteCi = auth.currentUser?.username ?? '1001';

                final service = Provider.of<ResenasService>(context, listen: false);
                final ok = await service.crearResena(
                  ropaId: widget.ropaId,
                  calificacion: calificacion,
                  comentario: comentarioCtrl.text.trim(),
                  clienteCi: clienteCi,
                  clienteNombre: clienteNombre,
                );
                if (ok && ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('¡Gracias por tu reseña!')),
                  );
                }
              },
              child: const Text('Publicar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resenasService = Provider.of<ResenasService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Opiniones: ${widget.prendaNombre}'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF4F46E5),
        icon: const Icon(Icons.rate_review, color: Colors.white),
        label: const Text('Escribir Reseña', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _abrirDialogoAgregarResena,
      ),
      body: resenasService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : resenasService.resenas.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star_outline, size: 64, color: Color(0xFFCBD5E1)),
                      SizedBox(height: 16),
                      Text(
                        'Aún no hay reseñas para esta prenda',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '¡Sé el primero en compartir tu experiencia de compra!',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: resenasService.resenas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final r = resenasService.resenas[i];

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: const Color(0xFFEEF2FF),
                                      child: Text(
                                        r.clienteNombre.isNotEmpty ? r.clienteNombre[0].toUpperCase() : 'C',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(r.clienteNombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                RatingStars(rating: r.calificacion.toDouble(), size: 16),
                              ],
                            ),
                            if (r.comentario != null && r.comentario!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(r.comentario!, style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4)),
                            ],
                            const SizedBox(height: 6),
                            Text(r.fecha, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

