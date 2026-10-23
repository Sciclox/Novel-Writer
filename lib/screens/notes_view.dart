import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/app_database.dart';
import '../shared/app_theme.dart';
import '../shared/app_widgets.dart';

import '../widgets/draggable_note.dart';

IconData _iconFromString(String name) {
  switch (name) {
    case 'auto_awesome':
      return Icons.auto_awesome;
    case 'lightbulb_outline':
      return Icons.lightbulb_outline;
    case 'person_outline':
      return Icons.person_outline;
    case 'alt_route':
      return Icons.alt_route;
    case 'movie_creation_outlined':
      return Icons.movie_creation_outlined;
    case 'search_outlined':
      return Icons.search_outlined;
    case 'format_quote_outlined':
      return Icons.format_quote_outlined;
    case 'priority_high':
      return Icons.priority_high;
    case 'star_outline':
      return Icons.star_outline;
    case 'favorite_outline':
      return Icons.favorite_outline;
    case 'book_outlined':
      return Icons.book_outlined;
    case 'flag_outlined':
      return Icons.flag_outlined;
    case 'location_on_outlined':
      return Icons.location_on_outlined;
    case 'schedule_outlined':
      return Icons.schedule_outlined;
    case 'category_outlined':
      return Icons.category_outlined;
    case 'label_outline':
      return Icons.label_outline;
    case 'psychology':
      return Icons.psychology;
    case 'palette_outlined':
      return Icons.palette_outlined;
    case 'music_note_outlined':
      return Icons.music_note_outlined;
    case 'videocam_outlined':
      return Icons.videocam_outlined;
    case 'description_outlined':
      return Icons.description_outlined;
    case 'create_outlined':
      return Icons.create_outlined;
    case 'question_answer_outlined':
      return Icons.question_answer_outlined;
    case 'emoji_objects_outlined':
      return Icons.emoji_objects_outlined;
    case 'travel_explore_outlined':
      return Icons.travel_explore_outlined;
    default:
      return Icons.auto_awesome;
  }
}

String _stringFromIcon(IconData icon) {
  if (icon == Icons.auto_awesome) return 'auto_awesome';
  if (icon == Icons.lightbulb_outline) return 'lightbulb_outline';
  if (icon == Icons.person_outline) return 'person_outline';
  if (icon == Icons.alt_route) return 'alt_route';
  if (icon == Icons.movie_creation_outlined) return 'movie_creation_outlined';
  if (icon == Icons.search_outlined) return 'search_outlined';
  if (icon == Icons.format_quote_outlined) return 'format_quote_outlined';
  if (icon == Icons.priority_high) return 'priority_high';
  if (icon == Icons.star_outline) return 'star_outline';
  if (icon == Icons.favorite_outline) return 'favorite_outline';
  if (icon == Icons.book_outlined) return 'book_outlined';
  if (icon == Icons.flag_outlined) return 'flag_outlined';
  if (icon == Icons.location_on_outlined) return 'location_on_outlined';
  if (icon == Icons.schedule_outlined) return 'schedule_outlined';
  if (icon == Icons.category_outlined) return 'category_outlined';
  if (icon == Icons.label_outline) return 'label_outline';
  if (icon == Icons.psychology) return 'psychology';
  if (icon == Icons.palette_outlined) return 'palette_outlined';
  if (icon == Icons.music_note_outlined) return 'music_note_outlined';
  if (icon == Icons.videocam_outlined) return 'videocam_outlined';
  if (icon == Icons.description_outlined) return 'description_outlined';
  if (icon == Icons.create_outlined) return 'create_outlined';
  if (icon == Icons.question_answer_outlined) return 'question_answer_outlined';
  if (icon == Icons.emoji_objects_outlined) return 'emoji_objects_outlined';
  if (icon == Icons.travel_explore_outlined) return 'travel_explore_outlined';
  return 'auto_awesome';
}

class _Categoria {
  final int id;
  final String nombre;
  final IconData icon;
  final String colorHex;
  Color get color => Color(int.parse(colorHex.replaceFirst('#', '0xFF')));

  _Categoria({
    required this.id,
    required this.nombre,
    required this.icon,
    required this.colorHex,
  });

  factory _Categoria.fromMap(Map<String, dynamic> map) => _Categoria(
    id: map['id'] as int,
    nombre: map['nombre'] as String? ?? 'Sin nombre',
    icon: _iconFromString(map['icon'] as String? ?? 'auto_awesome'),
    colorHex: map['color'] as String? ?? '#FFF9C4',
  );
}

