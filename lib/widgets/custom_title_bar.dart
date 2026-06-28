import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTitleBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomTitleBar({super.key});

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();

  @override
  Size get preferredSize => const Size.fromHeight(38);
}

class _CustomTitleBarState extends State<CustomTitleBar> with WindowListener {
  bool _isMaximized = false;
  bool _isHoveredClose = false;
  bool _isHoveredMinimize = false;
  bool _isHoveredMaximize = false;
  bool _isHoveredTitleBar = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _checkIsMaximized();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _checkIsMaximized() async {
    final isMax = await windowManager.isMaximized();
    if (mounted) setState(() => _isMaximized = isMax);
  }

  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _isMaximized = false);
  }

  Future<void> _toggleMaximize() async {
    final isMax = await windowManager.isMaximized();
    if (isMax) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          border: const Border(
            bottom: BorderSide(color: Color(0xFF48484A), width: 0.5),
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    color: const Color(0xFF1C1C1E).withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),
            MouseRegion(
              onEnter: (_) => setState(() => _isHoveredTitleBar = true),
              onExit: (_) => setState(() {
                _isHoveredTitleBar = false;
                _isHoveredClose = false;
                _isHoveredMinimize = false;
                _isHoveredMaximize = false;
              }),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  _TrafficLights(
                    onClose: () => windowManager.close(),
                    onMinimize: () => windowManager.minimize(),
                    onMaximize: _toggleMaximize,
                    isMaximized: _isMaximized,
                    isHovered: _isHoveredTitleBar,
                    isHoveredClose: _isHoveredClose,
                    isHoveredMinimize: _isHoveredMinimize,
                    isHoveredMaximize: _isHoveredMaximize,
                    onHoverClose: (v) => setState(() => _isHoveredClose = v),
                    onHoverMinimize: (v) => setState(() => _isHoveredMinimize = v),
                    onHoverMaximize: (v) => setState(() => _isHoveredMaximize = v),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DragToMoveArea(
                      child: GestureDetector(
                        onDoubleTap: _toggleMaximize,
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            Image.asset(
                              'lib/assets/logo.png',
                              width: 18,
                              height: 18,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const SizedBox(width: 18),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Novel Writer',
                              style: GoogleFonts.inter(
                                color: const Color(0xFFF5F5F7),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
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
      ),
    );
  }
}

class _TrafficLights extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onMinimize;
  final VoidCallback onMaximize;
  final bool isMaximized;
  final bool isHovered;
  final bool isHoveredClose;
  final bool isHoveredMinimize;
  final bool isHoveredMaximize;
  final ValueChanged<bool> onHoverClose;
  final ValueChanged<bool> onHoverMinimize;
  final ValueChanged<bool> onHoverMaximize;

  const _TrafficLights({
    required this.onClose,
    required this.onMinimize,
    required this.onMaximize,
    required this.isMaximized,
    required this.isHovered,
    required this.isHoveredClose,
    required this.isHoveredMinimize,
    required this.isHoveredMaximize,
    required this.onHoverClose,
    required this.onHoverMinimize,
    required this.onHoverMaximize,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TrafficLight(
            color: isHoveredClose ? const Color(0xFFFF453A) : const Color(0xFF3A3A3C),
            icon: isHovered ? Icons.close : null,
            iconColor: const Color(0xFF1C1C1E),
            onTap: onClose,
            isHovered: isHoveredClose,
            onHover: onHoverClose,
          ),
          const SizedBox(width: 8),
          _TrafficLight(
            color: isHoveredMinimize ? const Color(0xFFFF9F0A) : const Color(0xFF3A3A3C),
            icon: isHovered ? Icons.remove : null,
            iconColor: const Color(0xFF1C1C1E),
            onTap: onMinimize,
            isHovered: isHoveredMinimize,
            onHover: onHoverMinimize,
          ),
          const SizedBox(width: 8),
          _TrafficLight(
            color: isHoveredMaximize ? const Color(0xFF30D158) : const Color(0xFF3A3A3C),
            icon: isHovered ? (isMaximized ? Icons.filter_none : Icons.crop_square) : null,
            iconColor: const Color(0xFF1C1C1E),
            onTap: onMaximize,
            isHovered: isHoveredMaximize,
            onHover: onHoverMaximize,
          ),
        ],
      ),
    );
  }
}

class _TrafficLight extends StatelessWidget {
  final Color color;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback onTap;
  final bool isHovered;
  final ValueChanged<bool> onHover;

  const _TrafficLight({
    required this.color,
    this.icon,
    this.iconColor,
    required this.onTap,
    required this.isHovered,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: icon != null && isHovered
              ? Icon(icon, size: 8, color: iconColor)
              : null,
        ),
      ),
    );
  }
}
