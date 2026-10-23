#!/usr/bin/env python3
"""
Novel-Writer MCP Server
Model Context Protocol (MCP) server providing AI agents with programmatic access
to Novel-Writer's SQLite database, Lore Knowledge Graph, and Chapter Coherence Matrix.
"""

import sys
import os
import json
import sqlite3
import re
from typing import Any, Dict, List, Optional

# Forzar UTF-8 en Windows
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
if hasattr(sys.stdin, "reconfigure"):
    sys.stdin.reconfigure(encoding="utf-8")

# Base de datos predeterminada
DEFAULT_DB_PATH = r"C:\Users\Lenovo\OneDrive\Documentos\novel_writer.db"
DB_PATH = os.environ.get("NOVEL_WRITER_DB", DEFAULT_DB_PATH)

def get_db_connection() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def plain_text_from_delta(delta_json_str: str) -> str:
    """Extrae texto plano desde el JSON de Flutter Quill Delta."""
    if not delta_json_str:
        return ""
    try:
        data = json.loads(delta_json_str)
        if isinstance(data, list):
            parts = []
            for op in data:
                if isinstance(op, dict) and "insert" in op:
                    val = op["insert"]
                    if isinstance(val, str):
                        parts.append(val)
            return "".join(parts)
    except Exception:
        pass
    return delta_json_str

def delta_from_plain_text(text: str) -> str:
    """Convierte texto plano en un formato de Delta válido para Flutter Quill."""
    # Preservar saltos de línea y párrafos
    if not text.endswith("\n"):
        text += "\n"
    ops = [{"insert": text}]
    return json.dumps(ops, ensure_ascii=False)

def count_words(text: str) -> int:
    """Cuenta palabras de forma idéntica a NarrativeTextUtils en Flutter."""
    words = re.findall(r'\b\w+\b', text)
    return len(words)

# ==============================================================================
# DEFINICIÓN DE HERRAMIENTAS MCP
# ==============================================================================

