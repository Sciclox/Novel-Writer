import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/app_database.dart';

import '../widgets/draggable_card.dart';

class IdeasView extends StatefulWidget {
  final int proyectoId;
  const IdeasView({super.key, required this.proyectoId});

  @override
  State<IdeasView> createState() => _IdeasViewState();
}

class _IdeasViewState extends State<IdeasView> {
  List<Map<String, dynamic>> _tarjetas = [];
  List<Map<String, dynamic>> _conexiones = [];
  bool _isLoading = true;
  final TransformationController _transformationController = TransformationController();

  // Tamaño del lienzo
  static const double _canvasWidth = 3000.0;
  static const double _canvasHeight = 3000.0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
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

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    final tarjetas = await AppDatabase.getTarjetasByProyecto(widget.proyectoId);
    final conexiones = await AppDatabase.getConexionesByProyecto(widget.proyectoId);
    if (mounted) {
      setState(() {
        _tarjetas = List<Map<String, dynamic>>.from(tarjetas);
        _conexiones = List<Map<String, dynamic>>.from(conexiones);
        _isLoading = false;
      });
    }
  }

  void _onCardDragUpdate(int id, double x, double y) {
    setState(() {
      for (int i = 0; i < _tarjetas.length; i++) {
        if (_tarjetas[i]['id'] == id) {
          _tarjetas[i] = {
            ..._tarjetas[i],
            'pos_x': x,
            'pos_y': y,
          };
          break;
        }
      }
    });
  }

  Future<void> _onCardMoved(int id, double x, double y) async {
    await AppDatabase.updateTarjetaPosicion(id, x, y);
  }

  Future<void> _eliminarTarjeta(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar Tarjeta', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('¿Estás seguro de eliminar esta tarjeta de ideas? Sus conexiones se borrarán también.', style: GoogleFonts.inter(color: Colors.white70)),
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
      await AppDatabase.deleteTarjeta(id);
      _cargarDatos();
    }
  }

  Future<void> _agregarTarjeta() async {
    final colores = ['#FFCDD2', '#F8BBD9', '#E1BEE7', '#C5CAE9', '#BBDEFB', '#C8E6C9', '#FFF9C4', '#FFE0B2'];
    final color = colores[DateTime.now().millisecond % colores.length];

    // Colocarla en el centro del lienzo
    final double startX = _canvasWidth / 2 - 125;
    final double startY = _canvasHeight / 2 - 105;

    String titulo = '';
    String contenido = '';
    String tipo = 'idea';

    final creado = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('Nueva Tarjeta de Idea', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                dropdownColor: const Color(0xFF2C2C2E),
                initialValue: tipo,
                decoration: const InputDecoration(labelText: 'Categoría'),
                style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                items: const [
                  DropdownMenuItem(value: 'idea', child: Text('Idea General')),
                  DropdownMenuItem(value: 'personaje', child: Text('Personaje')),
                  DropdownMenuItem(value: 'escena', child: Text('Escena')),
                  DropdownMenuItem(value: 'lugar', child: Text('Lugar')),
                ],
                onChanged: (v) => tipo = v ?? 'idea',
              ),
              const SizedBox(height: 16),
              TextField(
                autofocus: true,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                decoration: const InputDecoration(labelText: 'Título'),
                onChanged: (v) => titulo = v,
              ),
              const SizedBox(height: 16),
              TextField(
                maxLines: 3,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                decoration: const InputDecoration(labelText: 'Descripción / Notas'),
                onChanged: (v) => contenido = v,
              ),
            ],
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
        ),
      ),
    );

    if (creado == true && titulo.trim().isNotEmpty) {
      await AppDatabase.insertTarjeta({
        'proyecto_id': widget.proyectoId,
        'titulo': titulo.trim(),
        'contenido': contenido.trim(),
        'tipo': tipo,
        'color': color,
        'pos_x': startX,
        'pos_y': startY,
        'ancho': 250.0,
        'alto': 210.0,
      });
      _cargarDatos();
    }
  }

  Future<void> _mostrarDialogoVincular() async {
    if (_tarjetas.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Necesitas al menos 2 tarjetas de ideas para crear una conexión.')),
      );
      return;
    }

    int? origenId;
    int? destinoId;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Conectar Tarjetas', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                dropdownColor: const Color(0xFF2C2C2E),
                decoration: const InputDecoration(labelText: 'Tarjeta de Origen'),
                style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                items: _tarjetas
                    .map((t) => DropdownMenuItem(
                          value: t['id'] as int,
                          child: Text(t['titulo']?.toString().isEmpty ?? true ? 'Sin título' : t['titulo']),
                        ))
                    .toList(),
                onChanged: (v) => setDialogState(() => origenId = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                dropdownColor: const Color(0xFF2C2C2E),
                decoration: const InputDecoration(labelText: 'Tarjeta de Destino'),
                style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                items: _tarjetas
                    .where((t) => t['id'] != origenId)
                    .map((t) => DropdownMenuItem(
                          value: t['id'] as int,
                          child: Text(t['titulo']?.toString().isEmpty ?? true ? 'Sin título' : t['titulo']),
                        ))
                    .toList(),
                onChanged: (v) => setDialogState(() => destinoId = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('CANCELAR', style: GoogleFonts.inter(color: Colors.white38)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (origenId != null && destinoId != null) {
                  final result = await AppDatabase.insertConexion(origenId!, destinoId!);
                  if (result > 0) {
                    _cargarDatos();
                    if (ctx.mounted) Navigator.pop(ctx);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Estas tarjetas ya están conectadas.')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F0FF),
                foregroundColor: const Color(0xFF1C1C1E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('CONECTAR', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoConexiones() async {
    if (_conexiones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aún no tienes conexiones entre tus tarjetas.')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Conexiones Activas', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          height: 300,
          child: StatefulBuilder(
            builder: (context, setDialogState) => ListView.builder(
              itemCount: _conexiones.length,
              itemBuilder: (ctx, index) {
                final conn = _conexiones[index];
                final origenCard = _tarjetas.firstWhere((t) => t['id'] == conn['tarjeta_origen_id'], orElse: () => {});
                final destinoCard = _tarjetas.firstWhere((t) => t['id'] == conn['tarjeta_destino_id'], orElse: () => {});

                if (origenCard.isEmpty || destinoCard.isEmpty) return const SizedBox.shrink();

                return ListTile(
                  title: Text(
                    '${origenCard['titulo']} ⟷ ${destinoCard['titulo']}',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.link_off, color: Colors.redAccent),
                    tooltip: 'Eliminar conexión',
                    onPressed: () async {
                      await AppDatabase.deleteConexion(conn['tarjeta_origen_id'], conn['tarjeta_destino_id']);
                      final conex = await AppDatabase.getConexionesByProyecto(widget.proyectoId);
                      setDialogState(() {
                        _conexiones = conex;
                      });
                      setState(() {
                        _conexiones = conex;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CERRAR', style: GoogleFonts.inter(color: const Color(0xFF00F0FF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarTarjeta,
        icon: const Icon(Icons.add_rounded),
        label: Text('NUEVA IDEA', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Header de la Vista
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Muro de Ideas',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Conecta ideas, personajes y locaciones. Haz doble clic en el fondo para arrastrar el lienzo.',
                    style: GoogleFonts.inter(color: const Color(0xFFAEAEB2), fontSize: 15),
                    ),
                  ],
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _mostrarDialogoVincular,
                  icon: const Icon(Icons.hub_rounded, size: 18),
                  label: Text('CONECTAR', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00F0FF),
                    side: const BorderSide(color: Color(0xFF00F0FF)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _mostrarDialogoConexiones,
                  icon: const Icon(Icons.link_off_rounded, size: 18),
                  label: Text('CONEXIONES', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ],
            ),
          ),

          // Lienzo Corkboard
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              decoration: BoxDecoration(
                color: const Color(0xFF12131F),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF2E2F48), width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: InteractiveViewer(
                transformationController: _transformationController,
                boundaryMargin: const EdgeInsets.all(800),
                minScale: 0.3,
                maxScale: 2.0,
                constrained: false,
                child: SizedBox(
                  width: _canvasWidth,
                  height: _canvasHeight,
                  child: Stack(
                    children: [
                      // Rejilla de Fondo y Conexiones
                      Positioned.fill(
                        child: GridPaper(
                          color: const Color(0xFF3A3A3C),
                          interval: 100,
                          divisions: 1,
                          subdivisions: 1,
                          child: CustomPaint(
                            painter: ConnectionsPainter(
                              tarjetas: _tarjetas,
                              conexiones: _conexiones,
                            ),
                          ),
                        ),
                      ),

                      // Tarjetas interactivas
                      ..._tarjetas.map(
                        (t) => Positioned(
                          key: ValueKey('pos_canvas_tarjeta_${t['id']}'),
                          left: 0,
                          top: 0,
                          child: DraggableCard(
                            key: ValueKey('canvas_tarjeta_${t['id']}'),
                            tarjeta: t,
                            onMoved: _onCardMoved,
                            onDragUpdate: _onCardDragUpdate,
                            onDelete: () => _eliminarTarjeta(t['id']),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CUSTOM PAINTER DE CONEXIONES ──────────────────────────
class ConnectionsPainter extends CustomPainter {
  final List<Map<String, dynamic>> tarjetas;
  final List<Map<String, dynamic>> conexiones;

  ConnectionsPainter({required this.tarjetas, required this.conexiones});

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.25)
      ..strokeWidth = 7.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final linePaint = Paint()
      ..color = const Color(0xFFAEAEB2)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final conn in conexiones) {
      final origenId = conn['tarjeta_origen_id'];
      final destinoId = conn['tarjeta_destino_id'];

      final origCard = tarjetas.firstWhere((t) => t['id'] == origenId, orElse: () => {});
      final destCard = tarjetas.firstWhere((t) => t['id'] == destinoId, orElse: () => {});

      if (origCard.isNotEmpty && destCard.isNotEmpty) {
        final double origX = (origCard['pos_x'] as num?)?.toDouble() ?? 0.0;
        final double origY = (origCard['pos_y'] as num?)?.toDouble() ?? 0.0;
        final double origW = (origCard['ancho'] as num?)?.toDouble() ?? 250.0;
        final double origH = (origCard['alto'] as num?)?.toDouble() ?? 210.0;

        final double destX = (destCard['pos_x'] as num?)?.toDouble() ?? 0.0;
        final double destY = (destCard['pos_y'] as num?)?.toDouble() ?? 0.0;
        final double destW = (destCard['ancho'] as num?)?.toDouble() ?? 250.0;
        final double destH = (destCard['alto'] as num?)?.toDouble() ?? 210.0;

        // Centros de las tarjetas
        final Offset origCenter = Offset(origX + origW / 2, origY + origH / 2);
        final Offset destCenter = Offset(destX + destW / 2, destY + destH / 2);

        // Curva Bézier entre nodos para estética fluida
        final path = Path()
          ..moveTo(origCenter.dx, origCenter.dy)
          ..cubicTo(
            (origCenter.dx + destCenter.dx) / 2,
            origCenter.dy,
            (origCenter.dx + destCenter.dx) / 2,
            destCenter.dy,
            destCenter.dx,
            destCenter.dy,
          );

        // Dibujar resplandor y luego línea interna
        canvas.drawPath(path, glowPaint);
        canvas.drawPath(path, linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ConnectionsPainter oldDelegate) {
    return true; // Redibujar continuamente para arrastre fluido
  }
}
