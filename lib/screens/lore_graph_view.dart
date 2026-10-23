import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/app_theme.dart';
import '../models/lore_node_model.dart';
import '../models/lore_edge_model.dart';
import '../repositories/lore_graph_repository.dart';

class LoreGraphView extends StatefulWidget {
  final int proyectoId;

  const LoreGraphView({
    super.key,
    required this.proyectoId,
  });

  @override
  State<LoreGraphView> createState() => _LoreGraphViewState();
}

class _LoreGraphViewState extends State<LoreGraphView> with SingleTickerProviderStateMixin {
  final LoreGraphRepository _repo = LoreGraphRepository();
  final TransformationController _transformController = TransformationController();

  List<LoreNodeModel> _nodes = [];
  List<LoreEdgeModel> _edges = [];
  bool _isLoading = true;

  // Filtros
  String _selectedFilter = 'todos';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  int? _selectedNodeId;
  int? _connectSourceNodeId;

  // Física
  final double canvasSize = 2400.0;
  late Offset _center;
  final Map<int, Offset> _positions = {};
  Map<int, Offset> _velocities = {};
  int? _draggingId;
  Ticker? _ticker;
  int _simulationTicks = 0;

  @override
  void initState() {
    super.initState();
    _center = Offset(canvasSize / 2, canvasSize / 2);
    _cargarDatos();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _transformController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    await _repo.syncExistingEntities(widget.proyectoId);
    final nodes = await _repo.getNodes(widget.proyectoId);
    final edges = await _repo.getEdges(widget.proyectoId);

    _initNodePositions(nodes);

    if (mounted) {
      setState(() {
        _nodes = nodes;
        _edges = edges;
        _isLoading = false;
      });
      _startPhysics();
      _centerView();
    }
  }

