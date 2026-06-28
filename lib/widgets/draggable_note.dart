import 'dart:ui';
import 'package:flutter/material.dart';
import '../database/app_database.dart';

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
          widget.nota['id'], _controller.text); // fire-and-forget
    }
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Color _hexToColor(String hex) =>
      Color(int.parse(hex.replaceFirst('#', '0xFF')));

  @override
  Widget build(BuildContext context) {
    final bgColor = _hexToColor(widget.nota['color'] as String? ?? '#FFF9C4');

    return Transform.translate(
      offset: Offset(_x, _y),
      child: GestureDetector(
        onPanStart: (_) => setState(() => _isDragging = true),
        onPanUpdate: (d) => setState(() {
            _x += d.delta.dx;
            _y += d.delta.dy;
            
            // Constreñir el área visual
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
          duration: const Duration(milliseconds: 120),
          width: (widget.nota['ancho'] as num?)?.toDouble() ?? 200,
          height: (widget.nota['alto'] as num?)?.toDouble() ?? 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: _isDragging
                ? [
                    BoxShadow(
                        color: bgColor.withValues(alpha: 0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 10))
                  ]
                : [
                    const BoxShadow(
                        color: Color(0x4D000000),
                        blurRadius: 10,
                        offset: Offset(2, 4))
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: bgColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: bgColor.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 14),
                child: Stack(
                  children: [
                    // Barra de arrastre (handle)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 24,
                      child: Row(
                        children: [
                          Icon(Icons.drag_indicator,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.6)),
                          const SizedBox(width: 4),
                          const Expanded(
                            child: Text(
                              'NOTA',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white38,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLines: null,
                        expands: true,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Colors.white,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          filled: false,
                          hintText: 'Escribe tu nota...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.white38,
                          ),
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),
                    // Botón cerrar
                    Positioned(
                      top: -4,
                      right: -4,
                      child: GestureDetector(
                        onTap: widget.onDelete,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              size: 12,
                              color: Colors.white70),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
