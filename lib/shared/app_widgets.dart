import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';

Widget buildLoadingIndicator({Color? color}) {
  return Center(
    child: CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(color ?? AppColors.accent),
      strokeWidth: 3,
    ),
  );
}

Widget buildEmptyState({
  required IconData icon,
  required String title,
  String? subtitle,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.1),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              size: 44,
              color: AppColors.accent.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.outfit(
              color: AppColors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                color: AppColors.textTertiary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 28),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'ELIMINAR',
  String cancelLabel = 'CANCELAR',
  Color? confirmColor,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.separator),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          color: confirmColor ?? AppColors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        message,
        style: GoogleFonts.outfit(
          color: AppColors.textSecondary,
          fontSize: 14,
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
          child: Text(cancelLabel),
        ),
        OutlinedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: OutlinedButton.styleFrom(
            foregroundColor: confirmColor ?? AppColors.red,
            side: BorderSide(color: confirmColor ?? AppColors.red),
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

class _DropdownItemWidget<T> extends StatefulWidget {
  final AppDropdownItem<T> item;
  final bool isSelected;
  final VoidCallback onTap;

  const _DropdownItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_DropdownItemWidget<T>> createState() => _DropdownItemWidgetState<T>();
}

class _DropdownItemWidgetState<T> extends State<_DropdownItemWidget<T>> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.accent.withValues(alpha: 0.08)
                : _isHovered
                ? AppColors.separator.withValues(alpha: 0.2)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              if (widget.item.icon != null) ...[
                Icon(
                  widget.item.icon,
                  size: 18,
                  color: widget.item.color ?? AppColors.textTertiary,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  widget.item.label,
                  style: GoogleFonts.outfit(
                    color: widget.isSelected
                        ? AppColors.accent
                        : AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (widget.isSelected)
                Icon(Icons.check_rounded, size: 16, color: AppColors.accent),
            ],
          ),
        ),
      ),
    );
  }
}

class PageTransition extends PageRouteBuilder {
  final Widget child;
  PageTransition({required this.child})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      );
}

class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 12,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: [
                const Color(0xFFE5E5EA),
                AppColors.accent.withValues(alpha: 0.2),
                const Color(0xFFE5E5EA),
              ],
              stops: [
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.2).clamp(0.0, 1.0),
                (_animation.value + 0.4).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.separator),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoading(width: 50, height: 50, borderRadius: 16),
          SizedBox(height: 16),
          ShimmerLoading(width: 100, height: 28),
          SizedBox(height: 8),
          ShimmerLoading(width: 80, height: 14),
        ],
      ),
    );
  }
}

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final Color? confirmColor;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'ELIMINAR',
    this.cancelLabel = 'CANCELAR',
    required this.onConfirm,
    this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.separator),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          color: confirmColor ?? AppColors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        message,
        style: GoogleFonts.outfit(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textTertiary,
            side: BorderSide(
              color: AppColors.textTertiary.withValues(alpha: 0.3),
            ),
          ),
          child: Text(cancelLabel),
        ),
        OutlinedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: confirmColor ?? AppColors.red,
            side: BorderSide(color: confirmColor ?? AppColors.red),
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

class ValidatedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool autofocus;
  final IconData? icon;

  const ValidatedTextField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.autofocus = false,
    this.icon,
  });

  @override
  State<ValidatedTextField> createState() => _ValidatedTextFieldState();
}

class _ValidatedTextFieldState extends State<ValidatedTextField> {
  String? _error;

  void _validate() {
    if (widget.validator != null) {
      setState(() => _error = widget.validator!(widget.controller.text));
    }
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_validate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_validate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _error != null ? AppColors.red : AppColors.separator,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            autofocus: widget.autofocus,
            keyboardType: widget.keyboardType,
            style: GoogleFonts.outfit(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              labelText: widget.label,
              labelStyle: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              prefixIcon: widget.icon != null
                  ? Icon(widget.icon, color: AppColors.textTertiary, size: 18)
                  : null,
              errorText: null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 6),
            child: Text(
              _error!,
              style: GoogleFonts.outfit(color: AppColors.red, fontSize: 11),
            ),
          ),
      ],
    );
  }
}

class AppDropdownItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  final Color? color;

  const AppDropdownItem({
    required this.value,
    required this.label,
    this.icon,
    this.color,
  });
}

class AppDropdown<T> extends StatefulWidget {
  final T? value;
  final List<AppDropdownItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final IconData? prefixIcon;
  final double? width;
  final double? height;

  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    this.onChanged,
    this.hint,
    this.prefixIcon,
    this.width,
    this.height,
  });

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  late AnimationController _animCtrl;
  late Animation<double> _anim;
  final _key = GlobalKey();
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _anim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _animCtrl.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final navRender =
        Navigator.of(context).context.findRenderObject() as RenderBox;
    final topLeft = box.localToGlobal(
      Offset(0.0, box.size.height),
      ancestor: navRender,
    );
    final size = box.size;

    setState(() => _isOpen = true);
    _animCtrl.forward(from: 0);

    _overlayEntry = OverlayEntry(
      builder: (ctx) {
        if (!_animCtrl.isAnimating && _animCtrl.isDismissed)
          return const SizedBox.shrink();
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _close,
          child: Stack(
            children: [
              Container(color: Colors.transparent),
              Positioned(
                left: topLeft.dx,
                top: topLeft.dy,
                width: widget.width ?? size.width,
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, -10 * (1 - _anim.value)),
                    child: Opacity(opacity: _anim.value, child: child),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.separator),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: widget.items
                            .map((item) => _buildItem(item))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildItem(AppDropdownItem<T> item) => _DropdownItemWidget<T>(
    item: item,
    isSelected: item.value == widget.value,
    onTap: () {
      widget.onChanged?.call(item.value);
      _close();
    },
  );

  void _close() {
    _animCtrl.reverse().then((_) {
      _removeOverlay();
      if (mounted) setState(() => _isOpen = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.items
        .where((i) => i.value == widget.value)
        .firstOrNull;

    return GestureDetector(
      onTap: _toggle,
      child: Container(
        key: _key,
        constraints: (widget.width != null || widget.height != null)
            ? BoxConstraints(
                maxWidth: widget.width ?? double.infinity,
                minHeight: widget.height ?? 0,
              )
            : null,
        padding: EdgeInsets.fromLTRB(
          14,
          widget.height != null ? 0 : 12,
          14,
          widget.height != null ? 0 : 12,
        ),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.separator),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              if (widget.prefixIcon != null) ...[
                Icon(
                  widget.prefixIcon,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 10),
              ],
              if (selected?.icon != null) ...[
                Icon(
                  selected!.icon,
                  size: 18,
                  color: selected.color ?? AppColors.textTertiary,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  selected?.label ?? widget.hint ?? '',
                  style: GoogleFonts.outfit(
                    color: selected != null
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                    fontSize: 14,
                  ),
                ),
              ),
              AnimatedRotation(
                turns: _isOpen ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.expand_more_rounded,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
