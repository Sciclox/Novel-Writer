import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/app_database.dart';

import '../widgets/draggable_note.dart';

class NotesView extends StatefulWidget {
  final int proyectoId;
  const NotesView({super.key, required this.proyectoId});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  int? _manuscritoId;
  List<Map<String, dynamic>> _notas = [];
  bool _isLoading = true;
  bool _isGridView = true; // Toggle entre Grid y Canvas
  String _searchQuery = '';
  String? _selectedColorFilter; // null para "Todos"

  final TransformationController _transformationController = TransformationController();
  static const double _canvasWidth = 2500.0;
  static const double _canvasHeight = 2500.0;

  // Lista de colores predefinidos con nombres legibles en español
  final List<Map<String, String>> _coloresDisponibles = [
    {'hex': '#FFCDD2', 'nombre': 'Rojo'},
    {'hex': '#F8BBD9', 'nombre': 'Rosa'},
    {'hex': '#E1BEE7', 'nombre': 'Lavanda'},
    {'hex': '#C5CAE9', 'nombre': 'Índigo'},
    {'hex': '#BBDEFB', 'nombre': 'Cielo'},
    {'hex': '#C8E6C9', 'nombre': 'Menta'},
    {'hex': '#FFF9C4', 'nombre': 'Amarillo'},
    {'hex': '#FFE0B2', 'nombre': 'Naranja'},
  ];

