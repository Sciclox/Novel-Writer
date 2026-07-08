import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/app_database.dart';
import '../shared/app_theme.dart';
import '../shared/app_widgets.dart';

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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.separator),
        ),
        title: Text('Eliminar Tarjeta', style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('¿Estás seguro de eliminar esta tarjeta de ideas? Sus conexiones se borrarán también.', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textTertiary,
              side: BorderSide(color: AppColors.textTertiary.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            child: Text('CANCELAR', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.red,
              side: BorderSide(color: AppColors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            child: Text('ELIMINAR', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.separator),
          ),
          title: Text('Nueva Tarjeta de Idea', style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppDropdown<String>(
                value: tipo,
                items: const [
                  AppDropdownItem(value: 'idea', label: 'Idea General'),
                  AppDropdownItem(value: 'personaje', label: 'Personaje'),
                  AppDropdownItem(value: 'escena', label: 'Escena'),
                  AppDropdownItem(value: 'lugar', label: 'Lugar'),
                ],
                onChanged: (v) {
                  if (v != null) setStateDialog(() => tipo = v);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                autofocus: true,
                style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Título',
                  labelStyle: GoogleFonts.outfit(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) => titulo = v,
              ),
              const SizedBox(height: 16),
              TextField(
                maxLines: 3,
                style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Descripción / Notas',
                  labelStyle: GoogleFonts.outfit(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) => contenido = v,
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textTertiary,
                side: BorderSide(color: AppColors.textTertiary.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              child: Text('CANCELAR', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: BorderSide(color: AppColors.accent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              child: Text('CREAR', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.separator),
          ),
          title: Text('Conectar Tarjetas', style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppDropdown<int>(
                value: origenId,
                hint: 'Seleccionar...',
                items: _tarjetas
                    .map((t) => AppDropdownItem<int>(
                          value: t['id'] as int,
                          label: t['titulo']?.toString().isEmpty ?? true ? 'Sin título' : t['titulo'],
                        ))
                    .toList(),
                onChanged: (v) => setDialogState(() => origenId = v),
              ),
              const SizedBox(height: 16),
              AppDropdown<int>(
                value: destinoId,
                hint: 'Seleccionar...',
                items: _tarjetas
                    .where((t) => t['id'] != origenId)
                    .map((t) => AppDropdownItem<int>(
                          value: t['id'] as int,
                          label: t['titulo']?.toString().isEmpty ?? true ? 'Sin título' : t['titulo'],
                        ))
                    .toList(),
                onChanged: (v) => setDialogState(() => destinoId = v),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textTertiary,
                side: BorderSide(color: AppColors.textTertiary.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              child: Text('CANCELAR', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
            OutlinedButton(
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
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: BorderSide(color: AppColors.accent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              child: Text('CONECTAR', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.separator),
        ),
        title: Text('Conexiones Activas', style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
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
                    style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary),
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
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: BorderSide(color: AppColors.accent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            child: Text('CERRAR', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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

    if (_tarjetas.isEmpty) {
      return buildEmptyState(
        icon: Icons.lightbulb_outline,
        title: 'Aún no tienes ideas',
        subtitle: 'Crea tu primera tarjeta en el corcho para capturar tus ideas.',
        actionLabel: 'CREAR PRIMER IDEA',
        onAction: _agregarTarjeta,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarTarjeta,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text('NUEVA IDEA', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Conecta ideas, personajes y locaciones. Haz doble clic en el fondo para arrastrar el lienzo.',
                    style: GoogleFonts.outfit(color: AppColors.textTertiary, fontSize: 15),
                    ),
                  ],
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _mostrarDialogoVincular,
                  icon: const Icon(Icons.hub_rounded, size: 18),
                  label: Text('CONECTAR', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: BorderSide(color: AppColors.accent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _mostrarDialogoConexiones,
                  icon: const Icon(Icons.link_off_rounded, size: 18),
                  label: Text('CONEXIONES', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: BorderSide(color: AppColors.accent),
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
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.separator, width: 1.5),
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
                          color: AppColors.surface,
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
      ..color = AppColors.accent.withValues(alpha: 0.25)
      ..strokeWidth = 7.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final linePaint = Paint()
      ..color = AppColors.textTertiary
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
