import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/app_theme.dart';

class CustomTitleBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomTitleBar({super.key});

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();

  @override
  Size get preferredSize => const Size.fromHeight(46);
}

class _CustomTitleBarState extends State<CustomTitleBar> with WindowListener {
  bool _isMaximized = false;
  bool _isHoveredClose = false;
  bool _isHoveredMinimize = false;
  bool _isHoveredMaximize = false;

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
        height: 46,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.separator, width: 0.5),
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(color: AppColors.bg.withValues(alpha: 0.95)),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 1,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.0),
                      AppColors.accent.withValues(alpha: 0.2),
                      AppColors.accent.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            MouseRegion(
              onExit: (_) => setState(() {
                _isHoveredClose = false;
                _isHoveredMinimize = false;
                _isHoveredMaximize = false;
              }),
              child: Row(
                children: [
                  const SizedBox(width: 12),
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
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox(width: 18),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Novel Writer',
                              style: GoogleFonts.outfit(
                                color: AppColors.textPrimary,
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
                  _WindowsWindowControls(
                    onClose: () => windowManager.close(),
                    onMinimize: () => windowManager.minimize(),
                    onMaximize: _toggleMaximize,
                    isMaximized: _isMaximized,
                    isHoveredClose: _isHoveredClose,
                    isHoveredMinimize: _isHoveredMinimize,
                    isHoveredMaximize: _isHoveredMaximize,
                    onHoverClose: (v) => setState(() => _isHoveredClose = v),
                    onHoverMinimize: (v) =>
                        setState(() => _isHoveredMinimize = v),
                    onHoverMaximize: (v) =>
                        setState(() => _isHoveredMaximize = v),
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

class _WindowsWindowControls extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onMinimize;
  final VoidCallback onMaximize;
  final bool isMaximized;
  final bool isHoveredClose;
  final bool isHoveredMinimize;
  final bool isHoveredMaximize;
  final ValueChanged<bool> onHoverClose;
  final ValueChanged<bool> onHoverMinimize;
  final ValueChanged<bool> onHoverMaximize;

  const _WindowsWindowControls({
    required this.onClose,
    required this.onMinimize,
    required this.onMaximize,
    required this.isMaximized,
    required this.isHoveredClose,
    required this.isHoveredMinimize,
    required this.isHoveredMaximize,
    required this.onHoverClose,
    required this.onHoverMinimize,
    required this.onHoverMaximize,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Minimize
        _WindowButton(
          icon: const Icon(
            Icons.remove_rounded,
            size: 22,
            color: Colors.white70,
          ),
          hoverColor: Colors.white.withValues(alpha: 0.08),
          onTap: onMinimize,
          isHovered: isHoveredMinimize,
          onHover: onHoverMinimize,
        ),
        // Maximize
        _WindowButton(
          icon: Icon(
            isMaximized ? Icons.filter_none_rounded : Icons.crop_square_rounded,
            size: 16,
            color: Colors.white70,
          ),
          hoverColor: Colors.white.withValues(alpha: 0.08),
          onTap: onMaximize,
          isHovered: isHoveredMaximize,
          onHover: onHoverMaximize,
        ),
        // Close
        _WindowButton(
          icon: const Icon(
            Icons.close_rounded,
            size: 22,
            color: Colors.white70,
          ),
          hoverColor: const Color(0xFFE81123),
          onTap: onClose,
          isHovered: isHoveredClose,
          onHover: onHoverClose,
        ),
      ],
    );
  }
}

class _WindowButton extends StatelessWidget {
  final Widget icon;
  final Color hoverColor;
  final VoidCallback onTap;
  final bool isHovered;
  final ValueChanged<bool> onHover;

  const _WindowButton({
    required this.icon,
    required this.hoverColor,
    required this.onTap,
    required this.isHovered,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 46,
          color: isHovered ? hoverColor : Colors.transparent,
          child: Center(child: icon),
        ),
      ),
    );
  }
}
