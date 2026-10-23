import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../database/app_database.dart';
import '../widgets/draggable_card.dart';
import '../widgets/editor_widgets.dart';
import '../shared/app_widgets.dart';
import '../shared/app_theme.dart';
import '../models/novel_style.dart';
import '../models/chapter_model.dart';
import '../models/character_model.dart';
import '../models/place_model.dart';
import '../repositories/chapter_repository.dart';
import '../repositories/character_repository.dart';
import '../repositories/place_repository.dart';
import '../utils/narrative_text_utils.dart';
import '../widgets/atajo_recorder.dart';
import '../widgets/app_color_picker.dart';
import '../widgets/chapter_metadata_dialog.dart';
import '../widgets/chapter_trash_dialog.dart';
import '../widgets/word_frequency_dialog.dart';
import '../widgets/version_diff_dialog.dart';
import '../widgets/editor_codex_sidebar.dart';
import '../widgets/editor_coherence_sidebar.dart';
import '../widgets/global_search_dialog.dart';

class EditorScreen extends StatefulWidget {
  final Map<String, dynamic> proyecto;
  final bool isNested;
  const EditorScreen({
    super.key,
    required this.proyecto,
    this.isNested = false,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late QuillController _quillController;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _fontSizeController = TextEditingController(
    text: '18',
  );
  final FocusNode _editorFocusNode = FocusNode();
  final FocusNode _fontSizeFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();
  bool _isQuillInitialized = false;
  int? _manuscritoId;
  List<Map<String, dynamic>> _notas = [];
  List<Map<String, dynamic>> _tarjetas = [];
  List<Map<String, dynamic>> _capitulos = [];
  int _selectedCapituloIndex = 0;
  int _selectedIndex = 0;
  bool _isPanelOpen = true;
  bool _isCapitulosOpen = true;
  SaveStatus _saveStatus = SaveStatus.saved;
  Timer? _autoSaveTimer;
  Timer? _statsTimer;
  Timer? _prefsSaveTimer;

  // Distraction-Free Mode & Writing Mechanics
  bool _distractionFreeMode = false;
  bool _typewriterMode = false;
  bool _autoEmDash = true;
  bool _splitView = false;
  int _splitCapituloIndex = 0;

  // Codex Inspector & Tabs
  int _rightSidebarTabIndex = 0; // 0 = Enfoque & Estadísticas, 1 = Codex Rápido
  List<Character> _codexCharacters = [];
  List<Place> _codexPlaces = [];

  // Find & Replace
  bool _showFindReplace = false;
  final TextEditingController _findController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  int? _highlightedMatchIndex;
  List<TextSelection> _findMatches = [];

  // Pomodoro y Metas de Productividad
  Timer? _pomodoroTimer;
  int _pomodoroSecondsRemaining = 25 * 60;
  int _pomodoroDurationMinutes = 25;
  bool _isPomodoroRunning = false;
  bool _showPomodoroCompletionOverlay = false;

  int _sessionWordGoal = 500;
  int _initialWordCountTotal = 0;
  int _sessionWordsWritten = 0;

  // Personalización del Entorno (Fijo para diseño premium y limpio)
  Color _pageColor = const Color(
    0xFFFFFFFF,
  ); // Papel de escritura blanco elegante
  String _fontFamily = 'Merriweather';
  double _fontSize = 18;
  double _lineHeight = 1.8;

  int _wordCount = 0;
  int _charCount = 0;
  List<NovelStyle> _estilos = [];

  String _lastSavedText = '';
  String _lastSavedTitle = '';
  String _lastSavedPageColorHex = '#FFFFFF';
  String _lastSavedFontFamily = 'Merriweather';
  double _lastSavedFontSize = 18;
  double _lastSavedLineHeight = 1.8;

  bool _kbdHandler(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (HardwareKeyboard.instance.isControlPressed &&
          HardwareKeyboard.instance.isShiftPressed &&
          event.logicalKey == LogicalKeyboardKey.keyF) {
        _abrirBusquedaGlobal();
        return true;
      }
    }
    if (!_editorFocusNode.hasFocus) return false;
    if (event is! KeyDownEvent) return false;
    final combo = pressedKeyCombo(event.logicalKey);
    if (combo == null) return false;
    final matching = _estilos.where((s) => s.atajo == combo).firstOrNull;
    if (matching != null) {
      _applyStyle(matching.id!);
      return true;
    }
    return false;
  }

  void _abrirBusquedaGlobal() {
    GlobalSearchDialog.show(
      context: context,
      capitulos: _capitulos,
      onNavigate: (chapterIndex, offset) {
        if (chapterIndex != _selectedCapituloIndex) {
          _cambiarCapitulo(chapterIndex);
        }
        Future.delayed(const Duration(milliseconds: 200), () {
          if (_isQuillInitialized) {
            final docLength = _quillController.document.length;
            final safeOffset = offset.clamp(0, docLength);
            _quillController.updateSelection(
              TextSelection.collapsed(offset: safeOffset),
              ChangeSource.local,
            );
            _editorFocusNode.requestFocus();
          }
        });
      },
    );
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_kbdHandler);
    _inicializar();
    // Aplicar tamaño cuando el campo de fuente pierde el foco
    _fontSizeFocusNode.addListener(() {
      if (!_fontSizeFocusNode.hasFocus) {
        _applyFontSizeFromController();
      }
    });
  }

  void _applyFontSizeFromController() {
    final val = double.tryParse(_fontSizeController.text.trim());
    if (val != null && val >= 8 && val <= 72) {
      setState(() => _fontSize = val);
      _schedulePrefsSave();
    } else {
      // Restaurar el valor válido actual si la entrada no es válida
      _fontSizeController.text = _fontSize.round().toString();
    }
  }

  // ── FIX: espera a que se cargue el manuscrito antes de cargar notas
  Future<void> _inicializar() async {
    await _cargarManuscrito();
    await Future.wait([_cargarNotas(), _cargarTarjetas(), _cargarCodex()]);
  }

  String _colorToHex(Color color) =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  int _countWords(String text) {
    var count = 0;
    var inWord = false;
    for (var i = 0; i < text.length; i++) {
      final c = text.codeUnitAt(i);
      final isWs = c <= 32;
      if (isWs) {
        inWord = false;
      } else if (!inWord) {
        count++;
        inWord = true;
      }
    }
    return count;
  }

  String _getChapterPlainText(String content) {
    if (content.trim().startsWith('[') && content.trim().endsWith(']')) {
      try {
        final List<dynamic> json = jsonDecode(content);
        final sb = StringBuffer();
        for (var op in json) {
          if (op is Map && op.containsKey('insert')) {
            final insertVal = op['insert'];
            if (insertVal is String) {
              sb.write(insertVal);
            }
          }
        }
        return sb.toString();
      } catch (e) {
        // Fallback
      }
    }
    return content;
  }

  void _updateStatsImmediate() {
    final text = _isQuillInitialized
        ? _quillController.document.toPlainText()
        : '';
    _wordCount = _countWords(text);
    _charCount = text.length;
    _updateSessionWords();
  }

