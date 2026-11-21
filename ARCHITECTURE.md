# Arquitectura Técnica :: Novel-Writer

Documento de arquitectura del motor de gestión literaria y servidor MCP.

---

## 1. Diagrama de Relación y Flujo de Lore

```mermaid
erDiagram
    PROYECTOS ||--o{ GRAFO_NODOS : contiene
    PROYECTOS ||--o{ GRAFO_ARISTAS : vincula
    PROYECTOS ||--o{ CAPITULOS : organiza
    CAPITULOS ||--o{ CAPITULOS_COHERENCIA : audita

    GRAFO_NODOS {
        int id PK
        int proyecto_id FK
        string tipo "personaje | lugar | faccion"
        string nombre
        string subtitulo
        text descripcion
        string color
        json propiedades
    }

    GRAFO_ARISTAS {
        int id PK
        int nodo_origen_id FK
        int nodo_destino_id FK
        string tipo_relacion
        string etiqueta
        float intensidad
        boolean es_bidireccional
    }

    CAPITULOS {
        int id PK
        int numero
        string titulo
        text contenido
    }
```

---

## 2. Integración MCP y Agentes

```mermaid
flowchart LR
    Agent["🤖 Antigravity / Claude Agent"] <-->|Protocolo MCP (JSON-RPC)| MCPServer["mcp_server/server.py"]
    MCPServer <-->|"PRAGMA integrity_check / SQL"| DB[("novel_writer.db (SQLite)")]
    DB -.->|Hook PostToolUse| Backup["backup_novel_db.py (Rotación 15)"]
    DB -.->|export-lore| Vault["lore_vault/ (Markdown + [[wikilinks]])"]
```
