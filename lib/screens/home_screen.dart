import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'project_screen.dart';
import '../database/app_database.dart';
import '../shared/app_theme.dart';
import '../shared/app_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _proyectos = [];
  bool _loading = true;
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _cargarProyectos();
  }

  Future<void> _cargarProyectos() async {
    final proyectos = (await AppDatabase.getProyectos())
        .map((p) => Map<String, dynamic>.from(p))
        .toList();
    for (var proyecto in proyectos) {
      final stats = await AppDatabase.getProyectoStats(proyecto['id'] as int);
      proyecto['palabras'] = stats['palabras'] ?? 0;
      proyecto['capitulos'] = stats['capitulos'] ?? 0;
    }
    if (mounted) {
      setState(() {
        _proyectos = proyectos;
        _loading = false;
      });
    }
  }

  VoidCallback? get onNewProject => _mostrarDialogoNuevoProyecto;
  VoidCallback? get onOpenProject => _abrirDialogoAbrirProyecto;
  VoidCallback? get onSave => null;
  VoidCallback? get onExport => null;

  void _abrirDialogoAbrirProyecto() {
    if (_proyectos.isEmpty) return;
    _abrirProyecto(_proyectos.first);
  }

  Future<void> _subirPortada(int proyectoId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }
    if (bytes != null && bytes.isNotEmpty) {
      await AppDatabase.updateProyectoPortada(proyectoId, bytes);
      _cargarProyectos();
    }
  }

  Future<void> _quitarPortada(int proyectoId) async {
    await AppDatabase.updateProyectoPortada(proyectoId, null);
    _cargarProyectos();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado tipo exporter
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mis Novelas',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gestiona y organiza tus proyectos literarios.',
                      style: GoogleFonts.outfit(color: Colors.white38, fontSize: 16),
                    ),
                  ],
                ),
                const Spacer(),
                _ViewToggle(
                  isGridView: _isGridView,
                  onToggle: () => setState(() => _isGridView = !_isGridView),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Body
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: AppColors.accent))
                  : _proyectos.isEmpty
                      ? _buildEmptyState()
                      : _buildProjectGrid(isWide, _proyectos),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(right: 12),
        child: FloatingActionButton.extended(
          onPressed: _mostrarDialogoNuevoProyecto,
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black87,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(Icons.add_rounded, size: 22),
          label: Text(
            'NUEVO PROYECTO',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return buildEmptyState(
      icon: Icons.menu_book_rounded,
      title: 'Aún no tienes proyectos',
      subtitle: 'Crea tu primer proyecto y comienza a escribir.',
      actionLabel: 'CREAR PROYECTO',
      onAction: _mostrarDialogoNuevoProyecto,
    );
  }

  Widget _buildProjectGrid(bool isWide, List<Map<String, dynamic>> proyectos) {
    if (_isGridView) {
      return GridView.builder(
        padding: EdgeInsets.fromLTRB(
          0,
          0,
          0,
          MediaQuery.of(context).padding.bottom + 100,
        ),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 260,
          mainAxisSpacing: 28,
          crossAxisSpacing: 28,
          mainAxisExtent: 390,
        ),
        itemCount: proyectos.length,
        itemBuilder: (context, index) => _BuildGridItem(
          proyecto: proyectos[index],
          index: index,
          onTap: () => _abrirProyecto(proyectos[index]),
          onDelete: () async {
            await AppDatabase.deleteProyecto(proyectos[index]['id'] as int);
            _cargarProyectos();
          },
          onDuplicate: () async {
            await AppDatabase.duplicateProyecto(proyectos[index]['id'] as int);
            _cargarProyectos();
          },
          onUploadCover: () => _subirPortada(proyectos[index]['id'] as int),
          onRemoveCover: () => _quitarPortada(proyectos[index]['id'] as int),
          onEdit: () => _mostrarDialogoEditarProyecto(proyectos[index]),
        ),
      );
    } else {
      return ListView.builder(
        padding: EdgeInsets.fromLTRB(
          0,
          0,
          0,
          MediaQuery.of(context).padding.bottom + 100,
        ),
        itemCount: proyectos.length,
        itemBuilder: (context, index) => _BuildListItem(
          proyecto: proyectos[index],
          index: index,
          onTap: () => _abrirProyecto(proyectos[index]),
          onDelete: () async {
            await AppDatabase.deleteProyecto(proyectos[index]['id'] as int);
            _cargarProyectos();
          },
          onDuplicate: () async {
            await AppDatabase.duplicateProyecto(proyectos[index]['id'] as int);
            _cargarProyectos();
          },
          onUploadCover: () => _subirPortada(proyectos[index]['id'] as int),
          onRemoveCover: () => _quitarPortada(proyectos[index]['id'] as int),
          onEdit: () => _mostrarDialogoEditarProyecto(proyectos[index]),
        ),
      );
    }
  }

  void _abrirProyecto(Map<String, dynamic> proyecto) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ProjectScreen(proyecto: proyecto),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
    _cargarProyectos();
  }

  void _mostrarDialogoEditarProyecto(Map<String, dynamic> proyecto) {
    final tituloController = TextEditingController(text: proyecto['titulo'] as String?);
    final sinopsisController = TextEditingController(text: proyecto['sinopsis'] as String?);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'EDITAR PROYECTO',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: tituloController,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
                    cursorColor: AppColors.accent,
                    decoration: InputDecoration(
                      labelText: 'Título de la obra',
                      labelStyle: GoogleFonts.outfit(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.02),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.accent, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: sinopsisController,
                    maxLines: 4,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
                    cursorColor: AppColors.accent,
                    decoration: InputDecoration(
                      labelText: 'Sinopsis (opcional)',
                      labelStyle: GoogleFonts.outfit(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.02),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.accent, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () async {
                        if (tituloController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('El título es obligatorio'),
                              backgroundColor: AppColors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                          return;
                        }
                        await AppDatabase.updateProyectoCompleto(
                          proyecto['id'] as int,
                          tituloController.text.trim(),
                          sinopsisController.text.trim(),
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          _cargarProyectos();
                        }
                      },
                      child: Text(
                        'GUARDAR CAMBIOS',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
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

  void _mostrarDialogoNuevoProyecto() {
    final tituloController = TextEditingController();
    final sinopsisController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'NUEVO PROYECTO',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: tituloController,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
                    cursorColor: AppColors.accent,
                    decoration: InputDecoration(
                      labelText: 'Título de la obra',
                      labelStyle: GoogleFonts.outfit(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.02),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.accent, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: sinopsisController,
                    maxLines: 4,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
                    cursorColor: AppColors.accent,
                    decoration: InputDecoration(
                      labelText: 'Sinopsis (opcional)',
                      labelStyle: GoogleFonts.outfit(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.02),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.accent, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () async {
                        if (tituloController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('El título es obligatorio'),
                              backgroundColor: AppColors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                          return;
                        }
                        await AppDatabase.insertProyecto({
                          'titulo': tituloController.text.trim(),
                          'sinopsis': sinopsisController.text.trim(),
                        });
                        if (context.mounted) {
                          Navigator.pop(context);
                          _cargarProyectos();
                        }
                      },
                      child: Text(
                        'CREAR PROYECTO',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
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

class _ViewToggle extends StatefulWidget {
  final bool isGridView;
  final VoidCallback onToggle;

  const _ViewToggle({
    required this.isGridView,
    required this.onToggle,
  });

  @override
  State<_ViewToggle> createState() => _ViewToggleState();
}

class _ViewToggleState extends State<_ViewToggle> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildSegment(
            selected: widget.isGridView,
            icon: Icons.grid_view_rounded,
            label: 'Cuadrícula',
            onTap: () {
              if (!widget.isGridView) widget.onToggle();
            },
          ),
          _buildSegment(
            selected: !widget.isGridView,
            icon: Icons.view_list_rounded,
            label: 'Lista',
            onTap: () {
              if (widget.isGridView) widget.onToggle();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSegment({
    required bool selected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.accent : Colors.white54,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
                color: selected ? AppColors.accent : Colors.white54,
              ),
            )
          ],
        ),
      ),
    ),
    );
  }
}

class _BuildGridItem extends StatefulWidget {
  final Map<String, dynamic> proyecto;
  final int index;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;
  final VoidCallback? onUploadCover;
  final VoidCallback? onRemoveCover;
  final VoidCallback? onEdit;

  const _BuildGridItem({
    required this.proyecto,
    required this.index,
    required this.onTap,
    this.onDelete,
    this.onDuplicate,
    this.onUploadCover,
    this.onRemoveCover,
    this.onEdit,
  });

  @override
  State<_BuildGridItem> createState() => _BuildGridItemState();
}

class _BuildGridItemState extends State<_BuildGridItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coverColor = AppColors.bookCoverColors[widget.index % AppColors.bookCoverColors.length];
    final spineColor = Color.lerp(coverColor, Colors.black, 0.35)!;
    final accent = AppColors.bookAccentColors[widget.index % AppColors.bookAccentColors.length];

    return Column(
      children: [
        Expanded(
          child: MouseRegion(
            onEnter: (_) => _controller.forward(),
            onExit: (_) => _controller.reverse(),
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: widget.onTap,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  final liftOffset = _animation.value * -6;
                  return Transform.translate(
                    offset: Offset(0, liftOffset),
                    child: child,
                  );
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final spineWidth = 26.0;
                    final coverWidth = constraints.maxWidth - spineWidth;

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Shadow
                        Positioned(
                          left: 4,
                          right: -4,
                          bottom: -4,
                          child: AnimatedBuilder(
                            animation: _animation,
                            builder: (context, child) {
                              return Container(
                                height: 12,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.35 + _animation.value * 0.25,
                                      ),
                                      blurRadius: 16 + _animation.value * 16,
                                      offset: const Offset(4, 8),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        // Spine (without title text)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: spineWidth,
                          child: Container(
                            decoration: BoxDecoration(
                              color: spineColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                bottomLeft: Radius.circular(6),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(2, 0),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Pages underneath
                        Positioned(
                          left: spineWidth,
                          top: 0,
                          bottom: 0,
                          width: coverWidth,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFFF8F8F8),
                                  const Color(0xFFEEEEEE),
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sinopsis',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF2C1810).withValues(alpha: 0.5),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 40,
                                  height: 1.5,
                                  color: const Color(0xFF2C1810).withValues(alpha: 0.15),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Text(
                                      widget.proyecto['sinopsis']?.toString().isNotEmpty == true
                                          ? widget.proyecto['sinopsis']
                                          : 'Sin sinopsis disponible',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF2C1810),
                                        fontSize: 13,
                                        height: 1.5,
                                        fontStyle: widget.proyecto['sinopsis']?.toString().isNotEmpty == true
                                            ? FontStyle.normal
                                            : FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Rotating cover with designs
                        AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            final angle = _animation.value * 1.5;
                            final opacity = 1.0 - _animation.value;
                            return Positioned(
                              left: spineWidth,
                              top: 0,
                              bottom: 0,
                              width: coverWidth,
                              child: Transform(
                                alignment: Alignment.centerLeft,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.0015)
                                  ..rotateY(angle),
                                child: Opacity(
                                  opacity: opacity,
                                  child: child,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: coverColor,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  coverColor,
                                  Color.lerp(coverColor, Colors.black, 0.15)!,
                                ],
                              ),
                            ),
                            child: Stack(
                              children: [
                                // Cover content
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 3,
                                        decoration: BoxDecoration(
                                          color: accent,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        widget.proyecto['titulo'] ?? 'Sin título',
                                        style: GoogleFonts.outfit(
                                          color: AppColors.textPrimary,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          height: 1.2,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        width: 60,
                                        height: 1.5,
                                        color: accent,
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          _StatLabel(
                                            icon: Icons.text_fields_rounded,
                                            label: '${widget.proyecto['palabras'] ?? 0}',
                                            color: accent,
                                          ),
                                          const SizedBox(width: 14),
                                          _StatLabel(
                                            icon: Icons.menu_book_rounded,
                                            label: '${widget.proyecto['capitulos'] ?? 0}',
                                            color: accent,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: List.generate(
                                          3,
                                          (i) => Expanded(
                                            child: Container(
                                              height: 1.5,
                                              margin: EdgeInsets.only(left: i == 0 ? 0 : 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.textTertiary.withValues(alpha: 0.2 + i * 0.1),
                                                borderRadius: BorderRadius.circular(1),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Cover image or classic design
                                _CoverDesign(
                                  imageBytes: widget.proyecto['portada_blob'] as Uint8List?,
                                  index: widget.index,
                                  accent: accent,
                                  coverColor: coverColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        // Action button below the book
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              const Spacer(),
              SizedBox(
                width: 28,
                height: 28,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  color: AppColors.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  offset: const Offset(0, 4),
                  onSelected: (value) {
                    if (value == 'delete') widget.onDelete?.call();
                    if (value == 'duplicate') widget.onDuplicate?.call();
                    if (value == 'uploadCover') widget.onUploadCover?.call();
                    if (value == 'removeCover') widget.onRemoveCover?.call();
                    if (value == 'edit') widget.onEdit?.call();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      height: 36,
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16, color: accent),
                          const SizedBox(width: 10),
                          Text(
                            'Editar',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'uploadCover',
                      height: 36,
                      child: Row(
                        children: [
                          Icon(Icons.image_outlined, size: 16, color: accent),
                          const SizedBox(width: 10),
                          Text(
                            'Subir portada',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.proyecto['portada_blob'] != null)
                      PopupMenuItem(
                        value: 'removeCover',
                        height: 36,
                        child: Row(
                          children: [
                            Icon(Icons.image_not_supported_outlined, size: 16, color: Colors.orangeAccent),
                            const SizedBox(width: 10),
                            Text(
                              'Quitar portada',
                              style: GoogleFonts.outfit(
                                color: Colors.orangeAccent,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'duplicate',
                      height: 36,
                      child: Row(
                        children: [
                          Icon(Icons.copy_rounded, size: 16, color: accent),
                          const SizedBox(width: 10),
                          Text(
                            'Duplicar',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      height: 36,
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                          const SizedBox(width: 10),
                          Text(
                            'Eliminar',
                            style: GoogleFonts.outfit(
                              color: Colors.redAccent,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.more_horiz_rounded,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CoverDesign extends StatelessWidget {
  final Uint8List? imageBytes;
  final int index;
  final Color accent;
  final Color coverColor;

  const _CoverDesign({
    this.imageBytes,
    required this.index,
    required this.accent,
    required this.coverColor,
  });

  @override
  Widget build(BuildContext context) {
    if (imageBytes != null && imageBytes!.isNotEmpty) {
      return Positioned.fill(
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(6),
            bottomRight: Radius.circular(6),
          ),
          child: Image.memory(
            imageBytes!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildClassicDesign(),
          ),
        ),
      );
    }
    return _buildClassicDesign();
  }

  Widget _buildClassicDesign() {
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: accent.withValues(alpha: 0.15),
                    width: 1.0,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 3,
              right: 3,
              top: 3,
              bottom: 3,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: accent.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 6,
              top: 6,
              child: _CornerOrnament(accent: accent),
            ),
            Positioned(
              right: 6,
              top: 6,
              child: Transform.flip(
                flipX: true,
                child: _CornerOrnament(accent: accent),
              ),
            ),
            Positioned(
              left: 6,
              bottom: 6,
              child: Transform.flip(
                flipY: true,
                child: _CornerOrnament(accent: accent),
              ),
            ),
            Positioned(
              right: 6,
              bottom: 6,
              child: Transform.flip(
                flipX: true,
                flipY: true,
                child: _CornerOrnament(accent: accent),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  width: 40,
                  height: 1,
                  color: accent.withValues(alpha: 0.08),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CornerOrnament extends StatelessWidget {
  final Color accent;

  const _CornerOrnament({required this.accent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(
        painter: _CornerPainter(accent),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color accent;

  _CornerPainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.25)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0);

    final dotPaint = Paint()
      ..color = accent.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.3), 1.5, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.15), 1, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StatLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _BuildListItem extends StatefulWidget {
  final Map<String, dynamic> proyecto;
  final int index;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;
  final VoidCallback? onUploadCover;
  final VoidCallback? onRemoveCover;
  final VoidCallback? onEdit;

  const _BuildListItem({
    required this.proyecto,
    required this.index,
    required this.onTap,
    this.onDelete,
    this.onDuplicate,
    this.onUploadCover,
    this.onRemoveCover,
    this.onEdit,
  });

  @override
  State<_BuildListItem> createState() => _BuildListItemState();
}

class _BuildListItemState extends State<_BuildListItem> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final imageBytes = widget.proyecto['portada_blob'] as Uint8List?;
    final hasCover = imageBytes != null && imageBytes.isNotEmpty;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isHovered
                  ? AppColors.accent.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.05),
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      blurRadius: 24,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          transform: _isPressed
              ? Matrix4.translationValues(0, 1, 0)
              : Matrix4.identity(),
          child: Row(
            children: [
              _MiniBook(
                proyecto: widget.proyecto,
                index: widget.index,
                isHovered: _isHovered,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.proyecto['titulo'] ?? 'Sin título',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _StatPill(
                          icon: Icons.text_fields_rounded,
                          label: '${widget.proyecto['palabras'] ?? 0}',
                          suffix: 'palabras',
                          isHovered: _isHovered,
                        ),
                        const SizedBox(width: 8),
                        _StatPill(
                          icon: Icons.menu_book_rounded,
                          label: '${widget.proyecto['capitulos'] ?? 0}',
                          suffix: 'capítulos',
                          isHovered: _isHovered,
                        ),
                      ],
                    ),
                    if (widget.proyecto['sinopsis']?.toString().isNotEmpty == true) ...[
                      const SizedBox(height: 10),
                      Text(
                        widget.proyecto['sinopsis'],
                        style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontSize: 12,
                          height: 1.4,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _ListActionChip(
                isHovered: _isHovered,
                hasCover: hasCover,
                onUploadCover: widget.onUploadCover,
                onRemoveCover: widget.onRemoveCover,
                onDuplicate: widget.onDuplicate,
                onDelete: widget.onDelete,
                onEdit: widget.onEdit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String suffix;
  final bool isHovered;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.suffix,
    required this.isHovered,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHovered
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white54),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            ' $suffix',
            style: GoogleFonts.outfit(
              color: Colors.white30,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListActionChip extends StatefulWidget {
  final bool isHovered;
  final bool hasCover;
  final VoidCallback? onUploadCover;
  final VoidCallback? onRemoveCover;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const _ListActionChip({
    required this.isHovered,
    required this.hasCover,
    this.onUploadCover,
    this.onRemoveCover,
    this.onDuplicate,
    this.onDelete,
    this.onEdit,
  });

  @override
  State<_ListActionChip> createState() => _ListActionChipState();
}

class _ListActionChipState extends State<_ListActionChip> {
  bool _chipHovered = false;

  @override
  Widget build(BuildContext context) {
    final show = widget.isHovered || _chipHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _chipHovered = true),
      onExit: (_) => setState(() => _chipHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: show ? null : 0,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _chipHovered
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: show
            ? PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                color: AppColors.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
                ),
                offset: const Offset(0, 4),
                onSelected: (value) {
                  if (value == 'delete') widget.onDelete?.call();
                  if (value == 'duplicate') widget.onDuplicate?.call();
                  if (value == 'uploadCover') widget.onUploadCover?.call();
                  if (value == 'removeCover') widget.onRemoveCover?.call();
                  if (value == 'edit') widget.onEdit?.call();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    height: 34,
                    child: _MenuRow(icon: Icons.edit_outlined, text: 'Editar'),
                  ),
                  if (!widget.hasCover)
                    PopupMenuItem(
                      value: 'uploadCover',
                      height: 34,
                      child: _MenuRow(icon: Icons.image_outlined, text: 'Subir portada'),
                    ),
                  if (widget.hasCover)
                    PopupMenuItem(
                      value: 'removeCover',
                      height: 34,
                      child: _MenuRow(icon: Icons.image_not_supported_outlined, text: 'Quitar portada', isDanger: true),
                    ),
                  PopupMenuItem(
                    value: 'duplicate',
                    height: 34,
                    child: _MenuRow(icon: Icons.copy_rounded, text: 'Duplicar'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    height: 34,
                    child: _MenuRow(icon: Icons.delete_outline_rounded, text: 'Eliminar', isDanger: true),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.more_horiz_rounded,
                    size: 16,
                    color: _chipHovered
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDanger;

  const _MenuRow({
    required this.icon,
    required this.text,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? Colors.redAccent : Colors.white;
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.outfit(
            color: isDanger ? Colors.redAccent : Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _MiniBook extends StatefulWidget {
  final Map<String, dynamic> proyecto;
  final int index;
  final bool isHovered;

  const _MiniBook({
    required this.proyecto,
    required this.index,
    required this.isHovered,
  });

  @override
  State<_MiniBook> createState() => _MiniBookState();
}

class _MiniBookState extends State<_MiniBook> {
  @override
  Widget build(BuildContext context) {
    final coverColor = AppColors.bookCoverColors[widget.index % AppColors.bookCoverColors.length];
    final spineColor = Color.lerp(coverColor, Colors.black, 0.35)!;
    final imageBytes = widget.proyecto['portada_blob'] as Uint8List?;
    final hasCover = imageBytes != null && imageBytes.isNotEmpty;

    return SizedBox(
      width: 68,
      height: 92,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Shadow
          Positioned(
            left: 2,
            right: -2,
            bottom: -2,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
            ),
          ),
          // Spine
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 7,
            child: Container(
              decoration: BoxDecoration(
                color: spineColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
              ),
            ),
          ),
          // Cover
          Positioned(
            left: 7,
            top: 0,
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: coverColor,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    coverColor,
                    Color.lerp(coverColor, Colors.black, 0.15)!,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(3),
                  bottomRight: Radius.circular(3),
                ),
                border: Border(
                  right: BorderSide(
                    color: Colors.black.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  bottom: BorderSide(
                    color: Colors.black.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Cover image
                  Positioned.fill(
                    child: hasCover
                        ? ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(3),
                              bottomRight: Radius.circular(3),
                            ),
                            child: Image.memory(
                              imageBytes,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox.shrink(),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  // Title overlay (hidden when cover image is present)
                  if (!hasCover)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(5, 12, 5, 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                        child: Text(
                          widget.proyecto['titulo'] ?? '',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
