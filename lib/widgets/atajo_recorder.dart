import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

bool isModifierKey(LogicalKeyboardKey key) => switch (key) {
  LogicalKeyboardKey.controlLeft ||
  LogicalKeyboardKey.controlRight ||
  LogicalKeyboardKey.shiftLeft ||
  LogicalKeyboardKey.shiftRight ||
  LogicalKeyboardKey.altLeft ||
  LogicalKeyboardKey.altRight ||
  LogicalKeyboardKey.metaLeft ||
  LogicalKeyboardKey.metaRight => true,
  _ => false,
};

String? keyLabel(LogicalKeyboardKey key) {
  if (key == LogicalKeyboardKey.space) return 'Space';
  if (key == LogicalKeyboardKey.enter) return 'Enter';
  if (key == LogicalKeyboardKey.tab) return 'Tab';
  if (key == LogicalKeyboardKey.escape) return 'Esc';
  if (key == LogicalKeyboardKey.backspace) return 'Backspace';
  if (key == LogicalKeyboardKey.delete) return 'Delete';
  if (key == LogicalKeyboardKey.arrowUp) return '↑';
  if (key == LogicalKeyboardKey.arrowDown) return '↓';
  if (key == LogicalKeyboardKey.arrowLeft) return '←';
  if (key == LogicalKeyboardKey.arrowRight) return '→';
  final id = key.keyId;
  if (id >= LogicalKeyboardKey.f1.keyId && id <= LogicalKeyboardKey.f12.keyId) {
    return key.keyLabel;
  }
  final label = key.keyLabel;
  if (label.isEmpty) return null;
  return label.length == 1 ? label.toUpperCase() : label;
}

String? pressedKeyCombo(LogicalKeyboardKey key) {
  if (isModifierKey(key)) return null;
  final kbd = HardwareKeyboard.instance;
  final parts = <String>[];
  if (kbd.isControlPressed) parts.add('Ctrl');
  if (kbd.isAltPressed) parts.add('Alt');
  if (kbd.isShiftPressed) parts.add('Shift');
  if (kbd.isMetaPressed) parts.add('Win');
  if (parts.isEmpty) return null;
  final label = keyLabel(key);
  if (label == null) return null;
  parts.add(label);
  return parts.join('+');
}

class AtajoRecorder extends StatefulWidget {
  final TextEditingController controller;
  final String? hint;

  const AtajoRecorder({
    super.key,
    required this.controller,
    this.hint,
  });

  @override
  State<AtajoRecorder> createState() => _AtajoRecorderState();
}

class _AtajoRecorderState extends State<AtajoRecorder> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.handled;
    final combo = pressedKeyCombo(event.logicalKey);
    if (combo != null) {
      widget.controller.text = combo;
      _focusNode.unfocus();
      if (mounted) setState(() {});
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.controller.text.isNotEmpty;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKeyEvent,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: _focused ? 0.06 : 0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _focused
                    ? const Color(0xFF00F0FF)
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                if (_focused)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(Icons.keyboard, size: 14, color: Color(0xFF00F0FF)),
                  ),
                Expanded(
                  child: Text(
                    hasValue
                        ? widget.controller.text
                        : (_focused ? 'Capturando...' : (widget.hint ?? 'Atajo')),
                    style: GoogleFonts.jetBrainsMono(
                      color: hasValue ? Colors.white : Colors.white38,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (hasValue && !_focused)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        widget.controller.text = '';
                        if (mounted) setState(() {});
                      },
                      child: Icon(Icons.close, size: 14, color: Colors.white24),
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