TOOLS = [
    {
        "name": "nw_list_projects",
        "description": "Lista todas las novelas y proyectos registrados en Novel-Writer con estadísticas de palabras y capítulos.",
        "inputSchema": {
            "type": "object",
            "properties": {},
            "required": []
        }
    },
    {
        "name": "nw_get_project_context",
        "description": "Recupera la ficha completa de un proyecto: sinopsis, personajes principales, lugares registrados y facciones.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "proyecto_id": {
                    "type": "integer",
                    "description": "ID numérico del proyecto"
                }
            },
            "required": ["proyecto_id"]
        }
    },
    {
        "name": "nw_list_chapters",
        "description": "Lista todos los capítulos de un proyecto con su orden, título, palabras y estado (borrador, revision, completado).",
        "inputSchema": {
            "type": "object",
            "properties": {
                "proyecto_id": {
                    "type": "integer",
                    "description": "ID numérico del proyecto"
                }
            },
            "required": ["proyecto_id"]
        }
    },
    {
        "name": "nw_get_chapter",
        "description": "Obtiene el contenido completo de un capítulo (en texto plano legible y en delta JSON), así como sus metadatos y notas.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "capitulo_id": {
                    "type": "integer",
                    "description": "ID numérico del capítulo"
                }
            },
            "required": ["capitulo_id"]
        }
    },
    {
        "name": "nw_get_chapter_coherence",
        "description": "Obtiene la matriz de coherencia del capítulo: escenario activo, personajes presentes con sus heridas/salud, armas en juego, secretos conocidos y la ficha Markdown lista para redactar sin contradicciones.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "capitulo_id": {
                    "type": "integer",
                    "description": "ID del capítulo"
                }
            },
            "required": ["capitulo_id"]
        }
    },
    {
        "name": "nw_update_chapter_coherence",
        "description": "Actualiza la matriz de coherencia de un capítulo: quién está en escena, qué heridas sufrieron, qué artefactos tienen en mano y qué secretos se revelaron.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "capitulo_id": {"type": "integer", "description": "ID del capítulo"},
                "lugar_id": {"type": "integer", "description": "ID del lugar o escenario donde ocurre el capítulo (opcional)"},
                "personajes_ids": {"type": "array", "items": {"type": "integer"}, "description": "Lista de IDs de personajes presentes en escena"},
                "artefactos_ids": {"type": "array", "items": {"type": "integer"}, "description": "Lista de IDs de artefactos o armas presentes"},
                "estado_salud": {"type": "object", "description": "Mapa de PersonajeID -> Descripción de herida o salud actual"},
                "secretos_revelados": {"type": "array", "items": {"type": "string"}, "description": "Nuevos secretos o verdades descubiertas en este capítulo"},
                "notas_continuidad": {"type": "string", "description": "Restricciones de continuidad (ej: X personaje debe mantener en secreto Y)"}
            },
            "required": ["capitulo_id"]
        }
    },
    {
        "name": "nw_write_chapter",
        "description": "Escribe o actualiza un capítulo de la novela. Guarda el texto formateado en Quill Delta, calcula palabras, guarda versión histórica y actualiza estado.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "proyecto_id": {"type": "integer", "description": "ID del proyecto"},
                "capitulo_id": {"type": "integer", "description": "ID del capítulo (opcional; si se omite, se crea un nuevo capítulo al final)"},
                "titulo": {"type": "string", "description": "Título del capítulo (ej: 'Capítulo 3: El Juramento en las Sombras')"},
                "contenido": {"type": "string", "description": "Texto narrativo completo del capítulo (en prosa de alta calidad)"},
                "sinopsis": {"type": "string", "description": "Breve resumen de 1 a 2 oraciones de los hechos del capítulo"},
                "pov_personaje_id": {"type": "integer", "description": "ID del personaje cuyo punto de vista guía el capítulo (opcional)"},
                "estado": {"type": "string", "enum": ["borrador", "revision", "completado"], "description": "Estado del manuscrito"}
            },
            "required": ["proyecto_id", "titulo", "contenido"]
        }
    },
    {
        "name": "nw_query_lore",
        "description": "Consulta nodos (personajes, facciones, artefactos, misterios) y conexiones en la Red de Lore de la novela.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "proyecto_id": {"type": "integer", "description": "ID del proyecto"},
                "tipo": {"type": "string", "enum": ["todos", "personaje", "faccion", "artefacto", "lugar", "misterio", "trama"], "description": "Filtro por tipo de entidad"},
                "termino_busqueda": {"type": "string", "description": "Término para buscar por nombre o descripción (opcional)"}
            },
            "required": ["proyecto_id"]
        }
    },
    {
        "name": "nw_add_lore_node",
        "description": "Crea una nueva entidad en la Red de Lore (nueva facción, artefacto legendario, técnica o misterio).",
        "inputSchema": {
            "type": "object",
            "properties": {
                "proyecto_id": {"type": "integer", "description": "ID del proyecto"},
                "tipo": {"type": "string", "enum": ["personaje", "faccion", "artefacto", "lugar", "misterio", "trama"], "description": "Tipo de entidad"},
                "nombre": {"type": "string", "description": "Nombre de la entidad"},
                "subtitulo": {"type": "string", "description": "Subtítulo o rol (ej: 'Tesoro Sagrado', 'Gremio de Asesinos')"},
                "descripcion": {"type": "string", "description": "Descripción detallada y antecedentes"},
                "color": {"type": "string", "description": "Color hexadecimal (ej: '#00F0FF', '#E91E63', '#FFB300')"},
                "estado": {"type": "string", "description": "Estado actual (ej: 'activo', 'destruido', 'sellado')"},
                "propiedades": {"type": "object", "description": "Diccionario JSON con propiedades adicionales (cultivo, poder, etc.)"}
            },
            "required": ["proyecto_id", "tipo", "nombre"]
        }
    },
    {
        "name": "nw_add_lore_edge",
        "description": "Conecta dos entidades en la Red de Lore estableciendo una relación tipada e intensidad.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "proyecto_id": {"type": "integer", "description": "ID del proyecto"},
                "origen_id": {"type": "integer", "description": "ID del nodo de origen"},
                "destino_id": {"type": "integer", "description": "ID del nodo de destino"},
                "tipo_relacion": {"type": "string", "description": "Relación: 'posee', 'enemigo_de', 'aliado_de', 'miembro_de', 'investiga', 'sabe_secreto'"},
                "etiqueta": {"type": "string", "description": "Nombre visible del vínculo (ej: 'Lealtad Incondicional', 'Odio Mortal')"},
                "intensidad": {"type": "number", "description": "Intensidad numérica de 0.0 a 1.0"},
                "es_bidireccional": {"type": "boolean", "description": "Si la relación es recíproca"},
                "detalles": {"type": "string", "description": "Explicación narrativa del vínculo"}
            },
            "required": ["proyecto_id", "origen_id", "destino_id", "tipo_relacion"]
        }
    },
    {
        "name": "nw_update_character_state",
        "description": "Actualiza el estado físico, emocional, heridas o cultivo de un personaje en el Codex oficial.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "personaje_id": {"type": "integer", "description": "ID del personaje en el Codex"},
                "estado_actual": {"type": "string", "description": "Condición física o de combate (ej: 'Herida en hombro curada con píldora')"},
                "estado_emocional": {"type": "string", "description": "Estado anímico o psicológico (ej: 'Sed de sangre contenida, calculador')"}
            },
            "required": ["personaje_id"]
        }
    }
]

