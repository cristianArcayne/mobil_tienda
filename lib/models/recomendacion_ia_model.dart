import 'prenda_model.dart';

class ChatMessageModel {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<PrendaModel>? prendasSugeridas;

  ChatMessageModel({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.prendasSugeridas,
  });
}

class OutfitRecomendadoModel {
  final String id;
  final String titulo;
  final String estilo;
  final String descripcionEstilistica;
  final double precioTotalEstimado;
  final double scoreAfinidad;
  final List<PrendaModel> prendas;

  OutfitRecomendadoModel({
    required this.id,
    required this.titulo,
    required this.estilo,
    required this.descripcionEstilistica,
    required this.precioTotalEstimado,
    this.scoreAfinidad = 98.0,
    required this.prendas,
  });

  factory OutfitRecomendadoModel.fromJson(Map<String, dynamic> json) {
    List<PrendaModel> listaPrendas = [];

    // 1. Extraer prenda principal si existe
    if (json['prenda_principal'] != null && json['prenda_principal'] is Map) {
      listaPrendas.add(PrendaModel.fromJson(json['prenda_principal'] as Map<String, dynamic>));
    }

    // 2. Extraer prendas complementarias si existen
    if (json['prendas_complementarias'] is List) {
      for (var item in (json['prendas_complementarias'] as List)) {
        if (item is Map<String, dynamic>) {
          listaPrendas.add(PrendaModel.fromJson(item));
        }
      }
    }

    // 3. Fallback a otras listas
    if (listaPrendas.isEmpty) {
      var rawPrendas = json['prendas'] as List? ?? json['prendas_sugeridas'] as List? ?? [];
      listaPrendas = rawPrendas.map((p) => PrendaModel.fromJson(p as Map<String, dynamic>)).toList();
    }

    final double precioTotal = double.tryParse(
          (json['precio_final_con_descuento'] ?? json['precio_total_outfit'] ?? json['precio_total_estimado'] ?? '0').toString(),
        ) ?? 0.0;

    final double score = double.tryParse((json['score_afinidad'] ?? json['score'] ?? '98.0').toString()) ?? 98.0;

    return OutfitRecomendadoModel(
      id: json['id']?.toString() ?? 'outfit-${DateTime.now().millisecondsSinceEpoch}',
      titulo: json['outfit_nombre']?.toString() ?? json['titulo']?.toString() ?? 'Look Completo Estilista IA',
      estilo: json['ocasion']?.toString() ?? json['estilo']?.toString() ?? 'Urban Tailored Casual',
      descripcionEstilistica: json['descripcion_estilo']?.toString() ?? json['descripcion_estilistica']?.toString() ?? 
          'Combinación personalizada basada en tus compras y prendas favoritas.',
      precioTotalEstimado: precioTotal,
      scoreAfinidad: score,
      prendas: listaPrendas,
    );
  }
}

