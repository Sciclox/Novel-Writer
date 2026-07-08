import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/app_database.dart';
import '../shared/app_theme.dart';

class DraggableCard extends StatefulWidget {
  final Map<String, dynamic> tarjeta;
  final Function(int, double, double) onMoved;
  final Function(int, double, double)? onDragUpdate;
  final VoidCallback onDelete;

  const DraggableCard({
    super.key,
    required this.tarjeta,
    required this.onMoved,
    this.onDragUpdate,
    required this.onDelete,
  });

  @override
  State<DraggableCard> createState() => _DraggableCardState();
}

class _DraggableCardState extends State<DraggableCard> {
  late double _x, _y;
  bool _isDragging = false;
  bool _contentChanged = false;
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late FocusNode _titleFocus;
  late FocusNode _contentFocus;
  late String _selectedType;

  static const _tipos = [
    ('idea', Icons.lightbulb_outline, 'Idea'),
    ('personaje', Icons.person_outline, 'Personaje'),
    ('escena', Icons.movie_outlined, 'Escena'),
    ('lugar', Icons.place_outlined, 'Lugar'),
  ];

  @override
  void initState() {
    super.initState();
    _x = (widget.tarjeta['pos_x'] as num?)?.toDouble() ?? 0.0;
    _y = (widget.tarjeta['pos_y'] as num?)?.toDouble() ?? 0.0;
    _selectedType = widget.tarjeta['tipo'] as String? ?? 'idea';
    _titleController =
        TextEditingController(text: widget.tarjeta['titulo'] ?? '');
    _contentController =
        TextEditingController(text: widget.tarjeta['contenido'] ?? '');
    _titleFocus = FocusNode();
    _contentFocus = FocusNode();
    _titleController.addListener(() => _contentChanged = true);
    _contentController.addListener(() => _contentChanged = true);
    _titleFocus.addListener(() {
      if (!_titleFocus.hasFocus && _contentChanged) _saveAll();
    });
    _contentFocus.addListener(() {
      if (!_contentFocus.hasFocus && _contentChanged) _saveAll();
    });
  }

  @override
  void didUpdateWidget(covariant DraggableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tarjeta['id'] != oldWidget.tarjeta['id']) {
      _x = (widget.tarjeta['pos_x'] as num?)?.toDouble() ?? 0.0;
      _y = (widget.tarjeta['pos_y'] as num?)?.toDouble() ?? 0.0;
      _selectedType = widget.tarjeta['tipo'] as String? ?? 'idea';
      _titleController.text = widget.tarjeta['titulo'] ?? '';
      _contentController.text = widget.tarjeta['contenido'] ?? '';
    }
  }

  Future<void> _saveAll() async {
    _contentChanged = false;
    await AppDatabase.updateTarjetaCompleta(
      widget.tarjeta['id'],
      _titleController.text,
      _contentController.text,
      _selectedType,
    );
  }

  @override
  void dispose() {
    if (_contentChanged) {
      AppDatabase.updateTarjetaCompleta(
        widget.tarjeta['id'],
        _titleController.text,
        _contentController.text,
        _selectedType,
      );
    }
    _titleFocus.dispose();
    _contentFocus.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  (IconData, String) _tipoInfo(String tipo) {
    for (final t in _tipos) {
      if (t.$1 == tipo) return (t.$2, t.$3);
    }
    return (Icons.lightbulb_outline, 'Idea');
  }

  @override
  Widget build(BuildContext context) {
    final (icon, label) = _tipoInfo(_selectedType);

    return Transform.translate(
      offset: Offset(_x, _y),
      child: GestureDetector(
        onPanStart: (_) => setState(() => _isDragging = true),
        onPanUpdate: (d) => setState(() {
          _x += d.delta.dx;
          _y += d.delta.dy;
          
          if (context.size != null) {
            final renderObject = context.findRenderObject();
            RenderObject? parent = renderObject?.parent;
            while (parent != null && parent is! RenderBox) {
              parent = parent.parent;
            }
            if (parent is RenderBox) {
              final width =
                  (widget.tarjeta['ancho'] as num?)?.toDouble() ?? 250.0;
              final height =
                  (widget.tarjeta['alto'] as num?)?.toDouble() ?? 210.0;
              _x = _x.clamp(0.0, parent.size.width - width);
              _y = _y.clamp(0.0, parent.size.height - height);
            }
          }
          if (widget.onDragUpdate != null) {
            widget.onDragUpdate!(widget.tarjeta['id'], _x, _y);
          }
        }),
        onPanEnd: (_) {
          setState(() => _isDragging = false);
          widget.onMoved(widget.tarjeta['id'], _x, _y);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: (widget.tarjeta['ancho'] as num?)?.toDouble() ?? 250,
          height: (widget.tarjeta['alto'] as num?)?.toDouble() ?? 210,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isDragging ? AppColors.accent.withValues(alpha: 0.5) : AppColors.separator,
              width: 1,
            ),
            boxShadow: _isDragging
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(2, 4),
                    )
                  ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PopupMenuButton<String>(
                    tooltip: 'Cambiar tipo',
                    color: AppColors.surface,
                    onSelected: (tipo) {
                      setState(() => _selectedType = tipo);
                      _saveAll();
                    },
                    itemBuilder: (_) => _tipos
                        .map((t) => PopupMenuItem(
                              value: t.$1,
                              child: Row(children: [
                                Icon(t.$2, size: 16, color: AppColors.textPrimary),
                                const SizedBox(width: 8),
                                Text(
                                  t.$3,
                                  style: GoogleFonts.outfit(color: AppColors.textPrimary),
                                ),
                              ]),
                            ))
                        .toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.separator.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            label,
                            style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.arrow_drop_down, size: 14, color: AppColors.textTertiary),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.drag_indicator, size: 16, color: AppColors.textTertiary),
                  const SizedBox(width: 6),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: widget.onDelete,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.separator.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, size: 12, color: AppColors.textTertiary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _titleController,
                focusNode: _titleFocus,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  filled: false,
                  hintText: 'Título',
                  hintStyle: GoogleFonts.outfit(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
              Divider(color: AppColors.separator.withValues(alpha: 0.4), height: 16),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  focusNode: _contentFocus,
                  maxLines: null,
                  expands: true,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    filled: false,
                    hintText: 'Describe aquí...',
                    hintStyle: GoogleFonts.outfit(color: AppColors.textTertiary, fontSize: 13),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
