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
  final List<PrendaModel> prendas;

  OutfitRecomendadoModel({
    required this.id,
    required this.titulo,
    required this.estilo,
    required this.descripcionEstilistica,
    required this.precioTotalEstimado,
    required this.prendas,
  });

  factory OutfitRecomendadoModel.fromJson(Map<String, dynamic> json) {
    var rawPrendas = json['prendas'] as List? ?? json['prendas_sugeridas'] as List? ?? [];
    return OutfitRecomendadoModel(
      id: json['id']?.toString() ?? 'outfit-${DateTime.now().millisecondsSinceEpoch}',
      titulo: json['titulo']?.toString() ?? 'Outfit Recomendado por IA',
      estilo: json['estilo']?.toString() ?? 'Casual Elegante',
      descripcionEstilistica: json['descripcion_estilistica']?.toString() ?? 
          'Combinación basada en armonía cromática y silueta para ocasiones especiales.',
      precioTotalEstimado: double.tryParse(json['precio_total_estimado']?.toString() ?? '0') ?? 0.0,
      prendas: rawPrendas.map((p) => PrendaModel.fromJson(p as Map<String, dynamic>)).toList(),
    );
  }
}