  void _centerView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = MediaQuery.of(context).size;
      final scale = 0.85;
      final x = -(_center.dx * scale - size.width / 2);
      final y = -(_center.dy * scale - size.height / 2);
      _transformController.value = Matrix4.identity()
        ..setTranslationRaw(x, y, 0.0)
        ..scaleByDouble(scale, scale, 1.0, 1.0);
    });
  }

  void _initNodePositions(List<LoreNodeModel> nodes) {
    _positions.clear();
    _velocities.clear();

    for (int i = 0; i < nodes.length; i++) {
      final n = nodes[i];
      if (n.posX != 0.0 || n.posY != 0.0) {
        _positions[n.id!] = Offset(n.posX.clamp(100.0, canvasSize - 100.0), n.posY.clamp(100.0, canvasSize - 100.0));
      } else {
        final angle = (i / (nodes.isEmpty ? 1 : nodes.length)) * 2 * math.pi;
        final radius = 220.0 + (i % 3) * 80.0;
        _positions[n.id!] = Offset(
          _center.dx + radius * math.cos(angle),
          _center.dy + radius * math.sin(angle),
        );
      }
      _velocities[n.id!] = Offset.zero;
    }
  }

  void _startPhysics() {
    _simulationTicks = 0;
    _ticker?.dispose();
    _ticker = createTicker(_onTick);
    _ticker?.start();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    if (_draggingId == null && _simulationTicks > 120) {
      _ticker?.stop();
      return;
    }
    _simulationTicks++;

    const double repulsion = 18000.0;
    const double springK = 0.055;
    const double springLength = 180.0;
    const double damping = 0.82;
    const double centerPull = 0.012;

    final newVelocities = <int, Offset>{};
    final ids = _positions.keys.toList();

    for (final id in ids) {
      if (id == _draggingId) {
        newVelocities[id] = Offset.zero;
        continue;
      }

      Offset force = Offset.zero;
      final posA = _positions[id]!;

      // 1. Repulsión entre todos los nodos
      for (final otherId in ids) {
        if (id == otherId) continue;
        final posB = _positions[otherId]!;
        final delta = posA - posB;
        final dist = math.max(delta.distance, 40.0);
        force += (delta / dist) * (repulsion / (dist * dist));
      }

      // 2. Tensión de resortes para aristas
      for (final e in _edges) {
        if (e.nodoOrigenId == id && _positions.containsKey(e.nodoDestinoId)) {
          final posB = _positions[e.nodoDestinoId]!;
          final delta = posB - posA;
          final dist = delta.distance;
          force += (delta / (dist == 0 ? 1 : dist)) * ((dist - springLength) * springK * e.intensidad);
        } else if (e.nodoDestinoId == id && _positions.containsKey(e.nodoOrigenId)) {
          final posB = _positions[e.nodoOrigenId]!;
          final delta = posB - posA;
          final dist = delta.distance;
          force += (delta / (dist == 0 ? 1 : dist)) * ((dist - springLength) * springK * e.intensidad);
        }
      }

      // 3. Suave gravedad hacia el centro
      force += (_center - posA) * centerPull;

      final currentVel = _velocities[id] ?? Offset.zero;
      final updatedVel = (currentVel + force) * damping;
      newVelocities[id] = updatedVel;
    }

    setState(() {
      _velocities = newVelocities;
      for (final id in ids) {
        if (id != _draggingId) {
          final p = _positions[id]! + _velocities[id]!;
          _positions[id] = Offset(
            p.dx.clamp(80.0, canvasSize - 80.0),
            p.dy.clamp(80.0, canvasSize - 80.0),
          );
        }
      }
    });
  }

  Color _getNodeColor(LoreNodeModel node) {
    if (node.color != null && node.color!.isNotEmpty) {
      try {
        final hex = node.color!.replaceAll('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }
    switch (node.tipo.toLowerCase()) {
      case 'personaje': return const Color(0xFF00F0FF); // Cian
      case 'faccion': return const Color(0xFFAB47BC); // Púrpura
      case 'artefacto': return const Color(0xFFFFB300); // Ámbar dorado
      case 'lugar': return const Color(0xFF2ECC71); // Verde esmeralda
      case 'misterio': return const Color(0xFFFF5252); // Rojo carmesí
      case 'trama': return const Color(0xFFFF7043); // Naranja
      default: return AppColors.accent;
    }
  }

  IconData _getNodeIcon(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'personaje': return Icons.person_rounded;
      case 'faccion': return Icons.shield_rounded;
      case 'artefacto': return Icons.auto_awesome_rounded;
      case 'lugar': return Icons.location_on_rounded;
      case 'misterio': return Icons.help_outline_rounded;
      case 'trama': return Icons.alt_route_rounded;
      default: return Icons.bubble_chart_rounded;
    }
  }

  List<LoreNodeModel> get _filteredNodes {
    return _nodes.where((n) {
      final matchesType = _selectedFilter == 'todos' || n.tipo == _selectedFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          n.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (n.subtitulo != null && n.subtitulo!.toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchesType && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final selectedNode = _selectedNodeId != null
        ? _nodes.where((n) => n.id == _selectedNodeId).firstOrNull
        : null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // 1. Lienzo Interactivo con física de nodos y aristas
          InteractiveViewer(
            transformationController: _transformController,
            boundaryMargin: const EdgeInsets.all(1200),
            minScale: 0.25,
            maxScale: 2.5,
            constrained: false,
            child: SizedBox(
              width: canvasSize,
              height: canvasSize,
              child: Stack(
                children: [
                  // Fondo sutil con cuadrícula de estrellas/puntos
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GridBackgroundPainter(),
                    ),
                  ),

                  // Pintor de Aristas (Líneas y Flechas)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _LoreEdgesPainter(
                        edges: _edges,
                        positions: _positions,
                        selectedNodeId: _selectedNodeId,
                      ),
                    ),
                  ),

                  // Nodos interactivos
                  ..._filteredNodes.map((node) {
                    final pos = _positions[node.id] ?? _center;
                    final isSelected = node.id == _selectedNodeId;
                    final isConnecting = node.id == _connectSourceNodeId;
                    final nodeColor = _getNodeColor(node);

                    return Positioned(
                      left: pos.dx - 40,
                      top: pos.dy - 40,
                      child: GestureDetector(
                        onTap: () {
                          if (_connectSourceNodeId != null && _connectSourceNodeId != node.id) {
                            _crearConexionDirecta(_connectSourceNodeId!, node.id!);
                          } else {
                            setState(() {
                              _selectedNodeId = isSelected ? null : node.id;
                            });
                          }
                        },
                        onPanStart: (_) {
                          setState(() => _draggingId = node.id);
                          _simulationTicks = 0;
                          _ticker?.start();
                        },
                        onPanUpdate: (details) {
                          setState(() {
                            final current = _positions[node.id] ?? _center;
                            _positions[node.id!] = Offset(
                              (current.dx + details.delta.dx).clamp(60.0, canvasSize - 60.0),
                              (current.dy + details.delta.dy).clamp(60.0, canvasSize - 60.0),
                            );
                          });
                        },
                        onPanEnd: (_) {
                          setState(() => _draggingId = null);
                          // Guardar posición persistente en BD
                          _repo.updateNode(node.copyWith(
                            posX: _positions[node.id]!.dx,
                            posY: _positions[node.id]!.dy,
                          ));
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surface,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : isConnecting
                                      ? Colors.amberAccent
                                      : nodeColor.withValues(alpha: 0.85),
                              width: isSelected || isConnecting ? 3.0 : 1.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: nodeColor.withValues(alpha: isSelected ? 0.65 : 0.25),
                                blurRadius: isSelected ? 20 : 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getNodeIcon(node.tipo),
                                color: nodeColor,
                                size: 22,
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  node.nombre,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // 2. Barra Superior de Filtros y Herramientas
          Positioned(
            top: 16,
            left: 20,
            right: 20,
            child: Row(
              children: [
                // Insignia de título
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.separator),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.hub_rounded, color: AppColors.accent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Red de Lore & Coherencia',
                        style: GoogleFonts.outfit(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_nodes.length} nodos',
                          style: GoogleFonts.outfit(
                            color: AppColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Filtros por Categoría
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('todos', 'Todos', Icons.all_inclusive_rounded, Colors.white70),
                        _buildFilterChip('personaje', 'Personajes', Icons.person_rounded, const Color(0xFF00F0FF)),
                        _buildFilterChip('faccion', 'Facciones', Icons.shield_rounded, const Color(0xFFAB47BC)),
                        _buildFilterChip('artefacto', 'Artefactos', Icons.auto_awesome_rounded, const Color(0xFFFFB300)),
                        _buildFilterChip('lugar', 'Lugares', Icons.location_on_rounded, const Color(0xFF2ECC71)),
                        _buildFilterChip('misterio', 'Misterios', Icons.help_outline_rounded, const Color(0xFFFF5252)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Buscador de nodo
                SizedBox(
                  width: 160,
                  height: 36,
                  child: TextField(
                    controller: _searchCtrl,
                    style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 12),
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Buscar nodo...',
                      hintStyle: GoogleFonts.outfit(color: AppColors.textTertiary, fontSize: 11),
                      prefixIcon: const Icon(Icons.search, size: 16, color: Colors.white54),
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.separator),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Acciones
                ElevatedButton.icon(
                  onPressed: _abrirDialogoNuevoNodo,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Nuevo Nodo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.center_focus_strong_rounded, color: Colors.white70),
                  tooltip: 'Centrar Vista',
                  onPressed: _centerView,
                ),
              ],
            ),
          ),

          // 3. Panel Lateral Flotante de Detalles del Nodo Seleccionado
          if (selectedNode != null)
            Positioned(
              top: 80,
              right: 20,
              bottom: 20,
              width: 320,
              child: _buildNodeDetailPanel(selectedNode),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon, Color color) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => setState(() => _selectedFilter = value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.2) : AppColors.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.separator.withValues(alpha: 0.4),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: isSelected ? color : Colors.white60),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: isSelected ? color : Colors.white70,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNodeDetailPanel(LoreNodeModel node) {
    final nodeColor = _getNodeColor(node);
    final connectedEdges = _edges.where((e) => e.nodoOrigenId == node.id || e.nodoDestinoId == node.id).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.separator),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: nodeColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getNodeIcon(node.tipo), color: nodeColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.nombre,
                      style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      node.subtitulo ?? node.tipo.toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: nodeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white54),
                onPressed: () => setState(() => _selectedNodeId = null),
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.white12),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (node.descripcion != null && node.descripcion!.isNotEmpty) ...[
                    Text('DESCRIPCIÓN', style: GoogleFonts.outfit(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 6),
                    Text(node.descripcion!, style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
                    const SizedBox(height: 16),
                  ],

                  // Conexiones / Relaciones
                  Text('VÍNCULOS NARRATIVOS (${connectedEdges.length})', style: GoogleFonts.outfit(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  if (connectedEdges.isEmpty)
                    Text('Sin conexiones registradas aún.', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11))
                  else
                    ...connectedEdges.map((e) {
                      final isOrigin = e.nodoOrigenId == node.id;
                      final otherId = isOrigin ? e.nodoDestinoId : e.nodoOrigenId;
                      final otherNode = _nodes.where((n) => n.id == otherId).firstOrNull;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            Icon(isOrigin ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded, size: 12, color: AppColors.accent),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${e.etiqueta ?? e.tipoRelacion} ➔ ${otherNode?.nombre ?? "Entidad"}',
                                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.white38),
                              onPressed: () async {
                                await _repo.deleteEdge(e.id!);
                                _cargarDatos();
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),

          // Acciones al pie del panel
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _iniciarConexion(node.id!),
                  icon: const Icon(Icons.linear_scale_rounded, size: 14),
                  label: const Text('Conectar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                tooltip: 'Eliminar Nodo',
                onPressed: () async {
                  await _repo.deleteNode(node.id!);
                  setState(() => _selectedNodeId = null);
                  _cargarDatos();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _iniciarConexion(int nodeId) {
    setState(() {
      _connectSourceNodeId = nodeId;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Toca otro nodo en el lienzo para trazar la relación.'),
        backgroundColor: Colors.blueGrey,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _crearConexionDirecta(int sourceId, int targetId) async {
    setState(() => _connectSourceNodeId = null);
    final tipoController = TextEditingController(text: 'vinculado_a');
    final etiquetaController = TextEditingController(text: 'Vínculo');

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Crear Relación Narrativa', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tipoController,
              decoration: const InputDecoration(labelText: 'Tipo de relación (ej: posee, enemigo_de, investiga)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: etiquetaController,
              decoration: const InputDecoration(labelText: 'Etiqueta visible'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
        ],
      ),
    );

    if (res == true) {
      await _repo.addEdge(LoreEdgeModel(
        proyectoId: widget.proyectoId,
        nodoOrigenId: sourceId,
        nodoDestinoId: targetId,
        tipoRelacion: tipoController.text.trim(),
        etiqueta: etiquetaController.text.trim(),
        intensidad: 1.0,
      ));
      _cargarDatos();
    }
  }

  Future<void> _abrirDialogoNuevoNodo() async {
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String tipoSeleccionado = 'personaje';

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Nuevo Nodo en la Red de Lore', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre de la entidad'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: tipoSeleccionado,
                decoration: const InputDecoration(labelText: 'Tipo de Entidad'),
                dropdownColor: AppColors.surface,
                items: const [
                  DropdownMenuItem(value: 'personaje', child: Text('Personaje')),
                  DropdownMenuItem(value: 'faccion', child: Text('Facción / Clan / Secta')),
                  DropdownMenuItem(value: 'artefacto', child: Text('Artefacto / Arma / Píldora')),
                  DropdownMenuItem(value: 'lugar', child: Text('Lugar / Territorio')),
                  DropdownMenuItem(value: 'misterio', child: Text('Misterio / Secreto')),
                  DropdownMenuItem(value: 'trama', child: Text('Hilo de Trama')),
                ],
                onChanged: (v) {
                  if (v != null) setDlgState(() => tipoSeleccionado = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Descripción / Detalles'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (nombreCtrl.text.trim().isNotEmpty) {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Crear Nodo'),
            ),
          ],
        ),
      ),
    );

    if (res == true && nombreCtrl.text.trim().isNotEmpty) {
      await _repo.addNode(LoreNodeModel(
        proyectoId: widget.proyectoId,
        tipo: tipoSeleccionado,
        nombre: nombreCtrl.text.trim(),
        descripcion: descCtrl.text.trim(),
        posX: _center.dx + (math.Random().nextDouble() - 0.5) * 200,
        posY: _center.dy + (math.Random().nextDouble() - 0.5) * 200,
      ));
      _cargarDatos();
    }
  }
}

class _GridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1.0;

    const step = 60.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LoreEdgesPainter extends CustomPainter {
  final List<LoreEdgeModel> edges;
  final Map<int, Offset> positions;
  final int? selectedNodeId;

  _LoreEdgesPainter({
    required this.edges,
    required this.positions,
    required this.selectedNodeId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final e in edges) {
      final posA = positions[e.nodoOrigenId];
      final posB = positions[e.nodoDestinoId];
      if (posA == null || posB == null) continue;

      final isHighlighted = selectedNodeId != null &&
          (e.nodoOrigenId == selectedNodeId || e.nodoDestinoId == selectedNodeId);

      final paint = Paint()
        ..color = isHighlighted
            ? AppColors.accent
            : Colors.white.withValues(alpha: 0.22)
        ..strokeWidth = isHighlighted ? 2.5 : 1.2
        ..style = PaintingStyle.stroke;

      canvas.drawLine(posA, posB, paint);

      // Dibujar etiqueta de la relación en el punto medio
      if (e.etiqueta != null && e.etiqueta!.isNotEmpty) {
        final mid = Offset((posA.dx + posB.dx) / 2, (posA.dy + posB.dy) / 2);
        final textSpan = TextSpan(
          text: e.etiqueta!,
          style: GoogleFonts.outfit(
            color: isHighlighted ? AppColors.accent : Colors.white60,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            backgroundColor: const Color(0xFF12131F).withValues(alpha: 0.8),
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(mid.dx - textPainter.width / 2, mid.dy - textPainter.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LoreEdgesPainter oldDelegate) => true;
}
