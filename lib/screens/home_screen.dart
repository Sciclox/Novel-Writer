import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'project_screen.dart';
import '../database/app_database.dart';

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
      backgroundColor: const Color(0xFF1C1C1E),
      body: Column(
        children: [
          // Header
          _buildHeader(isWide),
          // Body
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _proyectos.isEmpty
                    ? _buildEmptyState()
                    : _buildProjectGrid(isWide, _proyectos),
          ),
        ],
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(right: 12),
        child: FloatingActionButton.extended(
          onPressed: _mostrarDialogoNuevoProyecto,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1C1C1E),
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(Icons.add_rounded, size: 22),
          label: Text(
            'NUEVO',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isWide) {
    return Container(
      padding: EdgeInsets.fromLTRB(32, MediaQuery.of(context).padding.top + 12, 32, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        border: Border(
          bottom: BorderSide(color: const Color(0xFF48484A).withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3), width: 1,
              ),
            ),
            child: Icon(Icons.auto_stories_rounded, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SUS NOVELAS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3.0,
                ),
              ),
              Text(
                '${_proyectos.length} ${_proyectos.length == 1 ? 'proyecto' : 'proyectos'}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF6B6B8A),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ViewToggleChip(
                  icon: Icons.grid_view_rounded,
                  isActive: _isGridView,
                  onPressed: () => setState(() => _isGridView = true),
                ),
                const SizedBox(width: 2),
                _ViewToggleChip(
                  icon: Icons.list_rounded,
                  isActive: !_isGridView,
                  onPressed: () => setState(() => _isGridView = false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 2),
            ),
            child: const Icon(Icons.menu_book_rounded, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 32),
          Text(
            'Aún no tienes proyectos',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primer proyecto y comienza a escribir.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white38,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _mostrarDialogoNuevoProyecto,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('CREAR PROYECTO'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1C1C1E),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectGrid(bool isWide, List<Map<String, dynamic>> proyectos) {
    if (_isGridView) {
      return GridView.builder(
        padding: EdgeInsets.fromLTRB(
          32,
          28,
          32,
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
          32,
          16,
          32,
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
      MaterialPageRoute(
        builder: (context) => ProjectScreen(proyecto: proyecto),
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
        backgroundColor: const Color(0xFF3A3A3C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Edita el título y la sinopsis',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: tituloController,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      labelText: 'Título de la obra',
                      labelStyle: GoogleFonts.inter(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1C1C1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: sinopsisController,
                    maxLines: 4,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      labelText: 'Sinopsis (opcional)',
                      labelStyle: GoogleFonts.inter(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1C1C1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (tituloController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('El título es obligatorio'),
                              backgroundColor: Colors.redAccent,
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1C1C1E),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'GUARDAR CAMBIOS',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
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
        backgroundColor: const Color(0xFF3A3A3C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Crea un nuevo proyecto de escritura',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: tituloController,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      labelText: 'Título de la obra',
                      labelStyle: GoogleFonts.inter(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1C1C1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: sinopsisController,
                    maxLines: 4,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      labelText: 'Sinopsis (opcional)',
                      labelStyle: GoogleFonts.inter(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1C1C1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (tituloController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('El título es obligatorio'),
                              backgroundColor: Colors.redAccent,
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1C1C1E),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'CREAR PROYECTO',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
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

class _ViewToggleChip extends StatefulWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onPressed;

  const _ViewToggleChip({
    required this.icon,
    required this.isActive,
    required this.onPressed,
  });

  @override
  State<_ViewToggleChip> createState() => _ViewToggleChipState();
}

class _ViewToggleChipState extends State<_ViewToggleChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isActive
                ? Colors.white
                : _isHovered
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: widget.isActive
                    ? const Color(0xFF1C1C1E)
                    : _isHovered
                        ? Colors.white
                        : Colors.white38,
              ),
              const SizedBox(width: 6),
              Text(
                widget.icon == Icons.grid_view_rounded ? 'Cuadrícula' : 'Lista',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: widget.isActive
                      ? const Color(0xFF1C1C1E)
                      : _isHovered
                          ? Colors.white
                          : Colors.white38,
                ),
              ),
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
    final colors = [
      const Color(0xFF1E1B4B),
      const Color(0xFF1B1340),
      const Color(0xFF1B2A35),
      const Color(0xFF2D1B2E),
      const Color(0xFF1B2A2A),
    ];
    final accentColors = [
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFF06B6D4),
      const Color(0xFFEC4899),
      const Color(0xFF22C55E),
    ];
    final coverColor = colors[widget.index % colors.length];
    final spineColor = Color.lerp(coverColor, Colors.black, 0.35)!;
    final accent = accentColors[widget.index % accentColors.length];

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
                                  const Color(0xFFF5E6D3),
                                  const Color(0xFFE8D5C0),
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sinopsis',
                                  style: GoogleFonts.inter(
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
                                      style: GoogleFonts.inter(
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
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
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
                                        color: accent.withValues(alpha: 0.5),
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
                                                color: Colors.white.withValues(alpha: 0.05 + i * 0.03),
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
                  color: const Color(0xFF3A3A3C),
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
                            style: GoogleFonts.inter(
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
                            style: GoogleFonts.inter(
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
                              style: GoogleFonts.inter(
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
                            style: GoogleFonts.inter(
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
                            style: GoogleFonts.inter(
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
          style: GoogleFonts.inter(
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
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
          decoration: BoxDecoration(
            color: _isHovered
                ? const Color(0xFF18192B)
                : const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.04),
              width: 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.04),
                      blurRadius: 20,
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
                            style: GoogleFonts.inter(
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
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.3),
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
          Icon(icon, size: 11, color: Colors.white.withValues(alpha: 0.6)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            ' $suffix',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.35),
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
                color: const Color(0xFF3A3A3C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: const Color(0xFF48484A), width: 1),
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
          style: GoogleFonts.inter(
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
    final colors = [
      const Color(0xFF1E1B4B),
      const Color(0xFF1B1340),
      const Color(0xFF1B2A35),
      const Color(0xFF2D1B2E),
      const Color(0xFF1B2A2A),
    ];
    final coverColor = colors[widget.index % colors.length];
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
                          style: GoogleFonts.inter(
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