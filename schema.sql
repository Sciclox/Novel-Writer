-- ============================================================
-- NOVEL-WRITER DATABASE DDL SCHEMA
-- Generado automáticamente por Antigravity DDL Extractor
-- Base de datos: novel_writer.db
-- ============================================================

-- [TABLE] capitulos
CREATE TABLE capitulos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          manuscrito_id INTEGER NOT NULL,
          titulo TEXT NOT NULL DEFAULT 'Sin título',
          contenido TEXT DEFAULT '',
          orden INTEGER NOT NULL DEFAULT 0,
          creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP, tipo TEXT NOT NULL DEFAULT "capitulo", palabras INTEGER DEFAULT 0, meta_sesion INTEGER DEFAULT 0, meta_diaria INTEGER DEFAULT 0, sinopsis TEXT DEFAULT '', pov_personaje_id INTEGER DEFAULT NULL, estado TEXT DEFAULT 'borrador', meta_palabras INTEGER DEFAULT 0, eliminado_en TIMESTAMP DEFAULT NULL,
          FOREIGN KEY (manuscrito_id) REFERENCES manuscritos(id) ON DELETE CASCADE
        );

-- [TABLE] capitulos_coherencia
CREATE TABLE capitulos_coherencia (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          capitulo_id INTEGER NOT NULL UNIQUE,
          lugar_id INTEGER,
          personajes_ids TEXT,
          artefactos_ids TEXT,
          estado_salud TEXT,
          secretos_revelados TEXT,
          notas_continuidad TEXT,
          FOREIGN KEY (capitulo_id) REFERENCES capitulos(id) ON DELETE CASCADE
        );

-- [TABLE] capitulos_versiones
CREATE TABLE capitulos_versiones (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          capitulo_id INTEGER NOT NULL,
          contenido TEXT NOT NULL,
          creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (capitulo_id) REFERENCES capitulos(id) ON DELETE CASCADE
        );

-- [TABLE] categorias
CREATE TABLE categorias (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          proyecto_id INTEGER,
          nombre TEXT NOT NULL,
          icon TEXT NOT NULL DEFAULT 'auto_awesome',
          color TEXT NOT NULL DEFAULT '#FFF9C4',
          orden INTEGER DEFAULT 0,
          creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (proyecto_id) REFERENCES proyectos(id) ON DELETE CASCADE
        );

-- [TABLE] estilos
CREATE TABLE "estilos" (
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
        );

-- [TABLE] eventos_timeline
CREATE TABLE eventos_timeline (
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
        );

-- [TABLE] grafo_aristas
CREATE TABLE grafo_aristas (
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
        );

-- [TABLE] grafo_nodos
CREATE TABLE grafo_nodos (
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
        );

-- [TABLE] lugares
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
        );

-- [TABLE] manuscritos
CREATE TABLE manuscritos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        proyecto_id INTEGER NOT NULL,
        contenido TEXT,
        creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP, color_fondo TEXT, fuente TEXT, font_size REAL, line_height REAL,
        FOREIGN KEY (proyecto_id) REFERENCES proyectos(id) ON DELETE CASCADE
      );

-- [TABLE] mapas
CREATE TABLE mapas (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          proyecto_id INTEGER NOT NULL,
          nombre TEXT NOT NULL,
          datos_mapa TEXT,
          creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (proyecto_id) REFERENCES proyectos(id) ON DELETE CASCADE
        );

-- [TABLE] notas
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
        actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP, categoria TEXT DEFAULT "general",
        FOREIGN KEY (manuscrito_id) REFERENCES manuscritos(id) ON DELETE CASCADE
      );

-- [TABLE] personajes
CREATE TABLE personajes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          proyecto_id INTEGER NOT NULL,
          nombre TEXT NOT NULL,
          rol TEXT,
          descripcion TEXT,
          imagen_path TEXT,
          atributos TEXT, -- JSON string
          creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP, alias TEXT, frase_iconica TEXT, estado_emocional TEXT, estado_actual TEXT, edad TEXT,
          FOREIGN KEY (proyecto_id) REFERENCES proyectos(id) ON DELETE CASCADE
        );

-- [TABLE] proyectos
CREATE TABLE proyectos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        sinopsis TEXT,
        creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      , imagen_portada TEXT, portada_blob BLOB);

-- [TABLE] relaciones_personajes
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
        );

-- [TABLE] tarjetas
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
      );

-- [TABLE] tarjetas_conexiones
CREATE TABLE tarjetas_conexiones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tarjeta_origen_id INTEGER NOT NULL,
        tarjeta_destino_id INTEGER NOT NULL,
        creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (tarjeta_origen_id) REFERENCES tarjetas(id) ON DELETE CASCADE,
        FOREIGN KEY (tarjeta_destino_id) REFERENCES tarjetas(id) ON DELETE CASCADE
      );

