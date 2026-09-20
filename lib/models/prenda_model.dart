import '../config/environment.dart';

class VariantePrendaModel {
  final int id;
  final String talla;
  final String color;
  final String? codBarra;
  final int stockDisponible;
  final String estadoStock; // DISPONIBLE, ULTIMAS_UNIDADES, AGOTADO

  VariantePrendaModel({
    required this.id,
    required this.talla,
    required this.color,
    this.codBarra,
    required this.stockDisponible,
    required this.estadoStock,
  });

  factory VariantePrendaModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['variante_id'] ?? json['id'];
    final int parsedId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '0') ?? 0;

    final rawStock = json['stock_disponible_total'] ?? json['stock_disponible'];
    final int parsedStock = rawStock is int ? rawStock : int.tryParse(rawStock?.toString() ?? '0') ?? 0;

    final estado = json['estado_disponibilidad'] ?? json['estado_stock'] ?? (parsedStock > 0 ? 'DISPONIBLE' : 'AGOTADO');

    return VariantePrendaModel(
      id: parsedId,
      talla: json['talla']?.toString() ?? 'Única',
      color: json['color']?.toString() ?? 'Estándar',
      codBarra: (json['sku'] ?? json['cod_barra'])?.toString(),
      stockDisponible: parsedStock,
      estadoStock: estado.toString(),
    );
  }
}

class PrendaModel {
  final int id;
  final String nombre;
  final String descripcion;
  final double precio;
  final double? precioConDescuento;
  final String? categoriaNombre;
  final String? imagenPrincipal;
  final List<String> imagenes;
  final String? modelo3dUri;
  final int stockTotalDisponible;
  final String estadoGlobalStock;
  final double? calificacionPromedio;
  final int totalResenas;
  final List<VariantePrendaModel> variantes;

  PrendaModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    this.precioConDescuento,
    this.categoriaNombre,
    this.imagenPrincipal,
    required this.imagenes,
    this.modelo3dUri,
    required this.stockTotalDisponible,
    required this.estadoGlobalStock,
    this.calificacionPromedio,
    this.totalResenas = 0,
    required this.variantes,
  });

  factory PrendaModel.fromJson(Map<String, dynamic> json) {
    var rawVars = json['variantes'] as List? ?? [];
    var varsList = rawVars.map((v) => VariantePrendaModel.fromJson(v as Map<String, dynamic>)).toList();

    var rawImgs = (json['recursos_multimedia'] ?? json['imagenes']) as List? ?? [];
    List<String> imgUrls = [];
    for (var item in rawImgs) {
      if (item is String) {
        imgUrls.add(Environment.formatImageUrl(item));
      } else if (item is Map && item.containsKey('archivo_url')) {
        imgUrls.add(Environment.formatImageUrl(item['archivo_url'].toString()));
      }
    }

    String? rawPrinc = json['imagen_principal']?.toString();
    String? imgPrinc = rawPrinc != null && rawPrinc.isNotEmpty 
        ? Environment.formatImageUrl(rawPrinc) 
        : (imgUrls.isNotEmpty ? imgUrls.first : null);

    // Mapeo robusto de precios (precio_base, precio_minimo, precio)
    final rawPrecio = json['precio_base'] ?? json['precio'] ?? json['precio_minimo'] ?? '0';
    final double parsedPrecio = rawPrecio is num 
        ? rawPrecio.toDouble() 
        : double.tryParse(rawPrecio.toString()) ?? 0.0;

    final rawPromo = json['precio_promocional'] ?? json['precio_con_descuento'];
    final double? parsedPromo = rawPromo != null 
        ? (rawPromo is num ? rawPromo.toDouble() : double.tryParse(rawPromo.toString()))
        : null;

    // Mapeo robusto de stock
    final rawStock = json['stock_disponible_cadena'] ?? json['stock_total_disponible'] ?? '0';
    final int parsedStock = rawStock is int 
        ? rawStock 
        : int.tryParse(rawStock.toString()) ?? 0;

    final estado = json['estado_global_stock']?.toString() ?? 
        (json['disponible_en_cadena'] == false || parsedStock <= 0 ? 'AGOTADO' : (parsedStock <= 5 ? 'ULTIMAS_UNIDADES' : 'DISPONIBLE'));

    return PrendaModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      nombre: json['nombre']?.toString() ?? 'Prenda',
      descripcion: json['descripcion']?.toString() ?? '',
      precio: parsedPrecio,
      precioConDescuento: parsedPromo,
      categoriaNombre: json['categoria_nombre']?.toString() ?? json['categoria']?.toString(),
      imagenPrincipal: imgPrinc,
      imagenes: imgUrls,
      modelo3dUri: json['modelo_3d_uri'] != null ? Environment.formatImageUrl(json['modelo_3d_uri'].toString()) : null,
      stockTotalDisponible: parsedStock,
      estadoGlobalStock: estado,
      calificacionPromedio: json['calificacion_promedio'] != null 
          ? (json['calificacion_promedio'] is num 
              ? (json['calificacion_promedio'] as num).toDouble() 
              : double.tryParse(json['calificacion_promedio'].toString()))
          : null,
      totalResenas: json['total_resenas'] is int ? json['total_resenas'] : 0,
      variantes: varsList,
    );
  }
}
