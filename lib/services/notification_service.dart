import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('app_icon');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const LinuxInitializationSettings linuxSettings = LinuxInitializationSettings(defaultActionName: 'Open');
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      linux: linuxSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    if (!kIsWeb) {
      await _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap if needed
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'novel_writer',
      'Novel Writer',
      channelDescription: 'Notificaciones de la app Novel Writer',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'app_icon',
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const LinuxNotificationDetails linuxDetails = LinuxNotificationDetails(
      defaultActionName: 'Open',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      linux: linuxDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<void> showPomodoroComplete(int minutes) async {
    await showNotification(
      title: '¡Pomodoro Completado!',
      body: 'Has mantenido la concentración durante $minutes minutos. Es hora de un breve descanso.',
      payload: 'pomodoro_complete',
    );
  }

  Future<void> showExportComplete(String filePath) async {
    await showNotification(
      title: 'Exportación Completada',
      body: 'Tu manuscrito se ha exportado correctamente.',
      payload: 'export_complete:$filePath',
    );
  }

  Future<void> showAutoSave() async {
    await showNotification(
      title: 'Auto-guardado',
      body: 'Tus cambios se han guardado automáticamente.',
      payload: 'auto_save',
    );
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}