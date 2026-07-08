import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../shared/app_theme.dart';

class DraggableNote extends StatefulWidget {
  final Map<String, dynamic> nota;
  final Function(int, double, double) onMoved;
  final VoidCallback onDelete;

  const DraggableNote({
    super.key,
    required this.nota,
    required this.onMoved,
    required this.onDelete,
  });

  @override
  State<DraggableNote> createState() => _DraggableNoteState();
}

class _DraggableNoteState extends State<DraggableNote> {
  late double _x;
  late double _y;
  bool _isDragging = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _contentChanged = false;

  @override
  void initState() {
    super.initState();
    _x = (widget.nota['pos_x'] as num?)?.toDouble() ?? 0.0;
    _y = (widget.nota['pos_y'] as num?)?.toDouble() ?? 0.0;
    _controller =
        TextEditingController(text: widget.nota['contenido'] ?? '');
    _focusNode = FocusNode();
    _controller.addListener(() => _contentChanged = true);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _contentChanged) _saveContent();
    });
  }

  @override
  void didUpdateWidget(covariant DraggableNote oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.nota['id'] != oldWidget.nota['id']) {
      _x = (widget.nota['pos_x'] as num?)?.toDouble() ?? 0.0;
      _y = (widget.nota['pos_y'] as num?)?.toDouble() ?? 0.0;
      _controller.text = widget.nota['contenido'] ?? '';
    }
  }

  Future<void> _saveContent() async {
    _contentChanged = false;
    await AppDatabase.updateNotaContenido(widget.nota['id'], _controller.text);
  }

  @override
  void dispose() {
    if (_contentChanged) {
      AppDatabase.updateNotaContenido(
          widget.nota['id'], _controller.text);
    }
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    (widget.nota['ancho'] as num?)?.toDouble() ?? 200.0;
                final height =
                    (widget.nota['alto'] as num?)?.toDouble() ?? 150.0;
                _x = _x.clamp(0.0, parent.size.width - width);
                _y = _y.clamp(0.0, parent.size.height - height);
              }
            }
        }),
        onPanEnd: (_) {
          setState(() => _isDragging = false);
          widget.onMoved(widget.nota['id'], _x, _y);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: (widget.nota['ancho'] as num?)?.toDouble() ?? 200,
          height: (widget.nota['alto'] as num?)?.toDouble() ?? 150,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.separator,
              width: 1,
            ),
            boxShadow: _isDragging
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 10))
                  ]
                : [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(2, 4))
                  ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.drag_indicator, size: 14, color: AppColors.textTertiary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'NOTA',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.textTertiary,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLines: null,
                        expands: true,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          filled: false,
                          hintText: 'Escribe tu nota...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: AppColors.textTertiary,
                          ),
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: widget.onDelete,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close,
                          size: 12,
                          color: AppColors.textSecondary),
                    ),
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
