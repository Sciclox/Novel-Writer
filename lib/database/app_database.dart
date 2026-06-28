import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';

class AppDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'novel_writer.db');
    return await openDatabase(
      path,
      version: 13,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

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
  }

  // ── Proyectos ──────────────────────────────────────────
  static Future<int> insertProyecto(Map<String, dynamic> proyecto) async {
    final db = await database;
    return await db.insert('proyectos', proyecto);
  }

  static Future<List<Map<String, dynamic>>> getProyectos() async {
    final db = await database;
    return await db.query('proyectos', orderBy: 'actualizado_en DESC');
  }

  static Future<int> updateProyecto(Map<String, dynamic> proyecto) async {
    final db = await database;
    return await db.update(
      'proyectos',
      {...proyecto, 'actualizado_en': DateTime.now().toIso8601String()},
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

    // Contar capítulos
    final manuscritoResult = await db.query(
      'manuscritos',
      where: 'proyecto_id = ?',
      whereArgs: [proyectoId],
      limit: 1,
    );

    int capituloCount = 0;
    int wordCount = 0;

    if (manuscritoResult.isNotEmpty) {
      final manuscritoId = manuscritoResult.first['id'];
      final capitulos = await db.query(
        'capitulos',
        where: 'manuscrito_id = ?',
        whereArgs: [manuscritoId],
      );
      capituloCount = capitulos.length;

      // Contar palabras en todos los capítulos
      for (var cap in capitulos) {
        final contenido = cap['contenido'] as String? ?? '';
        String plainText = contenido;
        if (contenido.trim().startsWith('[') && contenido.trim().endsWith(']')) {
          try {
            final List<dynamic> json = jsonDecode(contenido);
            final sb = StringBuffer();
            for (var op in json) {
              if (op is Map && op.containsKey('insert')) {
                final insertVal = op['insert'];
                if (insertVal is String) {
                  sb.write(insertVal);
                }
              }
            }
            plainText = sb.toString();
          } catch (e) {
            // Fallback
          }
        }
        wordCount += plainText
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .length;
      }
    }

    // Contar personajes
    final personajes = await db.query(
      'personajes',
      where: 'proyecto_id = ?',
      whereArgs: [proyectoId],
    );

    // Contar lugares
    final lugares = await db.query(
      'lugares',
      where: 'proyecto_id = ?',
      whereArgs: [proyectoId],
    );

    // Contar eventos de timeline
    final eventos = await db.query(
      'eventos_timeline',
      where: 'proyecto_id = ?',
      whereArgs: [proyectoId],
    );

    return {
      'capitulos': capituloCount,
      'palabras': wordCount,
      'personajes': personajes.length,
      'lugares': lugares.length,
      'eventos': eventos.length,
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
    int manuscritoId,
  ) async {
    final db = await database;
    return await db.query(
      'capitulos',
      where: 'manuscrito_id = ?',
      whereArgs: [manuscritoId],
      orderBy: 'orden ASC',
    );
  }

  static Future<int> insertCapitulo(Map<String, dynamic> capitulo) async {
    final db = await database;
    return await db.insert('capitulos', capitulo);
  }

  static Future<int> updateCapitulo(int id, Map<String, dynamic> data) async {
    final db = await database;
    data['actualizado_en'] = DateTime.now().toIso8601String();
    return await db.update('capitulos', data, where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> deleteCapitulo(int id) async {
    final db = await database;
    return await db.delete('capitulos', where: 'id = ?', whereArgs: [id]);
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
}
