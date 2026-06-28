import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class SecondaryWindowService {
  static final SecondaryWindowService _instance = SecondaryWindowService._internal();
  factory SecondaryWindowService() => _instance;
  SecondaryWindowService._internal();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
  }

  Future<void> openWindow({
    required String title,
    required Widget child,
    Size? size,
  }) async {
    if (kIsWeb || !(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) return;

    await windowManager.ensureInitialized();

    final WindowOptions windowOptions = WindowOptions(
      size: size ?? const Size(600, 400),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setTitle(title);
    });
  }

  Future<void> openPomodoroTimer() async {
    await openWindow(
      title: 'Pomodoro Timer',
      size: const Size(400, 300),
      child: _PomodoroPlaceholder(),
    );
  }

  Future<void> openResearchPanel() async {
    await openWindow(
      title: 'Investigación',
      size: const Size(600, 500),
      child: _ResearchPlaceholder(),
    );
  }

  Future<void> openOutlineView() async {
    await openWindow(
      title: 'Esquema',
      size: const Size(500, 600),
      child: _OutlinePlaceholder(),
    );
  }
}

class _PomodoroPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1C1C1E),
      child: const Center(
        child: Text(
          'Temporizador Pomodoro\n(Próximamente)',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontFamily: 'Outfit', fontSize: 16),
        ),
      ),
    );
  }
}

class _ResearchPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1C1C1E),
      child: const Center(
        child: Text(
          'Panel de Investigación\n(Próximamente)',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontFamily: 'Outfit', fontSize: 16),
        ),
      ),
    );
  }
}

class _OutlinePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1C1C1E),
      child: const Center(
        child: Text(
          'Vista de Esquema\n(Próximamente)',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontFamily: 'Outfit', fontSize: 16),
        ),
      ),
    );
  }
}