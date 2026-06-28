import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';

class DropZone extends StatefulWidget {
  final Widget child;
  final void Function(String path)? onFileDropped;
  final void Function(List<String> paths)? onFilesDropped;

  const DropZone({
    super.key,
    required this.child,
    this.onFileDropped,
    this.onFilesDropped,
  });

  @override
  State<DropZone> createState() => _DropZoneState();
}

class _DropZoneState extends State<DropZone> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

    if (!isDesktop) return widget.child;

    return DropTarget(
      onDragDone: (detail) {
        setState(() => _isDragging = false);
        final paths = detail.files.map((f) => f.path).toList();
        widget.onFilesDropped?.call(paths);
        if (paths.length == 1) {
          widget.onFileDropped?.call(paths.first);
        }
      },
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      child: Stack(
        children: [
          widget.child,
          if (_isDragging)
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      color: Colors.white,
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Suelta los archivos aquí',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}