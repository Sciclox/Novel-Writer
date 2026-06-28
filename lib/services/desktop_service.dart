import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'notification_service.dart';
import 'file_association_service.dart';
import 'secondary_window_service.dart';

class DesktopService {
  static final DesktopService _instance = DesktopService._internal();
  factory DesktopService() => _instance;
  DesktopService._internal();

  bool _initialized = false;
  final NotificationService _notifications = NotificationService();
  final FileAssociationService _fileAssociation = FileAssociationService();
  final SecondaryWindowService _secondaryWindows = SecondaryWindowService();

  Future<void> initialize() async {
    if (_initialized) return;

    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720),
      minimumSize: Size(850, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      doWhenWindowReady(() {
        final win = appWindow;
        win.minSize = const Size(850, 600);
        win.size = const Size(1280, 720);
        win.alignment = Alignment.center;
        win.title = 'Novel Writer';
        win.show();
      });
    }

    await _notifications.initialize();
    await _fileAssociation.initialize();
    await _secondaryWindows.initialize();

    _initialized = true;
  }

  NotificationService get notifications => _notifications;
  FileAssociationService get fileAssociation => _fileAssociation;
  SecondaryWindowService get secondaryWindows => _secondaryWindows;

  Future<void> setAppTitle(String title) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      appWindow.title = title;
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notifications.showNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }

  Future<void> showPomodoroComplete(int minutes) async {
    await _notifications.showPomodoroComplete(minutes);
  }

  Future<void> showExportComplete(String filePath) async {
    await _notifications.showExportComplete(filePath);
  }

  Future<void> showAutoSave() async {
    await _notifications.showAutoSave();
  }

  Future<void> openFileExternally(String path) async {
    if (!kIsWeb && Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', path]);
    } else if (!kIsWeb && Platform.isMacOS) {
      await Process.run('open', [path]);
    } else if (!kIsWeb && Platform.isLinux) {
      await Process.run('xdg-open', [path]);
    }
  }

  Future<void> showInFolder(String path) async {
    if (!kIsWeb && Platform.isWindows) {
      await Process.run('explorer', ['/select,', path]);
    } else if (!kIsWeb && Platform.isMacOS) {
      await Process.run('open', ['-R', path]);
    } else if (!kIsWeb && Platform.isLinux) {
      final dir = Directory(path).parent.path;
      await Process.run('xdg-open', [dir]);
    }
  }

  Future<bool> isMaximized() async {
    if (kIsWeb) return false;
    try {
      return await windowManager.isMaximized();
    } catch (_) {
      return false;
    }
  }

  Future<void> toggleMaximize() async {
    if (await isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  Future<void> minimizeWindow() async {
    if (!kIsWeb) {
      await windowManager.minimize();
    }
  }

  Future<void> closeWindow() async {
    if (!kIsWeb) {
      await windowManager.close();
    }
  }

  Future<void> setFullScreen(bool fullScreen) async {
    if (!kIsWeb) {
      await windowManager.setFullScreen(fullScreen);
    }
  }
}