import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/miru_task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // 알림 서비스 초기화
  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // iOS 알림 권한 요청
    await _requestPermissions();
  }

  // 알림 권한 요청
  Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // 알림 탭 처리
  void _onNotificationTapped(NotificationResponse response) {
    // 알림 탭 시 처리 로직 (필요시 구현)
    print('알림 탭됨: ${response.payload}');
  }

  // 미루기 작업 알림 예약
  Future<void> scheduleNotification(MiruTask task) async {
    if (!task.hasNotification ||
        task.notificationTime == null ||
        !task.isEnabled) {
      return;
    }

    final now = DateTime.now();
    if (task.notificationTime!.isBefore(now)) {
      return; // 과거 시간이면 알림 예약하지 않음
    }

    // 미루기 알림장 특유의 UX 라이팅 생성
    final notificationContent = _generateNotificationContent(task);

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'miru_notifications',
          '미루기 알림',
          channelDescription: '미루기 작업 알림 채널',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_launcher',
          largeIcon: const DrawableResourceAndroidBitmap(
            '@drawable/ic_launcher',
          ),
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          color: const Color(0xFF1976D2), // 앱 테마 색상
          ledColor: const Color(0xFF1976D2),
          ledOnMs: 1000,
          ledOffMs: 500,
        );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
      presentBanner: true,
      presentList: true,
      sound: 'default',
      categoryIdentifier: 'miru_notifications',
      threadIdentifier: 'miru_task_${task.id}',
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      task.id.hashCode, // 고유한 ID
      notificationContent['title'], // 미루기 특유의 제목
      notificationContent['body'], // 미루기 특유의 내용
      tz.TZDateTime.from(task.notificationTime!, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: task.id,
    );
  }

  // 미루기 알림장 특유의 UX 라이팅 생성
  Map<String, String> _generateNotificationContent(MiruTask task) {
    final title = task.title;
    final memo = task.memo;

    // 제목이 20자 이상이면 줄임
    final shortTitle = title.length > 20
        ? '${title.substring(0, 20)}...'
        : title;

    // 미루기 알림장 특유의 제목 생성
    final notificationTitle = '미루기 시간이에요! 📝';

    // 미루기 알림장 특유의 내용 생성
    String notificationBody;
    if (memo.isNotEmpty) {
      // 메모가 있는 경우
      final shortMemo = memo.length > 30 ? '${memo.substring(0, 30)}...' : memo;
      notificationBody = '"$shortTitle"을(를) 미루고 계셨죠?\n$shortMemo';
    } else {
      // 메모가 없는 경우
      notificationBody = '"$shortTitle"을(를) 미루고 계셨죠?\n이제 처리할 시간이에요! 💪';
    }

    return {'title': notificationTitle, 'body': notificationBody};
  }

  // 알림 취소
  Future<void> cancelNotification(String taskId) async {
    await _notifications.cancel(taskId.hashCode);
  }

  // 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // 예약된 알림 목록 확인
  Future<List<dynamic>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
