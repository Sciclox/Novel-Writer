# Novel-Writer Project Rules (GEMINI.md)

Directrices de desarrollo y reglas de dominio para el motor literario **Novel-Writer**.

---

## 1. Integridad de la Base de Datos y Servidor MCP
- **Base de Datos**:
  - Ubicación única: `C:\Users\Lenovo\OneDrive\Documentos\novel_writer.db`.
  - Todo cambio estructural debe respaldar previamente la base o apoyarse en el hook automático `backup_novel_db.py`.
- **Servidor MCP (`mcp_server/server.py`)**:
  - Los tipos de nodo en el grafo de lore deben categorizarse estrictamente en: `personaje`, `lugar`, `faccion`, `objeto` o `suceso`.
  - Las relaciones (`aristas`) deben contemplar `intensidad` (0.0 a 1.0), `etiqueta` descriptiva y sentido (`es_bidireccional`).

---

## 2. Coherencia y Flujo Narrativo
- **Regla de Oro de Continuidad**:
  - Antes de escribir o sugerir un nuevo capítulo con `nw_write_chapter`, verificar el último resumen de coherencia (`nw_get_chapter_coherence`).
  - Al concluir un capítulo, registrar el estado actualizado del mundo y personajes con `nw_update_chapter_coherence`.
- **Integración con Neuromapa**:
  - Utilizar el conector MCP de `neuromapa` para consultar notas de investigación de mundo y trasfondo antes de inventar detalles contradictorios.
