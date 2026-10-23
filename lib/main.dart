import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'shared/app_theme.dart';
import 'shared/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'screens/home_screen.dart';
import 'database/app_database.dart';
import 'widgets/custom_title_bar.dart';
import 'widgets/drop_zone.dart';
import 'services/desktop_service.dart';
import 'services/app_shortcuts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.database;

  final desktop = DesktopService();
  await desktop.initialize();

  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    doWhenWindowReady(() {
      final win = appWindow;
      win.minSize = const Size(850, 600);
      win.size = const Size(1280, 720);
      win.alignment = Alignment.center;
      win.title = 'Novel Writer';
      win.maximize();
      win.show();
    });
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  bool _isFullScreen = false;

  HomeScreenState? get _homeState => _homeKey.currentState;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Shortcuts(
      shortcuts: {
        AppShortcuts.ctrl(LogicalKeyboardKey.keyN): _NewProjectIntent(),
        AppShortcuts.ctrl(LogicalKeyboardKey.keyO): _OpenProjectIntent(),
        AppShortcuts.ctrl(LogicalKeyboardKey.keyS): _SaveIntent(),
        AppShortcuts.ctrl(LogicalKeyboardKey.keyE): _ExportIntent(),
        AppShortcuts.ctrl(LogicalKeyboardKey.keyF): _SearchIntent(),
        AppShortcuts.ctrlShift(LogicalKeyboardKey.keyS): _SaveAsIntent(),
        AppShortcuts.ctrl(LogicalKeyboardKey.keyZ): _UndoIntent(),
        AppShortcuts.ctrlShift(LogicalKeyboardKey.keyZ): _RedoIntent(),
        AppShortcuts.only(LogicalKeyboardKey.f11): _ToggleFullScreenIntent(),
      },
      child: Actions(
        actions: {
          _NewProjectIntent: _NewProjectAction(this),
          _OpenProjectIntent: _OpenProjectAction(this),
          _SaveIntent: _SaveAction(this),
          _ExportIntent: _ExportAction(this),
          _SearchIntent: _SearchAction(),
          _SaveAsIntent: _SaveAsAction(this),
          _UndoIntent: _UndoAction(),
          _RedoIntent: _RedoAction(),
          _ToggleFullScreenIntent: _ToggleFullScreenAction(this),
        },
        child: MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'Novel Writer',
          debugShowCheckedModeBanner: false,
          theme: AppColors.lightTheme,
          darkTheme: AppColors.darkTheme,
          themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('es', 'ES'),
          ],
          home: DropZone(
            onFileDropped: (path) {
              if (path.endsWith('.nwproj')) {
                _homeKey.currentState?.importarDesdeArchivo(path);
              }
            },
            child: HomeScreen(key: _homeKey),
          ),
          builder: (context, child) {
            if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
              return Scaffold(
                body: WindowBorder(
                  color: AppColors.bg,
                  child: Column(
                    children: [
                      const CustomTitleBar(),
                      Expanded(child: child ?? const SizedBox()),
                    ],
                  ),
                ),
              );
            }
            return child ?? const SizedBox();
          },
        ),
      ),
    );
  }

  Future<void> _toggleFullScreen() async {
    if (_isFullScreen) {
      await windowManager.setFullScreen(false);
    } else {
      await windowManager.setFullScreen(true);
    }
    setState(() => _isFullScreen = !_isFullScreen);
  }
}

// Intent classes
class _NewProjectIntent extends Intent {}
class _OpenProjectIntent extends Intent {}
class _SaveIntent extends Intent {}
class _ExportIntent extends Intent {}
class _SearchIntent extends Intent {}
class _SaveAsIntent extends Intent {}
class _UndoIntent extends Intent {}
class _RedoIntent extends Intent {}
class _ToggleFullScreenIntent extends Intent {}

// Action classes
class _NewProjectAction extends Action<_NewProjectIntent> {
  final _MyAppState state;
  _NewProjectAction(this.state);
  @override
  void invoke(_NewProjectIntent intent) => state._homeState?.onNewProject?.call();
}

class _OpenProjectAction extends Action<_OpenProjectIntent> {
  final _MyAppState state;
  _OpenProjectAction(this.state);
  @override
  void invoke(_OpenProjectIntent intent) => state._homeState?.onOpenProject?.call();
}

class _SaveAction extends Action<_SaveIntent> {
  final _MyAppState state;
  _SaveAction(this.state);
  @override
  void invoke(_SaveIntent intent) => state._homeState?.onSave?.call();
}

class _ExportAction extends Action<_ExportIntent> {
  final _MyAppState state;
  _ExportAction(this.state);
  @override
  void invoke(_ExportIntent intent) => state._homeState?.onExport?.call();
}

class _SearchAction extends Action<_SearchIntent> {
  @override
  void invoke(_SearchIntent intent) {}
}

class _SaveAsAction extends Action<_SaveAsIntent> {
  final _MyAppState state;
  _SaveAsAction(this.state);
  @override
  void invoke(_SaveAsIntent intent) {}
}

class _UndoAction extends Action<_UndoIntent> {
  @override
  void invoke(_UndoIntent intent) {}
}

class _RedoAction extends Action<_RedoIntent> {
  @override
  void invoke(_RedoIntent intent) {}
}

class _ToggleFullScreenAction extends Action<_ToggleFullScreenIntent> {
  final _MyAppState state;
  _ToggleFullScreenAction(this.state);
  @override
  void invoke(_ToggleFullScreenIntent intent) => state._toggleFullScreen();
}
