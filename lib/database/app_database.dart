import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import '../models/novel_style.dart';

class AppDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static void setDatabaseForTesting(Database? db) {
    _database = db;
  }

  static Future<Database> _initDatabase() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'novel_writer.db');
      return await openDatabase(
        path,
        version: 21,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
  }

  static int _countWordsStatic(String text) {
    if (text.isEmpty) return 0;
    String plain = text;
    if (text.trim().startsWith('[') && text.trim().endsWith(']')) {
      try {
        final List<dynamic> json = jsonDecode(text);
        final sb = StringBuffer();
        for (var op in json) {
          if (op is Map && op.containsKey('insert')) {
            final insertVal = op['insert'];
            if (insertVal is String) {
              sb.write(insertVal);
            }
          }
        }
        plain = sb.toString();
      } catch (_) {}
    }
    return plain.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  static Future<void> upgradeDatabaseForTesting(Database db, int oldVersion, int newVersion) =>
      _onUpgrade(db, oldVersion, newVersion);

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS personajes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          proyecto_id INTEGER NOT NULL,
          nombre TEXT NOT NULL,
          rol TEXT,
          descripcion TEXT,
          imagen_path TEXT,
          atributos TEXT, -- JSON string
          creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (proyecto_id) REFERENCES proyectos(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 3) {
      // Agregar nuevos campos para el Codex de personajes
      await db.execute('ALTER TABLE personajes ADD COLUMN alias TEXT');
      await db.execute('ALTER TABLE personajes ADD COLUMN frase_iconica TEXT');
      await db.execute(
        'ALTER TABLE personajes ADD COLUMN estado_emocional TEXT',
      );
      await db.execute('ALTER TABLE personajes ADD COLUMN estado_actual TEXT');
      await db.execute('ALTER TABLE personajes ADD COLUMN edad TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS relaciones_personajes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          personaje_a_id INTEGER NOT NULL,
          personaje_b_id INTEGER NOT NULL,
          tipo TEXT NOT NULL,
          intensidad INTEGER DEFAULT 50,
          notas TEXT,
          creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (personaje_a_id) REFERENCES personajes(id) ON DELETE CASCADE,
          FOREIGN KEY (personaje_b_id) REFERENCES personajes(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE manuscritos ADD COLUMN color_fondo TEXT');
      await db.execute('ALTER TABLE manuscritos ADD COLUMN fuente TEXT');
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE manuscritos ADD COLUMN font_size REAL');
      await db.execute('ALTER TABLE manuscritos ADD COLUMN line_height REAL');
    }
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS capitulos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          manuscrito_id INTEGER NOT NULL,
          titulo TEXT NOT NULL DEFAULT 'Sin título',
          contenido TEXT DEFAULT '',
          orden INTEGER NOT NULL DEFAULT 0,
          tipo TEXT NOT NULL DEFAULT 'capitulo',
          creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (manuscrito_id) REFERENCES manuscritos(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 8) {
      try {
        await db.execute(
          'ALTER TABLE capitulos ADD COLUMN tipo TEXT NOT NULL DEFAULT "capitulo"',
        );
      } catch (e) {
        // La columna ya podría existir si se creó con v7 modificado
      }
    }
    if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS eventos_timeline (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          proyecto_id INTEGER NOT NULL,
          titulo TEXT NOT NULL,
          descripcion TEXT,
          fecha_relativa TEXT,
          importancia INTEGER DEFAULT 1,
          color_hex TEXT DEFAULT '#D4AF37',
          orden INTEGER DEFAULT 0,
          creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (proyecto_id) REFERENCES proyectos(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 10) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS lugares (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          proyecto_id INTEGER NOT NULL,
          nombre TEXT NOT NULL,
          descripcion TEXT,
          clima TEXT,
          poblacion TEXT,
          importancia TEXT DEFAULT 'Secundario',
          imagen_path TEXT,
          atributos TEXT, -- JSON string
          creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (proyecto_id) REFERENCES proyectos(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 11) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS mapas (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          proyecto_id INTEGER NOT NULL,
          nombre TEXT NOT NULL,
          datos_mapa TEXT,
          creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (proyecto_id) REFERENCES proyectos(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 12) {
      try {
        await db.execute(
          'ALTER TABLE proyectos ADD COLUMN imagen_portada TEXT',
        );
      } catch (e) {
        // Column may already exist
      }
    }
    if (oldVersion < 13) {
      try {
        await db.execute(
          'ALTER TABLE proyectos ADD COLUMN portada_blob BLOB',
        );
        // Migrate existing images from file paths to BLOB
        final projects = await db.query('proyectos',
            columns: ['id', 'imagen_portada']);
        for (var p in projects) {
          final path = p['imagen_portada'] as String?;
          if (path != null && path.isNotEmpty) {
            try {
              final file = File(path);
              if (await file.exists()) {
                final bytes = await file.readAsBytes();
                await db.update(
                  'proyectos',
                  {'portada_blob': bytes},
                  where: 'id = ?',
                  whereArgs: [p['id']],
                );
              }
            } catch (_) {}
          }
        }
      } catch (e) {
        // Column may already exist
      }
    }
    if (oldVersion < 14) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS capitulos_versiones (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          capitulo_id INTEGER NOT NULL,
          contenido TEXT NOT NULL,
          creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (capitulo_id) REFERENCES capitulos(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 15) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS estilos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          proyecto_id INTEGER NOT NULL,
          nombre TEXT NOT NULL,
          orden INTEGER NOT NULL DEFAULT 0,
          hereda_de_id INTEGER,
          atajo TEXT,
          config TEXT NOT NULL DEFAULT '{}',
          creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (proyecto_id) REFERENCES proyectos(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 16) {
      // Recreate estilos table: nullable proyecto_id + es_global flag
      await db.execute('''
        CREATE TABLE IF NOT EXISTS estilos_v16 (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          proyecto_id INTEGER,
          nombre TEXT NOT NULL,
          orden INTEGER NOT NULL DEFAULT 0,
          hereda_de_id INTEGER,
          atajo TEXT,
          config TEXT NOT NULL DEFAULT '{}',
          es_global INTEGER NOT NULL DEFAULT 0,
          creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (proyecto_id) REFERENCES proyectos(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        INSERT INTO estilos_v16 (id, proyecto_id, nombre, orden, hereda_de_id, atajo, config, creado_en, actualizado_en)
        SELECT id, proyecto_id, nombre, orden, hereda_de_id, atajo, config, creado_en, actualizado_en FROM estilos
      ''');
      await db.execute('DROP TABLE IF EXISTS estilos');
      await db.execute('ALTER TABLE estilos_v16 RENAME TO estilos');
      await _seedGlobalStyles(db);
    }
    if (oldVersion < 17) {
      await db.execute('ALTER TABLE notas ADD COLUMN categoria TEXT DEFAULT "general"');
    }
    if (oldVersion < 18) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categorias (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          proyecto_id INTEGER,
          nombre TEXT NOT NULL,
          icon TEXT NOT NULL DEFAULT 'auto_awesome',
          color TEXT NOT NULL DEFAULT '#FFF9C4',
          orden INTEGER DEFAULT 0,
          creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (proyecto_id) REFERENCES proyectos(id) ON DELETE CASCADE
        )
      ''');
      await _seedDefaultCategorias(db);
      await db.execute("UPDATE notas SET categoria = '1' WHERE categoria = 'general'");
      await db.execute("UPDATE notas SET categoria = '2' WHERE categoria = 'idea'");
      await db.execute("UPDATE notas SET categoria = '3' WHERE categoria = 'personaje'");
      await db.execute("UPDATE notas SET categoria = '4' WHERE categoria = 'trama'");
      await db.execute("UPDATE notas SET categoria = '5' WHERE categoria = 'escena'");
      await db.execute("UPDATE notas SET categoria = '6' WHERE categoria = 'investigacion'");
      await db.execute("UPDATE notas SET categoria = '7' WHERE categoria = 'dialogo'");
      await db.execute("UPDATE notas SET categoria = '8' WHERE categoria = 'importante'");
    }
    if (oldVersion < 19) {
      try {
        await db.execute('ALTER TABLE capitulos ADD COLUMN palabras INTEGER DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE capitulos ADD COLUMN meta_sesion INTEGER DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE capitulos ADD COLUMN meta_diaria INTEGER DEFAULT 0');
      } catch (_) {}
      try {
        final caps = await db.query('capitulos', columns: ['id', 'contenido']);
        for (final cap in caps) {
          final content = cap['contenido'] as String? ?? '';
          final words = _countWordsStatic(content);
          await db.update(
            'capitulos',
            {'palabras': words},
            where: 'id = ?',
            whereArgs: [cap['id']],
          );
        }
      } catch (_) {}
    }
    if (oldVersion < 20) {
      try {
        await db.execute("ALTER TABLE capitulos ADD COLUMN sinopsis TEXT DEFAULT ''");
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE capitulos ADD COLUMN pov_personaje_id INTEGER DEFAULT NULL');
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE capitulos ADD COLUMN estado TEXT DEFAULT 'borrador'");
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE capitulos ADD COLUMN meta_palabras INTEGER DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE capitulos ADD COLUMN eliminado_en TIMESTAMP DEFAULT NULL');
      } catch (_) {}
    }
    if (oldVersion < 21) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS grafo_nodos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          proyecto_id INTEGER NOT NULL,
          tipo TEXT NOT NULL,
          referencia_id INTEGER,
          nombre TEXT NOT NULL,
          subtitulo TEXT,
          descripcion TEXT,
          color TEXT,
          pos_x REAL DEFAULT 0.0,
          pos_y REAL DEFAULT 0.0,
          estado TEXT DEFAULT 'activo',
          propiedades TEXT,
          creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (proyecto_id) REFERENCES proyectos(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS grafo_aristas (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          proyecto_id INTEGER NOT NULL,
          nodo_origen_id INTEGER NOT NULL,
          nodo_destino_id INTEGER NOT NULL,
          tipo_relacion TEXT NOT NULL,
          etiqueta TEXT,
          intensidad REAL DEFAULT 1.0,
          es_bidireccional INTEGER DEFAULT 0,
          detalles TEXT,
          creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (proyecto_id) REFERENCES proyectos(id) ON DELETE CASCADE,
          FOREIGN KEY (nodo_origen_id) REFERENCES grafo_nodos(id) ON DELETE CASCADE,
          FOREIGN KEY (nodo_destino_id) REFERENCES grafo_nodos(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS capitulos_coherencia (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          capitulo_id INTEGER NOT NULL UNIQUE,
          lugar_id INTEGER,
          personajes_ids TEXT,
          artefactos_ids TEXT,
          estado_salud TEXT,
          secretos_revelados TEXT,
          notas_continuidad TEXT,
          FOREIGN KEY (capitulo_id) REFERENCES capitulos(id) ON DELETE CASCADE
        )
      ''');
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE proyectos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        sinopsis TEXT,
        imagen_portada TEXT,
        portada_blob BLOB,
        creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('''
      CREATE TABLE manuscritos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        proyecto_id INTEGER NOT NULL,
        contenido TEXT,
        color_fondo TEXT DEFAULT '#FFFFFF',
        fuente TEXT DEFAULT 'Merriweather',
        font_size REAL DEFAULT 18,
        line_height REAL DEFAULT 1.8,
        creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (proyecto_id) REFERENCES proyectos(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS capitulos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        manuscrito_id INTEGER NOT NULL,
        titulo TEXT NOT NULL DEFAULT 'Sin título',
        contenido TEXT DEFAULT '',
        orden INTEGER NOT NULL DEFAULT 0,
        tipo TEXT NOT NULL DEFAULT 'capitulo',
        palabras INTEGER DEFAULT 0,
        meta_sesion INTEGER DEFAULT 0,
        meta_diaria INTEGER DEFAULT 0,
        sinopsis TEXT DEFAULT '',
        pov_personaje_id INTEGER DEFAULT NULL,
        estado TEXT DEFAULT 'borrador',
        meta_palabras INTEGER DEFAULT 0,
        eliminado_en TIMESTAMP DEFAULT NULL,
        creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (manuscrito_id) REFERENCES manuscritos(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS eventos_timeline (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        proyecto_id INTEGER NOT NULL,
        titulo TEXT NOT NULL,
        descripcion TEXT,
        fecha_relativa TEXT,
        importancia INTEGER DEFAULT 1,
        color_hex TEXT DEFAULT '#D4AF37',
        orden INTEGER DEFAULT 0,
        creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (proyecto_id) REFERENCES proyectos(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE notas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        manuscrito_id INTEGER NOT NULL,
        contenido TEXT NOT NULL,
        posicion_cursor INTEGER,
        color TEXT DEFAULT '#FFF9C4',
        categoria TEXT DEFAULT 'general',
        pos_x REAL DEFAULT 0,
        pos_y REAL DEFAULT 0,
        ancho REAL DEFAULT 200,
        alto REAL DEFAULT 150,
        creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (manuscrito_id) REFERENCES manuscritos(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE tarjetas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        proyecto_id INTEGER NOT NULL,
        titulo TEXT NOT NULL,
        contenido TEXT,
        tipo TEXT DEFAULT 'idea',
        color TEXT DEFAULT '#FFCDD2',
        pos_x REAL DEFAULT 0,
        pos_y REAL DEFAULT 0,
        ancho REAL DEFAULT 250,
        alto REAL DEFAULT 200,
        creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (proyecto_id) REFERENCES proyectos(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE tarjetas_conexiones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tarjeta_origen_id INTEGER NOT NULL,
        tarjeta_destino_id INTEGER NOT NULL,
        creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (tarjeta_origen_id) REFERENCES tarjetas(id) ON DELETE CASCADE,
        FOREIGN KEY (tarjeta_destino_id) REFERENCES tarjetas(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE personajes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        proyecto_id INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        rol TEXT,
        alias TEXT,
        frase_iconica TEXT,
        estado_emocional TEXT,
        estado_actual TEXT,
        edad TEXT,
        descripcion TEXT,
        imagen_path TEXT,
        atributos TEXT, -- JSON string
        creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (proyecto_id) REFERENCES proyectos(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE relaciones_personajes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        personaje_a_id INTEGER NOT NULL,
        personaje_b_id INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        intensidad INTEGER DEFAULT 50,
        notas TEXT,
        creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (personaje_a_id) REFERENCES personajes(id) ON DELETE CASCADE,
        FOREIGN KEY (personaje_b_id) REFERENCES personajes(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE lugares (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        proyecto_id INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        clima TEXT,
        poblacion TEXT,
        importancia TEXT DEFAULT 'Secundario',
        imagen_path TEXT,
        atributos TEXT, -- JSON string
        creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (proyecto_id) REFERENCES proyectos(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mapas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        proyecto_id INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        datos_mapa TEXT,
        creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (proyecto_id) REFERENCES proyectos(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS capitulos_versiones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        capitulo_id INTEGER NOT NULL,
        contenido TEXT NOT NULL,
        creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (capitulo_id) REFERENCES capitulos(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS estilos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        proyecto_id INTEGER,
        nombre TEXT NOT NULL,
        orden INTEGER NOT NULL DEFAULT 0,
        hereda_de_id INTEGER,
        atajo TEXT,
        config TEXT NOT NULL DEFAULT '{}',
        es_global INTEGER NOT NULL DEFAULT 0,
        creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (proyecto_id) REFERENCES proyectos(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categorias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        proyecto_id INTEGER,
        nombre TEXT NOT NULL,
        icon TEXT NOT NULL DEFAULT 'auto_awesome',
        color TEXT NOT NULL DEFAULT '#FFF9C4',
        orden INTEGER DEFAULT 0,
        creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (proyecto_id) REFERENCES proyectos(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS grafo_nodos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        proyecto_id INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        referencia_id INTEGER,
        nombre TEXT NOT NULL,
        subtitulo TEXT,
        descripcion TEXT,
        color TEXT,
        pos_x REAL DEFAULT 0.0,
        pos_y REAL DEFAULT 0.0,
        estado TEXT DEFAULT 'activo',
        propiedades TEXT,
        creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (proyecto_id) REFERENCES proyectos(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS grafo_aristas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        proyecto_id INTEGER NOT NULL,
        nodo_origen_id INTEGER NOT NULL,
        nodo_destino_id INTEGER NOT NULL,
        tipo_relacion TEXT NOT NULL,
        etiqueta TEXT,
        intensidad REAL DEFAULT 1.0,
        es_bidireccional INTEGER DEFAULT 0,
        detalles TEXT,
        creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (proyecto_id) REFERENCES proyectos(id) ON DELETE CASCADE,
        FOREIGN KEY (nodo_origen_id) REFERENCES grafo_nodos(id) ON DELETE CASCADE,
        FOREIGN KEY (nodo_destino_id) REFERENCES grafo_nodos(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS capitulos_coherencia (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        capitulo_id INTEGER NOT NULL UNIQUE,
        lugar_id INTEGER,
        personajes_ids TEXT,
        artefactos_ids TEXT,
        estado_salud TEXT,
        secretos_revelados TEXT,
        notas_continuidad TEXT,
        FOREIGN KEY (capitulo_id) REFERENCES capitulos(id) ON DELETE CASCADE
      )
    ''');
    await _seedDefaultCategorias(db);
    await _seedGlobalStyles(db);
  }

  static Future<void> _seedDefaultCategorias(Database db) async {
    final existing = await db.query('categorias', where: 'proyecto_id IS NULL', limit: 1);
    if (existing.isNotEmpty) return;
    final defaults = [
      {'nombre': 'General', 'icon': 'auto_awesome', 'color': '#FFF9C4', 'orden': 0},
      {'nombre': 'Idea', 'icon': 'lightbulb_outline', 'color': '#C8E6C9', 'orden': 1},
      {'nombre': 'Personaje', 'icon': 'person_outline', 'color': '#E1BEE7', 'orden': 2},
      {'nombre': 'Trama', 'icon': 'alt_route', 'color': '#FFE0B2', 'orden': 3},
      {'nombre': 'Escena', 'icon': 'movie_creation_outlined', 'color': '#BBDEFB', 'orden': 4},
      {'nombre': 'Investigación', 'icon': 'search_outlined', 'color': '#C5CAE9', 'orden': 5},
      {'nombre': 'Diálogo', 'icon': 'format_quote_outlined', 'color': '#F8BBD9', 'orden': 6},
      {'nombre': 'Importante', 'icon': 'priority_high', 'color': '#FFCDD2', 'orden': 7},
    ];
    for (final cat in defaults) {
      await db.insert('categorias', {
        'proyecto_id': null,
        ...cat,
        'creado_en': DateTime.now().toIso8601String(),
      });
    }
  }

  static Future<void> _seedGlobalStyles(Database db) async {
    final existing = await db.query('estilos', where: 'es_global = 1', limit: 1);
    if (existing.isNotEmpty) return;

    final insertedIds = <int, int>{};
    for (int i = 0; i < defaultStyleConfigs.length; i++) {
      final estilo = defaultStyleConfigs[i];
      final rawHereda = estilo['hereda_de_id'] as int?;
      final parentId = rawHereda != null ? insertedIds[rawHereda - 1] : null;

      final id = await db.insert('estilos', {
        'proyecto_id': null,
        'nombre': estilo['nombre'],
        'orden': estilo['orden'],
        'hereda_de_id': parentId,
        'atajo': estilo['atajo'],
        'config': jsonEncode(estilo['config']),
        'es_global': 1,
        'creado_en': DateTime.now().toIso8601String(),
        'actualizado_en': DateTime.now().toIso8601String(),
      });
      insertedIds[i] = id;
    }
  }

  // ── Proyectos ──────────────────────────────────────────
  static Future<int> insertProyecto(Map<String, dynamic> proyecto) async {
    final db = await database;
    final id = await db.insert('proyectos', proyecto);
    await insertEstilosPorDefecto(id);
    return id;
  }

  static Future<List<Map<String, dynamic>>> getProyectos() async {
    final db = await database;
    return await db.query('proyectos', orderBy: 'actualizado_en DESC');
  }

  static const _proyectoColumns = [
    'id', 'titulo', 'sinopsis', 'imagen_portada', 'portada_blob',
    'creado_en', 'actualizado_en',
  ];

  static Future<int> updateProyecto(Map<String, dynamic> proyecto) async {
    final db = await database;
    final data = {
      for (var col in _proyectoColumns)
        if (proyecto.containsKey(col) && col != 'id' && col != 'creado_en')
          col: proyecto[col],
      'actualizado_en': DateTime.now().toIso8601String(),
    };
    return await db.update(
      'proyectos',
      data,
      where: 'id = ?',
      whereArgs: [proyecto['id']],
    );
  }

  static Future<void> updateProyectoPortada(int id, Uint8List? imageBytes) async {
    final db = await database;
    await db.update(
      'proyectos',
      {
        'portada_blob': imageBytes,
        'actualizado_en': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Actualiza título y sinopsis de un proyecto.
  static Future<int> updateProyectoCompleto(
    int id,
    String titulo,
    String sinopsis,
  ) async {
    final db = await database;
    return await db.update(
      'proyectos',
      {
        'titulo': titulo,
        'sinopsis': sinopsis,
        'actualizado_en': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> deleteProyecto(int id) async {
    final db = await database;
    return await db.delete('proyectos', where: 'id = ?', whereArgs: [id]);
  }

  static Future<Map<String, dynamic>> getProyectoStats(int proyectoId) async {
    final db = await database;

    final statsCapitulos = await db.rawQuery('''
      SELECT COUNT(c.id) as capitulos, COALESCE(SUM(c.palabras), 0) as palabras
      FROM capitulos c
      JOIN manuscritos m ON c.manuscrito_id = m.id
      WHERE m.proyecto_id = ? AND c.eliminado_en IS NULL
    ''', [proyectoId]);

    int capituloCount = 0;
    int wordCount = 0;
    if (statsCapitulos.isNotEmpty) {
      capituloCount = (statsCapitulos.first['capitulos'] as num?)?.toInt() ?? 0;
      wordCount = (statsCapitulos.first['palabras'] as num?)?.toInt() ?? 0;
    }

    final resPj = await db.rawQuery(
      'SELECT COUNT(*) as c FROM personajes WHERE proyecto_id = ?',
      [proyectoId],
    );
    final countPersonajes = resPj.isNotEmpty ? ((resPj.first['c'] as num?)?.toInt() ?? 0) : 0;

    final resLug = await db.rawQuery(
      'SELECT COUNT(*) as c FROM lugares WHERE proyecto_id = ?',
      [proyectoId],
    );
    final countLugares = resLug.isNotEmpty ? ((resLug.first['c'] as num?)?.toInt() ?? 0) : 0;

    final resEv = await db.rawQuery(
      'SELECT COUNT(*) as c FROM eventos_timeline WHERE proyecto_id = ?',
      [proyectoId],
    );
    final countEventos = resEv.isNotEmpty ? ((resEv.first['c'] as num?)?.toInt() ?? 0) : 0;

    return {
      'capitulos': capituloCount,
      'palabras': wordCount,
      'personajes': countPersonajes,
      'lugares': countLugares,
      'eventos': countEventos,
    };
  }

  static Future<int> duplicateProyecto(int proyectoId) async {
    final db = await database;

    // Obtener el proyecto original
    final proyectos = await db.query(
      'proyectos',
      where: 'id = ?',
      whereArgs: [proyectoId],
    );

    if (proyectos.isEmpty) return -1;

    final original = proyectos.first;

    // Crear nuevo proyecto con título modificado
    final nuevoProyecto = {
      'titulo': '${original['titulo']} (copia)',
      'sinopsis': original['sinopsis'],
      'creado_en': DateTime.now().toIso8601String(),
      'actualizado_en': DateTime.now().toIso8601String(),
    };

    final nuevoId = await db.insert('proyectos', nuevoProyecto);

    // Duplicar manuscrito si existe
    final manuscritoResult = await db.query(
      'manuscritos',
      where: 'proyecto_id = ?',
      whereArgs: [proyectoId],
      limit: 1,
    );

    if (manuscritoResult.isNotEmpty) {
      final manuscrito = manuscritoResult.first;
      final nuevoManuscrito = {
        'proyecto_id': nuevoId,
        'contenido': manuscrito['contenido'],
        'color_fondo': manuscrito['color_fondo'],
        'fuente': manuscrito['fuente'],
        'font_size': manuscrito['font_size'],
        'line_height': manuscrito['line_height'],
        'creado_en': DateTime.now().toIso8601String(),
        'actualizado_en': DateTime.now().toIso8601String(),
      };
      final nuevoManuscritoId = await db.insert('manuscritos', nuevoManuscrito);

      // Duplicar capítulos
      final capitulos = await db.query(
        'capitulos',
        where: 'manuscrito_id = ?',
        whereArgs: [manuscrito['id']],
        orderBy: 'orden ASC',
      );

      for (var cap in capitulos) {
        await db.insert('capitulos', {
          'manuscrito_id': nuevoManuscritoId,
          'titulo': cap['titulo'],
          'contenido': cap['contenido'],
          'orden': cap['orden'],
          'tipo': cap['tipo'],
          'creado_en': DateTime.now().toIso8601String(),
          'actualizado_en': DateTime.now().toIso8601String(),
        });
      }
    }

    // Duplicar personajes
    final personajes = await db.query(
      'personajes',
      where: 'proyecto_id = ?',
      whereArgs: [proyectoId],
    );

    for (var pers in personajes) {
      await db.insert('personajes', {
        'proyecto_id': nuevoId,
        'nombre': pers['nombre'],
        'rol': pers['rol'],
        'alias': pers['alias'],
        'frase_iconica': pers['frase_iconica'],
        'estado_emocional': pers['estado_emocional'],
        'estado_actual': pers['estado_actual'],
        'edad': pers['edad'],
        'descripcion': pers['descripcion'],
        'imagen_path': pers['imagen_path'],
        'atributos': pers['atributos'],
        'creado_en': DateTime.now().toIso8601String(),
        'actualizado_en': DateTime.now().toIso8601String(),
      });
    }

    // Duplicar lugares
    final lugares = await db.query(
      'lugares',
      where: 'proyecto_id = ?',
      whereArgs: [proyectoId],
    );

    for (var lug in lugares) {
      await db.insert('lugares', {
        'proyecto_id': nuevoId,
        'nombre': lug['nombre'],
        'descripcion': lug['descripcion'],
        'clima': lug['clima'],
        'poblacion': lug['poblacion'],
        'importancia': lug['importancia'],
        'imagen_path': lug['imagen_path'],
        'atributos': lug['atributos'],
        'creado_en': DateTime.now().toIso8601String(),
        'actualizado_en': DateTime.now().toIso8601String(),
      });
    }

    // Duplicar eventos de timeline
    final eventos = await db.query(
      'eventos_timeline',
      where: 'proyecto_id = ?',
      whereArgs: [proyectoId],
      orderBy: 'orden ASC',
    );

    for (var ev in eventos) {
      await db.insert('eventos_timeline', {
        'proyecto_id': nuevoId,
        'titulo': ev['titulo'],
        'descripcion': ev['descripcion'],
        'fecha_relativa': ev['fecha_relativa'],
        'importancia': ev['importancia'],
        'color_hex': ev['color_hex'],
        'orden': ev['orden'],
        'creado_en': DateTime.now().toIso8601String(),
        'actualizado_en': DateTime.now().toIso8601String(),
      });
    }

    // Duplicar estilos personalizados del proyecto (excluye globales)
    final estilos = await db.query(
      'estilos',
      where: 'proyecto_id = ? AND es_global = 0',
      whereArgs: [proyectoId],
    );

    for (var est in estilos) {
      await db.insert('estilos', {
        'proyecto_id': nuevoId,
        'nombre': est['nombre'],
        'orden': est['orden'],
        'hereda_de_id': est['hereda_de_id'],
        'atajo': est['atajo'],
        'config': est['config'],
        'es_global': 0,
        'creado_en': DateTime.now().toIso8601String(),
        'actualizado_en': DateTime.now().toIso8601String(),
      });
    }

    return nuevoId;
  }

  // ── Manuscritos ────────────────────────────────────────
  static Future<int> insertManuscrito(Map<String, dynamic> manuscrito) async {
    final db = await database;
    return await db.insert('manuscritos', manuscrito);
  }

  static Future<Map<String, dynamic>?> getManuscritoByProyecto(
    int proyectoId,
  ) async {
    final db = await database;
    final results = await db.query(
      'manuscritos',
      where: 'proyecto_id = ?',
      whereArgs: [proyectoId],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  static Future<int> updateManuscrito(int id, String contenido) async {
    final db = await database;
    return await db.update(
      'manuscritos',
      {
        'contenido': contenido,
        'actualizado_en': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── Notas ──────────────────────────────────────────────
  static Future<int> insertNota(Map<String, dynamic> nota) async {
    final db = await database;
    return await db.insert('notas', nota);
  }

  static Future<List<Map<String, dynamic>>> getNotasByManuscrito(
    int manuscritoId,
  ) async {
    final db = await database;
    return await db.query(
      'notas',
      where: 'manuscrito_id = ?',
      whereArgs: [manuscritoId],
    );
  }

  static Future<int> updateNotaPosicion(int id, double x, double y) async {
    final db = await database;
    return await db.update(
      'notas',
      {
        'pos_x': x,
        'pos_y': y,
        'actualizado_en': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Guarda el texto editado de una nota.
  static Future<int> updateNotaContenido(int id, String contenido) async {
    final db = await database;
    return await db.update(
      'notas',
      {
        'contenido': contenido,
        'actualizado_en': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> deleteNota(int id) async {
    final db = await database;
    return await db.delete('notas', where: 'id = ?', whereArgs: [id]);
  }

  // ── Categorías ─────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getCategorias() async {
    final db = await database;
    return await db.query('categorias', where: 'proyecto_id IS NULL', orderBy: 'orden ASC');
  }

  static Future<int> insertCategoria(Map<String, dynamic> cat) async {
    final db = await database;
    return await db.insert('categorias', cat);
  }

  static Future<int> updateCategoria(int id, Map<String, dynamic> cat) async {
    final db = await database;
    return await db.update('categorias', cat, where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> deleteCategoria(int id) async {
    final db = await database;
    return await db.delete('categorias', where: 'id = ?', whereArgs: [id]);
  }

  // ── Tarjetas ───────────────────────────────────────────
  static Future<int> insertTarjeta(Map<String, dynamic> tarjeta) async {
    final db = await database;
    return await db.insert('tarjetas', tarjeta);
  }

  static Future<List<Map<String, dynamic>>> getTarjetasByProyecto(
    int proyectoId,
  ) async {
    final db = await database;
    return await db.query(
      'tarjetas',
      where: 'proyecto_id = ?',
      whereArgs: [proyectoId],
    );
  }

  static Future<int> updateTarjetaPosicion(int id, double x, double y) async {
    final db = await database;
    return await db.update(
      'tarjetas',
      {
        'pos_x': x,
        'pos_y': y,
        'actualizado_en': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Guarda título, contenido y tipo de una tarjeta.
  static Future<int> updateTarjetaCompleta(
    int id,
    String titulo,
    String contenido,
    String tipo,
  ) async {
    final db = await database;
    return await db.update(
      'tarjetas',
      {
        'titulo': titulo,
        'contenido': contenido,
        'tipo': tipo,
        'actualizado_en': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> deleteTarjeta(int id) async {
    final db = await database;
    return await db.delete('tarjetas', where: 'id = ?', whereArgs: [id]);
  }

  // ── Conexiones de Tarjetas ──────────────────────────────
  static Future<int> insertConexion(int origenId, int destinoId) async {
    final db = await database;
    // Evitar duplicados o lazos a sí mismo
    if (origenId == destinoId) return -1;
    final exist = await db.query(
      'tarjetas_conexiones',
      where: '(tarjeta_origen_id = ? AND tarjeta_destino_id = ?) OR (tarjeta_origen_id = ? AND tarjeta_destino_id = ?)',
      whereArgs: [origenId, destinoId, destinoId, origenId],
    );
    if (exist.isNotEmpty) return -1;
    return await db.insert('tarjetas_conexiones', {
      'tarjeta_origen_id': origenId,
      'tarjeta_destino_id': destinoId,
    });
  }

  static Future<List<Map<String, dynamic>>> getConexionesByProyecto(
    int proyectoId,
  ) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT tc.* 
      FROM tarjetas_conexiones tc
      JOIN tarjetas t1 ON tc.tarjeta_origen_id = t1.id
      JOIN tarjetas t2 ON tc.tarjeta_destino_id = t2.id
      WHERE t1.proyecto_id = ? AND t2.proyecto_id = ?
    ''', [proyectoId, proyectoId]);
  }

  static Future<int> deleteConexion(int origenId, int destinoId) async {
    final db = await database;
    return await db.delete(
      'tarjetas_conexiones',
      where: '(tarjeta_origen_id = ? AND tarjeta_destino_id = ?) OR (tarjeta_origen_id = ? AND tarjeta_destino_id = ?)',
      whereArgs: [origenId, destinoId, destinoId, origenId],
    );
  }

  // ── Personajes ──────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getPersonajesByProyecto(
    int proyectoId,
  ) async {
    final db = await database;
    return await db.query(
      'personajes',
      where: 'proyecto_id = ?',
      whereArgs: [proyectoId],
      orderBy: 'actualizado_en DESC',
    );
  }

  static Future<int> insertPersonaje(Map<String, dynamic> personaje) async {
    final db = await database;
    return await db.insert('personajes', personaje);
  }

  static Future<int> updatePersonaje(
    int id,
    Map<String, dynamic> personaje,
  ) async {
    final db = await database;
    return await db.update(
      'personajes',
      personaje,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> deletePersonaje(int id) async {
    final db = await database;
    return await db.delete('personajes', where: 'id = ?', whereArgs: [id]);
  }

  // ── Relaciones ──────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getRelacionesByPersonaje(
    int personajeId,
  ) async {
    final db = await database;
    // Buscamos relaciones donde el personaje sea A o B
    return await db.rawQuery(
      '''
      SELECT r.*, p.nombre as nombre_otro, p.imagen_path as imagen_otro
      FROM relaciones_personajes r
      JOIN personajes p ON (r.personaje_b_id = p.id AND r.personaje_a_id = ?) 
                        OR (r.personaje_a_id = p.id AND r.personaje_b_id = ?)
      WHERE r.personaje_a_id = ? OR r.personaje_b_id = ?
    ''',
      [personajeId, personajeId, personajeId, personajeId],
    );
  }

  static Future<int> insertRelacion(Map<String, dynamic> relacion) async {
    final db = await database;
    return await db.insert('relaciones_personajes', relacion);
  }

  static Future<int> updateRelacion(
    int id,
    Map<String, dynamic> relacion,
  ) async {
    final db = await database;
    return await db.update(
      'relaciones_personajes',
      relacion,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> deleteRelacion(int id) async {
    final db = await database;
    return await db.delete(
      'relaciones_personajes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── Capítulos ──────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getCapitulosByManuscrito(
    int manuscritoId, {
    bool includeTrash = false,
  }) async {
    final db = await database;
    return await db.query(
      'capitulos',
      where: includeTrash
          ? 'manuscrito_id = ?'
          : 'manuscrito_id = ? AND eliminado_en IS NULL',
      whereArgs: [manuscritoId],
      orderBy: 'orden ASC',
    );
  }

  static Future<List<Map<String, dynamic>>> getCapitulosPapelera(int manuscritoId) async {
    final db = await database;
    return await db.query(
      'capitulos',
      where: 'manuscrito_id = ? AND eliminado_en IS NOT NULL',
      whereArgs: [manuscritoId],
      orderBy: 'eliminado_en DESC',
    );
  }

  static Future<int> insertCapitulo(Map<String, dynamic> capitulo) async {
    final db = await database;
    final map = Map<String, dynamic>.from(capitulo);
    if (map.containsKey('contenido') && !map.containsKey('palabras')) {
      map['palabras'] = _countWordsStatic(map['contenido'] as String? ?? '');
    }
    return await db.insert('capitulos', map);
  }

  static Future<int> updateCapitulo(int id, Map<String, dynamic> data) async {
    final db = await database;
    final map = Map<String, dynamic>.from(data);
    map['actualizado_en'] = DateTime.now().toIso8601String();
    if (map.containsKey('contenido') && !map.containsKey('palabras')) {
      map['palabras'] = _countWordsStatic(map['contenido'] as String? ?? '');
    }
    return await db.update('capitulos', map, where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> softDeleteCapitulo(int id) async {
    final db = await database;
    return await db.update(
      'capitulos',
      {'eliminado_en': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> restoreCapitulo(int id) async {
    final db = await database;
    return await db.update(
      'capitulos',
      {'eliminado_en': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> deleteCapitulo(int id) async {
    final db = await database;
    return await db.delete('capitulos', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> emptyTrash(int manuscritoId) async {
    final db = await database;
    return await db.delete(
      'capitulos',
      where: 'manuscrito_id = ? AND eliminado_en IS NOT NULL',
      whereArgs: [manuscritoId],
    );
  }

  // ── Timeline ──────────────────────────────────────────
  static Future<void> _ensureEventTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS eventos_timeline (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        proyecto_id INTEGER NOT NULL,
        titulo TEXT NOT NULL,
        descripcion TEXT,
        fecha_relativa TEXT,
        importancia INTEGER DEFAULT 1,
        color_hex TEXT DEFAULT '#D4AF37',
        orden INTEGER DEFAULT 0,
        creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (proyecto_id) REFERENCES proyectos(id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<List<Map<String, dynamic>>> getEventosByProyecto(
    int proyectoId,
  ) async {
    final db = await database;
    await _ensureEventTable(db);
    return await db.query(
      'eventos_timeline',
      where: 'proyecto_id = ?',
      whereArgs: [proyectoId],
      orderBy: 'orden ASC',
    );
  }

  static Future<int> insertEvento(Map<String, dynamic> evento) async {
    final db = await database;
    await _ensureEventTable(db);
    return await db.insert('eventos_timeline', evento);
  }

  static Future<int> updateEvento(int id, Map<String, dynamic> data) async {
    final db = await database;
    await _ensureEventTable(db);
    data['actualizado_en'] = DateTime.now().toIso8601String();
    return await db.update(
      'eventos_timeline',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> batchUpdateOrden(List<Map<String, dynamic>> eventos) async {
    final db = await database;
    await _ensureEventTable(db);
    await db.transaction((txn) async {
      for (int i = 0; i < eventos.length; i++) {
        await txn.update(
          'eventos_timeline',
          {'orden': i, 'actualizado_en': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [eventos[i]['id'] as int],
        );
      }
    });
  }

  static Future<int> deleteEvento(int id) async {
    final db = await database;
    await _ensureEventTable(db);
    return await db.delete(
      'eventos_timeline',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── Lugares ──────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getLugaresByProyecto(
    int proyectoId,
  ) async {
    final db = await database;
    return await db.query(
      'lugares',
      where: 'proyecto_id = ?',
      whereArgs: [proyectoId],
      orderBy: 'actualizado_en DESC',
    );
  }

  static Future<int> insertLugar(Map<String, dynamic> lugar) async {
    final db = await database;
    return await db.insert('lugares', lugar);
  }

  static Future<int> updateLugar(int id, Map<String, dynamic> lugar) async {
    final db = await database;
    return await db.update('lugares', lugar, where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> deleteLugar(int id) async {
    final db = await database;
    return await db.delete('lugares', where: 'id = ?', whereArgs: [id]);
  }

  // ── Mapas ──────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getMapasByProyecto(int proyectoId) async {
    final db = await database;
    return await db.query(
      'mapas',
      where: 'proyecto_id = ?',
      whereArgs: [proyectoId],
      orderBy: 'actualizado_en DESC',
    );
  }

  static Future<int> insertMapa(Map<String, dynamic> mapa) async {
    final db = await database;
    return await db.insert('mapas', mapa);
  }

  static Future<int> updateMapa(int id, Map<String, dynamic> mapa) async {
    final db = await database;
    mapa['actualizado_en'] = DateTime.now().toIso8601String();
    return await db.update(
      'mapas',
      mapa,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> deleteMapa(int id) async {
    final db = await database;
    return await db.delete(
      'mapas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> insertCapituloVersion(
    int capituloId,
    String contenido, {
    int palabras = 0,
    String? motivo,
  }) async {
    final db = await database;
    return await db.insert('capitulos_versiones', {
      'capitulo_id': capituloId,
      'contenido': contenido,
      'palabras': palabras,
      'motivo': motivo,
      'creado_en': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getCapituloVersiones(int capituloId) async {
    final db = await database;
    return await db.query(
      'capitulos_versiones',
      where: 'capitulo_id = ?',
      whereArgs: [capituloId],
      orderBy: 'creado_en DESC',
    );
  }

  static Future<int> deleteCapituloVersion(int versionId) async {
    final db = await database;
    return await db.delete(
      'capitulos_versiones',
      where: 'id = ?',
      whereArgs: [versionId],
    );
  }

  // ── Estilos ──────────────────────────────────────────────────────────────

  static Future<int> insertEstilo(Map<String, dynamic> estilo) async {
    final db = await database;
    return await db.insert('estilos', {
      ...estilo,
      'creado_en': DateTime.now().toIso8601String(),
      'actualizado_en': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getEstilos(int proyectoId) async {
    final db = await database;

    final globales = await db.query(
      'estilos',
      where: 'es_global = 1',
      orderBy: 'orden ASC, id ASC',
    );

    final locales = await db.query(
      'estilos',
      where: 'proyecto_id = ? AND es_global = 0',
      whereArgs: [proyectoId],
      orderBy: 'orden ASC, id ASC',
    );

    final localNames = locales.map((e) => e['nombre'] as String).toSet();

    final globalByName = <String, Map<String, dynamic>>{};
    for (final g in globales) {
      globalByName[g['nombre'] as String] = g;
    }

    final result = <Map<String, dynamic>>[];

    for (final g in globales) {
      if (!localNames.contains(g['nombre'] as String)) {
        result.add(g);
      }
    }

    for (final l in locales) {
      final matchingGlobal = globalByName[l['nombre'] as String];
      if (matchingGlobal != null) {
        final globalConfig = jsonDecode(matchingGlobal['config'] as String) as Map<String, dynamic>;
        final localConfig = jsonDecode(l['config'] as String) as Map<String, dynamic>;
        final mergedConfig = Map<String, dynamic>.from(globalConfig);
        mergedConfig.addAll(localConfig);
        final mergedRow = Map<String, dynamic>.from(l);
        mergedRow['config'] = jsonEncode(mergedConfig);
        result.add(mergedRow);
      } else {
        result.add(l);
      }
    }

    return result;
  }

  /// Returns only global styles (shared across all projects).
  static Future<List<Map<String, dynamic>>> getEstilosGlobales() async {
    final db = await database;
    return await db.query(
      'estilos',
      where: 'es_global = 1',
      orderBy: 'orden ASC, id ASC',
    );
  }

  static Future<Map<String, dynamic>?> getEstilo(int id) async {
    final db = await database;
    final results = await db.query('estilos', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  static Future<int> updateEstilo(int id, Map<String, dynamic> estilo) async {
    final db = await database;
    return await db.update(
      'estilos',
      {
        ...estilo,
        'actualizado_en': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> deleteEstilo(int id) async {
    final db = await database;
    return await db.delete('estilos', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> insertEstilosPorDefecto(int proyectoId) async {
    // Global styles are used by default.
    // Project-specific overrides are created only when the user forks a style.
  }

  /// Creates a project-specific copy of a global style.
  /// The new style inherits from the global (hereda_de_id = globalStyleId).
  /// Returns the new style's id.
  static Future<int> forkEstiloGlobal(int globalStyleId, int proyectoId) async {
    final db = await database;
    final rows = await db.query('estilos', where: 'id = ?', whereArgs: [globalStyleId]);
    if (rows.isEmpty) return -1;
    final global = rows.first;
    return await db.insert('estilos', {
      'proyecto_id': proyectoId,
      'nombre': global['nombre'],
      'orden': global['orden'],
      'hereda_de_id': globalStyleId,
      'atajo': global['atajo'],
      'config': global['config'],
      'es_global': 0,
      'creado_en': DateTime.now().toIso8601String(),
      'actualizado_en': DateTime.now().toIso8601String(),
    });
  }

  /// Removes a project-specific style override, reverting to the global style.
  static Future<int> revertEstiloToGlobal(int localStyleId) async {
    final db = await database;
    return await db.delete('estilos', where: 'id = ?', whereArgs: [localStyleId]);
  }

  // ==========================================
  // GRAFO DE CONOCIMIENTO NARRATIVO (LORE GRAPH)
  // ==========================================

  static Future<List<Map<String, dynamic>>> getGrafoNodos(int proyectoId) async {
    final db = await database;
    return await db.query(
      'grafo_nodos',
      where: 'proyecto_id = ?',
      whereArgs: [proyectoId],
      orderBy: 'tipo ASC, nombre ASC',
    );
  }

  static Future<int> insertGrafoNodo(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('grafo_nodos', data);
  }

  static Future<int> updateGrafoNodo(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update('grafo_nodos', data, where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> deleteGrafoNodo(int id) async {
    final db = await database;
    await db.delete('grafo_aristas', where: 'nodo_origen_id = ? OR nodo_destino_id = ?', whereArgs: [id, id]);
    return await db.delete('grafo_nodos', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Map<String, dynamic>>> getGrafoAristas(int proyectoId) async {
    final db = await database;
    return await db.query(
      'grafo_aristas',
      where: 'proyecto_id = ?',
      whereArgs: [proyectoId],
    );
  }

  static Future<int> insertGrafoArista(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('grafo_aristas', data);
  }

  static Future<int> updateGrafoArista(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update('grafo_aristas', data, where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> deleteGrafoArista(int id) async {
    final db = await database;
    return await db.delete('grafo_aristas', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // COHERENCIA DE CAPÍTULOS
  // ==========================================

  static Future<Map<String, dynamic>?> getCapituloCoherencia(int capituloId) async {
    final db = await database;
    final results = await db.query(
      'capitulos_coherencia',
      where: 'capitulo_id = ?',
      whereArgs: [capituloId],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  static Future<int> upsertCapituloCoherencia(int capituloId, Map<String, dynamic> data) async {
    final db = await database;
    final existing = await getCapituloCoherencia(capituloId);
    if (existing != null) {
      return await db.update(
        'capitulos_coherencia',
        data,
        where: 'capitulo_id = ?',
        whereArgs: [capituloId],
      );
    } else {
      return await db.insert('capitulos_coherencia', {
        ...data,
        'capitulo_id': capituloId,
      });
    }
  }

  /// Sincroniza entidades existentes (personajes, lugares y relaciones) en el grafo de lore
  /// si aún no existen nodos para este proyecto.
  static Future<void> syncGrafoFromProjectEntities(int proyectoId) async {
    final db = await database;
    final existingNodes = await getGrafoNodos(proyectoId);
    if (existingNodes.isNotEmpty) return;

    final personajes = await getPersonajesByProyecto(proyectoId);
    final Map<int, int> personajeToNodoMap = {};

    for (int i = 0; i < personajes.length; i++) {
      final p = personajes[i];
      final angle = (i / (personajes.isEmpty ? 1 : personajes.length)) * 2 * 3.14159;
      final posX = 500.0 + 260.0 * math.cos(angle);
      final posY = 500.0 + 260.0 * math.sin(angle);

      final nodoId = await insertGrafoNodo({
        'proyecto_id': proyectoId,
        'tipo': 'personaje',
        'referencia_id': p['id'],
        'nombre': p['nombre'],
        'subtitulo': p['rol'] ?? 'Personaje',
        'descripcion': p['descripcion'] ?? '',
        'color': '#00F0FF', // Accent cyan
        'pos_x': posX,
        'pos_y': posY,
        'estado': 'activo',
        'propiedades': jsonEncode({
          'arquetipo': p['arquetipo'] ?? '',
          'objetivo': p['objetivo'] ?? '',
          'imagen_path': p['imagen_path'],
        }),
      });
      personajeToNodoMap[p['id'] as int] = nodoId;
    }

    // Sincronizar Lugares
    final lugares = await getLugaresByProyecto(proyectoId);
    for (int i = 0; i < lugares.length; i++) {
      final l = lugares[i];
      final posX = 500.0 + (i % 2 == 0 ? -180.0 : 180.0);
      final posY = 500.0 + (i % 2 == 0 ? -180.0 : 180.0);

      await insertGrafoNodo({
        'proyecto_id': proyectoId,
        'tipo': 'lugar',
        'referencia_id': l['id'],
        'nombre': l['nombre'],
        'subtitulo': l['tipo'] ?? 'Lugar',
        'descripcion': l['descripcion'] ?? '',
        'color': '#34C759', // Green
        'pos_x': posX,
        'pos_y': posY,
        'estado': 'activo',
        'propiedades': jsonEncode({
          'imagen_path': l['imagen_path'],
        }),
      });
    }

    // Sincronizar Relaciones de personajes
    for (final p in personajes) {
      final pId = p['id'] as int;
      final rels = await getRelacionesByPersonaje(pId);
      for (final r in rels) {
        final destPId = r['personaje_destino_id'] as int?;
        if (destPId != null && personajeToNodoMap.containsKey(pId) && personajeToNodoMap.containsKey(destPId)) {
          final origenNodoId = personajeToNodoMap[pId]!;
          final destinoNodoId = personajeToNodoMap[destPId]!;
          // Evitar aristas duplicadas
          final exists = await db.query(
            'grafo_aristas',
            where: 'proyecto_id = ? AND nodo_origen_id = ? AND nodo_destino_id = ?',
            whereArgs: [proyectoId, origenNodoId, destinoNodoId],
          );
          if (exists.isEmpty) {
            await insertGrafoArista({
              'proyecto_id': proyectoId,
              'nodo_origen_id': origenNodoId,
              'nodo_destino_id': destinoNodoId,
              'tipo_relacion': r['tipo'] ?? 'relacion',
              'etiqueta': r['tipo'] ?? 'Relación',
              'intensidad': ((r['intensidad'] as num?)?.toDouble() ?? 50.0) / 100.0,
              'es_bidireccional': 1,
              'detalles': r['descripcion'] ?? '',
            });
          }
        }
      }
    }
  }
}