  @override
  void initState() {
    super.initState();
    _cargarManuscritoYNotas();
    _transformationController.value = Matrix4.translationValues(
      -(_canvasWidth / 2 - 400),
      -(_canvasHeight / 2 - 300),
      0.0,
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _cargarManuscritoYNotas() async {
    setState(() => _isLoading = true);
    final manuscrito = await AppDatabase.getManuscritoByProyecto(widget.proyectoId);
    if (manuscrito != null) {
      _manuscritoId = manuscrito['id'];
      await _cargarNotas();
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cargarNotas() async {
    if (_manuscritoId == null) return;
    final notas = await AppDatabase.getNotasByManuscrito(_manuscritoId!);
    if (mounted) {
      setState(() {
        _notas = List<Map<String, dynamic>>.from(notas);
        _isLoading = false;
      });
    }
  }

  Future<void> _agregarNota() async {
    if (_manuscritoId == null) return;

    // Pedir color y contenido inicial en un diálogo premium
    String selectedHex = _coloresDisponibles.first['hex'] ?? '#FFCDD2';
    String contenidoInicial = '';

    final crear = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(
              'Nueva Nota Rápida',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    autofocus: true,
                    maxLines: 4,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Escribe tu recordatorio o nota aquí...',
                      hintStyle: GoogleFonts.inter(color: Colors.white30),
                      filled: true,
                      fillColor: const Color(0xFF0F101A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) => contenidoInicial = v,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Color de Etiqueta',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _coloresDisponibles.map((colorMap) {
                      final hex = colorMap['hex'] ?? '#FFCDD2';
                      final col = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                      final isSel = selectedHex == hex;
                      return GestureDetector(
                        onTap: () => setStateDialog(() => selectedHex = hex),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: col,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSel ? Colors.white : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('CANCELAR', style: GoogleFonts.inter(color: Colors.white38)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F0FF),
                  foregroundColor: const Color(0xFF1C1C1E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('CREAR', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );

    if (crear == true && _manuscritoId != null) {
      // Colocarla en el centro del canvas si está en canvas, o simplemente guardarla
      final double posX = _canvasWidth / 2 - 100;
      final double posY = _canvasHeight / 2 - 75;

      await AppDatabase.insertNota({
        'manuscrito_id': _manuscritoId!,
        'contenido': contenidoInicial.trim(),
        'color': selectedHex,
        'pos_x': posX,
        'pos_y': posY,
        'ancho': 220.0,
        'alto': 170.0,
      });

      _cargarNotas();
    }
  }

  Future<void> _eliminarNota(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar Nota', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('¿Deseas eliminar esta nota permanentemente?', style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('CANCELAR', style: GoogleFonts.inter(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text('ELIMINAR', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AppDatabase.deleteNota(id);
      _cargarNotas();
    }
  }

  Future<void> _onNoteMoved(int id, double x, double y) async {
    await AppDatabase.updateNotaPosicion(id, x, y);
    // Actualizar localmente para mantener sincronicidad sin recargar todo de la BD
    setState(() {
      for (int i = 0; i < _notas.length; i++) {
        if (_notas[i]['id'] == id) {
          _notas[i] = {
            ..._notas[i],
            'pos_x': x,
            'pos_y': y,
          };
          break;
        }
      }
    });
  }

  List<Map<String, dynamic>> _obtenerNotasFiltradas() {
    return _notas.where((n) {
      final contenido = n['contenido']?.toString().toLowerCase() ?? '';
      final matchesSearch = contenido.contains(_searchQuery.toLowerCase());
      final matchesColor = _selectedColorFilter == null || n['color'] == _selectedColorFilter;
      return matchesSearch && matchesColor;
    }).toList();
  }

  Color _hexToColor(String hex) => Color(int.parse(hex.replaceFirst('#', '0xFF')));

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_manuscritoId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, size: 64, color: const Color(0xFFAEAEB2)),
            const SizedBox(height: 24),
            Text(
              'No se encontró el manuscrito para este proyecto.',
              style: GoogleFonts.inter(color: const Color(0xFFAEAEB2), fontSize: 18),
            ),
          ],
        ),
      );
    }

    final notasFiltradas = _obtenerNotasFiltradas();

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarNota,
        icon: const Icon(Icons.add_rounded),
        label: Text('NUEVA NOTA', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // HEADER CON FILTROS Y BÚSQUEDA
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scratchpad de Notas',
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Anota ideas fugaces, cabos sueltos o apuntes de investigación sin alterar el manuscrito.',
                          style: GoogleFonts.inter(color: const Color(0xFFAEAEB2), fontSize: 15),
                        ),
                      ],
                    ),
                    
                    // Segmented Button para Toggle de Vista
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A3A3C),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2E2F48)),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _isGridView = true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: _isGridView ? const Color(0xFF00F0FF) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.grid_view_rounded,
                                    size: 16,
                                    color: _isGridView ? Colors.black87 : Colors.white54,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Cuadrícula',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: _isGridView ? Colors.black87 : Colors.white54,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _isGridView = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: !_isGridView ? const Color(0xFF00F0FF) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.layers_rounded,
                                    size: 16,
                                    color: !_isGridView ? Colors.black87 : Colors.white54,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Lienzo Libre',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: !_isGridView ? Colors.black87 : Colors.white54,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // BARRA DE BÚSQUEDA Y FILTROS POR COLOR
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF12131F),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2E2F48)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, color: Colors.white30, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Buscar en notas...',
                                  hintStyle: GoogleFonts.inter(color: Colors.white30),
                                  border: InputBorder.none,
                                  filled: false,
                                ),
                                onChanged: (v) => setState(() => _searchQuery = v),
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white30, size: 16),
                                tooltip: 'Limpiar búsqueda',
                                onPressed: () => setState(() => _searchQuery = ''),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    
                    // Selector de Colores
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _selectedColorFilter = null),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: _selectedColorFilter == null
                                      ? const Color(0xFF00F0FF).withValues(alpha: 0.15)
                                      : const Color(0xFF12131F),
                                  border: Border.all(
                                    color: _selectedColorFilter == null
                                        ? const Color(0xFF00F0FF)
                                        : const Color(0xFF2E2F48),
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Todos',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedColorFilter == null
                                        ? const Color(0xFF00F0FF)
                                        : Colors.white54,
                                  ),
                                ),
                              ),
                            ),
                            ..._coloresDisponibles.map((colorMap) {
                              final hex = colorMap['hex'] ?? '#FFCDD2';
                              final name = colorMap['nombre'] ?? '';
                              final isSelected = _selectedColorFilter == hex;
                              final c = _hexToColor(hex);
                              return GestureDetector(
                                onTap: () => setState(() => _selectedColorFilter = hex),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? c.withValues(alpha: 0.2) : const Color(0xFF12131F),
                                    border: Border.all(
                                      color: isSelected ? c : const Color(0xFF2E2F48),
                                      width: isSelected ? 1.5 : 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: c,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        name,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? Colors.white : Colors.white54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // CONTENIDO DE NOTAS
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF12131F),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF2E2F48), width: 1.5),
                  ),
                  child: _isGridView 
                    ? _buildGridView(notasFiltradas) 
                    : _buildCanvasView(notasFiltradas),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── MODO 1: VISTA DE CUADRÍCULA ──────────────────────────
  Widget _buildGridView(List<Map<String, dynamic>> notas) {
    if (notas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sticky_note_2_outlined, size: 64, color: Colors.white10),
            const SizedBox(height: 16),
            Text(
              'No se encontraron notas con estos filtros.',
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1.3,
      ),
      itemCount: notas.length,
      itemBuilder: (context, index) {
        final n = notas[index];
        final id = n['id'] as int;
        return _StaticNoteCard(
          key: ValueKey('static_note_$id'),
          nota: n,
          onDelete: () => _eliminarNota(id),
          onContentChanged: (v) {
            AppDatabase.updateNotaContenido(id, v);
          },
        );
      },
    );
  }

  // ── MODO 2: VISTA DE LIENZO LIBRE ───────────────────────
  Widget _buildCanvasView(List<Map<String, dynamic>> notas) {
    return InteractiveViewer(
      transformationController: _transformationController,
      boundaryMargin: const EdgeInsets.all(1000),
      minScale: 0.3,
      maxScale: 2.0,
      constrained: false,
      child: SizedBox(
        width: _canvasWidth,
        height: _canvasHeight,
        child: Stack(
          children: [
            // Papel cuadriculado de fondo
            Positioned.fill(
              child: GridPaper(
                color: const Color(0xFF3A3A3C),
                interval: 100,
                divisions: 1,
                subdivisions: 1,
              ),
            ),
            
            // Renderizado de las notas arrastrables
            ...notas.map((n) {
              final id = n['id'] as int;
              return Positioned(
                key: ValueKey('pos_draggable_note_$id'),
                left: 0,
                top: 0,
                child: DraggableNote(
                  key: ValueKey('draggable_note_$id'),
                  nota: n,
                  onMoved: _onNoteMoved,
                  onDelete: () => _eliminarNota(id),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── TARJETA ESTÁTICA PARA CUADRÍCULA ─────────────────────
class _StaticNoteCard extends StatefulWidget {
  final Map<String, dynamic> nota;
  final VoidCallback onDelete;
  final ValueChanged<String> onContentChanged;

  const _StaticNoteCard({
    super.key,
    required this.nota,
    required this.onDelete,
    required this.onContentChanged,
  });

  @override
  State<_StaticNoteCard> createState() => _StaticNoteCardState();
}

class _StaticNoteCardState extends State<_StaticNoteCard> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _changed = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.nota['contenido'] ?? '');
    _focusNode = FocusNode();
    _controller.addListener(() => _changed = true);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _changed) {
        _changed = false;
        widget.onContentChanged(_controller.text);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _StaticNoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.nota['id'] != oldWidget.nota['id']) {
      _controller.text = widget.nota['contenido'] ?? '';
      _changed = false;
    }
  }

  @override
  void dispose() {
    if (_changed) {
      widget.onContentChanged(_controller.text);
    }
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Color _hexToColor(String hex) => Color(int.parse(hex.replaceFirst('#', '0xFF')));

  @override
  Widget build(BuildContext context) {
    final bgColor = _hexToColor(widget.nota['color'] as String? ?? '#FFF9C4');

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isHovered ? 0.35 : 0.25),
              blurRadius: _isHovered ? 12 : 8,
              offset: Offset(0, _isHovered ? 4 : 2),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                color: bgColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: bgColor.withValues(alpha: _isHovered ? 0.5 : 0.35),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NOTA',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          maxLines: null,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: Colors.white,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            filled: false,
                            isDense: true,
                            hintText: 'Añadir nota...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: Colors.white38,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  Positioned(
                    top: -4,
                    right: -4,
                    child: InkWell(
                      onTap: widget.onDelete,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