# ==============================================================================
# CONTROLADORES DE HERRAMIENTAS
# ==============================================================================

def handle_list_projects(args: Dict[str, Any]) -> Dict[str, Any]:
    with get_db_connection() as conn:
        rows = conn.execute("""
            SELECT p.id, p.titulo, p.sinopsis, p.creado_en, p.actualizado_en,
                   (SELECT COUNT(*) FROM capitulos c JOIN manuscritos m ON c.manuscrito_id = m.id WHERE m.proyecto_id = p.id AND c.eliminado_en IS NULL) as capitulos,
                   (SELECT IFNULL(SUM(c.palabras), 0) FROM capitulos c JOIN manuscritos m ON c.manuscrito_id = m.id WHERE m.proyecto_id = p.id AND c.eliminado_en IS NULL) as palabras,
                   (SELECT COUNT(*) FROM personajes pe WHERE pe.proyecto_id = p.id) as personajes
            FROM proyectos p
            ORDER BY p.actualizado_en DESC
        """).fetchall()

        projects = []
        for r in rows:
            projects.append({
                "id": r["id"],
                "titulo": r["titulo"],
                "sinopsis": r["sinopsis"],
                "capitulos": r["capitulos"],
                "palabras": r["palabras"],
                "personajes": r["personajes"],
                "actualizado_en": r["actualizado_en"]
            })

    return {"proyectos": projects, "total": len(projects)}

def handle_get_project_context(args: Dict[str, Any]) -> Dict[str, Any]:
    proj_id = args["proyecto_id"]
    with get_db_connection() as conn:
        proj = conn.execute("SELECT * FROM proyectos WHERE id = ?", (proj_id,)).fetchone()
        if not proj:
            raise ValueError(f"Proyecto con ID {proj_id} no encontrado")

        man = conn.execute("SELECT id FROM manuscritos WHERE proyecto_id = ?", (proj_id,)).fetchone()
        man_id = man["id"] if man else None

        chars = conn.execute("SELECT id, nombre, rol, alias, estado_actual, estado_emocional, descripcion FROM personajes WHERE proyecto_id = ?", (proj_id,)).fetchall()
        places = conn.execute("SELECT id, nombre, descripcion, clima FROM lugares WHERE proyecto_id = ?", (proj_id,)).fetchall()
        factions = conn.execute("SELECT id, nombre, subtitulo, descripcion FROM grafo_nodos WHERE proyecto_id = ? AND tipo = 'faccion'", (proj_id,)).fetchall()

    return {
        "proyecto": {
            "id": proj["id"],
            "titulo": proj["titulo"],
            "sinopsis": proj["sinopsis"],
            "manuscrito_id": man_id,
        },
        "personajes": [dict(c) for c in chars],
        "lugares": [dict(p) for p in places],
        "facciones": [dict(f) for f in factions]
    }

def handle_list_chapters(args: Dict[str, Any]) -> Dict[str, Any]:
    proj_id = args["proyecto_id"]
    with get_db_connection() as conn:
        rows = conn.execute("""
            SELECT c.id, c.titulo, c.orden, c.palabras, c.sinopsis, c.estado, c.pov_personaje_id,
                   p.nombre as pov_nombre
            FROM capitulos c
            JOIN manuscritos m ON c.manuscrito_id = m.id
            LEFT JOIN personajes p ON c.pov_personaje_id = p.id
            WHERE m.proyecto_id = ? AND c.eliminado_en IS NULL
            ORDER BY c.orden ASC
        """, (proj_id,)).fetchall()

    return {"capitulos": [dict(r) for r in rows], "total": len(rows)}

