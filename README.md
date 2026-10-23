<p align="center">
  <img src="assets/logo.png" alt="Novel Writer Logo" width="140" />
</p>

<h1 align="center">Novel Writer Studio</h1>

<p align="center">
  <strong>A modern, distraction-free desktop novel writing and world-building studio built with Flutter.</strong>
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter" /></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white" alt="Dart" /></a>
  <a href="https://www.sqlite.org"><img src="https://img.shields.io/badge/Storage-SQLite%20FFI-003B57?logo=sqlite&logoColor=white" alt="SQLite" /></a>
  <a href="https://modelcontextprotocol.io"><img src="https://img.shields.io/badge/AI-MCP%20Enabled-795298" alt="MCP Enabled" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License MIT" /></a>
  <img src="https://img.shields.io/badge/Platform-Windows%20Desktop-blue" alt="Windows Desktop" />
</p>

---

## 📖 Overview

**Novel Writer Studio** is a professional desktop suite designed specifically for novelists, web novel creators, and narrative designers. Combining a clean, distraction-free writing environment with a comprehensive world-building codex, interactive lore graphs, and **AI continuity verification via Model Context Protocol (MCP)**, Novel Writer bridges the gap between creative storytelling and structural lore management.

Everything runs **100% locally** using high-performance SQLite, keeping your intellectual property private, secure, and always accessible offline.

---

## ✨ Key Features

### ✍️ Distraction-Free Rich Text Editor
- **Rich Typography & Formatting:** Powered by Flutter Quill with custom font choices, line spacing, margins, and paper textures.
- **Narrative Writing Tools:** Real-time word count, character count, estimated reading time, and automatic dialogue em-dash formatting (`—`).
- **Chapter Versioning & Visual Diff:** Snapshot your drafts at any point and inspect side-by-side color-coded diffs to review revisions.
- **Vocabulary & Frequency Analysis:** Scan your chapter for repeated words, vocabulary density, and pacing.

### 🌐 World Codex & Interactive Lore Graph
- **Comprehensive Entity Management:** Organize characters, places, factions, artifacts, and plot mysteries with rich metadata and portraits.
- **Interactive Relational Graph:** Visualize how characters and factions connect with dynamic nodes, relationship types, and faction allegiances.
- **Chronological Timeline:** Sequence events across eras and chapters to maintain strict temporal accuracy.

### 🛡️ Chapter Coherence Matrix
- **Continuity Tracking:** Audit which characters appear in each chapter, their emotional arcs, physical states, and narrative locations.
- **Plot Hole Prevention:** Flag inconsistencies in lore or character knowledge before releasing or finalizing a chapter.

### 🤖 Model Context Protocol (MCP) Server
- **AI Agent Integration:** Built-in Python MCP server (`mcp_server/server.py`) allowing AI assistants (such as Claude Desktop, Cursor, or Antigravity) to safely read project context, query lore, draft chapters, and audit continuity.
- **Autonomous Co-Authoring:** AI can inspect character relationships, past events, and open mysteries to maintain continuity.

### 💡 Creative Ideation & Planning
- **Kanban Idea Board:** Organize sparks of inspiration by status (Idea, In Progress, Discarded, Implemented).
- **Floating Sticky Notes:** Pin quick thoughts, quotes, and research directly inside your project canvas.

### 📦 Local-First Architecture & Multi-Format Exporter
- **Complete Data Ownership:** All novel data is saved locally in an ACID-compliant SQLite database.
- **Project Bundles:** One-click export/import of entire projects (`.zip` bundle) including assets, chapters, lore nodes, and database tables.
- **Publication Formats:** Export directly to formatted Markdown, Web Novel release format (with author notes), PDF, or Word.

---

## 🏛️ Architecture

Novel Writer follows a structured, layered desktop architecture:

```
Novel-Writer/
├── lib/
│   ├── database/         # SQLite schema, migrations (v1-v21), FFI initialization
│   ├── models/           # Immutable data models & JSON/Map serialization
│   ├── repositories/     # Data abstraction layer for lore, chapters, and entities
│   ├── services/         # Window management, notifications, bundle import/export
│   ├── viewmodels/       # State management and UI business logic (ChangeNotifier)
│   ├── screens/          # Main application views (Editor, Codex, Timeline, Ideas, Graph)
│   ├── shared/           # Design system tokens, color palettes, and base widgets
│   ├── utils/            # Text analysis, diff algorithms, reading estimators
│   └── widgets/          # Reusable modular UI components, title bar, modals
├── mcp_server/           # Python-based Model Context Protocol server & diagnostic client
├── assets/               # Application logo, default textures, media
├── test/
│   └── unit/             # Automated test suite (models, diff, exporter, word counter)
└── installer/            # Inno Setup Windows installer configuration
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.11.0` or higher)
- [Dart SDK](https://dart.dev/get-dart)
- Visual Studio with C++ Desktop Development tools (standard Flutter Windows requirement)
- Python 3.10+ (optional, for running the MCP server)

### Installation & Run

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Sciclox/Novel-Writer.git
   cd Novel-Writer
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the desktop app:**
   ```bash
   flutter run -d windows
   ```

4. **Build release executable:**
   ```bash
   flutter build windows --release
   ```

---

## 🧪 Running Tests

Novel Writer includes an automated unit test suite covering data models, text analysis, exporter transformations, and project bundles:

```bash
flutter test test/unit
```

---

## 🤖 Using the MCP Server

To enable AI agents to collaborate on your novel:

1. Navigate to the `mcp_server` directory:
   ```bash
   cd mcp_server
   ```
2. Verify communication with the diagnostic client:
   ```bash
   python test_client.py
   ```
3. Add the server configuration to your AI client's MCP configuration. See [`mcp_server/README.md`](mcp_server/README.md) for full instructions.

---

## ⌨️ Shortcuts & Navigation

| Shortcut | Action |
|---|---|
| `Ctrl + S` | Force save current chapter draft |
| `Ctrl + K` | Open Command Palette / Quick Search |
| `Ctrl + F` | Global search across chapters and notes |
| `F11` | Toggle Fullscreen / Distraction-free mode |

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
