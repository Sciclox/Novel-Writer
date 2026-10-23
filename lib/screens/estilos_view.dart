import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/app_database.dart';
import '../models/novel_style.dart';
import '../shared/app_theme.dart';
import '../shared/app_widgets.dart';
import '../widgets/atajo_recorder.dart';
import '../widgets/app_color_picker.dart';

class EstilosView extends StatefulWidget {
  final int proyectoId;
  const EstilosView({super.key, required this.proyectoId});

  @override
  State<EstilosView> createState() => _EstilosViewState();
}

class _EstilosViewState extends State<EstilosView> {
  List<NovelStyle> _globales = [];
  bool _isLoading = true;

  static const _fontSizes = [8, 9, 10, 11, 12, 14, 16, 18, 20, 22, 24, 26, 28, 32, 36, 40, 48, 56, 64, 72];
  static const _fontFamilies = ['Merriweather', 'Inter', 'Outfit', 'JetBrains Mono', 'Roboto Slab', 'Playfair Display', 'Lora', 'Open Sans'];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final rows = await AppDatabase.getEstilosGlobales();
    if (!mounted) return;
    setState(() {
      _globales = rows.map((r) => NovelStyle.fromMap(r)).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditGlobalStyleDialog(),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text('NUEVO', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estilos Globales',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_globales.length} estilos disponibles para todos los proyectos',
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: _globales.isEmpty
                  ? _buildEmptyState()
                  : _buildStylesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return buildEmptyState(
      icon: Icons.text_fields_rounded,
      title: 'No hay estilos globales',
      subtitle: 'Crea tu primer estilo para definir la apariencia de tu novela.',
      actionLabel: 'CREAR PRIMER ESTILO',
      onAction: () => _showEditGlobalStyleDialog(),
    );
  }

  Widget _buildStylesList() {
    return ListView.separated(
      itemCount: _globales.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final estilo = _globales[index];
        return _buildStyleCard(estilo);
      },
    );
  }

  Widget _buildStyleCard(NovelStyle estilo) {
    final config = mergeStyleConfig(estilo, _globales);
    final fontFamily = config['fontFamily'] as String? ?? 'Merriweather';
    final fontSize = (config['fontSize'] as num?)?.toDouble() ?? 14;
    final fontWeight = config['fontWeight'] == 'bold' ? FontWeight.bold : FontWeight.normal;
    final fontStyle = config['fontStyle'] == 'italic' ? FontStyle.italic : FontStyle.normal;
    final colorHex = config['color'] as String?;
    final textColor = colorHex != null
        ? Color(int.parse(colorHex.replaceFirst('#', '0xFF')))
        : Colors.white70;
    final wrapperOpen = config['wrapperOpen'] as String? ?? '';
    final wrapperClose = config['wrapperClose'] as String? ?? '';
    final previewSample = wrapperOpen.isNotEmpty || wrapperClose.isNotEmpty
        ? '${wrapperOpen}Texto de ejemplo$wrapperClose'
        : 'The quick brown fox jumps over the lazy dog — Ejemplo de texto';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        estilo.nombre,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'Global',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 8,
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    previewSample,
                    style: GoogleFonts.getFont(
                      fontFamily,
                      fontSize: fontSize.clamp(12, 18),
                      fontWeight: fontWeight,
                      fontStyle: fontStyle,
                      color: textColor,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (estilo.atajo != null) ...[
                        Icon(Icons.keyboard, size: 11, color: Colors.white24),
                        const SizedBox(width: 4),
                        Text(
                          estilo.atajo!,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            color: Colors.white30,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        '${fontSize.round()}px · $fontFamily',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.white24,
                        ),
                      ),
                      if (wrapperOpen.isNotEmpty || wrapperClose.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.wrap_text, size: 11, color: Colors.white24),
                        const SizedBox(width: 4),
                        Text(
                          wrapperOpen.isNotEmpty ? '"${wrapperOpen.trim()}…"' : '…${wrapperClose.trim()}"',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            color: Colors.white24,
                          ),
                        ),
                      ],
                      if (estilo.heredaDeId != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.account_tree_outlined, size: 11, color: Colors.white24),
                        const SizedBox(width: 4),
                        Text(
                          'hereda de: ${_globales.where((s) => s.id == estilo.heredaDeId).firstOrNull?.nombre ?? '?'}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.white24,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Material(
              color: Colors.transparent,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: InkWell(
                  onTap: () => _showEditGlobalStyleDialog(existing: estilo),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.edit, size: 16, color: Colors.white38),
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
                  onTap: () => _deleteGlobalStyle(estilo),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.delete_outline, size: 16, color: Colors.white24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditGlobalStyleDialog({NovelStyle? existing}) async {
    final isEditing = existing != null;
    final nombreCtrl = TextEditingController(text: existing?.nombre ?? '');
    final atajoCtrl = TextEditingController(text: existing?.atajo ?? '');
    final config = existing != null ? Map<String, dynamic>.from(existing.config) : <dynamic, dynamic>{};
    final wrapperOpenCtrl = TextEditingController(text: config['wrapperOpen'] as String? ?? '');
    final wrapperCloseCtrl = TextEditingController(text: config['wrapperClose'] as String? ?? '');

    double fontSize = (config['fontSize'] as num?)?.toDouble() ?? 16;
    String fontFamily = config['fontFamily'] as String? ?? 'Merriweather';
    String fontWeight = config['fontWeight'] as String? ?? 'normal';
    String fontStyle = config['fontStyle'] as String? ?? 'normal';
    String alignment = config['alignment'] as String? ?? 'justify';
    double lineHeight = (config['lineHeight'] as num?)?.toDouble() ?? 1.8;
    String? colorHex = config['color'] as String?;
    int? heredaDeId = existing?.heredaDeId;
    bool showAdvanced = false;

    final textColorPresets = [
      const ColorPreset(Color(0xFFFFFFFF), 'Blanco'),
      const ColorPreset(Color(0xFFE8E8E8), 'Gris claro'),
      const ColorPreset(Color(0xFFA5ADBA), 'Plata'),
      const ColorPreset(Color(0xFF6C7A89), 'Gris oscuro'),
      const ColorPreset(Color(0xFF4D96FF), 'Azul'),
      const ColorPreset(Color(0xFF6BCB77), 'Verde'),
      const ColorPreset(Color(0xFFFFD93D), 'Amarillo'),
      const ColorPreset(Color(0xFFFF6B6B), 'Rojo'),
      const ColorPreset(Color(0xFFFF6B9D), 'Rosa'),
      const ColorPreset(Color(0xFFBB86FC), 'Violeta'),
      const ColorPreset(Color(0xFF03DAC6), 'Turquesa'),
    ];

    final alignmentIcons = {
      'left': Icons.format_align_left,
      'center': Icons.format_align_center,
      'right': Icons.format_align_right,
      'justify': Icons.format_align_justify,
    };

    void save() async {
      if (nombreCtrl.text.trim().isEmpty) return;
      final newConfig = {
        'fontSize': fontSize,
        'fontFamily': fontFamily,
        'fontWeight': fontWeight,
        'fontStyle': fontStyle,
        'alignment': alignment,
        'lineHeight': lineHeight,
        if (colorHex != null) 'color': colorHex!,
        if (wrapperOpenCtrl.text.trim().isNotEmpty) 'wrapperOpen': wrapperOpenCtrl.text.trim(),
        if (wrapperCloseCtrl.text.trim().isNotEmpty) 'wrapperClose': wrapperCloseCtrl.text.trim(),
      };

      if (isEditing && existing.id != null) {
        await AppDatabase.updateEstilo(existing.id!, {
          'nombre': nombreCtrl.text.trim(),
          'atajo': atajoCtrl.text.trim().isNotEmpty ? atajoCtrl.text.trim() : null,
          'hereda_de_id': heredaDeId,
          'config': jsonEncode(newConfig),
        });
      } else {
        await AppDatabase.insertEstilo({
          'nombre': nombreCtrl.text.trim(),
          'orden': _globales.length,
          'atajo': atajoCtrl.text.trim().isNotEmpty ? atajoCtrl.text.trim() : null,
          'hereda_de_id': heredaDeId,
          'config': jsonEncode(newConfig),
          'es_global': 1,
        });
      }
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            width: 520,
            constraints: const BoxConstraints(maxHeight: 700),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 60,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ──
                Container(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isEditing ? Icons.edit_outlined : Icons.add_rounded,
                          color: AppColors.accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? 'Editar estilo' : 'Nuevo estilo',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isEditing ? 'Personaliza la apariencia de este estilo' : 'Define un nuevo estilo para tus textos',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white38,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: InkWell(
                            onTap: () => Navigator.pop(ctx),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(Icons.close, size: 18, color: Colors.white38),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // ── Content ──
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Section: Identidad ──
                        _sectionHeader('Identidad'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _textField(nombreCtrl, hint: 'Nombre del estilo'),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 140,
                              child: AtajoRecorder(controller: atajoCtrl, hint: 'Atajo'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── Section: Tipografía ──
                        _sectionHeader('Tipografía'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.text_fields, size: 14, color: Colors.white24),
                            const SizedBox(width: 8),
                            Text('Familia', style: GoogleFonts.inter(fontSize: 11, color: Colors.white38)),
                            const Spacer(),
                            Text('Tamaño', style: GoogleFonts.inter(fontSize: 11, color: Colors.white38)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: _dropdown<String>(
                                value: fontFamily,
                                items: _fontFamilies.map((f) => AppDropdownItem(
                                  value: f,
                                  label: f,
                                )).toList(),
                                onChanged: (v) { if (v != null) setDialogState(() => fontFamily = v); },
                                height: 44,
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 100,
                              child: _dropdown<int>(
                                value: _fontSizes.contains(fontSize.round()) ? fontSize.round() : 16,
                                items: _fontSizes.map((v) => AppDropdownItem(value: v, label: '$v')).toList(),
                                onChanged: (v) { if (v != null) setDialogState(() => fontSize = v.toDouble()); },
                                height: 44,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Peso y estilo en chips
                        Row(
                          children: [
                            _buildStyleChip(
                              label: 'Bold',
                              icon: Icons.format_bold,
                              selected: fontWeight == 'bold',
                              onTap: () => setDialogState(() => fontWeight = fontWeight == 'bold' ? 'normal' : 'bold'),
                            ),
                            const SizedBox(width: 8),
                            _buildStyleChip(
                              label: 'Italic',
                              icon: Icons.format_italic,
                              selected: fontStyle == 'italic',
                              onTap: () => setDialogState(() => fontStyle = fontStyle == 'italic' ? 'normal' : 'italic'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Alineación como icon buttons
                        Row(
                          children: [
                            Icon(Icons.space_bar, size: 14, color: Colors.white24),
                            const SizedBox(width: 8),
                            Text('Alineación', style: GoogleFonts.inter(fontSize: 11, color: Colors.white38)),
                            const Spacer(),
                            ...['left', 'center', 'right', 'justify'].map((a) => Padding(
                              padding: EdgeInsets.only(left: a == 'left' ? 0 : 6),
                              child: _buildAlignmentButton(
                                icon: alignmentIcons[a]!,
                                selected: alignment == a,
                                onTap: () => setDialogState(() => alignment = a),
                              ),
                            )),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Interlineado con slider
                        Row(
                          children: [
                            Icon(Icons.height, size: 14, color: Colors.white24),
                            const SizedBox(width: 8),
                            Text('Interlineado', style: GoogleFonts.inter(fontSize: 11, color: Colors.white38)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: AppColors.accent,
                                  inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                                  thumbColor: AppColors.accent,
                                  overlayColor: AppColors.accent.withValues(alpha: 0.12),
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                ),
                                child: Slider(
                                  value: lineHeight,
                                  min: 1.0,
                                  max: 2.5,
                                  divisions: 15,
                                  onChanged: (v) => setDialogState(() => lineHeight = v),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 36,
                              child: Text(
                                lineHeight.toStringAsFixed(1),
                                style: GoogleFonts.jetBrainsMono(fontSize: 12, color: Colors.white54),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── Section: Color ──
                        _sectionHeader('Color de texto'),
                        const SizedBox(height: 12),
                        AppColorPicker(
                          selectedColor: colorHex != null
                              ? Color(int.parse(colorHex!.replaceFirst('#', '0xFF')))
                              : null,
                          presets: textColorPresets,
                          allowNull: true,
                          label: 'Color de texto',
                          onChanged: (color) {
                            setDialogState(() {
                              if (color == null) {
                                colorHex = null;
                              } else {
                                colorHex = '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 24),

                        // ── Section: Avanzado (collapsible) ──
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => setDialogState(() => showAdvanced = !showAdvanced),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    showAdvanced ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                    size: 16,
                                    color: Colors.white38,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Avanzado',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white38,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Herencia y wrappers',
                                    style: GoogleFonts.inter(fontSize: 10, color: Colors.white24),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (showAdvanced) ...[
                          const SizedBox(height: 8),
                          // Herencia
                          Row(
                            children: [
                              Icon(Icons.account_tree_outlined, size: 14, color: Colors.white24),
                              const SizedBox(width: 8),
                              Text('Heredar de', style: GoogleFonts.inter(fontSize: 11, color: Colors.white38)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _dropdown<int?>(
                            value: heredaDeId,
                            hint: 'Ninguno (estilo base)',
                            items: [
                              const AppDropdownItem<int?>(value: null, label: 'Ninguno (estilo base)'),
                              ..._globales.where((s) => s.id != existing?.id).map((s) => AppDropdownItem<int?>(
                                value: s.id,
                                label: s.nombre,
                              )),
                            ],
                            onChanged: (v) => setDialogState(() => heredaDeId = v),
                            height: 44,
                          ),
                          const SizedBox(height: 14),
                          // Wrappers
                          Row(
                            children: [
                              Icon(Icons.wrap_text, size: 14, color: Colors.white24),
                              const SizedBox(width: 8),
                              Text('Wrappers', style: GoogleFonts.inter(fontSize: 11, color: Colors.white38)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: _textField(wrapperOpenCtrl, hint: 'Abrir con...'),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _textField(wrapperCloseCtrl, hint: 'Cerrar con...'),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 20),

                        // ── Preview ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.preview, size: 12, color: Colors.white24),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Vista previa',
                                    style: GoogleFonts.jetBrainsMono(fontSize: 9, color: Colors.white24, letterSpacing: 0.5),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF161824),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      if (wrapperOpenCtrl.text.isNotEmpty)
                                        TextSpan(
                                          text: wrapperOpenCtrl.text,
                                          style: GoogleFonts.getFont(
                                            fontFamily,
                                            fontSize: fontSize.clamp(12, 20),
                                            color: AppColors.accent.withValues(alpha: 0.5),
                                          ),
                                        ),
                                      TextSpan(
                                        text: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
                                        style: GoogleFonts.getFont(
                                          fontFamily,
                                          fontSize: fontSize.clamp(12, 20),
                                          fontWeight: fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
                                          fontStyle: fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
                                          color: colorHex != null
                                              ? Color(int.parse(colorHex!.replaceFirst('#', '0xFF')))
                                              : Colors.white70,
                                          height: lineHeight,
                                        ),
                                      ),
                                      if (wrapperCloseCtrl.text.isNotEmpty)
                                        TextSpan(
                                          text: wrapperCloseCtrl.text,
                                          style: GoogleFonts.getFont(
                                            fontFamily,
                                            fontSize: fontSize.clamp(12, 20),
                                            color: AppColors.accent.withValues(alpha: 0.5),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                // ── Footer ──
                Container(
                  padding: const EdgeInsets.fromLTRB(28, 12, 28, 16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.textTertiary, side: BorderSide(color: AppColors.textTertiary.withValues(alpha: 0.3))),
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () {
                          save();
                          Navigator.pop(ctx);
                          _cargar();
                        },
                        child: Text(
                          isEditing ? 'Guardar cambios' : 'Crear estilo',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Dialog Sub-widgets ──

  Widget _sectionHeader(String label) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.06))),
      ],
    );
  }

  Widget _buildStyleChip({required String label, required IconData icon, required bool selected, required VoidCallback onTap}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.accent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: selected ? AppColors.accent : Colors.white38),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.accent : Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlignmentButton({required IconData icon, required bool selected, required VoidCallback onTap}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: selected ? AppColors.accent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.accent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Icon(icon, size: 18, color: selected ? AppColors.accent : Colors.white38),
        ),
      ),
    );
  }

  Future<void> _deleteGlobalStyle(NovelStyle estilo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'ELIMINAR ESTILO GLOBAL',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        content: Text(
          '¿Eliminar "${estilo.nombre}" globalmente? Los proyectos que hayan bifurcado este estilo mantendrán su copia.',
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.textTertiary, side: BorderSide(color: AppColors.textTertiary.withValues(alpha: 0.3))),
            child: Text('Cancelar', style: GoogleFonts.inter()),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.red, side: BorderSide(color: AppColors.red)),
            child: Text('Eliminar', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm == true && estilo.id != null) {
      await AppDatabase.deleteEstilo(estilo.id!);
      await _cargar();
    }
  }

  // ── Helpers ──

  Widget _textField(TextEditingController ctrl, {String? hint, ValueChanged<String>? onChanged, TextStyle? textStyle}) {
    return TextField(
      controller: ctrl,
      onChanged: onChanged,
      style: textStyle ?? GoogleFonts.inter(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.02),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF00F0FF)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<AppDropdownItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? hint,
    double height = 40,
  }) {
    return AppDropdown<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      hint: hint,
    );
  }
}
