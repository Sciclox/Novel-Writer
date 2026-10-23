import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/app_theme.dart';

/// A named color preset with label for tooltips.
class ColorPreset {
  final Color color;
  final String label;
  const ColorPreset(this.color, this.label);
}

/// Premium color picker widget with HSL wheel, hex input, presets, and recent colors.
///
/// Used in:
/// - Editor: page background color
/// - Estilos: text color
class AppColorPicker extends StatefulWidget {
  /// Currently selected color. Null means "no color" / default.
  final Color? selectedColor;

  /// Named preset colors to display.
  final List<ColorPreset> presets;

  /// Recently used colors.
  final List<Color> recents;

  /// Whether to show the "no color" option.
  final bool allowNull;

  /// Label for the section header.
  final String label;

  /// Callback when a color is selected. Null means "no color".
  final ValueChanged<Color?> onChanged;

  const AppColorPicker({
    super.key,
    required this.selectedColor,
    required this.presets,
    this.recents = const [],
    this.allowNull = false,
    this.label = 'COLOR',
    required this.onChanged,
  });

  @override
  State<AppColorPicker> createState() => _AppColorPickerState();
}

class _AppColorPickerState extends State<AppColorPicker>
    with SingleTickerProviderStateMixin {
  bool _showAdvancedPicker = false;
  late HSLColor _hsl;
  late TextEditingController _hexController;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _hsl = widget.selectedColor != null
        ? HSLColor.fromColor(widget.selectedColor!)
        : const HSLColor.fromAHSL(1.0, 210, 0.5, 0.5);
    _hexController = TextEditingController(
      text: widget.selectedColor != null
          ? _colorToHex(widget.selectedColor!)
          : '',
    );
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void didUpdateWidget(covariant AppColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedColor != oldWidget.selectedColor &&
        widget.selectedColor != null) {
      _hsl = HSLColor.fromColor(widget.selectedColor!);
      _hexController.text = _colorToHex(widget.selectedColor!);
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  String _colorToHex(Color c) {
    return '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  Color? _hexToColor(String hex) {
    hex = hex.trim().replaceFirst('#', '');
    if (hex.length == 6) {
      final value = int.tryParse('FF$hex', radix: 16);
      if (value != null) return Color(value);
    }
    if (hex.length == 8) {
      final value = int.tryParse(hex, radix: 16);
      if (value != null) return Color(value);
    }
    return null;
  }

  void _onHSLChanged(HSLColor hsl) {
    setState(() => _hsl = hsl);
    final color = hsl.toColor();
    _hexController.text = _colorToHex(color);
    widget.onChanged(color);
  }

  void _onHexSubmitted(String value) {
    final color = _hexToColor(value);
    if (color != null) {
      setState(() => _hsl = HSLColor.fromColor(color));
      widget.onChanged(color);
    }
  }

  void _toggleAdvanced() {
    setState(() => _showAdvancedPicker = !_showAdvancedPicker);
    if (_showAdvancedPicker) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Presets Grid ──
        _buildPresetsGrid(),

        // ── Recent Colors ──
        if (widget.recents.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildRecentsRow(),
        ],

        // ── Advanced Picker Toggle ──
        const SizedBox(height: 12),
        _buildAdvancedToggle(),

        // ── Advanced Picker (expandable) ──
        SizeTransition(
          sizeFactor: _expandAnimation,
          axisAlignment: -1.0,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _buildAdvancedPicker(),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetsGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // "No color" option
        if (widget.allowNull)
          _buildSwatch(
            color: null,
            isSelected: widget.selectedColor == null,
            tooltip: 'Sin color (predeterminado)',
            onTap: () => widget.onChanged(null),
          ),
        // Preset swatches
        ...widget.presets.map((preset) => _buildSwatch(
              color: preset.color,
              isSelected: widget.selectedColor == preset.color,
              tooltip: '${preset.label} (${_colorToHex(preset.color)})',
              onTap: () => widget.onChanged(preset.color),
            )),
      ],
    );
  }

  Widget _buildRecentsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history_rounded, size: 11, color: Colors.white24),
            const SizedBox(width: 5),
            Text(
              'RECIENTES',
              style: GoogleFonts.outfit(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white24,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: widget.recents.map((color) => _buildSwatch(
                color: color,
                isSelected: widget.selectedColor == color,
                tooltip: _colorToHex(color),
                onTap: () => widget.onChanged(color),
                size: 28,
              )).toList(),
        ),
      ],
    );
  }

  Widget _buildAdvancedToggle() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _toggleAdvanced,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: _showAdvancedPicker
                ? AppColors.accent.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedRotation(
                turns: _showAdvancedPicker ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  Icons.expand_more_rounded,
                  size: 14,
                  color: _showAdvancedPicker
                      ? AppColors.accent
                      : Colors.white38,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Color personalizado',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _showAdvancedPicker
                      ? AppColors.accent
                      : Colors.white38,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              if (widget.selectedColor != null && !widget.presets.any((p) => p.color == widget.selectedColor))
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: widget.selectedColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedPicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HSL Wheel ──
          Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: _HSLWheel(
                hsl: _hsl,
                onChanged: _onHSLChanged,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Lightness Slider ──
          Row(
            children: [
              Icon(Icons.brightness_6_rounded, size: 13, color: Colors.white30),
              const SizedBox(width: 8),
              Text(
                'Brillo',
                style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.accent,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                    thumbColor: AppColors.accent,
                    overlayColor: AppColors.accent.withValues(alpha: 0.12),
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                  ),
                  child: Slider(
                    value: _hsl.lightness,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (v) => _onHSLChanged(_hsl.withLightness(v)),
                  ),
                ),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '${(_hsl.lightness * 100).round()}%',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 11, color: Colors.white54),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Saturation Slider ──
          Row(
            children: [
              Icon(Icons.palette_rounded, size: 13, color: Colors.white30),
              const SizedBox(width: 8),
              Text(
                'Saturación',
                style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _hsl.toColor(),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                    thumbColor: _hsl.toColor(),
                    overlayColor: _hsl.toColor().withValues(alpha: 0.12),
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                  ),
                  child: Slider(
                    value: _hsl.saturation,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (v) => _onHSLChanged(_hsl.withSaturation(v)),
                  ),
                ),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '${(_hsl.saturation * 100).round()}%',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 11, color: Colors.white54),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Hex Input + Color Preview ──
          Row(
            children: [
              // Color preview swatch
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _hsl.toColor(),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _hsl.toColor().withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Hex text field
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _hexController,
                    onSubmitted: _onHexSubmitted,
                    onChanged: (v) {
                      if (v.length == 7 || v.length == 4) {
                        _onHexSubmitted(v);
                      }
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[#0-9A-Fa-f]')),
                      LengthLimitingTextInputFormatter(7),
                    ],
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: '#FF00FF',
                      hintStyle: GoogleFonts.jetBrainsMono(
                        color: Colors.white24,
                        fontSize: 13,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 10, right: 6),
                        child: Text(
                          'HEX',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            color: Colors.white30,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      prefixIconConstraints:
                          const BoxConstraints(minWidth: 0, minHeight: 0),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.04),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.accent),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Copy button
              Tooltip(
                message: 'Copiar código hex',
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: _colorToHex(_hsl.toColor())));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Color copiado: ${_colorToHex(_hsl.toColor())}'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: const Icon(Icons.copy_rounded,
                          size: 14, color: Colors.white38),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwatch({
    required Color? color,
    required bool isSelected,
    required String tooltip,
    required VoidCallback onTap,
    double size = 34,
  }) {
    final isNull = color == null;
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color ?? Colors.transparent,
              borderRadius: BorderRadius.circular(size > 30 ? 10 : 8),
              border: Border.all(
                color: isSelected
                    ? AppColors.accent
                    : isNull
                        ? Colors.white.withValues(alpha: 0.15)
                        : color.computeLuminance() > 0.5
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: (color ?? AppColors.accent)
                            .withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: isNull
                ? Center(
                    child: Icon(Icons.block_rounded,
                        size: size * 0.42, color: Colors.white24))
                : isSelected
                    ? Center(
                        child: Icon(
                          Icons.check_rounded,
                          size: size * 0.42,
                          color: color.computeLuminance() > 0.5
                              ? Colors.black87
                              : Colors.white,
                        ),
                      )
                    : null,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HSL Color Wheel (Custom Painter)
// ─────────────────────────────────────────────────────────────

class _HSLWheel extends StatefulWidget {
  final HSLColor hsl;
  final ValueChanged<HSLColor> onChanged;

  const _HSLWheel({required this.hsl, required this.onChanged});

  @override
  State<_HSLWheel> createState() => _HSLWheelState();
}

class _HSLWheelState extends State<_HSLWheel> {
  bool _isDragging = false;

  void _handlePan(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final dist = sqrt(dx * dx + dy * dy);

    if (dist > radius + 10) return;

    // Angle = hue (0-360)
    double angle = atan2(dy, dx) * (180 / pi);
    if (angle < 0) angle += 360;

    // Distance from center = saturation (0-1)
    final saturation = (dist / radius).clamp(0.0, 1.0);

    widget.onChanged(widget.hsl.withHue(angle).withSaturation(saturation));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onPanStart: (details) {
            _isDragging = true;
            _handlePan(details.localPosition, size);
          },
          onPanUpdate: (details) {
            if (_isDragging) _handlePan(details.localPosition, size);
          },
          onPanEnd: (_) => _isDragging = false,
          onTapDown: (details) => _handlePan(details.localPosition, size),
          child: CustomPaint(
            size: size,
            painter: _HSLWheelPainter(
              hsl: widget.hsl,
            ),
          ),
        );
      },
    );
  }
}

class _HSLWheelPainter extends CustomPainter {
  final HSLColor hsl;

  _HSLWheelPainter({required this.hsl});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw the hue/saturation wheel
    for (double angle = 0; angle < 360; angle += 1) {
      for (double sat = 0; sat <= 1.0; sat += 0.02) {
        final color = HSLColor.fromAHSL(1.0, angle, sat, hsl.lightness).toColor();
        final rad = angle * pi / 180;
        final r = sat * radius;
        final point = Offset(
          center.dx + r * cos(rad),
          center.dy + r * sin(rad),
        );
        canvas.drawCircle(
          point,
          2.5,
          Paint()..color = color,
        );
      }
    }

    // Draw outer ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.1)
        ..strokeWidth = 1,
    );

    // Draw selector indicator
    final selectorAngle = hsl.hue * pi / 180;
    final selectorDist = hsl.saturation * radius;
    final selectorPos = Offset(
      center.dx + selectorDist * cos(selectorAngle),
      center.dy + selectorDist * sin(selectorAngle),
    );

    // Outer ring of selector
    canvas.drawCircle(
      selectorPos,
      9,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white
        ..strokeWidth = 2.5,
    );

    // Shadow of selector
    canvas.drawCircle(
      selectorPos,
      8,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Fill selector with current color
    canvas.drawCircle(
      selectorPos,
      7,
      Paint()..color = hsl.toColor(),
    );
  }

  @override
  bool shouldRepaint(covariant _HSLWheelPainter oldDelegate) {
    return oldDelegate.hsl != hsl;
  }
}
