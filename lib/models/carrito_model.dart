class ItemCarritoModel {
  final int? id;
  final int varianteId;
  final int prendaId;
  final String prendaNombre;
  final String? imagenUrl;
  final String talla;
  final String color;
  final double precioUnitario;
  int cantidad;

  ItemCarritoModel({
    this.id,
    required this.varianteId,
    required this.prendaId,
    required this.prendaNombre,
    this.imagenUrl,
    required this.talla,
    required this.color,
    required this.precioUnitario,
    required this.cantidad,
  });

  double get subtotal => precioUnitario * cantidad;

  factory ItemCarritoModel.fromJson(Map<String, dynamic> json) {
    return ItemCarritoModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      varianteId: int.tryParse(json['variante_id']?.toString() ?? '0') ?? 0,
      prendaId: int.tryParse(json['prenda_id']?.toString() ?? '0') ?? 0,
      prendaNombre: json['prenda_nombre']?.toString() ?? 'Producto',
      imagenUrl: json['imagen_url']?.toString(),
      talla: json['talla']?.toString() ?? 'Única',
      color: json['color']?.toString() ?? 'Estándar',
      precioUnitario: double.tryParse(json['precio_unitario']?.toString() ?? '0') ?? 0.0,
      cantidad: int.tryParse(json['cantidad']?.toString() ?? '1') ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'variante_id': varianteId,
      'prenda_id': prendaId,
      'prenda_nombre': prendaNombre,
      'imagen_url': imagenUrl,
      'talla': talla,
      'color': color,
      'precio_unitario': precioUnitario,
      'cantidad': cantidad,
    };
  }
}

class CarritoModel {
  final int? id;
  final List<ItemCarritoModel> items;

  CarritoModel({
    this.id,
    required this.items,
  });

  int get totalArticulos => items.fold(0, (sum, item) => sum + item.cantidad);
  double get totalMonto => items.fold(0.0, (sum, item) => sum + item.subtotal);

  factory CarritoModel.fromJson(Map<String, dynamic> json) {
    var rawDetalles = json['detalles'] as List? ?? [];
    return CarritoModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      items: rawDetalles.map((d) => ItemCarritoModel.fromJson(d as Map<String, dynamic>)).toList(),
    );
  }
}

