import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/app_theme.dart';

class FluidDockItem {
  final IconData icon;
  final String tooltip;

  const FluidDockItem({required this.icon, required this.tooltip});
}

class FluidDock extends StatefulWidget {
  final List<FluidDockItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback? onBack;

  const FluidDock({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    this.onBack,
  });

  @override
  State<FluidDock> createState() => _FluidDockState();
}

class _FluidDockState extends State<FluidDock> with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _dropAnim;
  late Animation<double> _expandAnim;
  final FocusNode _focusNode = FocusNode(debugLabel: 'FluidDock');
  bool _isOpen = false;
  bool _inTrigger = false;
  bool _inDock = false;
  Timer? _closeTimer;

  static const _triggerTop = 8.0;
  static const _triggerHeight = 48.0;
  static const _dockH = 76.0;
  static const _dockGap = 6.0;
  static const _minDockWidthExpanded = 220.0;
  static const _minDockHeight = 34.0;
  static const _itemBaseWidth = 60.0;
  static const _itemBasePadding = 42.0;
  static const _dropDistance = 10.0;
  static const _fadeThreshold = 0.12;
  static const _itemsFadeThreshold = 0.45;
  static const _surfaceAlphaClosed = 0.68;
  static const _surfaceAlphaOpen = 0.78;
  static const _borderAlphaClosed = 0.72;
  static const _borderAlphaOpen = 0.35;
  static const _shadowAlphaClosed = 0.18;
  static const _pulseClosedMin = 0.08;
  static const _pulseClosedMax = 0.16;
  static const _separatorWidth = 1.0;
  static const _separatorHeight = 34.0;
  static const _separatorAlpha = 0.32;
  static const _separatorHPadding = 8.0;
  static const _staggerBaseDelay = 0.20;
  static const _staggerIncrement = 0.025;
  static const _appearDuration = 0.82;
  static const _collapsedMinWidth = 0.0;
  static const _collapsedMaxWidth = 240.0;
  static const _collapsedHeight = 38.0;
  static const _collapsedHPadding = 12.0;
  static const _collapsedBorderRadius = 999.0;
  static const _collapsedIconSize = 17.0;
  static const _collapsedTextSize = 12.0;
  static const _collapsedArrowSize = 18.0;
  static const _collapsedIconTextGap = 8.0;
  static const _collapsedTextArrowGap = 6.0;
  static const _rotationTurns = 0.5;
  static const _animDuration = 180;
  static const _ctrlDuration = 380;
  static const _closeDelay = 260;
  static const _minDockWidth = 260.0;
  static const _sidePadding = 24.0;
  static const _itemsHorizontalPadding = 12.0;
  static const _itemsVerticalPadding = 8.0;
  static const _dockBorderRadius = 16.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _ctrlDuration),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _dropAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    );
    _expandAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.08, 1.0, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    _ctrl.dispose();
    _pulseCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _open() {
    _closeTimer?.cancel();
    _closeTimer = null;
    if (!_focusNode.hasFocus) _focusNode.requestFocus();
    if (!_isOpen) {
      setState(() => _isOpen = true);
      _ctrl.forward(from: 0);
      _pulseCtrl.stop();
    }
  }

  void _scheduleClose() {
    if (_inTrigger || _inDock) return;
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: _closeDelay), _close);
  }

  void _close() {
    if (!mounted || !_isOpen) return;
    _ctrl.reverse();
    setState(() => _isOpen = false);
    _pulseCtrl.repeat(reverse: true);
  }

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _selectIndex(int index) {
    if (widget.items.isEmpty) return;
    final last = widget.items.length - 1;
    final next = index.clamp(0, last);
    widget.onItemSelected(next);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.escape:
        _close();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.space:
        _toggle();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.arrowDown:
        _open();
        _selectIndex(widget.selectedIndex + 1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.arrowUp:
        _open();
        _selectIndex(widget.selectedIndex - 1);
        return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  double _targetDockWidth(double viewportWidth) {
    final visibleItems = widget.items.length + (widget.onBack != null ? 1 : 0);
    final contentWidth = _itemBasePadding + (visibleItems * _itemBaseWidth);
    final maxWidth = math.max(_minDockWidth, viewportWidth - _sidePadding);
    return contentWidth.clamp(_minDockWidth, maxWidth).toDouble();
  }

  FluidDockItem? get _selectedItem {
    if (widget.items.isEmpty) return null;
    final index = widget.selectedIndex.clamp(0, widget.items.length - 1);
    return widget.items[index];
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final dockWidth = _targetDockWidth(viewportWidth);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: _triggerTop,
                child: Center(
                  child: RepaintBoundary(child: _buildCollapsedPill()),
                ),
              ),

              if (_isOpen || _ctrl.isAnimating)
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (ctx, child) {
                    final dropY = _dropAnim.value * _dropDistance;
                    final expW = _expandAnim.value * dockWidth;
                    final expH = _expandAnim.value * _dockH;
                    final opacity = _ctrl.value < _fadeThreshold
                        ? _ctrl.value / _fadeThreshold
                        : 1.0;
                    final shapeP = _expandAnim.value;
                    final w = math.max(_minDockWidthExpanded, expW);
                    final h = math.max(_minDockHeight, expH);

                    return Positioned(
                      top: _triggerHeight + _dockGap + dropY,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Opacity(
                          opacity: opacity.clamp(0.0, 1.0),
                          child: SizedBox(
                            width: w,
                            height: h,
                            child: MouseRegion(
                              onEnter: (_) {
                                _inDock = true;
                                _closeTimer?.cancel();
                                _closeTimer = null;
                              },
                              onExit: (_) {
                                _inDock = false;
                                _scheduleClose();
                              },
                              cursor: SystemMouseCursors.basic,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    _dockBorderRadius,
                                  ),
                                  border: Border.all(
                                    color: AppColors.accent.withValues(
                                      alpha: 0.10 * shapeP,
                                    ),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.35 * shapeP,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                    BoxShadow(
                                      color: AppColors.accent.withValues(
                                        alpha: 0.04 * shapeP,
                                      ),
                                      blurRadius: 30,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    _dockBorderRadius,
                                  ),
                                  child: Stack(
                                    children: [
                                      child!,
                                      if (_expandAnim.value >
                                          _itemsFadeThreshold)
                                        Positioned.fill(
                                          child: Center(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal:
                                                        _itemsHorizontalPadding,
                                                    vertical:
                                                        _itemsVerticalPadding,
                                                  ),
                                              child: ClipRect(
                                                child: SingleChildScrollView(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  physics:
                                                      const BouncingScrollPhysics(),
                                                  child: _buildItemsRow(),
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
                          ),
                        ),
                      ),
                    );
                  },
                  child: _buildGlassBody(),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCollapsedPill() {
    final selected = _selectedItem;

    return MouseRegion(
      onEnter: (_) {
        _inTrigger = true;
        _open();
      },
      onExit: (_) {
        _inTrigger = false;
        _scheduleClose();
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _open,
        child: Semantics(
          button: true,
          label: 'Navegación del proyecto',
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (ctx, _) {
              final pulse = _isOpen
                  ? 0.0
                  : (_pulseClosedMin +
                        _pulseCtrl.value * (_pulseClosedMax - _pulseClosedMin));

              return AnimatedContainer(
                duration: const Duration(milliseconds: _animDuration),
                constraints: const BoxConstraints(
                  minWidth: _collapsedMinWidth,
                  maxWidth: _collapsedMaxWidth,
                ),
                height: _collapsedHeight,
                padding: const EdgeInsets.symmetric(
                  horizontal: _collapsedHPadding,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(
                    alpha: _isOpen ? _surfaceAlphaOpen : _surfaceAlphaClosed,
                  ),
                  borderRadius: BorderRadius.circular(_collapsedBorderRadius),
                  border: Border.all(
                    color: _isOpen
                        ? AppColors.accent.withValues(alpha: _borderAlphaOpen)
                        : AppColors.separator.withValues(
                            alpha: _borderAlphaClosed,
                          ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: pulse),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: _shadowAlphaClosed),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selected?.icon ?? Icons.apps_rounded,
                      color: AppColors.accent,
                      size: _collapsedIconSize,
                    ),
                    const SizedBox(width: _collapsedIconTextGap),
                    Flexible(
                      child: Text(
                        selected?.tooltip ?? 'Navegación',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: AppColors.textPrimary,
                          fontSize: _collapsedTextSize,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: _collapsedTextArrowGap),
                    AnimatedRotation(
                      turns: _isOpen ? _rotationTurns : 0,
                      duration: const Duration(milliseconds: _animDuration),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textTertiary,
                        size: _collapsedArrowSize,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGlassBody() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navSurface,
        border: Border(
          top: BorderSide(color: AppColors.separator.withValues(alpha: 0.2)),
        ),
      ),
    );
  }

  Widget _buildItemsRow() {
    final widgets = <Widget>[];

    if (widget.onBack != null) {
      widgets.add(
        _buildItem(
          icon: Icons.arrow_back_rounded,
          tooltip: 'Volver',
          index: 0,
          onTap: widget.onBack,
        ),
      );
      widgets.add(_separator());
    }

    for (int i = 0; i < widget.items.length; i++) {
      final idx = widget.onBack != null ? i + 1 : i;
      widgets.add(
        _buildItem(
          icon: widget.items[i].icon,
          tooltip: widget.items[i].tooltip,
          index: idx,
          isSelected: i == widget.selectedIndex,
          onTap: () => widget.onItemSelected(i),
        ),
      );
    }

    return RepaintBoundary(
      child: Row(mainAxisSize: MainAxisSize.min, children: widgets),
    );
  }

  Widget _separator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _separatorHPadding),
      child: Container(
        width: _separatorWidth,
        height: _separatorHeight,
        color: AppColors.separator.withValues(alpha: _separatorAlpha),
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String tooltip,
    required int index,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    final staggerDelay = _staggerBaseDelay + index * _staggerIncrement;
    final appear = (_ctrl.value - staggerDelay).clamp(0.0, 1.0);
    final total = (_appearDuration - staggerDelay).clamp(0.01, 1.0);
    final itemP = (appear / total).clamp(0.0, 1.0).toDouble();

    final opacity = itemP;
    final scale = 0.3 + itemP * 0.7;

    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale.clamp(0.3, 1.0),
        child: _DockItem(
          icon: icon,
          tooltip: tooltip,
          isSelected: isSelected,
          onTap: onTap,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual dock item
// ---------------------------------------------------------------------------

class _DockItem extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback? onTap;

  const _DockItem({
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    this.onTap,
  });

  @override
  State<_DockItem> createState() => _DockItemState();
}

class _DockItemState extends State<_DockItem> {
  bool _hovered = false;
  bool _focused = false;
  final FocusNode _focusNode = FocusNode(debugLabel: 'DockItem');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = MediaQuery.maybeOf(context)?.disableAnimations == true ? 0 : 180;
    final iconSize = _hovered ? 20.0 : 18.0;
    final isSelected = widget.isSelected;

    final itemContent = Semantics(
      button: true,
      selected: isSelected,
      label: widget.tooltip,
      child: Container(
        width: 56,
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: _hovered ? 0.16 : 0.10)
              : _hovered
              ? AppColors.surfaceLight.withValues(alpha: 0.22)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: _focused
                ? AppColors.accent
                : isSelected
                ? AppColors.accent.withValues(alpha: _hovered ? 0.56 : 0.32)
                : _hovered
                ? AppColors.separator.withValues(alpha: 0.72)
                : Colors.transparent,
            width: _focused ? 1.5 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.accent.withValues(
                  alpha: _hovered ? 0.14 : 0.07,
                ),
                blurRadius: _hovered ? 12 : 8,
                offset: const Offset(0, 5),
              ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.hardEdge,
          children: [
            AnimatedSlide(
              duration: Duration(milliseconds: d),
              curve: Curves.easeOutCubic,
              offset: Offset(0, _hovered ? -0.04 : 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    size: iconSize,
                    color: isSelected
                        ? AppColors.accent
                        : _hovered
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 2,
              child: AnimatedContainer(
                duration: Duration(milliseconds: d),
                width: isSelected ? 16 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final inner = RepaintBoundary(
      child: Focus(
        focusNode: _focusNode,
        onFocusChange: (v) => setState(() => _focused = v),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(onTap: widget.onTap, child: itemContent),
        ),
      ),
    );

    if (_focused) {
      return Padding(
        padding: const EdgeInsets.all(2),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accent, width: 1.5),
          ),
          child: Padding(padding: const EdgeInsets.all(2), child: inner),
        ),
      );
    }

    return Padding(padding: const EdgeInsets.all(2), child: inner);
  }
}