  void _scheduleStatsUpdate() {
    _statsTimer?.cancel();
    _statsTimer = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      final text = _isQuillInitialized
          ? _quillController.document.toPlainText()
          : '';
      setState(() {
        _wordCount = _countWords(text);
        _charCount = text.length;
      });
      _updateSessionWords();
    });
  }

  void _updateSessionWords() {
    if (_capitulos.isEmpty) return;
    if (_isQuillInitialized) {
      _capitulos[_selectedCapituloIndex] = {
        ..._capitulos[_selectedCapituloIndex],
        'contenido': jsonEncode(_quillController.document.toDelta().toJson()),
      };
    }
    final currentTotal = _capitulos
        .map((c) => _countWords(_getChapterPlainText(c['contenido'] ?? '')))
        .fold(0, (a, b) => a + b);

    if (mounted) {
      setState(() {
        _sessionWordsWritten = max(0, currentTotal - _initialWordCountTotal);
      });
    } else {
      _sessionWordsWritten = max(0, currentTotal - _initialWordCountTotal);
    }
  }

  void _startPomodoro() {
    _pomodoroTimer?.cancel();
    setState(() {
      _isPomodoroRunning = true;
    });
    _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_pomodoroSecondsRemaining > 0) {
        setState(() {
          _pomodoroSecondsRemaining--;
        });
      } else {
        _completePomodoro();
      }
    });
  }

  void _pausePomodoro() {
    _pomodoroTimer?.cancel();
    setState(() {
      _isPomodoroRunning = false;
    });
  }

  void _resetPomodoro() {
    _pomodoroTimer?.cancel();
    setState(() {
      _isPomodoroRunning = false;
      _pomodoroSecondsRemaining = _pomodoroDurationMinutes * 60;
    });
  }

  void _setPomodoroDuration(int minutes) {
    _pomodoroTimer?.cancel();
    setState(() {
      _isPomodoroRunning = false;
      _pomodoroDurationMinutes = minutes;
      _pomodoroSecondsRemaining = minutes * 60;
    });
  }

  void _completePomodoro() {
    _pomodoroTimer?.cancel();
    setState(() {
      _isPomodoroRunning = false;
      _showPomodoroCompletionOverlay = true;
      _pomodoroSecondsRemaining = _pomodoroDurationMinutes * 60;
    });
  }

  Widget _buildAppBarPomodoroTimer() {
    if (!_isPomodoroRunning &&
        _pomodoroSecondsRemaining == _pomodoroDurationMinutes * 60) {
      return Container();
    }
    final minutes = _pomodoroSecondsRemaining ~/ 60;
    final seconds = _pomodoroSecondsRemaining % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Tooltip(
      message: _isPomodoroRunning
          ? 'Pomodoro activo. ¡Sigue escribiendo!'
          : 'Pomodoro pausado',
      child: Center(
        child: Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _isPomodoroRunning
                ? AppColors.accent.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isPomodoroRunning
                  ? const Color(0xFF00F0FF)
                  : Colors.white24,
              width: 1,
            ),
            boxShadow: _isPomodoroRunning
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.hourglass_bottom_rounded,
                size: 14,
                color: _isPomodoroRunning ? AppColors.accent : Colors.white30,
              ),
              const SizedBox(width: 6),
              Text(
                timeStr,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _isPomodoroRunning
                      ? const Color(0xFF00F0FF)
                      : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPomodoroSection(ThemeData theme) {
    final minutes = _pomodoroSecondsRemaining ~/ 60;
    final seconds = _pomodoroSecondsRemaining % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final double progress =
        _pomodoroSecondsRemaining / (_pomodoroDurationMinutes * 60);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          // Circular Pomodoro Indicator
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.03),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isPomodoroRunning
                          ? const Color(0xFF00F0FF)
                          : const Color(0xFFAEAEB2),
                    ),
                  ),
                ),
                // Glowing effect under circular indicator
                if (_isPomodoroRunning)
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF00F0FF,
                            ).withValues(alpha: 0.1),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeStr,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: _isPomodoroRunning
                            ? Colors.white
                            : Colors.white38,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isPomodoroRunning ? 'ENFOQUE' : 'PAUSA',
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: _isPomodoroRunning
                            ? AppColors.accent
                            : Colors.white24,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Play/Pause button
              Material(
                color: Colors.transparent,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: InkWell(
                    onTap: _isPomodoroRunning ? _pausePomodoro : _startPomodoro,
                    borderRadius: BorderRadius.circular(50),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isPomodoroRunning
                            ? const Color(0xFF00F0FF).withValues(alpha: 0.1)
                            : Colors.white.withValues(alpha: 0.05),
                        border: Border.all(
                          color: _isPomodoroRunning
                              ? AppColors.accent
                              : Colors.white24,
                        ),
                      ),
                      child: Icon(
                        _isPomodoroRunning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: _isPomodoroRunning
                            ? AppColors.accent
                            : Colors.white70,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Reset button
              Material(
                color: Colors.transparent,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: InkWell(
                    onTap: _resetPomodoro,
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.02),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: const Icon(
                        Icons.replay_rounded,
                        color: Colors.white38,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Presets
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [15, 25, 45, 60].map((mins) {
              final isCurrent = _pomodoroDurationMinutes == mins;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: InkWell(
                      onTap: () => _setPomodoroDuration(mins),
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFF00F0FF).withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isCurrent
                                ? const Color(0xFF00F0FF)
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${mins}m',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: isCurrent
                                ? AppColors.accent
                                : Colors.white38,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionGoalSection(ThemeData theme) {
    double progress = _sessionWordGoal > 0
        ? _sessionWordsWritten / _sessionWordGoal
        : 0.0;
    progress = progress.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'META DE SESIÓN',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textTertiary,
                  letterSpacing: 1.5,
                ),
              ),
              Material(
                color: Colors.transparent,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: InkWell(
                    onTap: _showSetSessionGoalDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.edit_note_rounded,
                        size: 18,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_sessionWordsWritten / $_sessionWordGoal palabras',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00F0FF), Color(0xFFAEAEB2)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSetSessionGoalDialog() {
    final controller = TextEditingController(text: _sessionWordGoal.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppColors.separator),
        ),
        title: Text(
          'Meta de la Sesión',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Cuántas palabras deseas escribir en esta sesión?',
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.separator),
              ),
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Meta de palabras',
                  labelStyle: GoogleFonts.outfit(
                    color: AppColors.textTertiary,
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textTertiary,
              side: BorderSide(
                color: AppColors.textTertiary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'CANCELAR',
              style: GoogleFonts.outfit(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                setState(() {
                  _sessionWordGoal = val;
                });
                Navigator.pop(ctx);
              }
            },
            child: Text(
              'GUARDAR',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNestedHeader() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.separator)),
      ),
      padding: const EdgeInsets.only(left: 8, right: 16),
      height: 48,
      child: Row(
        children: [
          _ToolbarButton(
            icon: _isCapitulosOpen
                ? Icons.menu_open_rounded
                : Icons.menu_rounded,
            onPressed: () =>
                setState(() => _isCapitulosOpen = !_isCapitulosOpen),
            tooltip: _isCapitulosOpen
                ? 'Ocultar capítulos'
                : 'Mostrar capítulos',
          ),
          const SizedBox(width: 8),
          _ToolbarButton(
            icon: Icons.search_rounded,
            onPressed: () =>
                setState(() => _showFindReplace = !_showFindReplace),
            tooltip: 'Buscar y reemplazar (Ctrl+F)',
          ),
          _ToolbarButton(
            icon: Icons.manage_search_rounded,
            onPressed: _abrirBusquedaGlobal,
            tooltip: 'Búsqueda global en toda la novela (Ctrl+Shift+F)',
          ),
          _ToolbarButton(
            icon: Icons.fullscreen_exit_rounded,
            onPressed: () =>
                setState(() => _distractionFreeMode = !_distractionFreeMode),
            tooltip: 'Modo sin distracciones',
          ),
          _ToolbarButton(
            icon: Icons.keyboard_outlined,
            color: _typewriterMode ? AppColors.accent : null,
            onPressed: _toggleTypewriterMode,
            tooltip: _typewriterMode
                ? 'Modo Máquina de Escribir (Activo)'
                : 'Modo Máquina de Escribir (Inactivo)',
          ),
          _ToolbarButton(
            icon: Icons.horizontal_rule_rounded,
            color: _autoEmDash ? AppColors.accent : null,
            onPressed: () => setState(() => _autoEmDash = !_autoEmDash),
            tooltip: _autoEmDash
                ? 'Raya de diálogo automática — (Activo)'
                : 'Raya de diálogo automática (Inactivo)',
          ),
          _ToolbarButton(
            icon: Icons.vertical_split_rounded,
            color: _splitView ? AppColors.accent : null,
            onPressed: _toggleSplitView,
            tooltip: _splitView
                ? 'Cerrar Vista Dividida'
                : 'Abrir Vista Dividida (Split View)',
          ),
          const SizedBox(width: 4),
          _buildAppBarPomodoroTimer(),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NestedModeChip(
                  label: 'Escritura',
                  isActive: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
                const SizedBox(width: 2),
                _NestedModeChip(
                  label: 'Organización',
                  isActive: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _ToolbarButton(
            icon: _isPanelOpen ? Icons.visibility_off : Icons.visibility,
            onPressed: () => setState(() => _isPanelOpen = !_isPanelOpen),
            tooltip: 'Ver panel lateral',
          ),
        ],
      ),
    );
  }

  void _markUnsaved() {
    if (_saveStatus != SaveStatus.unsaved) {
      setState(() => _saveStatus = SaveStatus.unsaved);
    }
  }

  void _schedulePrefsSave() {
    _markUnsaved();
    _prefsSaveTimer?.cancel();
    _prefsSaveTimer = Timer(
      const Duration(milliseconds: 400),
      _guardarContenido,
    );
  }

  QuillController _initQuillController(String content) {
    QuillController controller;
    if (content.trim().startsWith('[') && content.trim().endsWith(']')) {
      try {
        final json = jsonDecode(content);
        controller = QuillController(
          document: Document.fromJson(json),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        final doc = Document();
        if (content.isNotEmpty) doc.insert(0, content);
        controller = QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } else {
      final doc = Document();
      if (content.isNotEmpty) doc.insert(0, content);
      controller = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    controller.changes.listen((change) {
      if (_autoEmDash) {
        _checkAndApplySmartEmDash(controller);
      }
    });

    controller.addListener(_handleTypewriterScroll);

    return controller;
  }

  void _handleTypewriterScroll() {
    if (!_typewriterMode) return;
    if (!_editorScrollController.hasClients) return;
    if (!_isQuillInitialized) return;

    final sel = _quillController.selection;
    if (!sel.isValid) return;

    final plainText = _quillController.document.toPlainText();
    final cursor = sel.baseOffset.clamp(0, plainText.length);

    // Number of lines before cursor
    final textBeforeCursor = plainText.substring(0, cursor);
    final lineIndex = '\n'.allMatches(textBeforeCursor).length;

    // Approximate vertical height per line
    final lineHeightPx = (_fontSize * _lineHeight) + 4.0;
    const headerOffset = 110.0;
    final cursorY = headerOffset + (lineIndex * lineHeightPx);

    final viewportHeight = _editorScrollController.position.viewportDimension;
    final maxScroll = _editorScrollController.position.maxScrollExtent;

    final targetScroll = (cursorY - (viewportHeight * 0.45)).clamp(0.0, maxScroll);

    if ((_editorScrollController.offset - targetScroll).abs() > 6.0) {
      _editorScrollController.animateTo(
        targetScroll,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _toggleTypewriterMode() {
    setState(() {
      _typewriterMode = !_typewriterMode;
    });
    if (_typewriterMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleTypewriterScroll();
      });
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.surface,
          content: Row(
            children: [
              Icon(Icons.keyboard_outlined, color: AppColors.accent, size: 18),
              const SizedBox(width: 10),
              Text(
                'Modo Máquina de Escribir activado (Línea centrada)',
                style: GoogleFonts.outfit(color: AppColors.accent, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _toggleSplitView() {
    setState(() {
      _splitView = !_splitView;
      if (_splitView) {
        _autoSelectSecondarySplitChapter();
      }
    });
  }

  void _autoSelectSecondarySplitChapter() {
    if (_capitulos.length <= 1) {
      _splitCapituloIndex = 0;
      return;
    }
    // Si estamos en el primer capítulo (ej. Prólogo o Cap 1), mostrar el siguiente (Cap 2)
    // Si estamos en un capítulo intermedio o final, mostrar el siguiente si existe, sino el anterior
    if (_selectedCapituloIndex + 1 < _capitulos.length) {
      _splitCapituloIndex = _selectedCapituloIndex + 1;
    } else if (_selectedCapituloIndex - 1 >= 0) {
      _splitCapituloIndex = _selectedCapituloIndex - 1;
    } else {
      _splitCapituloIndex = 0;
    }
  }

  bool _isApplyingSmartDash = false;

  void _checkAndApplySmartEmDash(QuillController ctrl) {
    if (_isApplyingSmartDash) return;
    final sel = ctrl.selection;
    if (!sel.isCollapsed || sel.baseOffset < 1) return;

    final plainText = ctrl.document.toPlainText();
    final cursor = sel.baseOffset;
    if (cursor > plainText.length) return;

    // 1. Transformación instantánea de '--' a '—' (sin necesidad de presionar espacio)
    if (cursor >= 2) {
      final last2 = plainText.substring(cursor - 2, cursor);
      if (last2 == '--') {
        _isApplyingSmartDash = true;
        try {
          ctrl.replaceText(cursor - 2, 2, '—', null);
          ctrl.updateSelection(
            TextSelection.collapsed(offset: cursor - 1),
            ChangeSource.local,
          );
        } finally {
          _isApplyingSmartDash = false;
        }
        return;
      }
    }

    // 2. Auto-capitalización de la primera letra tras la raya de diálogo ('—' o '— ')
    if (cursor >= 2) {
      final charTyped = plainText.substring(cursor - 1, cursor);
      final isLowerLetter = RegExp(r'^[a-záéíóúüñ]$').hasMatch(charTyped);

      if (isLowerLetter) {
        // Directamente después de la raya '—' (ej. '—hola' -> '—Hola')
        final prev1 = plainText.substring(cursor - 2, cursor - 1);
        if (prev1 == '—') {
          _isApplyingSmartDash = true;
          try {
            ctrl.replaceText(cursor - 1, 1, charTyped.toUpperCase(), null);
            ctrl.updateSelection(
              TextSelection.collapsed(offset: cursor),
              ChangeSource.local,
            );
          } finally {
            _isApplyingSmartDash = false;
          }
          return;
        }

        // Después de raya y espacio '— ' (ej. '— hola' -> '— Hola')
        if (cursor >= 3) {
          final prev2 = plainText.substring(cursor - 3, cursor - 1);
          if (prev2 == '— ') {
            _isApplyingSmartDash = true;
            try {
              ctrl.replaceText(cursor - 1, 1, charTyped.toUpperCase(), null);
              ctrl.updateSelection(
                TextSelection.collapsed(offset: cursor),
                ChangeSource.local,
              );
            } finally {
              _isApplyingSmartDash = false;
            }
            return;
          }
        }
      }
    }
  }

  Future<void> _cargarCodex() async {
    final projId = widget.proyecto['id'] as int;
    final charRepo = CharacterRepository();
    final placeRepo = PlaceRepository();
    final chars = await charRepo.getByProject(projId);
    final places = await placeRepo.getByProject(projId);
    if (!mounted) return;
    setState(() {
      _codexCharacters = chars;
      _codexPlaces = places;
    });
  }

  void _onTextChanged() {
    _markUnsaved();
    _scheduleStatsUpdate();
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), _guardarContenido);
  }

  Future<void> _cargarManuscrito() async {
    final manuscrito = await AppDatabase.getManuscritoByProyecto(
      widget.proyecto['id'],
    );
    if (manuscrito != null) {
      _manuscritoId = manuscrito['id'];
      _pageColor = manuscrito['color_fondo'] != null
          ? _hexToColor(manuscrito['color_fondo'] as String)
          : const Color(0xFFFFFFFF);
      _fontFamily = 'Merriweather';
      if (manuscrito['font_size'] != null) {
        _fontSize = (manuscrito['font_size'] as num).toDouble();
      } else {
        _fontSize = 18.0;
      }
      if (manuscrito['line_height'] != null) {
        _lineHeight = (manuscrito['line_height'] as num).toDouble();
      } else {
        _lineHeight = 1.8;
      }
      _fontSizeController.text = _fontSize.round().toString();

      // Cargar Capítulos
      final caps = await AppDatabase.getCapitulosByManuscrito(_manuscritoId!);
      if (caps.isEmpty) {
        // Migración: Crear un capítulo inicial con el contenido existente
        final firstCapId = await AppDatabase.insertCapitulo({
          'manuscrito_id': _manuscritoId,
          'titulo': '',
          'contenido': manuscrito['contenido'] ?? '',
          'orden': 0,
        });
        _capitulos = [
          {
            'id': firstCapId,
            'manuscrito_id': _manuscritoId,
            'titulo': '',
            'contenido': manuscrito['contenido'] ?? '',
            'orden': 0,
          },
        ];
      } else {
        _capitulos = List<Map<String, dynamic>>.from(caps);
      }

      // Limpiar títulos por defecto "Capítulo X" sólo si son puramente el marcador genérico sin subtítulo
      final defaultCapRegex = RegExp(r'^cap[ií]tulo\s+\d+$', caseSensitive: false);
      for (var cap in _capitulos) {
        final title = (cap['titulo'] as String?)?.trim() ?? '';
        if (defaultCapRegex.hasMatch(title)) {
          cap['titulo'] = '';
        }
      }

      _quillController = _initQuillController(
        _capitulos[_selectedCapituloIndex]['contenido'] ?? '',
      );
      _isQuillInitialized = true;
      _titleController.text =
          _capitulos[_selectedCapituloIndex]['titulo'] ?? '';

      _lastSavedText = jsonEncode(_quillController.document.toDelta().toJson());
      _lastSavedTitle = _titleController.text;
      _lastSavedPageColorHex =
          manuscrito['color_fondo'] ?? _colorToHex(_pageColor);
      _lastSavedFontFamily = manuscrito['fuente'] ?? _fontFamily;
      _lastSavedFontSize = _fontSize;
      _lastSavedLineHeight = _lineHeight;
    } else {
      final id = await AppDatabase.insertManuscrito({
        'proyecto_id': widget.proyecto['id'],
        'contenido': '',
        'color_fondo': '#FFFFFF',
        'fuente': _fontFamily,
        'font_size': _fontSize,
        'line_height': _lineHeight,
      });
      _manuscritoId = id;

      final firstCapId = await AppDatabase.insertCapitulo({
        'manuscrito_id': _manuscritoId,
        'titulo': '',
        'contenido': '',
        'orden': 0,
      });
      _capitulos = [
        {
          'id': firstCapId,
          'manuscrito_id': _manuscritoId,
          'titulo': '',
          'contenido': '',
          'orden': 0,
        },
      ];

      _quillController = _initQuillController('');
      _isQuillInitialized = true;

      _lastSavedText = jsonEncode(_quillController.document.toDelta().toJson());
      _lastSavedTitle = '';
      _lastSavedPageColorHex = _colorToHex(_pageColor);
      _lastSavedFontFamily = _fontFamily;
      _lastSavedFontSize = _fontSize;
      _lastSavedLineHeight = _lineHeight;
    }
    _estilos = (await AppDatabase.getEstilos(
      widget.proyecto['id'],
    )).map((r) => NovelStyle.fromMap(r)).toList();
    _initialWordCountTotal = _capitulos
        .map((c) => _countWords(_getChapterPlainText(c['contenido'] ?? '')))
        .fold(0, (a, b) => a + b);
    _updateStatsImmediate();
    _quillController.addListener(_onTextChanged);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _guardarContenido() async {
    if (_manuscritoId == null || !_isQuillInitialized) return;
    final text = jsonEncode(_quillController.document.toDelta().toJson());
    final pageColorHex = _colorToHex(_pageColor);

    final changes = <String, Object?>{};

    // Guardar el contenido y título del capítulo actual
    if (_capitulos.isNotEmpty) {
      final currentCap = _capitulos[_selectedCapituloIndex];
      final title = _titleController.text;
      if (text != _lastSavedText || title != _lastSavedTitle) {
        await AppDatabase.updateCapitulo(currentCap['id'], {
          'contenido': text,
          'titulo': title,
        });
        // Actualizar el estado local para reflejar el cambio en el sidebar
        if (mounted) {
          setState(() {
            _capitulos[_selectedCapituloIndex] = {
              ...currentCap,
              'contenido': text,
              'titulo': title,
            };
          });
        }
      }
    }

    if (pageColorHex != _lastSavedPageColorHex) {
      changes['color_fondo'] = pageColorHex;
    }
    if (_fontFamily != _lastSavedFontFamily) changes['fuente'] = _fontFamily;
    if (_fontSize != _lastSavedFontSize) changes['font_size'] = _fontSize;
    if (_lineHeight != _lastSavedLineHeight) {
      changes['line_height'] = _lineHeight;
    }

    if (changes.isEmpty) {
      if (mounted) {
        setState(() => _saveStatus = SaveStatus.saved);
      }
      return;
    }

    if (mounted) {
      setState(() => _saveStatus = SaveStatus.saving);
    }
    changes['actualizado_en'] = DateTime.now().toIso8601String();

    final db = await AppDatabase.database;
    await db.update(
      'manuscritos',
      changes,
      where: 'id = ?',
      whereArgs: [_manuscritoId],
    );

    _lastSavedText = text;
    _lastSavedTitle = _titleController.text;
    _lastSavedPageColorHex = pageColorHex;
    _lastSavedFontFamily = _fontFamily;
    _lastSavedFontSize = _fontSize;
    _lastSavedLineHeight = _lineHeight;

    await AppDatabase.updateProyecto(widget.proyecto);
    if (mounted) {
      setState(() => _saveStatus = SaveStatus.saved);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: AppColors.accent,
              ),
              const SizedBox(width: 10),
              Text(
                'Guardado',
                style: GoogleFonts.outfit(color: AppColors.textPrimary),
              ),
            ],
          ),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.separator),
          ),
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.only(bottom: 20, right: 20),
        ),
      );
    }
  }

  Future<void> _cargarNotas() async {
    if (_manuscritoId == null) return;
    final notas = await AppDatabase.getNotasByManuscrito(_manuscritoId!);
    if (mounted) {
      setState(() => _notas = List<Map<String, dynamic>>.from(notas));
    }
  }

  Future<void> _agregarNota() async {
    if (_manuscritoId == null) return;
    final colores = ['#FFF9C4', '#FFECB3', '#E8F5E9', '#E3F2FD', '#F3E5F5'];
    final color = colores[DateTime.now().millisecond % colores.length];

    // Calcular una posición en cascada que no se salga de la pantalla
    double startX = 50.0 + (_notas.length * 30);
    double startY = 50.0 + (_notas.length * 30);
    startX = startX.clamp(20.0, 400.0);
    startY = startY.clamp(20.0, 300.0);

    final nueva = {
      'manuscrito_id': _manuscritoId!,
      'contenido': '',
      'posicion_cursor': _isQuillInitialized
          ? _quillController.selection.baseOffset
          : 0,
      'color': color,
      'pos_x': startX,
      'pos_y': startY,
      'ancho': 200.0,
      'alto': 150.0,
    };
    final id = await AppDatabase.insertNota(nueva);
    setState(
      () => _notas = [
        ..._notas,
        {...nueva, 'id': id},
      ],
    );
  }

  Future<void> _cargarTarjetas() async {
    final tarjetas = await AppDatabase.getTarjetasByProyecto(
      widget.proyecto['id'],
    );
    if (mounted) {
      setState(() => _tarjetas = List<Map<String, dynamic>>.from(tarjetas));
    }
  }

  Future<void> _agregarTarjeta() async {
    final colores = ['#FFCDD2', '#F8BBD9', '#E1BEE7', '#C5CAE9', '#BBDEFB'];
    final color = colores[DateTime.now().millisecond % colores.length];

    // Posición en cascada acotada
    double startX = 50.0 + (_tarjetas.length * 40);
    double startY = 50.0 + (_tarjetas.length * 40);
    startX = startX.clamp(20.0, 500.0);
    startY = startY.clamp(20.0, 400.0);

    final nueva = {
      'proyecto_id': widget.proyecto['id'],
      'titulo': '',
      'contenido': '',
      'tipo': 'idea',
      'color': color,
      'pos_x': startX,
      'pos_y': startY,
      'ancho': 250.0,
      'alto': 210.0,
    };
    final id = await AppDatabase.insertTarjeta(nueva);
    setState(
      () => _tarjetas = [
        ..._tarjetas,
        {...nueva, 'id': id},
      ],
    );
  }

  Future<void> _moverTarjeta(int id, double x, double y) =>
      AppDatabase.updateTarjetaPosicion(id, x, y);

  Future<void> _eliminarTarjeta(int id) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Eliminar Tarjeta',
      message:
          '¿Estás seguro de eliminar esta tarjeta? La información se perderá permanentemente.',
      confirmLabel: 'ELIMINAR',
    );
    if (!confirm) return;
    await AppDatabase.deleteTarjeta(id);
    setState(() => _tarjetas = _tarjetas.where((t) => t['id'] != id).toList());
  }

  @override
  Widget build(BuildContext context) {
    if (!_isQuillInitialized) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F0FF)),
          ),
        ),
      );
    }
    final theme = Theme.of(context);

    final body = Row(
      children: [
        if (_isCapitulosOpen && !_distractionFreeMode)
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                right: BorderSide(
                  color: AppColors.separator,
                  width: 1,
                ),
              ),
            ),
            child: _buildCapitulosSidebar(theme),
          ),
        Expanded(
          child: _selectedIndex == 0
              ? _buildEditorConNotas()
              : _buildPanelOrganizacion(),
        ),
        if (_isPanelOpen && !_distractionFreeMode)
          Container(
            width: 270,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                left: BorderSide(
                  color: AppColors.separator,
                  width: 1,
                ),
              ),
            ),
            child: _buildPanelLateral(theme),
          ),
      ],
    );

    if (_distractionFreeMode) {
      return Stack(
        children: [
          Column(
            children: [
              _buildDistractionFreeHeader(),
              Expanded(child: body),
              if (_showFindReplace) _buildFindReplaceBar(),
            ],
          ),
          if (_showPomodoroCompletionOverlay)
            PomodoroCompletionOverlay(
              durationMinutes: _pomodoroDurationMinutes,
              onClose: () =>
                  setState(() => _showPomodoroCompletionOverlay = false),
            ),
        ],
      );
    }

    final Widget mainWidget = widget.isNested
        ? Column(
            children: [
              _buildNestedHeader(),
              Expanded(child: body),
              if (_showFindReplace) _buildFindReplaceBar(),
            ],
          )
        : Scaffold(
            appBar: AppBar(
              titleSpacing: 0,
              title: Row(
                children: [
                  Container(
                    width: 6,
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.proyecto['titulo'] ?? 'Mi Novela',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              actions: [
                _buildAppBarPomodoroTimer(),
                _ToolbarButton(
                  icon: Icons.search_rounded,
                  onPressed: () =>
                      setState(() => _showFindReplace = !_showFindReplace),
                  tooltip: 'Buscar y reemplazar (Ctrl+F)',
                ),
                _ToolbarButton(
                  icon: Icons.manage_search_rounded,
                  onPressed: _abrirBusquedaGlobal,
                  tooltip: 'Búsqueda global en toda la novela (Ctrl+Shift+F)',
                ),
                _ToolbarButton(
                  icon: Icons.fullscreen_exit_rounded,
                  onPressed: () => setState(
                    () => _distractionFreeMode = !_distractionFreeMode,
                  ),
                  tooltip: 'Modo sin distracciones',
                ),
                _ToolbarButton(
                  icon: Icons.keyboard_outlined,
                  color: _typewriterMode ? AppColors.accent : null,
                  onPressed: _toggleTypewriterMode,
                  tooltip: _typewriterMode
                      ? 'Modo Máquina de Escribir (Activo)'
                      : 'Modo Máquina de Escribir (Inactivo)',
                ),
                _ToolbarButton(
                  icon: Icons.vertical_split_rounded,
                  color: _splitView ? AppColors.accent : null,
                  onPressed: _toggleSplitView,
                  tooltip: _splitView
                      ? 'Cerrar Vista Dividida'
                      : 'Abrir Vista Dividida (Split View)',
                ),
                _ToolbarDivider(),
                _ToolbarButton(
                  icon: _isCapitulosOpen ? Icons.menu_open : Icons.menu,
                  onPressed: () =>
                      setState(() => _isCapitulosOpen = !_isCapitulosOpen),
                  tooltip: _isCapitulosOpen
                      ? 'Ocultar capítulos'
                      : 'Mostrar capítulos',
                ),
                _ToolbarButton(
                  icon: _isPanelOpen
                      ? Icons.close_fullscreen
                      : Icons.open_in_full,
                  onPressed: () => setState(() => _isPanelOpen = !_isPanelOpen),
                  tooltip: _isPanelOpen ? 'Ocultar panel' : 'Mostrar panel',
                ),
                _ToolbarDivider(),
                _ToolbarButton(
                  icon: Icons.save_outlined,
                  onPressed: _guardarContenido,
                  tooltip: 'Guardar ahora',
                ),
                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(40),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.separator)),
                  ),
                  child: Row(
                    children: [
                      _ModeTab(
                        icon: Icons.edit_note,
                        label: 'Editor',
                        isActive: _selectedIndex == 0,
                        onTap: () => setState(() => _selectedIndex = 0),
                      ),
                      _ModeTab(
                        icon: Icons.grid_view,
                        label: 'Organización',
                        isActive: _selectedIndex == 1,
                        onTap: () => setState(() => _selectedIndex = 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            body: body,
          );

    if (_showPomodoroCompletionOverlay) {
      return Stack(
        children: [
          mainWidget,
          PomodoroCompletionOverlay(
            durationMinutes: _pomodoroDurationMinutes,
            onClose: () =>
                setState(() => _showPomodoroCompletionOverlay = false),
          ),
        ],
      );
    }
    return mainWidget;
  }

  Widget _buildEditorConNotas() {
    final isLight = _pageColor.computeLuminance() > 0.5;

    return Theme(
      data: Theme.of(context).copyWith(
        platform:
            TargetPlatform.macOS, // Enables smooth cursor blinking animation
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: isLight ? Colors.black87 : const Color(0xFF00F0FF),
          selectionColor: isLight
              ? Colors.blue.withValues(alpha: 0.2)
              : const Color(0xFF00F0FF).withValues(alpha: 0.25),
          selectionHandleColor: isLight
              ? Colors.black87
              : const Color(0xFF00F0FF),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    color: AppColors.bg,
                    padding: EdgeInsets.fromLTRB(_splitView ? 16 : 36, _splitView ? 16 : 36, _splitView ? 16 : 36, 0),
                    child: _splitView
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _buildActiveEditorCard(isLight),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildSecondarySplitPane(isLight),
                              ),
                            ],
                          )
                        : Center(
                            child: _buildActiveEditorCard(isLight),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveEditorCard(bool isLight) {
    return GestureDetector(
      onTap: () {
        if (!_editorFocusNode.hasFocus) {
          _editorFocusNode.requestFocus();
        }
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.text,
        child: Container(
          constraints: BoxConstraints(maxWidth: _splitView ? double.infinity : 780),
          decoration: BoxDecoration(
            color: _pageColor,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.04),
                blurRadius: 20,
                spreadRadius: -5,
              ),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(48, 44, 48, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (widget.proyecto['titulo'] ?? 'Tu novela')
                      .toString()
                      .toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isLight
                        ? Colors.black38
                        : Colors.white38,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  style: GoogleFonts.getFont(
                    _fontFamily,
                    fontSize: _fontSize + 4,
                    fontWeight: FontWeight.bold,
                    color: isLight
                        ? Colors.black87
                        : Colors.white,
                    height: 1.2,
                  ),
                  showCursor: true,
                  cursorWidth: 2.5,
                  cursorColor: isLight
                      ? Colors.black87
                      : const Color(0xFF00F0FF),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    filled: false,
                    fillColor: Colors.transparent,
                    hintText: 'Título del capítulo',
                    hintStyle: GoogleFonts.getFont(
                      _fontFamily,
                      fontSize: _fontSize + 4,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      color: isLight
                          ? Colors.black12
                          : AppColors.textTertiary,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) =>
                      _onTextChanged(), // Trigger auto-save
                ),
                Divider(
                  color: isLight
                      ? Colors.black12
                      : Colors.white10,
                  thickness: 1,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: QuillEditor.basic(
                    controller: _quillController,
                    focusNode: _editorFocusNode,
                    scrollController: _editorScrollController,
                    config: QuillEditorConfig(
                      showCursor: true,
                      placeholder:
                          'Comienza a escribir tu historia...',
                      expands: true,
                      padding: EdgeInsets.fromLTRB(
                        0,
                        0,
                        0,
                        _typewriterMode ? 600 : 40,
                      ),
                      scrollBottomInset: _typewriterMode ? 600 : 0,
                      customStyles: DefaultStyles(
                        paragraph: DefaultTextBlockStyle(
                          GoogleFonts.getFont(
                            _fontFamily,
                            fontSize: _fontSize,
                            height: _lineHeight,
                            color: isLight
                                ? const Color(0xFF2C2A25)
                                : Colors.white70,
                          ),
                          const HorizontalSpacing(0, 0),
                          const VerticalSpacing(0, 0),
                          const VerticalSpacing(0, 0),
                          null,
                        ),
                        placeHolder: DefaultTextBlockStyle(
                          GoogleFonts.getFont(
                            _fontFamily,
                            fontSize: _fontSize,
                            height: _lineHeight,
                            color: isLight
                                ? Colors.black12
                                : AppColors.textTertiary,
                          ),
                          const HorizontalSpacing(0, 0),
                          const VerticalSpacing(0, 0),
                          const VerticalSpacing(0, 0),
                          null,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondarySplitPane(bool isLight) {
    if (_capitulos.isEmpty) return const SizedBox.shrink();
    final safeIndex = _splitCapituloIndex.clamp(0, _capitulos.length - 1);
    final splitCap = _capitulos[safeIndex];
    final splitTipo = splitCap['tipo']?.toString() ?? 'capitulo';
    final splitTitle = splitCap['titulo']?.toString().trim().isNotEmpty == true
        ? splitCap['titulo'].toString().trim()
        : (splitTipo == 'prologo' ? 'Prólogo' : 'Capítulo ${safeIndex + 1}');

    // Parse plain text from quill JSON or raw string
    final rawContent = splitCap['contenido']?.toString() ?? '';
    String plain = rawContent;
    if (rawContent.trim().startsWith('[') && rawContent.trim().endsWith(']')) {
      try {
        final List<dynamic> json = jsonDecode(rawContent);
        final sb = StringBuffer();
        for (var op in json) {
          if (op is Map && op.containsKey('insert')) {
            final ins = op['insert'];
            if (ins is String) sb.write(ins);
          }
        }
        plain = sb.toString();
      } catch (_) {}
    }

    final splitWords = _countWords(plain);

    return Container(
      decoration: BoxDecoration(
        color: _pageColor,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Split Pane Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_stories_outlined, size: 14, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      'VISTA PARALELA',
                      style: GoogleFonts.outfit(
                        color: AppColors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Botón rápido capítulo anterior
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 18),
                color: safeIndex > 0 ? AppColors.textSecondary : Colors.white24,
                onPressed: safeIndex > 0
                    ? () => setState(() => _splitCapituloIndex = safeIndex - 1)
                    : null,
                tooltip: 'Capítulo anterior',
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: EdgeInsets.zero,
              ),
              // Botón rápido capítulo siguiente
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                color: safeIndex < _capitulos.length - 1 ? AppColors.textSecondary : Colors.white24,
                onPressed: safeIndex < _capitulos.length - 1
                    ? () => setState(() => _splitCapituloIndex = safeIndex + 1)
                    : null,
                tooltip: 'Capítulo siguiente',
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: EdgeInsets.zero,
              ),
              const Spacer(),
              // Selector desplegable de capítulo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: safeIndex,
                    dropdownColor: AppColors.surface,
                    style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 12),
                    icon: Icon(Icons.arrow_drop_down, color: AppColors.accent, size: 18),
                    isDense: true,
                    items: List.generate(_capitulos.length, (i) {
                      final c = _capitulos[i];
                      final tType = c['tipo']?.toString() ?? 'capitulo';
                      final defaultName = tType == 'prologo' ? 'Prólogo' : 'Capítulo ${i + 1}';
                      final t = c['titulo']?.toString().trim().isNotEmpty == true
                          ? '${c['titulo']}'
                          : defaultName;
                      final isCurrentEditing = i == _selectedCapituloIndex;

                      return DropdownMenuItem<int>(
                        value: i,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              t,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: isCurrentEditing ? AppColors.accent : AppColors.textPrimary,
                                fontWeight: isCurrentEditing ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            if (isCurrentEditing) ...[
                              const SizedBox(width: 6),
                              Text(
                                '(En edición)',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: AppColors.accent.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                    onChanged: (newIdx) {
                      if (newIdx != null) {
                        setState(() => _splitCapituloIndex = newIdx);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.close_rounded, size: 18, color: AppColors.textTertiary),
                onPressed: () => setState(() => _splitView = false),
                tooltip: 'Cerrar Vista Dividida',
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: isLight ? Colors.black12 : Colors.white10),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  splitTitle,
                  style: GoogleFonts.getFont(
                    _fontFamily,
                    fontSize: _fontSize + 2,
                    fontWeight: FontWeight.bold,
                    color: isLight ? Colors.black87 : Colors.white,
                  ),
                ),
              ),
              Text(
                '$splitWords palabras',
                style: GoogleFonts.outfit(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              child: SelectableText(
                plain.trim().isEmpty ? 'Este capítulo aún no tiene contenido escrito.' : plain,
                style: GoogleFonts.getFont(
                  _fontFamily,
                  fontSize: _fontSize,
                  height: _lineHeight,
                  color: isLight ? const Color(0xFF2C2A25) : Colors.white70,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelOrganizacion() {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: AppColors.surface,
            child: GridPaper(
              color: const Color(0xFF1E2033),
              interval: 60,
              divisions: 1,
              subdivisions: 1,
              child: _tarjetas.isEmpty
                  ? Center(
                      child: Text(
                        'Agrega tarjetas desde el panel derecho\npara organizar ideas, personajes y escenas.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    )
                  : Container(),
            ),
          ),
        ),
        ..._tarjetas.map(
          (t) => Positioned(
            key: ValueKey('pos_tarjeta_${t['id']}'),
            left: 0,
            top: 0,
            child: DraggableCard(
              key: ValueKey('tarjeta_${t['id']}'),
              tarjeta: t,
              onMoved: _moverTarjeta,
              onDelete: () => _eliminarTarjeta(t['id']),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPanelLateral(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selector de Pestañas
        Container(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.separator)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildSidebarTab(
                  index: 0,
                  icon: Icons.timer_outlined,
                  label: 'Enfoque',
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: _buildSidebarTab(
                  index: 1,
                  icon: Icons.people_outline_rounded,
                  label: 'Codex',
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: _buildSidebarTab(
                  index: 2,
                  icon: Icons.analytics_outlined,
                  label: 'Métricas',
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: _buildSidebarTab(
                  index: 3,
                  icon: Icons.hub_outlined,
                  label: 'Coherencia',
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _rightSidebarTabIndex == 1
              ? EditorCodexSidebar(
                  characters: _codexCharacters,
                  places: _codexPlaces,
                )
              : _rightSidebarTabIndex == 2
                  ? _buildMetricasTab(theme)
                  : _rightSidebarTabIndex == 3
                      ? EditorCoherenceSidebar(
                          proyectoId: widget.proyecto['id'] as int,
                          capitulo: _capitulos.isNotEmpty && _selectedCapituloIndex < _capitulos.length
                              ? _capitulos[_selectedCapituloIndex]
                              : null,
                        )
                      : _buildEnfoqueTab(theme),
        ),
      ],
    );
  }

  Widget _buildSidebarTab({required int index, required IconData icon, required String label}) {
    final isSelected = _rightSidebarTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _rightSidebarTabIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.accent.withValues(alpha: 0.4) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? AppColors.accent : AppColors.textTertiary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected ? AppColors.accent : AppColors.textTertiary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricasTab(ThemeData theme) {
    final readingTime = NarrativeTextUtils.estimateReadingTime(_wordCount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ANÁLISIS DE LECTURA',
            style: GoogleFonts.outfit(
              color: AppColors.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                _StatItem(
                  icon: Icons.timer_rounded,
                  label: 'Tiempo de Lectura',
                  value: readingTime,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: Colors.white10),
                ),
                _StatItem(
                  icon: Icons.text_fields_rounded,
                  label: 'Palabras en Capítulo',
                  value: '$_wordCount',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: Colors.white10),
                ),
                _StatItem(
                  icon: Icons.format_size_rounded,
                  label: 'Caracteres',
                  value: '$_charCount',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Botones de acción avanzada
          Text(
            'HERRAMIENTAS DE ESTILO',
            style: GoogleFonts.outfit(
              color: AppColors.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              WordFrequencyDialog.show(
                context,
                _quillController.document.toPlainText(),
                _wordCount,
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.analytics_rounded, color: AppColors.accent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Analizar Repeticiones',
                          style: GoogleFonts.outfit(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Detecta palabras sobreutilizadas',
                          style: GoogleFonts.outfit(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _abrirBusquedaGlobal,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.manage_search_rounded, color: AppColors.accent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Búsqueda Global',
                          style: GoogleFonts.outfit(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'En toda la novela (Ctrl+Shift+F)',
                          style: GoogleFonts.outfit(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () async {
              if (_capitulos.isEmpty) return;
              final currentCap = _capitulos[_selectedCapituloIndex];
              final snapshots = await AppDatabase.getCapituloVersiones(currentCap['id']);
              if (!mounted) return;
              if (snapshots.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.surface,
                    content: Text(
                      'No hay versiones históricas guardadas para este capítulo.',
                      style: GoogleFonts.outfit(color: AppColors.textPrimary),
                    ),
                  ),
                );
                return;
              }
              final latest = snapshots.first;
              VersionDiffDialog.show(
                context: context,
                currentText: _quillController.document.toPlainText(),
                snapshotContent: latest['contenido'] ?? '',
                snapshotMotivo: latest['motivo'] ?? 'Guardado automático',
                snapshotFecha: latest['creado_en'] ?? '',
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.separator),
              ),
              child: Row(
                children: [
                  Icon(Icons.compare_arrows_rounded, color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Comparar Revisiones (Diff)',
                          style: GoogleFonts.outfit(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Ver diferencias con última versión guardada',
                          style: GoogleFonts.outfit(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnfoqueTab(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'HERRAMIENTAS',
              style: GoogleFonts.outfit(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Tooltip(
                    message: 'Agregar nueva nota adhesiva',
                    child: _GlassButton(
                      icon: Icons.sticky_note_2_rounded,
                      label: 'NOTA',
                      onPressed: _agregarNota,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Tooltip(
                    message: 'Agregar nueva tarjeta de idea',
                    child: _GlassButton(
                      icon: Icons.post_add_rounded,
                      label: 'TARJETA',
                      onPressed: _agregarTarjeta,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildPageColorSection(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: AppColors.separator),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'ENFOQUE & POMODORO',
              style: GoogleFonts.outfit(
                color: AppColors.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          _buildPomodoroSection(theme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: AppColors.separator),
          ),
          const SizedBox(height: 12),
          _buildSessionGoalSection(theme),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: AppColors.separator),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'ESTADÍSTICAS',
              style: GoogleFonts.outfit(
                color: AppColors.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                children: [
                  _StatItem(
                    icon: Icons.text_fields_rounded,
                    label: 'Palabras',
                    value: '$_wordCount',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: Colors.white10),
                  ),
                  _StatItem(
                    icon: Icons.format_size_rounded,
                    label: 'Caracteres',
                    value: '$_charCount',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: Colors.white10),
                  ),
                  _StatItem(
                    icon: Icons.sticky_note_2_rounded,
                    label: 'Notas',
                    value: '${_notas.length}',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: Colors.white10),
                  ),
                  _StatItem(
                    icon: Icons.grid_view_rounded,
                    label: 'Tarjetas',
                    value: '${_tarjetas.length}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: AppColors.separator),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'ESTILOS',
              style: GoogleFonts.outfit(
                color: AppColors.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildEstilosSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  static const _pageColorPresets = [
    ColorPreset(Color(0xFFFFFFFF), 'Blanco'),
    ColorPreset(Color(0xFFFFF8E0), 'Crema'),
    ColorPreset(Color(0xFFF5E6C8), 'Sepia'),
    ColorPreset(Color(0xFFF0F0F0), 'Gris suave'),
    ColorPreset(Color(0xFFE8F0FE), 'Azul claro'),
    ColorPreset(Color(0xFFE8F5E9), 'Verde claro'),
    ColorPreset(Color(0xFF2C2C2C), 'Oscuro'),
    ColorPreset(Color(0xFF1A1A2E), 'Medianoche'),
    ColorPreset(Color(0xFFFDE8E8), 'Rosa suave'),
  ];

  Widget _buildPageColorSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COLOR DE HOJA',
            style: GoogleFonts.outfit(
              color: AppColors.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          AppColorPicker(
            selectedColor: _pageColor,
            presets: _pageColorPresets,
            label: 'COLOR DE HOJA',
            onChanged: (color) {
              if (color != null) {
                setState(() => _pageColor = color);
              }
            },
          ),
        ],
      ),
    );
  }

  // --- Estilos ---

  void _applyStyle(int styleId) {
    final style = _estilos.where((s) => s.id == styleId).firstOrNull;
    if (style == null) return;

    final config = mergeStyleConfig(style, _estilos);
    final wrapperOpen = config['wrapperOpen'] as String? ?? '';
    final wrapperClose = config['wrapperClose'] as String? ?? '';
    final attr = Attribute<String>(
      'styleId',
      AttributeScope.inline,
      styleId.toString(),
    );

    if (wrapperOpen.isEmpty && wrapperClose.isEmpty) {
      _quillController.formatSelection(attr);
      return;
    }

    if (!_editorFocusNode.hasFocus) {
      _editorFocusNode.requestFocus();
    }

    final sel = _quillController.selection;
    if (!sel.isValid) return;

    if (!sel.isCollapsed) {
      final start = sel.start;
      final end = sel.end;
      final selectedText = _quillController.document.toPlainText().substring(
        start,
        end,
      );
      _quillController.replaceText(
        start,
        end - start,
        '$wrapperOpen$selectedText$wrapperClose',
        null,
      );
      _quillController.updateSelection(
        TextSelection(
          baseOffset: start,
          extentOffset:
              start +
              wrapperOpen.length +
              selectedText.length +
              wrapperClose.length,
        ),
        ChangeSource.local,
      );
      _quillController.formatSelection(attr);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _quillController.updateSelection(
            TextSelection.collapsed(
              offset: start + wrapperOpen.length + selectedText.length,
            ),
            ChangeSource.local,
          );
        }
      });
    } else {
      final pos = sel.baseOffset;
      _quillController.replaceText(pos, 0, '$wrapperOpen$wrapperClose', null);
      _quillController.updateSelection(
        TextSelection(
          baseOffset: pos,
          extentOffset: pos + wrapperOpen.length + wrapperClose.length,
        ),
        ChangeSource.local,
      );
      _quillController.formatSelection(attr);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _quillController.updateSelection(
            TextSelection.collapsed(offset: pos + wrapperOpen.length),
            ChangeSource.local,
          );
        }
      });
    }
  }

  Widget _buildEstilosSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_estilos.length} estilos',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white38,
                  letterSpacing: 1.5,
                ),
              ),
              Material(
                color: Colors.transparent,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: InkWell(
                    onTap: _showNuevoEstiloDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.add, size: 18, color: AppColors.accent),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_estilos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Crea un nuevo estilo para empezar',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            )
          else
            ..._estilos.map((estilo) => _buildEstiloRow(estilo)),
        ],
      ),
    );
  }

  Widget _buildEstiloRow(NovelStyle estilo) {
    final config = mergeStyleConfig(estilo, _estilos);
    final previewText = estilo.nombre;
    final isGlobal = estilo.esGlobal;
    final isFork =
        !isGlobal &&
        _estilos.any((s) => s.esGlobal && s.nombre == estilo.nombre);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: MouseRegion(
              cursor: isGlobal
                  ? SystemMouseCursors.basic
                  : SystemMouseCursors.click,
              child: GestureDetector(
                onTap: isGlobal ? null : () => _showEditEstiloDialog(estilo),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          previewText,
                          style: GoogleFonts.getFont(
                            config['fontFamily'] as String? ?? _fontFamily,
                            fontSize:
                                (config['fontSize'] as num?)?.toDouble().clamp(
                                  10,
                                  16,
                                ) ??
                                13,
                            fontWeight: config['fontWeight'] == 'bold'
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontStyle: config['fontStyle'] == 'italic'
                                ? FontStyle.italic
                                : FontStyle.normal,
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isGlobal) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              'Global',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 7,
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (estilo.atajo != null)
                      Text(
                        estilo.atajo!,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          color: Colors.white24,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (isGlobal)
            Material(
              color: Colors.transparent,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: InkWell(
                  onTap: () => _forkEstiloGlobal(estilo),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.call_split,
                      size: 14,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
            ),
          if (isFork)
            Material(
              color: Colors.transparent,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: InkWell(
                  onTap: () => _revertEstiloToGlobal(estilo),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.restore, size: 14, color: Colors.white38),
                  ),
                ),
              ),
            ),
          if (!isGlobal) ...[
            Material(
              color: Colors.transparent,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: InkWell(
                  onTap: () => _showEditEstiloDialog(estilo),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.edit, size: 14, color: Colors.white24),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Material(
              color: Colors.transparent,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: InkWell(
                  onTap: () => _confirmDeleteEstilo(estilo),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline,
                      size: 14,
                      color: Colors.white24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _recargarEstilos() async {
    final rows = await AppDatabase.getEstilos(widget.proyecto['id']);
    if (!mounted) return;
    setState(() {
      _estilos = rows.map((r) => NovelStyle.fromMap(r)).toList();
    });
  }

  Future<void> _forkEstiloGlobal(NovelStyle estilo) async {
    final newId = await AppDatabase.forkEstiloGlobal(
      estilo.id!,
      widget.proyecto['id'],
    );
    if (newId <= 0) return;
    await _recargarEstilos();
    final forked = _estilos.where((s) => s.id == newId).firstOrNull;
    if (forked != null) _showEditEstiloDialog(forked);
  }

  Future<void> _revertEstiloToGlobal(NovelStyle estilo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'RESTAURAR ESTILO',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        content: Text(
          '¿Restaurar "${estilo.nombre}" a su versión global? Se perderán los cambios personalizados.',
          style: GoogleFonts.outfit(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.5,
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
            child: Text(
              'Cancelar',
              style: GoogleFonts.outfit(color: AppColors.textTertiary),
            ),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.red,
              side: BorderSide(color: AppColors.red),
            ),
            child: Text(
              'Restaurar',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && estilo.id != null) {
      await AppDatabase.revertEstiloToGlobal(estilo.id!);
      await _recargarEstilos();
    }
  }

  Future<void> _showNuevoEstiloDialog() async {
    final nombreCtrl = TextEditingController();
    final atajoCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'NUEVO ESTILO',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              autofocus: true,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Nombre del estilo',
                hintStyle: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.02),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.accent),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),
            AtajoRecorder(controller: atajoCtrl, hint: 'Atajo (ej. Ctrl+6)'),
          ],
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
            child: Text(
              'Cancelar',
              style: GoogleFonts.outfit(color: Colors.white54),
            ),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Crear',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (result == true && nombreCtrl.text.trim().isNotEmpty) {
      await AppDatabase.insertEstilo({
        'proyecto_id': widget.proyecto['id'],
        'nombre': nombreCtrl.text.trim(),
        'orden': _estilos.length,
        'atajo': atajoCtrl.text.trim().isNotEmpty
            ? atajoCtrl.text.trim()
            : null,
      });
      await _recargarEstilos();
    }
  }

  Future<void> _showEditEstiloDialog(NovelStyle estilo) async {
    final nombreCtrl = TextEditingController(text: estilo.nombre);
    final atajoCtrl = TextEditingController(text: estilo.atajo ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'EDITAR ESTILO',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              autofocus: true,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Nombre del estilo',
                hintStyle: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.02),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.accent),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),
            AtajoRecorder(controller: atajoCtrl, hint: 'Atajo (ej. Ctrl+6)'),
          ],
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
            child: Text(
              'Cancelar',
              style: GoogleFonts.outfit(color: Colors.white54),
            ),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Guardar',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (result == true &&
        nombreCtrl.text.trim().isNotEmpty &&
        estilo.id != null) {
      await AppDatabase.updateEstilo(estilo.id!, {
        'nombre': nombreCtrl.text.trim(),
        'atajo': atajoCtrl.text.trim().isNotEmpty
            ? atajoCtrl.text.trim()
            : null,
      });
      await _recargarEstilos();
    }
  }

  Future<void> _confirmDeleteEstilo(NovelStyle estilo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'ELIMINAR ESTILO',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        content: Text(
          '¿Eliminar "${estilo.nombre}"? Los textos que usen este estilo mantendrán el formato actual.',
          style: GoogleFonts.outfit(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.5,
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
            child: Text(
              'Cancelar',
              style: GoogleFonts.outfit(color: AppColors.textTertiary),
            ),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.red,
              side: BorderSide(color: AppColors.red),
            ),
            child: Text(
              'Eliminar',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && estilo.id != null) {
      await AppDatabase.deleteEstilo(estilo.id!);
      await _recargarEstilos();
    }
  }

  // --- Capítulos UI ---
  Widget _buildCapitulosSidebar(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ÍNDICE',
                style: GoogleFonts.outfit(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.add, color: AppColors.accent, size: 20),
                tooltip: 'Nuevo...',
                onSelected: (tipo) => _agregarCapitulo(tipo: tipo),
                color: AppColors.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.separator),
                ),
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'prologo',
                    child: Text(
                      'Prólogo',
                      style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'capitulo',
                    child: Text(
                      'Capítulo estándar',
                      style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'epilogo',
                    child: Text(
                      'Epílogo',
                      style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.auto_delete_outlined,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
                tooltip: 'Papelera del manuscrito',
                onPressed: _abrirPapelera,
              ),
            ],
          ),
        ),
        Divider(color: AppColors.separator),
        const SizedBox(height: 8),
        Expanded(
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            itemCount: _capitulos.length,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final item = _capitulos.removeAt(oldIndex);
                _capitulos.insert(newIndex, item);

                // Si el capítulo seleccionado se movió, actualizar el índice
                if (_selectedCapituloIndex == oldIndex) {
                  _selectedCapituloIndex = newIndex;
                } else if (_selectedCapituloIndex > oldIndex &&
                    _selectedCapituloIndex <= newIndex) {
                  _selectedCapituloIndex--;
                } else if (_selectedCapituloIndex < oldIndex &&
                    _selectedCapituloIndex >= newIndex) {
                  _selectedCapituloIndex++;
                }
              });
              _guardarOrdenCapitulos();
            },
            itemBuilder: (context, index) {
              final cap = _capitulos[index];
              final isSelected = index == _selectedCapituloIndex;
              final customTitle = cap['titulo']?.toString().trim() ?? '';

              // Calcular numeración solo para capítulos estándar
              String label = 'Capítulo';
              final tipo = cap['tipo'] ?? 'capitulo';
              if (tipo == 'prologo') {
                label = 'Prólogo';
              } else if (tipo == 'epilogo') {
                label = 'Epílogo';
              } else {
                int chapterNum = 0;
                for (int i = 0; i <= index; i++) {
                  if ((_capitulos[i]['tipo'] ?? 'capitulo') == 'capitulo') {
                    chapterNum++;
                  }
                }
                label = 'Capítulo $chapterNum';
              }

              return ReorderableDragStartListener(
                key: ValueKey(cap['id']),
                index: index,
                child: _CapituloSidebarItem(
                  label: label,
                  title: customTitle,
                  words: (cap['palabras'] as num?)?.toInt() ?? 0,
                  estado: cap['estado']?.toString() ?? 'borrador',
                  povName: _getPovName(cap['pov_personaje_id']),
                  metaPalabras: (cap['meta_palabras'] as num?)?.toInt() ?? 0,
                  isSelected: isSelected,
                  onTap: () {
                    if (_selectedCapituloIndex != index) {
                      _cambiarCapitulo(index);
                    }
                  },
                  onEditMetadata: () => _openChapterMetadata(index),
                  onDelete: _capitulos.length > 1
                      ? () => _eliminarCapitulo(index)
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _cambiarCapitulo(int newIndex) async {
    await _guardarContenido(); // Save current chapter before switching
    setState(() {
      _selectedCapituloIndex = newIndex;
      final currentCap = _capitulos[_selectedCapituloIndex];
      _quillController.removeListener(_onTextChanged);
      _quillController.dispose();
      _quillController = _initQuillController(currentCap['contenido'] ?? '');
      _quillController.addListener(_onTextChanged);
      _titleController.text = currentCap['titulo'] ?? '';
      _lastSavedText = jsonEncode(_quillController.document.toDelta().toJson());
      _lastSavedTitle = _titleController.text;

      // Si la vista dividida está activa y apunta al mismo capítulo que ahora se está editando,
      // ajustar automáticamente la vista secundaria al capítulo contiguo
      if (_splitView && _splitCapituloIndex == _selectedCapituloIndex) {
        _autoSelectSecondarySplitChapter();
      }
    });
    _updateStatsImmediate();
  }

  Future<void> _agregarCapitulo({String tipo = 'capitulo'}) async {
    if (_manuscritoId == null) return;
    await _guardarContenido();
    final newOrder = _capitulos.length;
    final id = await AppDatabase.insertCapitulo({
      'manuscrito_id': _manuscritoId,
      'titulo': '',
      'contenido': '',
      'orden': newOrder,
      'tipo': tipo,
    });

    final newCap = {
      'id': id,
      'manuscrito_id': _manuscritoId,
      'titulo': '',
      'contenido': '',
      'orden': newOrder,
      'tipo': tipo,
    };

    setState(() {
      _capitulos.add(newCap);
      _selectedCapituloIndex = _capitulos.length - 1;
      _quillController.removeListener(_onTextChanged);
      _quillController.dispose();
      _quillController = _initQuillController('');
      _quillController.addListener(_onTextChanged);
      _titleController.text = '';
      _lastSavedText = jsonEncode(_quillController.document.toDelta().toJson());
      _lastSavedTitle = '';
    });
    _updateStatsImmediate();
  }

  // Se elimina _renombrarCapitulo con popup, ahora se usa el TextField en el editor

  String? _getPovName(dynamic povId) {
    if (povId == null) return null;
    final int? id = povId is num ? povId.toInt() : int.tryParse(povId.toString());
    if (id == null) return null;
    final match = _codexCharacters.where((c) => c.id == id).firstOrNull;
    return match?.nombre;
  }

  Future<void> _openChapterMetadata(int index) async {
    final capMap = _capitulos[index];
    final chapter = Chapter.fromMap(capMap);
    await ChapterMetadataDialog.show(
      context: context,
      chapter: chapter,
      characters: _codexCharacters,
      onSave: (updated) async {
        final repo = ChapterRepository();
        await repo.updateChapter(updated);
        setState(() {
          _capitulos[index] = updated.toMap();
          if (index == _selectedCapituloIndex) {
            _titleController.text = updated.titulo;
          }
        });
      },
    );
  }

  Future<void> _abrirPapelera() async {
    if (_manuscritoId == null) return;
    await ChapterTrashDialog.show(
      context: context,
      manuscritoId: _manuscritoId!,
      onRestored: () async {
        final caps = await AppDatabase.getCapitulosByManuscrito(_manuscritoId!);
        setState(() {
          _capitulos = List<Map<String, dynamic>>.from(caps);
          if (_selectedCapituloIndex >= _capitulos.length) {
            _selectedCapituloIndex = _capitulos.isEmpty ? 0 : _capitulos.length - 1;
          }
        });
      },
    );
  }

  Future<void> _eliminarCapitulo(int index) async {
    if (_capitulos.length <= 1) return;
    final cap = _capitulos[index];
    final title = cap['titulo']?.toString().trim().isNotEmpty == true
        ? cap['titulo'].toString().trim()
        : 'Capítulo';
    final deletedId = cap['id'] as int;

    await AppDatabase.softDeleteCapitulo(deletedId);
    setState(() {
      _capitulos.removeAt(index);
      if (_selectedCapituloIndex >= _capitulos.length) {
        _selectedCapituloIndex = _capitulos.length - 1;
      } else if (index < _selectedCapituloIndex) {
        _selectedCapituloIndex--;
      }
      _cambiarCapitulo(_selectedCapituloIndex);
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface,
        content: Text(
          '"$title" se movió a la papelera',
          style: GoogleFonts.outfit(color: AppColors.textPrimary),
        ),
        action: SnackBarAction(
          label: 'DESHACER',
          textColor: AppColors.accent,
          onPressed: () async {
            await AppDatabase.restoreCapitulo(deletedId);
            if (_manuscritoId != null) {
              final caps = await AppDatabase.getCapitulosByManuscrito(_manuscritoId!);
              setState(() {
                _capitulos = List<Map<String, dynamic>>.from(caps);
              });
            }
          },
        ),
      ),
    );
  }

  Future<void> _guardarOrdenCapitulos() async {
    for (int i = 0; i < _capitulos.length; i++) {
      final cap = _capitulos[i];
      if (cap['orden'] != i) {
        await AppDatabase.updateCapitulo(cap['id'], {'orden': i});
        cap['orden'] = i;
      }
    }
  }

  Widget _buildDistractionFreeHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.separator)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            (widget.proyecto['titulo'] ?? 'Mi Novela').toString(),
            style: GoogleFonts.outfit(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          _ToolbarButton(
            icon: Icons.keyboard_outlined,
            color: _typewriterMode ? AppColors.accent : null,
            onPressed: _toggleTypewriterMode,
            tooltip: _typewriterMode
                ? 'Modo Máquina de Escribir (Activo)'
                : 'Modo Máquina de Escribir (Inactivo)',
          ),
          const SizedBox(width: 4),
          _ToolbarButton(
            icon: Icons.search_rounded,
            onPressed: () =>
                setState(() => _showFindReplace = !_showFindReplace),
            tooltip: 'Buscar y reemplazar (Ctrl+F)',
          ),
          const SizedBox(width: 4),
          _ToolbarButton(
            icon: Icons.manage_search_rounded,
            onPressed: _abrirBusquedaGlobal,
            tooltip: 'Búsqueda global en toda la novela (Ctrl+Shift+F)',
          ),
          const SizedBox(width: 4),
          _ToolbarButton(
            icon: Icons.fullscreen_rounded,
            onPressed: () =>
                setState(() => _distractionFreeMode = !_distractionFreeMode),
            tooltip: 'Salir del modo sin distracciones',
          ),
        ],
      ),
    );
  }

  Widget _buildFindReplaceBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.separator)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                controller: _findController,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Buscar...',
                  hintStyle: GoogleFonts.outfit(
                    color: Colors.white24,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 16,
                    color: Colors.white38,
                  ),
                  suffixIcon: _findController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Colors.white38,
                          ),
                          onPressed: () {
                            _findController.clear();
                            _findMatches = [];
                            _highlightedMatchIndex = null;
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (_) => _performFind(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.chevron_left_rounded,
              size: 20,
              color: Colors.white54,
            ),
            onPressed: _highlightedMatchIndex != null && _findMatches.isNotEmpty
                ? () {
                    setState(() {
                      _highlightedMatchIndex = (_highlightedMatchIndex! - 1)
                          .clamp(0, _findMatches.length - 1);
                      _applyFindSelection();
                    });
                  }
                : null,
            tooltip: 'Anterior',
          ),
          Text(
            _findMatches.isNotEmpty
                ? '${(_highlightedMatchIndex ?? 0) + 1}/${_findMatches.length}'
                : '0/0',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: Colors.white38,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Colors.white54,
            ),
            onPressed: _highlightedMatchIndex != null && _findMatches.isNotEmpty
                ? () {
                    setState(() {
                      _highlightedMatchIndex = (_highlightedMatchIndex! + 1)
                          .clamp(0, _findMatches.length - 1);
                      _applyFindSelection();
                    });
                  }
                : null,
            tooltip: 'Siguiente',
          ),
          Container(width: 1, height: 24, color: Colors.white10),
          const SizedBox(width: 8),
          SizedBox(
            width: 140,
            height: 36,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                controller: _replaceController,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Reemplazar con...',
                  hintStyle: GoogleFonts.outfit(
                    color: Colors.white24,
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _replaceCurrent,
            child: Text(
              'REEMPLAZAR',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: _replaceAll,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orangeAccent,
              side: BorderSide(color: Colors.orangeAccent),
            ),
            child: Text(
              'TODO',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _performFind() {
    if (!_isQuillInitialized) return;
    final query = _findController.text;
    if (query.isEmpty) {
      setState(() {
        _findMatches = [];
        _highlightedMatchIndex = null;
      });
      return;
    }
    final plainText = _quillController.document.toPlainText();
    final lowerText = plainText.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matches = <TextSelection>[];
    int start = 0;
    while (true) {
      final idx = lowerText.indexOf(lowerQuery, start);
      if (idx == -1) break;
      matches.add(TextSelection.collapsed(offset: idx));
      start = idx + 1;
    }
    setState(() {
      _findMatches = matches;
      _highlightedMatchIndex = matches.isNotEmpty ? 0 : null;
    });
    if (matches.isNotEmpty) {
      _applyFindSelection();
    }
  }

  void _applyFindSelection() {
    if (_highlightedMatchIndex == null || _findMatches.isEmpty) return;
    final selection = _findMatches[_highlightedMatchIndex!];
    _quillController.updateSelection(selection, ChangeSource.local);
  }

  void _replaceCurrent() {
    if (_highlightedMatchIndex == null || _findMatches.isEmpty) return;
    final query = _findController.text;
    final replacement = _replaceController.text;
    if (query.isEmpty) return;
    if (_replaceText(
      query,
      replacement,
      _findMatches[_highlightedMatchIndex!].baseOffset,
    )) {
      final newMatches = List<TextSelection>.from(_findMatches);
      newMatches.removeAt(_highlightedMatchIndex!);
      setState(() {
        _findMatches = newMatches;
        _highlightedMatchIndex = newMatches.isNotEmpty
            ? _highlightedMatchIndex!.clamp(0, newMatches.length - 1)
            : null;
      });
      if (_highlightedMatchIndex != null) {
        _applyFindSelection();
      }
    }
  }

  bool _replaceText(String query, String replacement, int offset) {
    if (!_isQuillInitialized) return false;
    try {
      final length = query.length;
      _quillController.replaceText(offset, length, replacement, null);
      _markUnsaved();
      return true;
    } catch (e) {
      return false;
    }
  }

  void _replaceAll() {
    if (!_isQuillInitialized) return;
    final query = _findController.text;
    final replacement = _replaceController.text;
    if (query.isEmpty) return;
    var offset = 0;
    var count = 0;
    while (true) {
      final text = _quillController.document.toPlainText();
      final idx = text.indexOf(query, offset);
      if (idx == -1) break;
      _quillController.replaceText(idx, query.length, replacement, null);
      offset = idx + replacement.length;
      count++;
    }
    setState(() {
      _findMatches = [];
      _highlightedMatchIndex = null;
    });
    if (count > 0) {
      _markUnsaved();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count reemplazos realizados.'),
          backgroundColor: AppColors.accent,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_kbdHandler);
    _autoSaveTimer?.cancel();
    _statsTimer?.cancel();
    _prefsSaveTimer?.cancel();
    _pomodoroTimer?.cancel();
    if (_isQuillInitialized) {
      _quillController.removeListener(_onTextChanged);
    }
    // Guardado best-effort sin setState (widget ya desmontado)
    if (_manuscritoId != null) {
      final text = _isQuillInitialized
          ? jsonEncode(_quillController.document.toDelta().toJson())
          : '';
      final pageColorHex = _colorToHex(_pageColor);

      final changes = <String, Object?>{};

      // Guardar el contenido del capítulo actual (best-effort al salir)
      if (_capitulos.isNotEmpty &&
          (text != _lastSavedText ||
              _titleController.text != _lastSavedTitle)) {
        final currentCap = _capitulos[_selectedCapituloIndex];
        AppDatabase.database.then((db) {
          db.update(
            'capitulos',
            {
              'contenido': text,
              'titulo': _titleController.text,
              'actualizado_en': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [currentCap['id']],
          );
        });
      }

      if (pageColorHex != _lastSavedPageColorHex) {
        changes['color_fondo'] = pageColorHex;
      }
      if (_fontFamily != _lastSavedFontFamily) changes['fuente'] = _fontFamily;
      if (_fontSize != _lastSavedFontSize) changes['font_size'] = _fontSize;
      if (_lineHeight != _lastSavedLineHeight) {
        changes['line_height'] = _lineHeight;
      }

      if (changes.isNotEmpty) {
        changes['actualizado_en'] = DateTime.now().toIso8601String();
        AppDatabase.database.then((db) {
          db.update(
            'manuscritos',
            changes,
            where: 'id = ?',
            whereArgs: [_manuscritoId],
          );
        });
      }
      AppDatabase.updateProyecto(widget.proyecto);
    }
    _titleController.dispose();
    _fontSizeController.dispose();
    _editorFocusNode.dispose();
    _fontSizeFocusNode.dispose();
    _editorScrollController.dispose();
    if (_isQuillInitialized) {
      _quillController.dispose();
    }
    super.dispose();
  }
}

class _CapituloSidebarItem extends StatefulWidget {
  final String label;
  final String title;
  final int words;
  final String estado;
  final String? povName;
  final int metaPalabras;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEditMetadata;
  final VoidCallback? onDelete;

  const _CapituloSidebarItem({
    required this.label,
    required this.title,
    this.words = 0,
    this.estado = 'borrador',
    this.povName,
    this.metaPalabras = 0,
    required this.isSelected,
    required this.onTap,
    required this.onEditMetadata,
    this.onDelete,
  });

  @override
  State<_CapituloSidebarItem> createState() => _CapituloSidebarItemState();
}

class _CapituloSidebarItemState extends State<_CapituloSidebarItem> {
  bool _isHovered = false;

  Color _getStatusColor(String st) {
    switch (st) {
      case 'completado':
        return const Color(0xFF4CAF50);
      case 'en_revision':
        return const Color(0xFFFFB300);
      case 'reescritura':
        return const Color(0xFFFF7043);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String _getStatusLabel(String st) {
    switch (st) {
      case 'completado':
        return 'Listo';
      case 'en_revision':
        return 'Revisión';
      case 'reescritura':
        return 'Reescribir';
      default:
        return 'Borrador';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.estado);
    final statusLabel = _getStatusLabel(widget.estado);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: widget.isSelected
                ? LinearGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.15),
                      AppColors.accent.withValues(alpha: 0.02),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : _isHovered
                ? LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.04),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.accent.withValues(alpha: 0.25)
                  : _isHovered
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 3,
                height: widget.isSelected ? 24 : 0,
                margin: EdgeInsets.only(right: widget.isSelected ? 8 : 0),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: widget.isSelected
                                  ? AppColors.accent
                                  : _isHovered
                                  ? AppColors.textSecondary
                                  : AppColors.textTertiary,
                              fontSize: 11,
                              fontWeight: widget.isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusLabel,
                            style: GoogleFonts.outfit(
                              color: statusColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.title.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.title,
                        style: GoogleFonts.outfit(
                          color: widget.isSelected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: widget.isSelected
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (widget.povName != null && widget.povName!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.person_pin_circle_outlined,
                            size: 11,
                            color: AppColors.accent.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.povName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: AppColors.accent.withValues(alpha: 0.85),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          '${widget.words} palabras',
                          style: GoogleFonts.outfit(
                            color: AppColors.textTertiary,
                            fontSize: 10,
                          ),
                        ),
                        if (widget.metaPalabras > 0) ...[
                          Text(
                            ' / ${widget.metaPalabras}',
                            style: GoogleFonts.outfit(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (_isHovered || widget.isSelected) ...[
                IconButton(
                  icon: Icon(
                    Icons.tune_rounded,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  onPressed: widget.onEditMetadata,
                  splashRadius: 14,
                  tooltip: 'Detalles y metadatos',
                ),
                if (widget.onDelete != null)
                  IconButton(
                    icon: Icon(
                      Icons.delete_rounded,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    onPressed: widget.onDelete,
                    splashRadius: 14,
                    hoverColor: Colors.redAccent.withValues(alpha: 0.1),
                    tooltip: 'Mover a la papelera',
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppColors.separator,
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final Color? color;

  const _ToolbarButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18, color: color ?? AppColors.textSecondary),
      onPressed: onPressed,
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      splashRadius: 18,
    );
  }
}

class _NestedModeChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NestedModeChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.accent.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? AppColors.accent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppColors.accent : Colors.white54,
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeTab({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isActive ? AppColors.accent : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isActive ? AppColors.accent : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? AppColors.accent
                        : AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _GlassButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.separator),
            color: Colors.white.withValues(alpha: 0.04),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: AppColors.accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppColors.accent.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