def handle_get_chapter(args: Dict[str, Any]) -> Dict[str, Any]:
    cap_id = args["capitulo_id"]
    with get_db_connection() as conn:
        cap = conn.execute("""
            SELECT c.*, p.nombre as pov_nombre, m.proyecto_id
            FROM capitulos c
            JOIN manuscritos m ON c.manuscrito_id = m.id
            LEFT JOIN personajes p ON c.pov_personaje_id = p.id
            WHERE c.id = ?
        """, (cap_id,)).fetchone()

        if not cap:
            raise ValueError(f"Capítulo con ID {cap_id} no encontrado")

        content_raw = cap["contenido"] or ""
        plain_text = plain_text_from_delta(content_raw)

    return {
        "id": cap["id"],
        "proyecto_id": cap["proyecto_id"],
        "manuscrito_id": cap["manuscrito_id"],
        "titulo": cap["titulo"],
        "orden": cap["orden"],
        "palabras": cap["palabras"] or count_words(plain_text),
        "sinopsis": cap["sinopsis"] or "",
        "estado": cap["estado"] or "borrador",
        "pov_personaje": cap["pov_nombre"],
        "texto_plano": plain_text,
        "delta_json": content_raw
    }

def handle_get_chapter_coherence(args: Dict[str, Any]) -> Dict[str, Any]:
    cap_id = args["capitulo_id"]
    with get_db_connection() as conn:
        cap = conn.execute("""
            SELECT c.id, c.titulo, m.proyecto_id
            FROM capitulos c
            JOIN manuscritos m ON c.manuscrito_id = m.id
            WHERE c.id = ?
        """, (cap_id,)).fetchone()

        if not cap:
            raise ValueError(f"Capítulo con ID {cap_id} no encontrado")

        proj_id = cap["proyecto_id"]
        coh = conn.execute("SELECT * FROM capitulos_coherencia WHERE capitulo_id = ?", (cap_id,)).fetchone()
        nodes = conn.execute("SELECT * FROM grafo_nodos WHERE proyecto_id = ?", (proj_id,)).fetchall()
        edges = conn.execute("SELECT * FROM grafo_aristas WHERE proyecto_id = ?", (proj_id,)).fetchall()

    nodes_map = {n["id"]: dict(n) for n in nodes}

    parsed_coh = {}
    if coh:
        try:
            p_ids = json.loads(coh["personajes_ids"] or "[]")
        except:
            p_ids = []
        try:
            a_ids = json.loads(coh["artefactos_ids"] or "[]")
        except:
            a_ids = []
        try:
            salud = json.loads(coh["estado_salud"] or "{}")
        except:
            salud = {}
        try:
            secretos = json.loads(coh["secretos_revelados"] or "[]")
        except:
            secretos = []

        parsed_coh = {
            "lugar_id": coh["lugar_id"],
            "personajes_ids": p_ids,
            "artefactos_ids": a_ids,
            "estado_salud": salud,
            "secretos_revelados": secretos,
            "notas_continuidad": coh["notas_continuidad"] or ""
        }

    # Construir Markdown compilado para IA
    sb = []
    sb.append(f"### FICHA DE COHERENCIA Y ESTADO NARRATIVO")
    sb.append(f"**Capítulo:** {cap['titulo']}")

    if parsed_coh.get("lugar_id"):
        lid = parsed_coh["lugar_id"]
        l_node = nodes_map.get(lid)
        if l_node:
            sb.append(f"\n#### 📍 Escenario / Ubicación")
            sb.append(f"- **{l_node['nombre']}:** {l_node.get('descripcion') or 'Sin descripción'}")

    p_ids = parsed_coh.get("personajes_ids", [])
    if p_ids:
        sb.append(f"\n#### 👥 Personajes Presentes en Escena")
        for pid in p_ids:
            p_node = nodes_map.get(pid)
            if p_node:
                salud_desc = parsed_coh.get("estado_salud", {}).get(str(pid)) or p_node.get("estado") or "Saludable"
                sb.append(f"- **{p_node['nombre']}** ({p_node.get('subtitulo') or 'Personaje'})")
                sb.append(f"  * Condición / Salud: {salud_desc}")

                # Buscar relaciones con otros presentes
                for e in edges:
                    if (e["nodo_origen_id"] == pid and e["nodo_destino_id"] in p_ids) or \
                       (e["es_bidireccional"] and e["nodo_destino_id"] == pid and e["nodo_origen_id"] in p_ids):
                        other_id = e["nodo_destino_id"] if e["nodo_origen_id"] == pid else e["nodo_origen_id"]
                        other = nodes_map.get(other_id)
                        if other:
                            etiqueta = e["etiqueta"] or e["tipo_relacion"]
                            pct = int(e["intensidad"] * 100)
                            sb.append(f"  * Vínculo con {other['nombre']}: {etiqueta} ({pct}% intensidad)")

    a_ids = parsed_coh.get("artefactos_ids", [])
    if a_ids:
        sb.append(f"\n#### ⚔️ Artefactos y Armas en Escena")
        for aid in a_ids:
            a_node = nodes_map.get(aid)
            if a_node:
                desc = a_node.get("descripcion") or a_node.get("subtitulo") or "Activo en escena"
                sb.append(f"- **{a_node['nombre']}:** {desc}")

    secs = parsed_coh.get("secretos_revelados", [])
    if secs:
        sb.append(f"\n#### 🗝️ Secretos Conocidos en este Punto")
        for s in secs:
            sb.append(f"- {s}")

    notas = parsed_coh.get("notas_continuidad", "").strip()
    if notas:
        sb.append(f"\n#### ⚠️ Reglas y Advertencias de Continuidad")
        sb.append(notas)

    sb.append("\n---")
    sb.append("*Instrucción para redacción: Respeta estrictamente los estados, heridas y limitaciones expuestos arriba. Cero contradicciones con hechos previos.*")

    compiled_prompt = "\n".join(sb)

    return {
        "capitulo_id": cap_id,
        "titulo": cap["titulo"],
        "coherencia": parsed_coh,
        "ai_context_prompt": compiled_prompt
    }

