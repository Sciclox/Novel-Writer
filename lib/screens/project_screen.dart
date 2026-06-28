import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'editor_screen.dart';
import 'characters_view.dart';
import 'timeline_view.dart';
import 'places_view.dart';
import 'notes_view.dart';
import 'ideas_view.dart';
import 'exporter_view.dart';
import '../database/app_database.dart';
import '../shared/app_theme.dart';

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
  bool _isSidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    _cargarStats();
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
    {'title': 'Compilar', 'icon': CupertinoIcons.share},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Container(
              color: AppColors.surface,
              child: _buildCurrentView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final isCollapsed = _isSidebarCollapsed;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: isCollapsed ? 68 : 220,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.separator, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
            children: [
              if (!isCollapsed)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Icon(CupertinoIcons.chevron_left, color: AppColors.textSecondary, size: 20),
                    ),
                  ),
                ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
                  child: Padding(
                    padding: EdgeInsets.only(right: isCollapsed ? 0 : 12),
                    child: Icon(
                      isCollapsed ? CupertinoIcons.bars : CupertinoIcons.sidebar_left,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (!isCollapsed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.proyecto['titulo'] ?? 'Sin título',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.proyecto['genero'] ?? 'Novela',
                    style: GoogleFonts.inter(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                (widget.proyecto['titulo'] as String? ?? 'S').isNotEmpty
                    ? (widget.proyecto['titulo'] as String)[0].toUpperCase()
                    : 'S',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedIndex == index;
                return _SidebarMenuItem(
                  title: _menuItems[index]['title'] as String,
                  icon: _menuItems[index]['icon'] as IconData,
                  isSelected: isSelected,
                  isCollapsed: isCollapsed,
                  onTap: () => setState(() => _selectedIndex = index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
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
      case 7: return ExporterView(proyecto: widget.proyecto);
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
          _buildHeader(),
          const SizedBox(height: 36),
          _buildStatsRow(),
          const SizedBox(height: 36),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: _buildSynopsisCard()),
              const SizedBox(width: 24),
              Expanded(flex: 3, child: _buildQuickActions()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.proyecto['titulo'] ?? 'Sin título',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if ((widget.proyecto['sinopsis'] as String?)?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  widget.proyecto['sinopsis'],
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 20),
              _ContinueButton(onPressed: () => setState(() => _selectedIndex = 1)),
            ],
          ),
        ),
        const SizedBox(width: 32),
        _ProgressRing(
          progress: (_totalWords / 50000).clamp(0.0, 1.0),
          value: _totalWords,
          goal: 50000,
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    final stats = [
      {'label': 'Palabras', 'value': _formatNumber(_totalWords)},
      {'label': 'Capítulos', 'value': _totalChapters.toString()},
      {'label': 'Personajes', 'value': _totalCharacters.toString()},
      {'label': 'Eventos', 'value': _totalEvents.toString()},
      {'label': 'Lugares', 'value': _totalPlaces.toString()},
    ];

    return Row(
      children: stats.map((s) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(left: stats.indexOf(s) == 0 ? 0 : 8, right: stats.indexOf(s) == stats.length - 1 ? 0 : 8),
          child: _StatCard(
            label: s['label'] as String,
            value: s['value'] as String,
          ),
        ),
      )).toList(),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  Widget _buildSynopsisCard() {
    final sinopsis = widget.proyecto['sinopsis'] as String?;
    final hasSinopsis = sinopsis?.isNotEmpty == true;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SINOPSIS',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasSinopsis ? '\u201C${sinopsis!}\u201D' : '\u201CTu historia comienza aqu\u00ED.\u201D',
            style: GoogleFonts.inter(
              color: hasSinopsis ? AppColors.textSecondary : AppColors.textTertiary,
              fontSize: 14,
              height: 1.7,
            ),
            maxLines: 8,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'label': 'Escribir', 'icon': CupertinoIcons.pencil, 'index': 1},
      {'label': 'Personajes', 'icon': CupertinoIcons.person_2, 'index': 3},
      {'label': 'Timeline', 'icon': CupertinoIcons.clock, 'index': 2},
      {'label': 'Notas', 'icon': CupertinoIcons.doc_plaintext, 'index': 5},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACCESO R\u00C1PIDO',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        ...actions.map((a) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _QuickActionCard(
            label: a['label'] as String,
            icon: a['icon'] as IconData,
            onTap: () => setState(() => _selectedIndex = a['index'] as int),
          ),
        )),
      ],
    );
  }
}

class _SidebarMenuItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _SidebarMenuItem({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  State<_SidebarMenuItem> createState() => _SidebarMenuItemState();
}

class _SidebarMenuItemState extends State<_SidebarMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: widget.isCollapsed ? widget.title : '',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: EdgeInsets.symmetric(vertical: 2, horizontal: widget.isCollapsed ? 12 : 8),
            padding: EdgeInsets.symmetric(
              vertical: 10,
              horizontal: widget.isCollapsed ? 0 : 12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: widget.isSelected
                  ? AppColors.accent.withValues(alpha: 0.12)
                  : _isHovered
                      ? AppColors.accent.withValues(alpha: 0.06)
                      : null,
            ),
            child: Row(
              mainAxisAlignment: widget.isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  widget.icon,
                  color: widget.isSelected
                      ? AppColors.accent
                      : _isHovered
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                  size: 18,
                ),
                if (!widget.isCollapsed) ...[
                  const SizedBox(width: 12),
                  Text(
                    widget.title,
                    style: GoogleFonts.inter(
                      color: widget.isSelected
                          ? AppColors.accent
                          : _isHovered
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                      fontWeight: widget.isSelected ? FontWeight.w500 : FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: _isHovered ? Matrix4.translationValues(4, 0, 0) : Matrix4.identity(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 18, color: _isHovered ? AppColors.accent : AppColors.textSecondary),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  color: _isHovered ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: _isHovered ? AppColors.accent : AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ContinueButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(CupertinoIcons.pencil, size: 16),
      label: const Text('CONTINUAR ESCRIBIENDO'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.bg,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final double progress;
  final int value;
  final int goal;

  const _ProgressRing({
    required this.progress,
    required this.value,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 6,
              backgroundColor: AppColors.card,
              color: AppColors.accent,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$value / ${goal ~/ 1000}k',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
