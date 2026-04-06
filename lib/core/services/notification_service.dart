import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:couple_app/features/tasks/data/task_model.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:couple_app/core/ui/pet_assets.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    try {
      tz.initializeTimeZones();
      String timezoneId = 'UTC';
      try {
        final timezoneInfo = await FlutterTimezone.getLocalTimezone().timeout(
          const Duration(seconds: 3),
        );
        timezoneId = timezoneInfo.identifier;
      } catch (e) {}
      tz.setLocalLocation(tz.getLocation(timezoneId));

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const settings = InitializationSettings(android: androidSettings);

      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (details) {},
      );
      _requestNotificationsPermissionAsync();
    } catch (e) {}
  }

  void _requestNotificationsPermissionAsync() {
    Future.microtask(() async {
      try {
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      } catch (e) {}
    });
  }

  // Вспомогательный метод для загрузки большой иконки уведомления
  Future<ByteArrayAndroidBitmap?> _getAppLogo() async {
    try {
      // Укажите путь к вашей иконке приложения (ту же, что для лаунчера)
      final byteData = await rootBundle.load('assets\icons\logo.png');
      return ByteArrayAndroidBitmap(byteData.buffer.asUint8List());
    } catch (_) {
      return null; // Если файл не найден, просто не будем показывать большую иконку
    }
  }

  Future<void> scheduleTaskNotification(Task task) async {
    if (task.date == null || task.reminderMinutes == null) return;

    DateTime notifyAt;
    if (task.time != null) {
      final parts = task.time!.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      notifyAt = DateTime(
        task.date!.year,
        task.date!.month,
        task.date!.day,
        hour,
        minute,
      ).subtract(Duration(minutes: task.reminderMinutes!));
    } else {
      notifyAt = DateTime(
        task.date!.year,
        task.date!.month,
        task.date!.day,
        9,
        0,
      ).subtract(Duration(minutes: task.reminderMinutes!));
    }

    final now = DateTime.now();
    final isToday =
        task.date!.day == now.day &&
        task.date!.month == now.month &&
        task.date!.year == now.year;

    if (notifyAt.isBefore(now) && !isToday) {
      return;
    } else if (notifyAt.isBefore(now) && isToday) {
      notifyAt = now.add(const Duration(seconds: 3));
    }

    final tzNotifyAt = tz.TZDateTime.from(notifyAt, tz.local);
    final reminderText = task.reminderMinutes! >= 60
        ? '${task.reminderMinutes! ~/ 60} ч'
        : '${task.reminderMinutes!} мин';

    final fullMessage =
        '${task.title} — через $reminderText${task.time != null ? ' (${task.time})' : ''}';

    // ЗАГРУЖАЕМ ЛОГОТИП
    final logo = await _getAppLogo();

    await _plugin.zonedSchedule(
      task.id.hashCode.abs(),
      '📋 Напоминание',
      fullMessage,
      tzNotifyAt,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Напоминания о задачах',
          channelDescription: 'Уведомления о предстоящих задачах',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFF16001), // Ваш оранжевый цвет
          largeIcon: logo, // ДОБАВЛЕНА БОЛЬШАЯ ИКОНКА
          styleInformation: BigTextStyleInformation(
            // ДОБАВЛЕН РАЗВЕРНУТЫЙ ТЕКСТ
            fullMessage,
            htmlFormatBigText: true,
            contentTitle: '<b>📋 Напоминание</b>',
            htmlFormatContentTitle: true,
          ),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> showPetReminder({
    required String petName,
    String? petId,
    String? taskTitle,
  }) async {
    ByteArrayAndroidBitmap? petBitmap;
    try {
      final path = PetAssets.sadImage(petId);
      final byteData = await rootBundle.load(path);
      petBitmap = ByteArrayAndroidBitmap(byteData.buffer.asUint8List());
    } catch (_) {}

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      '$petName скучает',
      taskTitle != null
          ? '$petName скучает, выполни задачу: «$taskTitle»!'
          : '$petName скучает, выполни задачу!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'pet_reminders',
          'Напоминания от питомца',
          channelDescription: 'Питомец напоминает о задачах',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFE8622A),
          largeIcon: petBitmap,
          styleInformation: petBitmap != null
              ? BigPictureStyleInformation(
                  petBitmap,
                  hideExpandedLargeIcon: true,
                )
              : null,
        ),
      ),
    );
  }

  Future<void> cancelTaskNotification(String taskId) async {
    await _plugin.cancel(taskId.hashCode.abs());
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> showInstant({
    required String title,
    required String body,
  }) async {
    final logo = await _getAppLogo();
    await _plugin.show(
      0,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'instant',
          'Мгновенные уведомления',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFF16001),
          largeIcon: logo,
        ),
      ),
    );
  }
}