def handle_update_chapter_coherence(args: Dict[str, Any]) -> Dict[str, Any]:
    cap_id = args["capitulo_id"]
    lugar_id = args.get("lugar_id")
    p_ids = args.get("personajes_ids", [])
    a_ids = args.get("artefactos_ids", [])
    salud = args.get("estado_salud", {})
    secretos = args.get("secretos_revelados", [])
    notas = args.get("notas_continuidad", "")

    with get_db_connection() as conn:
        conn.execute("""
            INSERT INTO capitulos_coherencia (
                capitulo_id, lugar_id, personajes_ids, artefactos_ids, estado_salud, secretos_revelados, notas_continuidad
            ) VALUES (?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(capitulo_id) DO UPDATE SET
                lugar_id = excluded.lugar_id,
                personajes_ids = excluded.personajes_ids,
                artefactos_ids = excluded.artefactos_ids,
                estado_salud = excluded.estado_salud,
                secretos_revelados = excluded.secretos_revelados,
                notas_continuidad = excluded.notas_continuidad
        """, (
            cap_id,
            lugar_id,
            json.dumps(p_ids),
            json.dumps(a_ids),
            json.dumps(salud, ensure_ascii=False),
            json.dumps(secretos, ensure_ascii=False),
            notas
        ))
        conn.commit()

    return {"status": "ok", "capitulo_id": cap_id, "message": "Coherencia actualizada exitosamente"}

