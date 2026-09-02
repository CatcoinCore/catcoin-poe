import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInit = false;

  Future<void> init() async {
    if (_isInit) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    const DarwinInitializationSettings initializationSettingsMacOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const WindowsInitializationSettings initializationSettingsWindows =
        WindowsInitializationSettings(
      appName: 'Catcoin PoE',
      appUserModelId: 'org.catcoin.cat_poe',
      guid: '00000000-0000-0000-0000-000000000000',
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      macOS: initializationSettingsMacOS,
      linux: initializationSettingsLinux,
      windows: initializationSettingsWindows,
    );

    await _notificationsPlugin.initialize(settings: initializationSettings);

    // Request Android 13+ permission
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
    }

    _isInit = true;
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  Future<String> _getImageFilePath(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final fileName = assetPath.split('/').last;
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    return file.path;
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? imageAssetPath,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return;

    String? localImagePath;
    if (imageAssetPath != null) {
      try {
        localImagePath = await _getImageFilePath(imageAssetPath);
      } catch (e) {
        debugPrint('Failed to load notification image: $e');
      }
    }

    BigPictureStyleInformation? bigPictureStyleInformation;
    List<DarwinNotificationAttachment>? iosAttachments;

    if (localImagePath != null) {
      bigPictureStyleInformation = BigPictureStyleInformation(
        FilePathAndroidBitmap(localImagePath),
        hideExpandedLargeIcon: true,
        contentTitle: title,
        summaryText: body,
      );
      iosAttachments = [DarwinNotificationAttachment(localImagePath)];
    }

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'catcoin_poe_channel',
      'Catcoin Reminders',
      channelDescription: 'Reminders for mining and rewards',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: bigPictureStyleInformation,
    );

    final DarwinNotificationDetails darwinPlatformChannelSpecifics =
        DarwinNotificationDetails(
      attachments: iosAttachments,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics,
    );

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> scheduleSmartReminders({
    required bool isMining,
    required bool canTimeBoost,
    required bool canBoostRef,
    required int pendingMissions,
    required Duration timeLeft,
  }) async {
    await cancelAll();

    List<String> pendingActions = [];
    if (!isMining) pendingActions.add("Mining stopped");
    if (canTimeBoost) pendingActions.add("Unused time boosts");
    if (canBoostRef) pendingActions.add("Unused referral boosts");
    if (pendingMissions > 0) {
      pendingActions.add("$pendingMissions pending missions");
    }

    final prefs = await SharedPreferences.getInstance();

    if (pendingActions.isEmpty) {
      await prefs.remove('smart_reminder_actions');
      await prefs.remove('smart_reminder_ref_time');
    } else {
      final currentActionsStr = pendingActions.join('|');
      final lastActionsStr = prefs.getString('smart_reminder_actions');
      DateTime refTime;

      if (currentActionsStr != lastActionsStr) {
        refTime = DateTime.now();
        await prefs.setString(
            'smart_reminder_ref_time', refTime.toIso8601String());
        await prefs.setString('smart_reminder_actions', currentActionsStr);
      } else {
        final refTimeStr = prefs.getString('smart_reminder_ref_time');
        refTime =
            refTimeStr != null ? DateTime.parse(refTimeStr) : DateTime.now();
        // Reset if it's way in the past (e.g. older than 12 hours)
        if (DateTime.now().difference(refTime).inHours > 12) {
          refTime = DateTime.now();
          await prefs.setString(
              'smart_reminder_ref_time', refTime.toIso8601String());
        }
      }

      final now = DateTime.now();
      final intervals = [2, 4, 8, 12];

      for (int i = 0; i < intervals.length; i++) {
        final hours = intervals[i];
        final scheduledTime = refTime.add(Duration(hours: hours));

        // Skip if this interval has already passed relative to now
        if (scheduledTime.isBefore(now)) continue;

        String title = "Catcoin Reminders";
        String body = "";
        String image = "";

        if (!isMining) {
          title = "Start Mining!";
          body = "${pendingActions.join(', ')}. Start mining now to earn!";
          image = i == 0 ? "mining_remind_1.png" : "mining_remind_3.png";
        } else if (canTimeBoost || canBoostRef) {
          if (scheduledTime.isBefore(now.add(timeLeft))) {
            title = "Boosts Available!";
            body = "You have unused bonuses. Activate them now!";
            image = i == 0 ? "mining_remind_1.png" : "mining_remind_2.png";
          } else {
            continue;
          }
        } else if (pendingMissions > 0) {
          if (scheduledTime.isBefore(now.add(timeLeft))) {
            title = "Missions Ready!";
            body = "Complete tasks to earn massive Catoshi!";
            // 3. Missions (Approximating based on reminder depth for now)
            // First: boost_remind_1 (normal), Second: boost_remind_2 (high), Third+: boost_remind_3 (ultra)
            image = i == 0
                ? "boost_remind_1.png"
                : (i == 1 ? "boost_remind_2.png" : "boost_remind_3.png");
          } else {
            continue;
          }
        } else {
          continue;
        }

        await scheduleNotification(
          id: 10 + i,
          title: title,
          body: body,
          scheduledDate: scheduledTime,
          imageAssetPath: 'assets/images/$image',
        );
      }
    }

    if (isMining && timeLeft.inSeconds > 0) {
      final sessionEndTimeLocal = DateTime.now().add(timeLeft);
      await scheduleNotification(
        id: 50,
        title: 'Mining Stopped!',
        body: 'Your mining session has completed. Restart now!',
        scheduledDate: sessionEndTimeLocal,
        imageAssetPath: 'assets/images/mining_remind_2.png',
      );

      await scheduleNotification(
        id: 51,
        title: 'Start Mining!',
        body: 'You are missing out on coins! Restart your mining session.',
        scheduledDate: sessionEndTimeLocal.add(const Duration(hours: 4)),
        imageAssetPath: 'assets/images/mining_remind_3.png',
      );
    }
  }
}


