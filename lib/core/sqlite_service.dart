import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/prenda_model.dart';
import '../models/carrito_model.dart';

/// Servicio Centralizado de Base de Datos Local SQLite (fashionstore_local.db)
/// Cumple con CU-05, CU-07, CU-08, CU-14.
/// Garantiza aislamiento estricto de datos por usuario (usuario_id).
class SqliteService {
  static Database? _db;
  static const String _dbName = 'fashionstore_local.db';
  static const int _dbVersion = 2;

  // Fallback keys en SharedPreferences cuando se ejecuta en entorno Web (kIsWeb)
  static const String _webCatalogoKey = 'fs_sqlite_prendas_cache';
  static const String _webFavKeyPrefix = 'fs_sqlite_fav_u_';
  static const String _webCartKeyPrefix = 'fs_sqlite_cart_u_';
  static const String _webOutboxKeyPrefix = 'fs_sqlite_outbox_u_';

  static Future<Database?> get database async {
    if (kIsWeb) return null; // En Web usamos espejo JSON estructurado sobre SharedPreferences
    if (_db != null) return _db;
    try {
      final dbPath = await getDatabasesPath();
      final fullPath = p.join(dbPath, _dbName);
      _db = await openDatabase(
        fullPath,
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
      return _db;
    } catch (e) {
      debugPrint('Aviso SQLite init (usando espejo local): $e');
      return null;
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    // 1. Tabla de Caché de Prendas (CU-05)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS prendas_cache (
        id INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        precio REAL NOT NULL,
        precio_con_descuento REAL,
        categoria_id INTEGER,
        categoria_nombre TEXT,
        imagen_principal TEXT,
        imagenes_json TEXT,
        modelo_3d_uri TEXT,
        stock_total INTEGER DEFAULT 0,
        estado_stock TEXT DEFAULT 'DISPONIBLE',
        calificacion_promedio REAL,
        total_resenas INTEGER DEFAULT 0,
        empresa_id INTEGER DEFAULT 1,
        actualizado_en TEXT
      )
    ''');

    // 2. Tabla de Caché de Variantes (Talla y Color)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS variantes_cache (
        id INTEGER PRIMARY KEY,
        ropa_id INTEGER NOT NULL,
        talla TEXT NOT NULL,
        color TEXT NOT NULL,
        color_hex TEXT,
        sku TEXT,
        stock_disponible INTEGER DEFAULT 0,
        estado_stock TEXT DEFAULT 'DISPONIBLE',
        imagen_url TEXT,
        FOREIGN KEY (ropa_id) REFERENCES prendas_cache(id) ON DELETE CASCADE
      )
    ''');

    // 3. Tabla de Favoritos Aislados por Usuario
    await db.execute('''
      CREATE TABLE IF NOT EXISTS favoritos_local (
        prenda_id INTEGER NOT NULL,
        usuario_id TEXT NOT NULL,
        prenda_json TEXT NOT NULL,
        nombre TEXT NOT NULL,
        precio REAL NOT NULL,
        imagen_principal TEXT,
        categoria_nombre TEXT,
        fecha_agregado TEXT NOT NULL,
        pendiente_sync INTEGER DEFAULT 0,
        PRIMARY KEY (prenda_id, usuario_id)
      )
    ''');

    // 4. Tabla de Carrito Persistente Aislado por Usuario (CU-08)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS carrito_local (
        variante_id INTEGER NOT NULL,
        usuario_id TEXT NOT NULL,
        prenda_id INTEGER NOT NULL,
        prenda_nombre TEXT NOT NULL,
        imagen_url TEXT,
        talla TEXT NOT NULL,
        color TEXT NOT NULL,
        precio_unitario REAL NOT NULL,
        cantidad INTEGER NOT NULL,
        actualizado_en TEXT NOT NULL,
        PRIMARY KEY (variante_id, usuario_id)
      )
    ''');

    // 5. Cola Outbox de Sincronización Offline con UUIDv4 (CU-07, CU-14)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS outbox_sync (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid_transaccion TEXT NOT NULL UNIQUE,
        usuario_id TEXT NOT NULL,
        tipo_operacion TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        estado TEXT NOT NULL DEFAULT 'PENDIENTE',
        fecha_creacion TEXT NOT NULL,
        reintentos INTEGER DEFAULT 0,
        ultimo_error TEXT
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _onCreate(db, newVersion);
  }

  // ===========================================================================
  // 1. GESTIÓN DE CATÁLOGO Y STOCK OFFLINE (CU-05)
  // ===========================================================================

  static Map<String, dynamic> _prendaToMap(PrendaModel p) {
    return {
      'id': p.id,
      'nombre': p.nombre,
      'descripcion': p.descripcion,
      'precio': p.precio,
      'precio_con_descuento': p.precioConDescuento,
      'categoria_nombre': p.categoriaNombre,
      'imagen_principal': p.imagenPrincipal,
      'imagenes': p.imagenes,
      'modelo_3d_uri': p.modelo3dUri,
      'stock_total_disponible': p.stockTotalDisponible,
      'estado_global_stock': p.estadoGlobalStock,
      'calificacion_promedio': p.calificacionPromedio,
      'total_resenas': p.totalResenas,
      'variantes': p.variantes.map((v) => {
        'id': v.id,
        'talla': v.talla,
        'color': v.color,
        'cod_barra': v.codBarra,
        'stock_disponible': v.stockDisponible,
        'estado_stock': v.estadoStock,
        'imagen_url': v.imagenUrl,
      }).toList(),
    };
  }

  static Future<void> guardarCatalogoEnCache(List<PrendaModel> prendas) async {
    if (prendas.isEmpty) return;

    // Guardar también copia rápida en SharedPreferences para compatibilidad multiplataforma
    try {
      final prefs = await SharedPreferences.getInstance();
      final listMap = prendas.map(_prendaToMap).toList();
      await prefs.setString(_webCatalogoKey, jsonEncode(listMap));
    } catch (_) {}

    final db = await database;
    if (db == null) return;

    try {
      await db.transaction((txn) async {
        final now = DateTime.now().toIso8601String();
        for (final p in prendas) {
          await txn.insert(
            'prendas_cache',
            {
              'id': p.id,
              'nombre': p.nombre,
              'descripcion': p.descripcion,
              'precio': p.precio,
              'precio_con_descuento': p.precioConDescuento,
              'categoria_nombre': p.categoriaNombre,
              'imagen_principal': p.imagenPrincipal,
              'imagenes_json': jsonEncode(p.imagenes),
              'modelo_3d_uri': p.modelo3dUri,
              'stock_total': p.stockTotalDisponible,
              'estado_stock': p.estadoGlobalStock,
              'calificacion_promedio': p.calificacionPromedio,
              'total_resenas': p.totalResenas,
              'empresa_id': 1,
              'actualizado_en': now,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          for (final v in p.variantes) {
            await txn.insert(
              'variantes_cache',
              {
                'id': v.id,
                'ropa_id': p.id,
                'talla': v.talla,
                'color': v.color,
                'sku': v.codBarra,
                'stock_disponible': v.stockDisponible,
                'estado_stock': v.estadoStock,
                'imagen_url': v.imagenUrl,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      });
    } catch (e) {
      debugPrint('Error guardando catálogo en SQLite: $e');
    }
  }

  static Future<List<PrendaModel>> obtenerPrendasOffline({
    String? buscar,
    String? categoriaNombre,
    bool soloConStock = false,
  }) async {
    List<PrendaModel> resultado = [];
    final db = await database;

    if (db != null) {
      try {
        String whereClause = '1=1';
        List<dynamic> whereArgs = [];

        if (buscar != null && buscar.trim().isNotEmpty) {
          whereClause += ' AND (LOWER(nombre) LIKE ? OR LOWER(descripcion) LIKE ? OR LOWER(categoria_nombre) LIKE ?)';
          final q = '%${buscar.trim().toLowerCase()}%';
          whereArgs.addAll([q, q, q]);
        }
        if (categoriaNombre != null && categoriaNombre.isNotEmpty) {
          whereClause += ' AND LOWER(categoria_nombre) = ?';
          whereArgs.add(categoriaNombre.toLowerCase());
        }
        if (soloConStock) {
          whereClause += ' AND stock_total > 0';
        }

        final rows = await db.query('prendas_cache', where: whereClause, whereArgs: whereArgs);
        for (final r in rows) {
          final int prendaId = r['id'] as int;
          final varRows = await db.query('variantes_cache', where: 'ropa_id = ?', whereArgs: [prendaId]);
          final variantes = varRows.map((vr) => VariantePrendaModel(
            id: vr['id'] as int,
            talla: vr['talla']?.toString() ?? 'Única',
            color: vr['color']?.toString() ?? 'Estándar',
            codBarra: vr['sku']?.toString(),
            stockDisponible: (vr['stock_disponible'] as int?) ?? 0,
            estadoStock: vr['estado_stock']?.toString() ?? 'DISPONIBLE',
            imagenUrl: vr['imagen_url']?.toString(),
          )).toList();

          List<String> imgs = [];
          try {
            if (r['imagenes_json'] != null) {
              imgs = List<String>.from(jsonDecode(r['imagenes_json'].toString()));
            }
          } catch (_) {}

          resultado.add(PrendaModel(
            id: prendaId,
            nombre: r['nombre']?.toString() ?? '',
            descripcion: r['descripcion']?.toString() ?? '',
            precio: (r['precio'] as num?)?.toDouble() ?? 0.0,
            precioConDescuento: (r['precio_con_descuento'] as num?)?.toDouble(),
            categoriaNombre: r['categoria_nombre']?.toString(),
            imagenPrincipal: r['imagen_principal']?.toString(),
            imagenes: imgs,
            modelo3dUri: r['modelo_3d_uri']?.toString(),
            stockTotalDisponible: (r['stock_total'] as int?) ?? 0,
            estadoGlobalStock: r['estado_stock']?.toString() ?? 'DISPONIBLE',
            calificacionPromedio: (r['calificacion_promedio'] as num?)?.toDouble(),
            totalResenas: (r['total_resenas'] as int?) ?? 0,
            variantes: variantes,
          ));
        }
        if (resultado.isNotEmpty) return resultado;
      } catch (e) {
        debugPrint('Error leyendo SQLite prendas_cache: $e');
      }
    }

    // Respaldo inmediato desde espejo local
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_webCatalogoKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List;
        resultado = list.map((e) => PrendaModel.fromJson(e as Map<String, dynamic>)).toList();
        if (buscar != null && buscar.trim().isNotEmpty) {
          final q = buscar.trim().toLowerCase();
          resultado = resultado.where((p) =>
            p.nombre.toLowerCase().contains(q) ||
            p.descripcion.toLowerCase().contains(q) ||
            (p.categoriaNombre?.toLowerCase().contains(q) ?? false)
          ).toList();
        }
        if (categoriaNombre != null && categoriaNombre.isNotEmpty) {
          resultado = resultado.where((p) =>
            p.categoriaNombre?.toLowerCase() == categoriaNombre.toLowerCase()
          ).toList();
        }
        if (soloConStock) {
          resultado = resultado.where((p) => p.stockTotalDisponible > 0).toList();
        }
      }
    } catch (_) {}

    return resultado;
  }

  /// Descuenta stock provisionalmente en SQLite al crear una reserva o compra en modo offline
  static Future<void> descontarStockLocalProvisional(int varianteId, int cantidad) async {
    final db = await database;
    if (db != null) {
      try {
        final rows = await db.query('variantes_cache', where: 'id = ?', whereArgs: [varianteId]);
        if (rows.isNotEmpty) {
          final actual = (rows.first['stock_disponible'] as int?) ?? 0;
          final int ropaId = rows.first['ropa_id'] as int;
          final nuevo = (actual - cantidad) < 0 ? 0 : (actual - cantidad);
          await db.update(
            'variantes_cache',
            {
              'stock_disponible': nuevo,
              'estado_stock': nuevo > 0 ? 'DISPONIBLE' : 'AGOTADO',
            },
            where: 'id = ?',
            whereArgs: [varianteId],
          );

          final pRows = await db.query('prendas_cache', where: 'id = ?', whereArgs: [ropaId]);
          if (pRows.isNotEmpty) {
            final actualTotal = (pRows.first['stock_total'] as int?) ?? 0;
            final nuevoTotal = (actualTotal - cantidad) < 0 ? 0 : (actualTotal - cantidad);
            await db.update(
              'prendas_cache',
              {
                'stock_total': nuevoTotal,
                'estado_stock': nuevoTotal > 0 ? 'DISPONIBLE' : 'AGOTADO',
              },
              where: 'id = ?',
              whereArgs: [ropaId],
            );
          }
        }
      } catch (_) {}
    }
  }

  // ===========================================================================
  // 2. FAVORITOS AISLADOS POR USUARIO CON SOPORTE OFFLINE
  // ===========================================================================

  static Future<List<PrendaModel>> obtenerFavoritosUsuario(String usuarioId) async {
    final uid = usuarioId.trim().isEmpty ? 'guest' : usuarioId.trim();
    final db = await database;

    if (db != null) {
      try {
        final rows = await db.query(
          'favoritos_local',
          where: 'usuario_id = ?',
          whereArgs: [uid],
          orderBy: 'fecha_agregado DESC',
        );
        if (rows.isNotEmpty) {
          return rows.map((r) {
            final map = jsonDecode(r['prenda_json'].toString()) as Map<String, dynamic>;
            return PrendaModel.fromJson(map);
          }).toList();
        }
      } catch (e) {
        debugPrint('Error leyendo favoritos SQLite: $e');
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_webFavKeyPrefix$uid');
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        return decoded.map((e) => PrendaModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    return [];
  }

  static Future<void> guardarFavoritoUsuario(
    String usuarioId,
    PrendaModel prenda, {
    bool pendienteSync = false,
  }) async {
    final uid = usuarioId.trim().isEmpty ? 'guest' : usuarioId.trim();
    final map = _prendaToMap(prenda);

    final db = await database;
    if (db != null) {
      try {
        await db.insert(
          'favoritos_local',
          {
            'prenda_id': prenda.id,
            'usuario_id': uid,
            'prenda_json': jsonEncode(map),
            'nombre': prenda.nombre,
            'precio': prenda.precioConDescuento ?? prenda.precio,
            'imagen_principal': prenda.imagenPrincipal,
            'categoria_nombre': prenda.categoriaNombre,
            'fecha_agregado': DateTime.now().toIso8601String(),
            'pendiente_sync': pendienteSync ? 1 : 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (_) {}
    }

    try {
      final actuales = await obtenerFavoritosUsuario(uid);
      final sinDuplicado = actuales.where((p) => p.id != prenda.id).toList();
      sinDuplicado.insert(0, prenda);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_webFavKeyPrefix$uid',
        jsonEncode(sinDuplicado.map(_prendaToMap).toList()),
      );
    } catch (_) {}
  }

  static Future<void> eliminarFavoritoUsuario(String usuarioId, int prendaId) async {
    final uid = usuarioId.trim().isEmpty ? 'guest' : usuarioId.trim();
    final db = await database;
    if (db != null) {
      try {
        await db.delete(
          'favoritos_local',
          where: 'prenda_id = ? AND usuario_id = ?',
          whereArgs: [prendaId, uid],
        );
      } catch (_) {}
    }

    try {
      final actuales = await obtenerFavoritosUsuario(uid);
      final filtrados = actuales.where((p) => p.id != prendaId).toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_webFavKeyPrefix$uid',
        jsonEncode(filtrados.map(_prendaToMap).toList()),
      );
    } catch (_) {}
  }

  // ===========================================================================
  // 3. CARRITO PERSISTENTE AISLADO POR USUARIO (CU-08)
  // ===========================================================================

  static Future<List<ItemCarritoModel>> obtenerCarritoUsuario(String usuarioId) async {
    final uid = usuarioId.trim().isEmpty ? 'guest' : usuarioId.trim();
    final db = await database;

    if (db != null) {
      try {
        final rows = await db.query(
          'carrito_local',
          where: 'usuario_id = ?',
          whereArgs: [uid],
        );
        if (rows.isNotEmpty) {
          return rows.map((r) => ItemCarritoModel(
            varianteId: r['variante_id'] as int,
            prendaId: r['prenda_id'] as int,
            prendaNombre: r['prenda_nombre']?.toString() ?? '',
            imagenUrl: r['imagen_url']?.toString(),
            talla: r['talla']?.toString() ?? 'Única',
            color: r['color']?.toString() ?? 'Estándar',
            precioUnitario: (r['precio_unitario'] as num).toDouble(),
            cantidad: r['cantidad'] as int,
          )).toList();
        }
      } catch (e) {
        debugPrint('Error leyendo carrito SQLite: $e');
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_webCartKeyPrefix$uid');
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List;
        return list.map((e) => ItemCarritoModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    return [];
  }

  static Future<void> guardarCarritoUsuario(String usuarioId, List<ItemCarritoModel> items) async {
    final uid = usuarioId.trim().isEmpty ? 'guest' : usuarioId.trim();
    final now = DateTime.now().toIso8601String();

    final db = await database;
    if (db != null) {
      try {
        await db.transaction((txn) async {
          await txn.delete('carrito_local', where: 'usuario_id = ?', whereArgs: [uid]);
          for (final item in items) {
            await txn.insert(
              'carrito_local',
              {
                'variante_id': item.varianteId,
                'usuario_id': uid,
                'prenda_id': item.prendaId,
                'prenda_nombre': item.prendaNombre,
                'imagen_url': item.imagenUrl,
                'talla': item.talla,
                'color': item.color,
                'precio_unitario': item.precioUnitario,
                'cantidad': item.cantidad,
                'actualizado_en': now,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        });
      } catch (_) {}
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_webCartKeyPrefix$uid',
        jsonEncode(items.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  // ===========================================================================
  // 4. COLA OUTBOX DE OPERACIONES OFFLINE CON UUIDv4 (CU-07, CU-14)
  // ===========================================================================

  static Future<void> encolarOperacionOffline({
    required String uuidTransaccion,
    required String usuarioId,
    required String tipoOperacion, // 'RESERVA' | 'VENTA_PRELIMINAR' | 'FAVORITO'
    required Map<String, dynamic> payload,
  }) async {
    final uid = usuarioId.trim().isEmpty ? 'guest' : usuarioId.trim();
    final now = DateTime.now().toIso8601String();
    final entry = {
      'uuid_transaccion': uuidTransaccion,
      'usuario_id': uid,
      'tipo_operacion': tipoOperacion,
      'payload_json': jsonEncode(payload),
      'estado': 'PENDIENTE',
      'fecha_creacion': now,
      'reintentos': 0,
      'ultimo_error': null,
    };

    final db = await database;
    if (db != null) {
      try {
        await db.insert(
          'outbox_sync',
          entry,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (e) {
        debugPrint('Error encolando en SQLite outbox_sync: $e');
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_webOutboxKeyPrefix$uid';
      final raw = prefs.getString(key);
      List<Map<String, dynamic>> current = [];
      if (raw != null && raw.isNotEmpty) {
        current = (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      current.removeWhere((e) => e['uuid_transaccion'] == uuidTransaccion);
      current.insert(0, entry);
      await prefs.setString(key, jsonEncode(current));
    } catch (_) {}
  }

  static Future<List<Map<String, dynamic>>> obtenerOutboxPendientes({String? usuarioId, bool incluirConflictos = false}) async {
    final uid = (usuarioId != null && usuarioId.trim().isNotEmpty) ? usuarioId.trim() : null;
    final db = await database;

    final Map<String, Map<String, dynamic>> unificadosPorUuid = {};

    if (db != null) {
      try {
        final whereClause = incluirConflictos ? 'estado = ? OR estado = ?' : 'estado = ?';
        final whereArgs = incluirConflictos ? ['PENDIENTE', 'CONFLICTO_STOCK'] : ['PENDIENTE'];
        final rows = await db.query(
          'outbox_sync',
          where: whereClause,
          whereArgs: whereArgs,
          orderBy: 'fecha_creacion ASC',
        );
        for (final r in rows) {
          final m = Map<String, dynamic>.from(r);
          final rowUid = m['usuario_id']?.toString() ?? '';
          if (uid == null || uid == 'guest' || rowUid == uid || rowUid == 'guest') {
            final u = m['uuid_transaccion']?.toString() ?? '';
            if (u.isNotEmpty) unificadosPorUuid[u] = m;
          }
        }
      } catch (_) {}
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCid = prefs.getString('fs_cliente_id');
      final keysToCheck = <String>{
        if (uid != null) '$_webOutboxKeyPrefix$uid',
        if (savedCid != null && savedCid.isNotEmpty) '$_webOutboxKeyPrefix$savedCid',
        '${_webOutboxKeyPrefix}guest',
      };
      for (final k in prefs.getKeys()) {
        if (k.startsWith(_webOutboxKeyPrefix)) {
          keysToCheck.add(k);
        }
      }

      for (final key in keysToCheck) {
        final raw = prefs.getString(key);
        if (raw != null && raw.isNotEmpty) {
          final list = (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
          for (final item in list) {
            final st = item['estado']?.toString() ?? '';
            final coincide = incluirConflictos ? (st == 'PENDIENTE' || st == 'CONFLICTO_STOCK') : (st == 'PENDIENTE');
            if (coincide) {
              final u = item['uuid_transaccion']?.toString() ?? '';
              if (u.isNotEmpty) {
                unificadosPorUuid[u] = item;
              }
            }
          }
        }
      }
    } catch (_) {}

    return unificadosPorUuid.values.toList();
  }

  static Future<void> marcarOutboxSincronizado(String uuidTransaccion, String usuarioId, {String nuevoEstado = 'SINCRONIZADO', String? error}) async {
    final db = await database;
    if (db != null) {
      try {
        await db.update(
          'outbox_sync',
          {
            'estado': nuevoEstado,
            if (error != null) 'ultimo_error': error,
          },
          where: 'uuid_transaccion = ?',
          whereArgs: [uuidTransaccion],
        );
      } catch (_) {}
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final outboxKeys = prefs.getKeys().where((k) => k.startsWith(_webOutboxKeyPrefix)).toList();
      for (final key in outboxKeys) {
        final raw = prefs.getString(key);
        if (raw != null && raw.isNotEmpty) {
          final list = (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
          for (final item in list) {
            if (item['uuid_transaccion'] == uuidTransaccion) {
              item['estado'] = nuevoEstado;
              if (error != null) item['ultimo_error'] = error;
            }
          }
          final soloPendientes = list.where((e) => e['estado'] == 'PENDIENTE' || e['estado'] == 'CONFLICTO_STOCK').toList();
          await prefs.setString(key, jsonEncode(soloPendientes));
        }
      }
    } catch (_) {}
  }

  static Future<void> limpiarOutboxUsuario(String usuarioId) async {
    final uid = usuarioId.trim().isEmpty ? 'guest' : usuarioId.trim();
    final db = await database;
    if (db != null) {
      try {
        await db.delete('outbox_sync', where: 'usuario_id = ?', whereArgs: [uid]);
      } catch (_) {}
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_webOutboxKeyPrefix$uid');
    } catch (_) {}
  }
}
