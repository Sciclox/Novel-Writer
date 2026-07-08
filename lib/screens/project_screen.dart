import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'editor_screen.dart';
import 'characters_view.dart';
import 'timeline_view.dart';
import 'places_view.dart';
import 'notes_view.dart';
import 'ideas_view.dart';
import 'estilos_view.dart';
import 'exporter_view.dart';
import '../database/app_database.dart';
import '../shared/app_theme.dart';
import '../widgets/fluid_dock.dart';

class ProjectScreen extends StatefulWidget {
  final Map<String, dynamic> proyecto;

  const ProjectScreen({super.key, required this.proyecto});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  int _selectedIndex = 0;
  int _totalWords = 0;
  int _totalChapters = 0;
  int _totalCharacters = 0;
  int _totalEvents = 0;
  int _totalPlaces = 0;
  bool _statsLoading = true;

  // Synopsis editing state
  bool _isEditingSinopsis = false;
  bool _isSavingSinopsis = false;
  late TextEditingController _sinopsisController;
  late FocusNode _sinopsisFocusNode;

  @override
  void initState() {
    super.initState();
    _sinopsisController = TextEditingController(
      text: widget.proyecto['sinopsis'] as String? ?? '',
    );
    _sinopsisFocusNode = FocusNode();
    _cargarStats();
  }

  @override
  void dispose() {
    _sinopsisController.dispose();
    _sinopsisFocusNode.dispose();
    super.dispose();
  }

  Future<void> _cargarStats() async {
    final stats = await AppDatabase.getProyectoStats(widget.proyecto['id'] as int);

    if (mounted) {
      setState(() {
        _totalWords = stats['palabras'] ?? 0;
        _totalChapters = stats['capitulos'] ?? 0;
        _totalCharacters = stats['personajes'] ?? 0;
        _totalEvents = stats['eventos'] ?? 0;
        _totalPlaces = stats['lugares'] ?? 0;
        _statsLoading = false;
      });
    }
  }

