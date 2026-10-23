import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/app_database.dart';
import '../shared/app_theme.dart';
import '../shared/app_widgets.dart';

Color _parseColor(String? hex, {Color? fallback}) {
  final actualFallback = fallback ?? AppColors.accent;
  if (hex == null || hex.isEmpty) return actualFallback;
  try {
    return Color(int.parse(hex.replaceAll('#', '0xFF')));
  } catch (_) {
    return actualFallback;
  }
}

class TimelineView extends StatefulWidget {
  final int proyectoId;

  const TimelineView({super.key, required this.proyectoId});

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  List<Map<String, dynamic>> _eventos = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cargarEventos();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollBy(double delta) {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final target = (pos.pixels + delta).clamp(0.0, pos.maxScrollExtent);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _cargarEventos() async {
    try {
      final eventos = await AppDatabase.getEventosByProyecto(widget.proyectoId);
      debugPrint('Timeline: loaded ${eventos.length} events for project ${widget.proyectoId}');
      if (!mounted) return;
      setState(() {
        _eventos = List<Map<String, dynamic>>.from(eventos);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading timeline events: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _agregarEvento() async {
    final placeholder = {
      'proyecto_id': widget.proyectoId,
      'titulo': '',
      'descripcion': '',
      'fecha_relativa': 'Día ${_eventos.length + 1}',
      'importancia': 1,
      'color_hex': '#00F0FF',
      'orden': _eventos.length,
    };
    
    _editarEvento(placeholder, isNew: true);
  }

  Future<void> _eliminarEvento(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.separator),
        ),
        title: Text(
          '¿Eliminar evento?',
          style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Esta acción no se puede deshacer.',
          style: GoogleFonts.outfit(color: AppColors.textSecondary),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.textTertiary, side: BorderSide(color: AppColors.textTertiary.withValues(alpha: 0.3))),
            child: Text('CANCELAR'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.red, side: BorderSide(color: AppColors.red)),
            child: Text('ELIMINAR'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AppDatabase.deleteEvento(id);
      _cargarEventos();
    }
  }

  Future<void> _editarEvento(Map<String, dynamic> evento, {bool isNew = false}) async {
    final tituloCtrl = TextEditingController(text: evento['titulo']);
    final descCtrl = TextEditingController(text: evento['descripcion']);
    final fechaCtrl = TextEditingController(text: evento['fecha_relativa']);

    final List<String> colores = [
      '#00F0FF',
      '#FF5252',
      '#448AFF',
      '#69F0AE',
      '#E040FB',
      '#FFAB40',
    ];

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        int importancia = evento['importancia'] ?? 1;
        String colorHex = evento['color_hex'] ?? '#00F0FF';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final Color activeColor = _parseColor(colorHex);

            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: AppColors.separator),
              ),
              contentPadding: EdgeInsets.zero,
              content: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: activeColor.withValues(alpha: 0.07),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        border: Border(
                          bottom: BorderSide(
                            color: activeColor.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: activeColor),
                          const SizedBox(width: 16),
                          Text(
                            isNew ? 'Nuevo Punto de Trama' : 'Editar Punto de Trama',
                            style: GoogleFonts.outfit(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildField('Título del Evento', tituloCtrl, Icons.title),
                          const SizedBox(height: 16),
                          _buildField('Ubicación Temporal (ej: Día 4)', fechaCtrl, Icons.access_time_rounded),
                          const SizedBox(height: 16),
                          _buildField('Descripción Narrativa', descCtrl, Icons.description_rounded, maxLines: 3),

                          const SizedBox(height: 24),
                          Text(
                            'Importancia Narrativa',
                            style: GoogleFonts.outfit(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _impSelect(1, 'Menor', importancia == 1, (v) => setDialogState(() => importancia = v)),
                              _impSelect(2, 'Mayor', importancia == 2, (v) => setDialogState(() => importancia = v)),
                              _impSelect(3, 'Crítico', importancia == 3, (v) => setDialogState(() => importancia = v)),
                            ],
                          ),

                          const SizedBox(height: 24),
                          Text(
                            'Color del Nodo',
                            style: GoogleFonts.outfit(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: colores.map((c) {
                              final cColor = _parseColor(c);
                              return MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () => setDialogState(() => colorHex = c),
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: cColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: colorHex == c ? AppColors.textPrimary : Colors.transparent,
                                        width: 2,
                                      ),
                                      boxShadow: colorHex == c
                                          ? [BoxShadow(color: cColor.withValues(alpha: 0.6), blurRadius: 10, spreadRadius: 1)]
                                          : null,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    // Footer
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Row(
                        children: [
                          if (!isNew)
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: InkWell(
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _eliminarEvento(evento['id'] as int);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                      const SizedBox(width: 4),
                                      Text(
                                        'ELIMINAR',
                                        style: GoogleFonts.outfit(
                                          color: Colors.redAccent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          const Spacer(),
                          OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.textTertiary, side: BorderSide(color: AppColors.textTertiary.withValues(alpha: 0.3))),
                            child: Text('DESCARTAR'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () async {
                              if (tituloCtrl.text.trim().isEmpty) {
                                tituloCtrl.text = 'Sin título';
                              }

                              final data = {
                                'proyecto_id': widget.proyectoId,
                                'titulo': tituloCtrl.text,
                                'descripcion': descCtrl.text,
                                'fecha_relativa': fechaCtrl.text,
                                'importancia': importancia,
                                'color_hex': colorHex,
                                'orden': evento['orden'] ?? _eventos.length,
                              };

                              if (isNew) {
                                await AppDatabase.insertEvento(data);
                              } else {
                                await AppDatabase.updateEvento(evento['id'] as int, data);
                              }

                              if (ctx.mounted) Navigator.pop(ctx);
                              _cargarEventos();
                            },
                            child: Text('GUARDAR'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.separator),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(color: AppColors.textTertiary, fontSize: 13),
          prefixIcon: Icon(icon, color: AppColors.textTertiary, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _impSelect(int val, String label, bool isSelected, Function(int) onTap) {
    Color activeColor;
    switch (val) {
      case 3: activeColor = Colors.redAccent; break;
      case 2: activeColor = AppColors.accent; break;
      default: activeColor = Colors.blueAccent;
    }
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onTap(val),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 120,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? activeColor : AppColors.separator,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected ? activeColor : AppColors.textTertiary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _reorderEventos(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final item = _eventos.removeAt(oldIndex);
      _eventos.insert(newIndex, item);
    });

    await AppDatabase.batchUpdateOrden(_eventos);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return LayoutBuilder(
      builder: (context, constraints) {
        final tlHeight = (constraints.maxHeight - 250).clamp(320.0, 600.0);
        return Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -0.3),
              radius: 1.2,
              colors: [
                AppColors.bg,
                AppColors.bg,
              ],
            ),
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(48, 48, 48, 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pared de Detective',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Conecta los puntos y visualiza el ritmo cronológico de tu historia.',
                      style: GoogleFonts.outfit(color: AppColors.textTertiary, fontSize: 15),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: _agregarEvento,
                  icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                  label: const Text('AGREGAR EVENTO'),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _eventos.isEmpty
                ? buildEmptyState(
                    icon: Icons.timeline_rounded,
                    title: 'No hay eventos aún',
                    subtitle: 'Presiona AGREGAR EVENTO para comenzar tu línea de tiempo.',
                    actionLabel: 'AGREGAR EVENTO',
                    onAction: _agregarEvento,
                  )
                : Stack(
                    children: [
                      ScrollbarTheme(
                        data: ScrollbarThemeData(
                          thumbColor: WidgetStateProperty.all(
                            AppColors.accent.withValues(alpha: 0.5),
                          ),
                          trackColor: WidgetStateProperty.all(
                            AppColors.separator.withValues(alpha: 0.3),
                          ),
                          trackVisibility: WidgetStateProperty.all(true),
                          thickness: WidgetStateProperty.all(8),
                          radius: const Radius.circular(4),
                        ),
                        child: Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          child: Center(
                          child: SizedBox(
                            height: tlHeight,
                            child: ReorderableListView.builder(
                              scrollController: _scrollController,
                              buildDefaultDragHandles: false,
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 100),
                              itemCount: _eventos.length,
                              onReorder: _reorderEventos,
                              proxyDecorator: (child, index, animation) {
                                return AnimatedBuilder(
                                  animation: animation,
                                  builder: (context, child) {
                                    return Material(
                                      color: Colors.transparent,
                                      child: child,
                                    );
                                  },
                                  child: child,
                                );
                              },
                              itemBuilder: (context, index) {
                                return ReorderableDragStartListener(
                                  key: ValueKey(_eventos[index]['id'] as int),
                                  index: index,
                                  child: _EventNodeWidget(
                                    evento: _eventos[index],
                                    index: index,
                                    totalCount: _eventos.length,
                                    onTap: () => _editarEvento(_eventos[index]),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      ),
                      // Botón ◀
                      Positioned(
                        left: 16,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: _TimelineNavButton(
                            icon: Icons.chevron_left_rounded,
                            onTap: () => _scrollBy(-400),
                          ),
                        ),
                      ),
                      // Botón ▶
                      Positioned(
                        right: 16,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: _TimelineNavButton(
                            icon: Icons.chevron_right_rounded,
                            onTap: () => _scrollBy(400),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
      },
    );
  }
}

class _EventNodeWidget extends StatefulWidget {
  final Map<String, dynamic> evento;
  final int index;
  final int totalCount;
  final VoidCallback onTap;

  const _EventNodeWidget({
    required this.evento,
    required this.index,
    required this.totalCount,
    required this.onTap,
  });

  @override
  State<_EventNodeWidget> createState() => _EventNodeWidgetState();
}

class _EventNodeWidgetState extends State<_EventNodeWidget> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTop = widget.index % 2 == 0;
    final Color nodeColor = _parseColor(widget.evento['color_hex'] as String?);
    final importance = widget.evento['importancia'] ?? 1;

    double nodeSize;
    switch (importance) {
      case 3:
        nodeSize = 24;
        break;
      case 2:
        nodeSize = 18;
        break;
      default:
        nodeSize = 13;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            final cardW = (h * 0.7).clamp(200.0, 300.0);
            final midY = h / 2;
            const cardH = 145.0;
            const cardEdge = 24.0;

            return SizedBox(
              width: cardW,
              height: h,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Horizontal timeline line
                  Positioned(
                    left: widget.index == 0 ? cardW / 2 : 0,
                    right: widget.index == widget.totalCount - 1 ? cardW / 2 : 0,
                    top: midY - 1.5,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.index == 0 ? Colors.transparent : nodeColor.withValues(alpha: 0.15),
                            nodeColor.withValues(alpha: _isHovered ? 0.8 : 0.4),
                            widget.index == widget.totalCount - 1 ? Colors.transparent : nodeColor.withValues(alpha: 0.15),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: nodeColor.withValues(alpha: _isHovered ? 0.4 : 0.1),
                            blurRadius: _isHovered ? 12 : 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Vertical connector (from card edge to center line)
                  Positioned(
                    left: cardW / 2 - 1.25,
                    width: 2.5,
                    top: isTop ? cardEdge + cardH : midY,
                    bottom: isTop ? midY + 2 : cardEdge + cardH,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: isTop ? Alignment.topCenter : Alignment.bottomCenter,
                          end: isTop ? Alignment.bottomCenter : Alignment.topCenter,
                          colors: [
                            nodeColor.withValues(alpha: _isHovered ? 0.7 : 0.3),
                            nodeColor.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Node circle (on the center line)
                  Positioned(
                    left: cardW / 2 - nodeSize / 2 - 2,
                    top: midY - nodeSize / 2 - 4,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final pulseValue = _pulseController.value;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: _isHovered ? nodeSize + 8 : nodeSize + 4,
                          height: _isHovered ? nodeSize + 8 : nodeSize + 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.bg,
                            border: Border.all(
                              color: _isHovered ? AppColors.textPrimary : nodeColor,
                              width: _isHovered ? 3.5 : 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: nodeColor.withValues(alpha: 0.4 + (pulseValue * 0.3)),
                                blurRadius: 8 + (pulseValue * 12),
                                spreadRadius: 1 + (pulseValue * 3),
                              ),
                              if (_isHovered)
                                BoxShadow(
                                  color: AppColors.accent.withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Info card (with hover lift animation)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    top: isTop ? (_isHovered ? cardEdge - 6 : cardEdge) : null,
                    bottom: isTop ? null : (_isHovered ? cardEdge - 6 : cardEdge),
                    left: 0,
                    right: 0,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      scale: _isHovered ? 1.03 : 1.0,
                      child: Container(
                        height: cardH,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isHovered
                              ? AppColors.surface.withValues(alpha: 0.95)
                              : AppColors.surface.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isHovered
                                ? nodeColor.withValues(alpha: 0.8)
                                : AppColors.separator,
                            width: _isHovered ? 1.5 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _isHovered
                                  ? nodeColor.withValues(alpha: 0.3)
                                  : Colors.black.withValues(alpha: 0.06),
                              blurRadius: _isHovered ? 24 : 12,
                              offset: Offset(0, _isHovered ? 8 : 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.evento['fecha_relativa']?.toUpperCase() ?? 'SIN FECHA',
                                    style: GoogleFonts.outfit(
                                      color: nodeColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (_isHovered)
                                  Icon(Icons.drag_indicator_rounded, size: 14, color: AppColors.textTertiary),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.evento['titulo'] ?? 'Sin título',
                              style: GoogleFonts.outfit(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Text(
                                (widget.evento['descripcion'] as String?)?.isNotEmpty == true
                                    ? widget.evento['descripcion']
                                    : 'Sin descripción...',
                                style: GoogleFonts.outfit(
                                  color: _isHovered ? AppColors.textSecondary : AppColors.textTertiary,
                                  fontSize: 11,
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TimelineNavButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TimelineNavButton({required this.icon, required this.onTap});

  @override
  State<_TimelineNavButton> createState() => _TimelineNavButtonState();
}

class _TimelineNavButtonState extends State<_TimelineNavButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _hovered
                ? AppColors.accent.withValues(alpha: 0.15)
                : AppColors.separator.withValues(alpha: 0.2),
            border: Border.all(
              color: _hovered
                  ? AppColors.accent.withValues(alpha: 0.6)
                  : AppColors.separator,
              width: 1.5,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.25),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            widget.icon,
            size: 26,
            color: _hovered ? AppColors.accent : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
