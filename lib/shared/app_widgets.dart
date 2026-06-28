import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget buildLoadingIndicator({Color? color}) {
  return Center(
    child: CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(color ?? const Color(0xFF00F0FF)),
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
          Icon(icon, size: 80, color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.inter(color: Colors.white30, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: GoogleFonts.inter(color: Colors.white12, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1C1C1E),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: Text(actionLabel, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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
      backgroundColor: const Color(0xFF2C2C2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          color: confirmColor ?? Colors.redAccent,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        message,
        style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            cancelLabel,
            style: GoogleFonts.inter(color: Colors.white38, fontWeight: FontWeight.w600),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: confirmColor ?? Colors.redAccent),
          child: Text(
            confirmLabel,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
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
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
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

class _ShimmerLoadingState extends State<ShimmerLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _animation = Tween<double>(begin: -1, end: 2).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine));
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
              colors: const [
                const Color(0xFF3A3A3C),
                const Color(0xFF48484A),
                const Color(0xFF3A3A3C),
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
        color: const Color(0xFF3A3A3C),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF48484A)),
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
      backgroundColor: const Color(0xFF2C2C2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          color: confirmColor ?? Colors.redAccent,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        message,
        style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(cancelLabel, style: GoogleFonts.inter(color: Colors.white38, fontWeight: FontWeight.w600)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: TextButton.styleFrom(foregroundColor: confirmColor ?? Colors.redAccent),
          child: Text(confirmLabel, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _error != null ? Colors.redAccent : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: TextField(
            controller: widget.controller,
            autofocus: widget.autofocus,
            keyboardType: widget.keyboardType,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              labelText: widget.label,
              labelStyle: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
              prefixIcon: widget.icon != null ? Icon(widget.icon, color: Colors.white38, size: 18) : null,
              errorText: null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 6),
            child: Text(
              _error!,
              style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 11),
            ),
          ),
      ],
    );
  }
}