class _GridPainter extends CustomPainter {
  final double interval;
  final Color color;
  _GridPainter({this.interval = 100, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;
    for (double x = 0; x <= size.width; x += interval) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += interval) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) =>
      old.interval != interval || old.color != color;
}

class NotesView extends StatefulWidget {
  final int proyectoId;
  const NotesView({super.key, required this.proyectoId});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  int? _manuscritoId;
  List<Map<String, dynamic>> _notas = [];
  List<_Categoria> _categorias = [];
  bool _isLoading = true;
  bool _isGridView = true;
  String _searchQuery = '';
  String? _selectedCategory;

  final TransformationController _transformationController =
      TransformationController();
  static const double _canvasWidth = 5000.0;
  static const double _canvasHeight = 5000.0;

  @override
  void initState() {
    super.initState();
    _cargarManuscritoYNotas();
    _cargarCategorias();
    _transformationController.value = Matrix4.translationValues(
      -(_canvasWidth / 2 - 400),
      -(_canvasHeight / 2 - 300),
      0.0,
    );
  }

  Future<void> _cargarCategorias() async {
    final rows = await AppDatabase.getCategorias();
    if (mounted) {
      setState(
        () => _categorias = rows.map((r) => _Categoria.fromMap(r)).toList(),
      );
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _cargarManuscritoYNotas() async {
    setState(() => _isLoading = true);
    final manuscrito = await AppDatabase.getManuscritoByProyecto(
      widget.proyectoId,
    );
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

    String selectedCategory = _categorias.isNotEmpty
        ? _categorias.first.id.toString()
        : '0';
    String contenidoInicial = '';

    final crear = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(
              'Nueva Nota',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    autofocus: true,
                    maxLines: 4,
                    style: GoogleFonts.outfit(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Escribe tu recordatorio o nota aquí...',
                      hintStyle: GoogleFonts.outfit(
                        color: AppColors.textTertiary,
                      ),
                      filled: true,
                      fillColor: AppColors.bg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) => contenidoInicial = v,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Categoría',
                    style: GoogleFonts.outfit(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  AppDropdown<String>(
                    value: selectedCategory,
                    hint: 'Seleccionar...',
                    items: _categorias
                        .map(
                          (cat) => AppDropdownItem<String>(
                            value: cat.id.toString(),
                            label: cat.nombre,
                            icon: cat.icon,
                            color: cat.color,
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setStateDialog(() => selectedCategory = v);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textTertiary,
                  side: BorderSide(
                    color: AppColors.textTertiary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text('CANCELAR'),
              ),
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('CREAR'),
              ),
            ],
          );
        },
      ),
    );

    if (crear == true && _manuscritoId != null) {
      final double posX = _canvasWidth / 2 - 100;
      final double posY = _canvasHeight / 2 - 75;

      final cat = _categorias.firstWhere(
        (c) => c.id.toString() == selectedCategory,
        orElse: () => _categorias.first,
      );
      await AppDatabase.insertNota({
        'manuscrito_id': _manuscritoId!,
        'contenido': contenidoInicial.trim(),
        'categoria': cat.id.toString(),
        'color': cat.colorHex,
        'pos_x': posX,
        'pos_y': posY,
        'ancho': 220.0,
        'alto': 170.0,
      });

      _cargarNotas();
    }
  }

  static final List<IconData> _iconosDisponibles = [
    Icons.auto_awesome,
    Icons.lightbulb_outline,
    Icons.person_outline,
    Icons.alt_route,
    Icons.movie_creation_outlined,
    Icons.search_outlined,
    Icons.format_quote_outlined,
    Icons.priority_high,
    Icons.star_outline,
    Icons.favorite_outline,
    Icons.book_outlined,
    Icons.flag_outlined,
    Icons.location_on_outlined,
    Icons.schedule_outlined,
    Icons.category_outlined,
    Icons.label_outline,
    Icons.psychology,
    Icons.palette_outlined,
    Icons.music_note_outlined,
    Icons.videocam_outlined,
    Icons.description_outlined,
    Icons.create_outlined,
    Icons.question_answer_outlined,
    Icons.emoji_objects_outlined,
    Icons.travel_explore_outlined,
  ];

  static final List<String> _coloresDisponibles = [
    '#FFF9C4',
    '#C8E6C9',
    '#E1BEE7',
    '#FFE0B2',
    '#BBDEFB',
    '#C5CAE9',
    '#F8BBD9',
    '#FFCDD2',
    '#B2EBF2',
    '#B2DFDB',
    '#D7CCC8',
    '#CE93D8',
    '#80DEEA',
    '#A5D6A7',
    '#FFCC80',
    '#EF9A9A',
  ];

  Future<void> _mostrarDialogoCategorias() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Gestionar Categorías',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 400,
          child: _categorias.isEmpty
              ? Center(
                  child: Text(
                    'No hay categorías',
                    style: GoogleFonts.outfit(color: AppColors.textTertiary),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: _categorias.length,
                  separatorBuilder: (_, _) =>
                      Divider(color: AppColors.separator, height: 1),
                  itemBuilder: (context, index) {
                    final cat = _categorias[index];
                    return ListTile(
                      dense: true,
                      leading: Icon(cat.icon, color: cat.color, size: 24),
                      title: Text(
                        cat.nombre,
                        style: GoogleFonts.outfit(color: AppColors.textPrimary),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () async {
                                await _mostrarDialogoEditarCategoria(cat);
                                if (ctx.mounted) Navigator.pop(ctx, true);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () async {
                                await AppDatabase.deleteCategoria(cat.id);
                                if (ctx.mounted) Navigator.pop(ctx, true);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.red.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: AppColors.red,
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
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textTertiary,
            ),
            child: Text('CERRAR'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () async {
              await _mostrarDialogoEditarCategoria(null);
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text('NUEVA CATEGORÍA'),
          ),
        ],
      ),
    );
    if (changed == true) _cargarCategorias();
  }

  Future<void> _mostrarDialogoEditarCategoria(_Categoria? existing) async {
    final esNueva = existing == null;
    String nombre = existing?.nombre ?? '';
    IconData icono = existing?.icon ?? Icons.auto_awesome;
    String colorHex = existing?.colorHex ?? '#FFF9C4';
    String iconString = _stringFromIcon(icono);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(
              esNueva ? 'Nueva Categoría' : 'Editar Categoría',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nombre',
                      style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: TextEditingController(text: nombre),
                      style: GoogleFonts.outfit(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Nombre de la categoría',
                        hintStyle: GoogleFonts.outfit(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      onChanged: (v) => nombre = v,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Icono',
                      style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _iconosDisponibles.map((ic) {
                        final isSel = iconString == _stringFromIcon(ic);
                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => setStateDialog(() {
                              icono = ic;
                              iconString = _stringFromIcon(ic);
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? AppColors.accent.withValues(alpha: 0.15)
                                    : AppColors.bg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSel
                                      ? AppColors.accent
                                      : AppColors.separator,
                                  width: isSel ? 1.5 : 1,
                                ),
                              ),
                              child: Icon(
                                ic,
                                size: 20,
                                color: isSel
                                    ? AppColors.accent
                                    : AppColors.textTertiary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Color',
                      style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _coloresDisponibles.map((hex) {
                        final c = Color(
                          int.parse(hex.replaceFirst('#', '0xFF')),
                        );
                        final isSel = colorHex == hex;
                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => setStateDialog(() => colorHex = hex),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSel
                                      ? AppColors.textPrimary
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textTertiary,
                ),
                child: Text('CANCELAR'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nombre.trim().isEmpty) return;
                  if (esNueva) {
                    await AppDatabase.insertCategoria({
                      'proyecto_id': null,
                      'nombre': nombre.trim(),
                      'icon': iconString,
                      'color': colorHex,
                      'orden': _categorias.length,
                    });
                  } else {
                    await AppDatabase.updateCategoria(existing.id, {
                      'nombre': nombre.trim(),
                      'icon': iconString,
                      'color': colorHex,
                    });
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(esNueva ? 'CREAR' : 'GUARDAR'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _eliminarNota(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Eliminar Nota',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Deseas eliminar esta nota permanentemente?',
          style: GoogleFonts.outfit(color: AppColors.textSecondary),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textTertiary,
              side: BorderSide(
                color: AppColors.textTertiary.withValues(alpha: 0.3),
              ),
            ),
            child: Text('CANCELAR'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.red,
              side: BorderSide(color: AppColors.red),
            ),
            child: Text('ELIMINAR'),
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
          _notas[i] = {..._notas[i], 'pos_x': x, 'pos_y': y};
          break;
        }
      }
    });
  }

  List<Map<String, dynamic>> _obtenerNotasFiltradas() {
    return _notas.where((n) {
      final contenido = n['contenido']?.toString().toLowerCase() ?? '';
      final matchesSearch = contenido.contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == null || n['categoria'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

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
            Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 24),
            Text(
              'No se encontró el manuscrito para este proyecto.',
              style: GoogleFonts.outfit(
                color: AppColors.textTertiary,
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    final notasFiltradas = _obtenerNotasFiltradas();

    if (_notas.isEmpty) {
      return buildEmptyState(
        icon: Icons.sticky_note_2_outlined,
        title: 'Aún no tienes notas',
        subtitle: 'Crea tu primera nota para organizar tus ideas.',
        actionLabel: 'CREAR PRIMER NOTA',
        onAction: _agregarNota,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarNota,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text(
          'NUEVA NOTA',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      body: Column(
        children: [
          // HEADER CON FILTROS Y BÚSQUEDA
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
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
                          'SCRATCHPAD DE NOTAS',
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Anota ideas fugaces, cabos sueltos o apuntes de investigación sin alterar el manuscrito.',
                          style: GoogleFonts.outfit(
                            color: AppColors.textTertiary,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),

                    // Segmented Button para Toggle de Vista
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => setState(() => _isGridView = true),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _isGridView
                                      ? AppColors.accent.withValues(alpha: 0.08)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _isGridView
                                        ? AppColors.accent
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.grid_view_rounded,
                                      size: 16,
                                      color: _isGridView
                                          ? AppColors.accent
                                          : Colors.white54,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Cuadrícula',
                                      style: GoogleFonts.outfit(
                                        fontWeight: _isGridView
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 13,
                                        color: _isGridView
                                            ? AppColors.accent
                                            : Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => setState(() => _isGridView = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: !_isGridView
                                      ? AppColors.accent.withValues(alpha: 0.08)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: !_isGridView
                                        ? AppColors.accent
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.layers_rounded,
                                      size: 16,
                                      color: !_isGridView
                                          ? AppColors.accent
                                          : Colors.white54,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Lienzo Libre',
                                      style: GoogleFonts.outfit(
                                        fontWeight: !_isGridView
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 13,
                                        color: !_isGridView
                                            ? AppColors.accent
                                            : Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // BARRA DE BÚSQUEDA Y FILTROS
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: GoogleFonts.outfit(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Buscar en notas...',
                          hintStyle: GoogleFonts.outfit(
                            color: AppColors.textTertiary,
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 16,
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(
                              left: 14,
                              right: 8,
                            ),
                            child: Icon(
                              Icons.search_rounded,
                              color: AppColors.textTertiary,
                              size: 18,
                            ),
                          ),
                          suffixIconConstraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _searchQuery = ''),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceLight
                                            .withValues(alpha: 0.3),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 14,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ),
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.separator.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.separator.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.accent.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 200,
                      child: AppDropdown<String?>(
                        value: _selectedCategory,
                        hint: 'Todas',
                        height: 48,
                        items: [
                          const AppDropdownItem<String?>(
                            value: null,
                            label: 'Todas',
                          ),
                          ..._categorias.map(
                            (cat) => AppDropdownItem<String?>(
                              value: cat.id.toString(),
                              label: cat.nombre,
                              icon: cat.icon,
                              color: cat.color,
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _selectedCategory = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: _mostrarDialogoCategorias,
                        child: Container(
width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.separator.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
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
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _isGridView
                  ? _buildGridView(notasFiltradas)
                  : _buildCanvasView(notasFiltradas),
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
            Icon(
              Icons.sticky_note_2_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron notas con estos filtros.',
              style: GoogleFonts.outfit(
                color: AppColors.textTertiary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
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
      boundaryMargin: const EdgeInsets.all(2000),
      minScale: 0.3,
      maxScale: 2.0,
      constrained: false,
      child: SizedBox(
        width: _canvasWidth,
        height: _canvasHeight,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _GridPainter(
                  interval: 100,
                  color: AppColors.separator,
                ),
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

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transformAlignment: Alignment.center,
        transform: _isHovered
            ? (Matrix4.translationValues(0.0, -6.0, 0.0) *
                  Matrix4.diagonal3Values(1.02, 1.02, 1.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? AppColors.accent.withValues(alpha: 0.4)
                : AppColors.separator,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? AppColors.accent.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.15),
              blurRadius: _isHovered ? 20 : 10,
              offset: Offset(0, _isHovered ? 8 : 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.sticky_note_2_outlined,
                        size: 12,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'NOTA',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.5,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: null,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        filled: false,
                        isDense: true,
                        hintText: 'Añadir nota...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: InkWell(
                  onTap: widget.onDelete,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