  static final _menuItems = [
    {'title': 'Dashboard', 'icon': CupertinoIcons.square_grid_2x2},
    {'title': 'Manuscrito', 'icon': CupertinoIcons.doc_text},
    {'title': 'Línea de Tiempo', 'icon': CupertinoIcons.clock},
    {'title': 'Personajes', 'icon': CupertinoIcons.person_2},
    {'title': 'Lugares', 'icon': CupertinoIcons.map_pin},
    {'title': 'Notas', 'icon': CupertinoIcons.doc_plaintext},
    {'title': 'Ideas', 'icon': CupertinoIcons.lightbulb},
    {'title': 'Estilos', 'icon': CupertinoIcons.textformat_size},
    {'title': 'Compilar', 'icon': CupertinoIcons.share},
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.bg,
          body: Row(
            children: [
              Expanded(
                child: _buildCurrentView(),
              ),
            ],
          ),
        ),
        FluidDock(
          items: _menuItems.map((m) => FluidDockItem(
            icon: m['icon'] as IconData,
            tooltip: m['title'] as String,
          )).toList(),
          selectedIndex: _selectedIndex,
          onItemSelected: (i) {
            setState(() => _selectedIndex = i);
            if (i == 0) _cargarStats();
          },
          onBack: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildCurrentView() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          children: [
            ...previousChildren.map((child) => RepaintBoundary(key: child.key, child: child)),
            if (currentChild != null) RepaintBoundary(key: currentChild.key, child: currentChild),
          ],
        );
      },
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: KeyedSubtree(
        key: ValueKey('view_$_selectedIndex'),
        child: _buildViewByIndex(),
      ),
    );
  }

  Widget _buildViewByIndex() {
    switch (_selectedIndex) {
      case 0: return _buildDashboard();
      case 1: return EditorScreen(proyecto: widget.proyecto, isNested: true);
      case 2: return TimelineView(proyectoId: widget.proyecto['id'] as int);
      case 3: return CharactersView(proyectoId: widget.proyecto['id'] as int);
      case 4: return PlacesView(proyectoId: widget.proyecto['id'] as int);
      case 5: return NotesView(proyectoId: widget.proyecto['id'] as int);
      case 6: return IdeasView(proyectoId: widget.proyecto['id'] as int);
      case 7: return EstilosView(proyectoId: widget.proyecto['id'] as int);
      case 8: return ExporterView(proyecto: widget.proyecto);
      default: return const Center(child: Text('Vista no encontrada'));
    }
  }

  Widget _buildDashboard() {
    if (_statsLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelHeader(),
          const SizedBox(height: 24),
          _buildKpiWithProgress(),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: _buildSynopsisPanel()),
              const SizedBox(width: 24),
              Expanded(flex: 4, child: _buildQuickActionsPanel()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _panelContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }

  Widget _buildPanelHeader() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Buenos días';
    } else if (hour < 18) {
      greeting = 'Buenas tardes';
    } else {
      greeting = 'Buenas noches';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, Escritor'.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.proyecto['titulo'] ?? 'Sin título',
                  style: GoogleFonts.outfit(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(CupertinoIcons.book, size: 13, color: Colors.white38),
                    const SizedBox(width: 6),
                    Text(
                      widget.proyecto['genero'] as String? ?? 'Novela',
                      style: GoogleFonts.outfit(fontSize: 13, color: Colors.white54),
                    ),
                    const SizedBox(width: 16),
                    Container(width: 3, height: 3, decoration: BoxDecoration(color: Colors.white38, shape: BoxShape.circle)),
                    const SizedBox(width: 16),
                    Icon(CupertinoIcons.doc_text, size: 13, color: Colors.white38),
                    const SizedBox(width: 6),
                    Text(
                      '$_totalChapters capítulos',
                      style: GoogleFonts.outfit(fontSize: 13, color: Colors.white54),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          _buildRing(),
        ],
      ),
    );
  }

  Widget _buildRing() {
    final p = (_totalWords / 50000).clamp(0.0, 1.0);
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.08),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CircularProgressIndicator(
            value: p,
            strokeWidth: 5,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            color: AppColors.accent,
            strokeCap: StrokeCap.round,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${(p * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatNumber(_totalWords),
              style: GoogleFonts.outfit(fontSize: 9, color: Colors.white38, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiWithProgress() {
    final p = (_totalWords / 50000).clamp(0.0, 1.0);
    final milestones = [10000, 25000, 50000];
    final items = [
      ('Palabras', _formatNumber(_totalWords), CupertinoIcons.text_alignleft),
      ('Capítulos', _totalChapters.toString(), CupertinoIcons.book),
      ('Personajes', _totalCharacters.toString(), CupertinoIcons.person_2),
      ('Eventos', _totalEvents.toString(), CupertinoIcons.clock),
      ('Lugares', _totalPlaces.toString(), CupertinoIcons.location),
    ];

    return _panelContainer(
      child: Column(
        children: [
          // KPI row
          Row(
            children: List.generate(items.length, (i) {
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(items[i].$3, size: 14, color: Colors.white38),
                              const SizedBox(width: 6),
                              Text(
                                items[i].$1.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white38,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            items[i].$2,
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < items.length - 1)
                      Container(
                        width: 1,
                        height: 44,
                        margin: const EdgeInsets.only(left: 16),
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 24),
          // Progress section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PROGRESO DE ESCRITURA',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_formatNumber(_totalWords)} / 50,000',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: p,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: milestones.map((m) {
              final reached = _totalWords >= m;
              return Expanded(
                child: Row(
                  children: [
                    Icon(
                      reached ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 12,
                      color: reached ? AppColors.accent : Colors.white24,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatNumber(m),
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: reached ? AppColors.accent : Colors.white24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                p >= 1.0 ? Icons.celebration_rounded : Icons.trending_up_rounded,
                size: 16,
                color: AppColors.accent,
              ),
              const SizedBox(width: 8),
              Text(
                p >= 1.0
                    ? '¡Felicidades! Has alcanzado la meta de 50,000 palabras.'
                    : 'Te faltan ${_formatNumber(50000 - _totalWords)} palabras para alcanzar la meta.',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.white54,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Synopsis Save / Cancel ──────────────────────────────

  Future<void> _saveSinopsis() async {
    if (_isSavingSinopsis) return;
    setState(() => _isSavingSinopsis = true);

    final newSinopsis = _sinopsisController.text.trim();
    try {
      await AppDatabase.updateProyecto({
        'id': widget.proyecto['id'],
        'sinopsis': newSinopsis,
      });
      widget.proyecto['sinopsis'] = newSinopsis;
      if (mounted) {
        setState(() {
          _isEditingSinopsis = false;
          _isSavingSinopsis = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isSavingSinopsis = false);
    }
  }

  void _cancelEditSinopsis() {
    _sinopsisController.text = widget.proyecto['sinopsis'] as String? ?? '';
    setState(() => _isEditingSinopsis = false);
  }

  // ── Synopsis Panel ──────────────────────────────────────

  Widget _buildSynopsisPanel() {
    final sinopsis = widget.proyecto['sinopsis'] as String?;
    final hasSinopsis = sinopsis?.isNotEmpty == true;

    return _panelContainer(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent,
                    AppColors.accent.withValues(alpha: 0.3),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with title + action buttons
                  Row(
                    children: [
                      Icon(CupertinoIcons.text_quote, size: 14, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Text(
                        'SINOPSIS',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const Spacer(),
                      if (_isEditingSinopsis) ...[
                        // Cancel button
                        _SynopsisActionButton(
                          icon: CupertinoIcons.xmark,
                          label: 'Cancelar',
                          onTap: _cancelEditSinopsis,
                          isAccent: false,
                        ),
                        const SizedBox(width: 8),
                        // Save button
                        _SynopsisActionButton(
                          icon: CupertinoIcons.checkmark_alt,
                          label: 'Guardar',
                          onTap: _isSavingSinopsis ? null : _saveSinopsis,
                          isAccent: true,
                          isLoading: _isSavingSinopsis,
                        ),
                      ] else ...[
                        if (!hasSinopsis)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Text(
                              '— PENDIENTE',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                color: AppColors.orange,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        _SynopsisActionButton(
                          icon: hasSinopsis
                              ? CupertinoIcons.pencil
                              : CupertinoIcons.plus,
                          label: hasSinopsis ? 'Editar' : 'Escribir',
                          onTap: () {
                            setState(() => _isEditingSinopsis = true);
                            Future.delayed(
                              const Duration(milliseconds: 100),
                              () => _sinopsisFocusNode.requestFocus(),
                            );
                          },
                          isAccent: true,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Content: editable or read-only
                  if (_isEditingSinopsis)
                    _buildSinopsisEditor()
                  else
                    _buildSinopsisDisplay(sinopsis, hasSinopsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSinopsisEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
            controller: _sinopsisController,
            focusNode: _sinopsisFocusNode,
            maxLines: 10,
            minLines: 5,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              height: 1.8,
            ),
            decoration: InputDecoration(
              hintText: 'Escribe la sinopsis de tu novela...',
              hintStyle: GoogleFonts.outfit(
                fontSize: 15,
                color: Colors.white24,
                fontStyle: FontStyle.italic,
              ),
              contentPadding: const EdgeInsets.all(16),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.accent.withValues(alpha: 0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.accent.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.accent.withValues(alpha: 0.4), width: 1.5),
              ),
            ),
            cursorColor: AppColors.accent,
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(CupertinoIcons.info_circle, size: 13, color: Colors.white24),
            const SizedBox(width: 6),
            Text(
              'La sinopsis aparecerá en la portada y al exportar tu novela.',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.white30,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSinopsisDisplay(String? sinopsis, bool hasSinopsis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Positioned(
              top: -8,
              left: -4,
              child: Opacity(
                opacity: 0.04,
                child: Icon(CupertinoIcons.text_quote, size: 64, color: AppColors.accent),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                hasSinopsis
                    ? sinopsis!
                    : 'Aún no has escrito una sinopsis.',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: hasSinopsis ? Colors.white : Colors.white38,
                  height: 1.8,
                  fontStyle: hasSinopsis ? FontStyle.normal : FontStyle.italic,
                ),
                maxLines: 14,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (!hasSinopsis) ...[
          const SizedBox(height: 8),
          Text(
            'Define el rumbo de tu historia.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.white30,
            ),
          ),
        ],
      ],
    );
  }

  // ── Quick Actions Panel ─────────────────────────────────

  Widget _buildQuickActionsPanel() {
    return _panelContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(CupertinoIcons.bolt_fill, size: 16, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Text(
                'ACCESO RÁPIDO',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _QuickActionItem(
            icon: CupertinoIcons.pencil,
            label: 'Escribir',
            subtitle: 'Continúa tu manuscrito',
            onTap: () => setState(() => _selectedIndex = 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Divider(height: 1, color: Colors.white10),
          ),
          _QuickActionItem(
            icon: CupertinoIcons.person_2,
            label: 'Personajes',
            subtitle: 'Gestiona tus personajes',
            onTap: () => setState(() => _selectedIndex = 3),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Divider(height: 1, color: Colors.white10),
          ),
          _QuickActionItem(
            icon: CupertinoIcons.clock,
            label: 'Timeline',
            subtitle: 'Línea de tiempo',
            onTap: () => setState(() => _selectedIndex = 2),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Divider(height: 1, color: Colors.white10),
          ),
          _QuickActionItem(
            icon: CupertinoIcons.doc_plaintext,
            label: 'Notas',
            subtitle: 'Notas y apuntes',
            onTap: () => setState(() => _selectedIndex = 5),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Icon(CupertinoIcons.lightbulb_fill, size: 14, color: AppColors.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consejo del día',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dailyTip(),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.white54,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _dailyTip() {
    final tips = [
      'Escribe al menos 500 palabras al día para mantener el ritmo.',
      'Revisa el capítulo anterior antes de empezar a escribir.',
      'No edites mientras escribes el primer borrador.',
      'Usa la línea de tiempo para mantener la coherencia cronológica.',
      'Define bien a tus personajes antes de escribir sus diálogos.',
    ];
    return tips[DateTime.now().millisecondsSinceEpoch ~/ 86400000 % tips.length];
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

// ── Synopsis Action Button ──────────────────────────────

class _SynopsisActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isAccent;
  final bool isLoading;

  const _SynopsisActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isAccent = false,
    this.isLoading = false,
  });

  @override
  State<_SynopsisActionButton> createState() => _SynopsisActionButtonState();
}

class _SynopsisActionButtonState extends State<_SynopsisActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isAccent ? AppColors.accent : Colors.white54;
    final hoverColor = widget.isAccent ? AppColors.accent : Colors.white70;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: (_isHovered ? color : color.withValues(alpha: 0.1))
                .withValues(alpha: _isHovered ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (_isHovered ? hoverColor : color).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isLoading)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: color,
                  ),
                )
              else
                Icon(widget.icon, size: 12, color: _isHovered ? hoverColor : color),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _isHovered ? hoverColor : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quick Action Item ───────────────────────────────────

class _QuickActionItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.label,
    required this.icon,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_QuickActionItem> createState() => _QuickActionItemState();
}

class _QuickActionItemState extends State<_QuickActionItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.only(left: _isHovered ? 8 : 0),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: _isHovered ? AppColors.accent : Colors.white54,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: GoogleFonts.outfit(
                          color: _isHovered ? Colors.white : Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: _isHovered ? AppColors.accent : Colors.white24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
