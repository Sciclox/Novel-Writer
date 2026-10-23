import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/app_theme.dart';

class CommandPaletteAction {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String? shortcut;
  final VoidCallback onPerform;

  const CommandPaletteAction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.shortcut,
    required this.onPerform,
  });
}

class CommandPaletteModal extends StatefulWidget {
  final List<CommandPaletteAction> actions;

  const CommandPaletteModal({super.key, required this.actions});

  static Future<void> show(BuildContext context, List<CommandPaletteAction> actions) async {
    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => CommandPaletteModal(actions: actions),
    );
  }

  @override
  State<CommandPaletteModal> createState() => _CommandPaletteModalState();
}

class _CommandPaletteModalState extends State<CommandPaletteModal> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _selectedIndex = 0;
  String _query = '';

  List<CommandPaletteAction> get _filteredActions {
    if (_query.trim().isEmpty) return widget.actions;
    final q = _query.toLowerCase();
    return widget.actions.where((a) {
      return a.title.toLowerCase().contains(q) || a.subtitle.toLowerCase().contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text;
        _selectedIndex = 0;
      });
    });
    Future.delayed(const Duration(milliseconds: 50), () {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _executeSelected() {
    final list = _filteredActions;
    if (list.isNotEmpty && _selectedIndex >= 0 && _selectedIndex < list.length) {
      final action = list[_selectedIndex];
      Navigator.pop(context);
      action.onPerform();
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredActions;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Center(
        child: Container(
          width: 580,
          constraints: const BoxConstraints(maxHeight: 460),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.separator),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.separator)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: AppColors.accent, size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        style: GoogleFonts.outfit(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Buscar comando, capítulo, personaje o vista...',
                          hintStyle: GoogleFonts.outfit(
                            color: AppColors.textTertiary,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (_) => _executeSelected(),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        'ESC',
                        style: GoogleFonts.jetBrainsMono(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Action list
              Flexible(
                child: list.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'No se encontraron comandos para "$_query"',
                          style: GoogleFonts.outfit(color: AppColors.textTertiary, fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final item = list[index];
                          final isSelected = index == _selectedIndex;

                          return MouseRegion(
                            cursor: SystemMouseCursors.click,
                            onEnter: (_) => setState(() => _selectedIndex = index),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                item.onPerform();
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.accent.withValues(alpha: 0.12)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.accent.withValues(alpha: 0.4)
                                        : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.accent.withValues(alpha: 0.2)
                                            : Colors.white.withValues(alpha: 0.04),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        item.icon,
                                        size: 16,
                                        color: isSelected ? AppColors.accent : AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: GoogleFonts.outfit(
                                              color: isSelected ? AppColors.accent : AppColors.textPrimary,
                                              fontSize: 14,
                                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            item.subtitle,
                                            style: GoogleFonts.outfit(
                                              color: AppColors.textTertiary,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (item.shortcut != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.white10),
                                        ),
                                        child: Text(
                                          item.shortcut!,
                                          style: GoogleFonts.jetBrainsMono(
                                            color: AppColors.textTertiary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.separator)),
                  color: AppColors.bg.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Text(
                      '↑↓ Navegar  ·  ↵ Ejecutar  ·  ESC Salir',
                      style: GoogleFonts.outfit(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Novel Writer Command Palette',
                      style: GoogleFonts.outfit(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
