# 🤖 Novel-Writer MCP Server

Model Context Protocol (MCP) server providing AI agents with bidirectional, structured access to Novel-Writer's local SQLite database, Lore Knowledge Graph, and Chapter Coherence Matrix.

---

## 🚀 Features

- **Project Context Discovery (`nw_list_projects`, `nw_get_project_context`)**: Inspect active novel projects, synopsis, genres, style configurations, character rosters, and timeline milestones.
- **Chapter Engine (`nw_list_chapters`, `nw_get_chapter`, `nw_write_chapter`)**: Read and write chapter drafts directly with Flutter Quill Delta JSON support and plain text generation.
- **Lore Knowledge Graph (`nw_query_lore`, `nw_add_lore_node`, `nw_add_lore_edge`)**: Query and expand characters, factions, artifacts, places, and their relational links.
- **Continuity & Audit Matrix (`nw_get_chapter_coherence`, `nw_update_chapter_coherence`, `nw_update_character_state`)**: Track character appearances, emotional states, continuity flags, and narrative consistency across chapters.

---

## 🛠️ Requirements

- **Python 3.10+** (uses Python Standard Library only — no heavy external dependencies needed).

---

## ⚙️ Configuration

### Environment Variables

| Variable | Description | Default |
|---|---|---|
| `NOVEL_WRITER_DB` | Absolute path to the Novel-Writer SQLite database file (`novel_writer.db`). | Local user documents directory. |

### Connecting to Claude Desktop / Cursor / Antigravity

Add the server to your `claude_desktop_config.json` or MCP settings:

```json
{
  "mcpServers": {
    "novel-writer": {
      "command": "python",
      "args": [
        "c:/path/to/Novel-Writer/mcp_server/server.py"
      ],
      "env": {
        "NOVEL_WRITER_DB": "C:/path/to/your/novel_writer.db"
      }
    }
  }
}
```

---

## 🧪 Testing the Server

You can run the built-in diagnostic client to verify communication:

```bash
python mcp_server/test_client.py
```