def handle_write_chapter(args: Dict[str, Any]) -> Dict[str, Any]:
    proj_id = args["proyecto_id"]
    cap_id = args.get("capitulo_id")
    titulo = args["titulo"]
    contenido = args["contenido"]
    sinopsis = args.get("sinopsis", "")
    pov_id = args.get("pov_personaje_id")
    estado = args.get("estado", "borrador")

    delta_json = delta_from_plain_text(contenido)
    words = count_words(contenido)

    with get_db_connection() as conn:
        # Obtener manuscrito del proyecto
        man = conn.execute("SELECT id FROM manuscritos WHERE proyecto_id = ?", (proj_id,)).fetchone()
        if not man:
            cur = conn.execute("INSERT INTO manuscritos (proyecto_id, contenido) VALUES (?, '')", (proj_id,))
            man_id = cur.lastrowid
        else:
            man_id = man["id"]

        if cap_id:
            # Actualizar capítulo existente
            conn.execute("""
                UPDATE capitulos
                SET titulo = ?, contenido = ?, palabras = ?, sinopsis = ?, pov_personaje_id = ?, estado = ?, actualizado_en = CURRENT_TIMESTAMP
                WHERE id = ?
            """, (titulo, delta_json, words, sinopsis, pov_id, estado, cap_id))
            action = "updated"
            target_cap_id = cap_id
        else:
            # Determinar orden
            max_order_row = conn.execute("SELECT MAX(orden) as max_ord FROM capitulos WHERE manuscrito_id = ?", (man_id,)).fetchone()
            next_order = (max_order_row["max_ord"] or 0) + 1

            cur = conn.execute("""
                INSERT INTO capitulos (manuscrito_id, titulo, contenido, palabras, orden, sinopsis, pov_personaje_id, estado)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, (man_id, titulo, delta_json, words, next_order, sinopsis, pov_id, estado))
            target_cap_id = cur.lastrowid
            action = "created"

        # Guardar versión histórica
        conn.execute("""
            INSERT INTO capitulos_versiones (capitulo_id, contenido)
            VALUES (?, ?)
        """, (target_cap_id, delta_json))

        # Actualizar fecha del proyecto
        conn.execute("UPDATE proyectos SET actualizado_en = CURRENT_TIMESTAMP WHERE id = ?", (proj_id,))
        conn.commit()

    return {
        "status": "ok",
        "action": action,
        "capitulo_id": target_cap_id,
        "titulo": titulo,
        "palabras": words,
        "estado": estado
    }

def handle_query_lore(args: Dict[str, Any]) -> Dict[str, Any]:
    proj_id = args["proyecto_id"]
    tipo = args.get("tipo", "todos")
    query = args.get("termino_busqueda", "").strip().lower()

    with get_db_connection() as conn:
        sql = "SELECT * FROM grafo_nodos WHERE proyecto_id = ?"
        params: List[Any] = [proj_id]

        if tipo and tipo != "todos":
            sql += " AND tipo = ?"
            params.append(tipo)

        if query:
            sql += " AND (LOWER(nombre) LIKE ? OR LOWER(subtitulo) LIKE ? OR LOWER(descripcion) LIKE ?)"
            term = f"%{query}%"
            params.extend([term, term, term])

        nodes = conn.execute(sql, params).fetchall()

        # Obtener aristas vinculadas
        edges = conn.execute("SELECT * FROM grafo_aristas WHERE proyecto_id = ?", (proj_id,)).fetchall()

    return {
        "nodos": [dict(n) for n in nodes],
        "aristas": [dict(e) for e in edges],
        "total_nodos": len(nodes),
        "total_aristas": len(edges)
    }

def handle_add_lore_node(args: Dict[str, Any]) -> Dict[str, Any]:
    proj_id = args["proyecto_id"]
    tipo = args["tipo"]
    nombre = args["nombre"]
    subtitulo = args.get("subtitulo")
    descripcion = args.get("descripcion", "")
    color = args.get("color", "#00F0FF")
    estado = args.get("estado", "activo")
    propiedades = args.get("propiedades", {})

    with get_db_connection() as conn:
        cur = conn.execute("""
            INSERT INTO grafo_nodos (proyecto_id, tipo, nombre, subtitulo, descripcion, color, estado, propiedades)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (proj_id, tipo, nombre, subtitulo, descripcion, color, estado, json.dumps(propiedades, ensure_ascii=False)))
        node_id = cur.lastrowid
        conn.commit()

    return {"status": "ok", "nodo_id": node_id, "nombre": nombre, "tipo": tipo}

