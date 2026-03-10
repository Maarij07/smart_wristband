import 'dart:io';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Manages the Android foreground service that keeps BLE alive in background.
/// On iOS this is a no-op — iOS uses bluetooth-central background mode instead.
class BleForegroundService {
  static bool _initialized = false;

  /// Call once at app start (before runApp) to configure the notification channel.
  static void init() {
    if (!Platform.isAndroid) return;
    if (_initialized) return;
    _initialized = true;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'ble_wristband_channel',
        channelName: 'Wristband Connection',
        channelDescription:
            'Keeps your Status Band wristband connected in the background',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  /// Start the persistent foreground notification.
  /// Safe to call multiple times — skips if already running.
  static Future<void> start() async {
    if (!Platform.isAndroid) return;
    if (await FlutterForegroundTask.isRunningService) return;

    // Request notification permission on Android 13+ (API 33+).
    // This is required for the persistent notification to be shown.
    final notifPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notifPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'Status Band',
      notificationText: 'Wristband connected',
    );
  }

  /// Update the notification text (e.g. to show device name).
  static Future<void> updateNotification(String deviceName) async {
    if (!Platform.isAndroid) return;
    if (!await FlutterForegroundTask.isRunningService) return;

    await FlutterForegroundTask.updateService(
      notificationTitle: 'Status Band',
      notificationText: 'Connected to $deviceName',
    );
  }

  /// Stop the foreground notification.
  static Future<void> stop() async {
    if (!Platform.isAndroid) return;
    if (!await FlutterForegroundTask.isRunningService) return;

    await FlutterForegroundTask.stopService();
  }
}