def handle_add_lore_edge(args: Dict[str, Any]) -> Dict[str, Any]:
    proj_id = args["proyecto_id"]
    origen_id = args["origen_id"]
    destino_id = args["destino_id"]
    tipo_relacion = args["tipo_relacion"]
    etiqueta = args.get("etiqueta")
    intensidad = float(args.get("intensidad", 1.0))
    es_bidi = 1 if args.get("es_bidireccional", False) else 0
    detalles = args.get("detalles")

    with get_db_connection() as conn:
        cur = conn.execute("""
            INSERT INTO grafo_aristas (proyecto_id, nodo_origen_id, nodo_destino_id, tipo_relacion, etiqueta, intensidad, es_bidireccional, detalles)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (proj_id, origen_id, destino_id, tipo_relacion, etiqueta, intensidad, es_bidi, detalles))
        edge_id = cur.lastrowid
        conn.commit()

    return {"status": "ok", "arista_id": edge_id}

def handle_update_character_state(args: Dict[str, Any]) -> Dict[str, Any]:
    char_id = args["personaje_id"]
    estado_actual = args.get("estado_actual")
    estado_emocional = args.get("estado_emocional")

    updates = []
    params: List[Any] = []
    if estado_actual is not None:
        updates.append("estado_actual = ?")
        params.append(estado_actual)
    if estado_emocional is not None:
        updates.append("estado_emocional = ?")
        params.append(estado_emocional)

    if not updates:
        return {"status": "ok", "message": "Nada que actualizar"}

    params.append(char_id)
    with get_db_connection() as conn:
        conn.execute(f"UPDATE personajes SET {', '.join(updates)}, actualizado_en = CURRENT_TIMESTAMP WHERE id = ?", params)
        # Sincronizar también nodo del grafo si existe
        if estado_actual:
            conn.execute("UPDATE grafo_nodos SET estado = ? WHERE tipo = 'personaje' AND referencia_id = ?", (estado_actual, char_id))
        conn.commit()

    return {"status": "ok", "personaje_id": char_id, "message": "Estado de personaje actualizado"}

# Mapa de controladores
DISPATCHER = {
    "nw_list_projects": handle_list_projects,
    "nw_get_project_context": handle_get_project_context,
    "nw_list_chapters": handle_list_chapters,
    "nw_get_chapter": handle_get_chapter,
    "nw_get_chapter_coherence": handle_get_chapter_coherence,
    "nw_update_chapter_coherence": handle_update_chapter_coherence,
    "nw_write_chapter": handle_write_chapter,
    "nw_query_lore": handle_query_lore,
    "nw_add_lore_node": handle_add_lore_node,
    "nw_add_lore_edge": handle_add_lore_edge,
    "nw_update_character_state": handle_update_character_state,
}

# ==============================================================================
# BUCLE PRINCIPAL JSON-RPC 2.0 (MCP SOBRE STDIO)
# ==============================================================================

def send_response(response: Dict[str, Any]) -> None:
    body = json.dumps(response, ensure_ascii=False)
    sys.stdout.write(body + "\n")
    sys.stdout.flush()

def main():
    while True:
        try:
            line = sys.stdin.readline()
            if not line:
                break
            line = line.strip()
            if not line:
                continue

            req = json.loads(line)
            req_id = req.get("id")
            method = req.get("method")
            params = req.get("params", {})

            # 1. Lifecycle: initialize
            if method == "initialize":
                send_response({
                    "jsonrpc": "2.0",
                    "id": req_id,
                    "result": {
                        "protocolVersion": "2024-11-05",
                        "capabilities": {
                            "tools": {}
                        },
                        "serverInfo": {
                            "name": "novel-writer-mcp",
                            "version": "1.0.0"
                        }
                    }
                })
            # 2. Lifecycle: initialized notification
            elif method == "notifications/initialized":
                pass
            # 3. Lifecycle: ping
            elif method == "ping":
                send_response({"jsonrpc": "2.0", "id": req_id, "result": {}})
            # 4. Tools list
            elif method == "tools/list":
                send_response({
                    "jsonrpc": "2.0",
                    "id": req_id,
                    "result": {
                        "tools": TOOLS
                    }
                })
            # 5. Tools call
            elif method == "tools/call":
                tool_name = params.get("name")
                tool_args = params.get("arguments", {})
                handler = DISPATCHER.get(tool_name)

                if not handler:
                    send_response({
                        "jsonrpc": "2.0",
                        "id": req_id,
                        "error": {
                            "code": -32601,
                            "message": f"Herramienta desconocida: {tool_name}"
                        }
                    })
                else:
                    try:
                        res = handler(tool_args)
                        send_response({
                            "jsonrpc": "2.0",
                            "id": req_id,
                            "result": {
                                "content": [
                                    {
                                        "type": "text",
                                        "text": json.dumps(res, ensure_ascii=False, indent=2)
                                    }
                                ]
                            }
                        })
                    except Exception as e:
                        send_response({
                            "jsonrpc": "2.0",
                            "id": req_id,
                            "result": {
                                "isError": True,
                                "content": [
                                    {
                                        "type": "text",
                                        "text": f"Error ejecutando {tool_name}: {str(e)}"
                                    }
                                ]
                            }
                        })
            else:
                if req_id is not None:
                    send_response({
                        "jsonrpc": "2.0",
                        "id": req_id,
                        "error": {
                            "code": -32601,
                            "message": f"Método no soportado: {method}"
                        }
                    })
        except Exception as e:
            # Formato de error genérico
            sys.stderr.write(f"Error procesando mensaje: {e}\n")
            sys.stderr.flush()

if __name__ == "__main__":
    main()
