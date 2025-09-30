import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/miru_task.dart';
import '../utils/logger.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _notificationEnabledKey = 'notification_enabled';
  bool _isNotificationEnabled = true;

  // 알림 서비스 초기화
  Future<void> initialize() async {
    // 먼저 저장된 알림 설정 로드
    await _loadNotificationSettings();

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
    await requestPermissions();
  }

  // 알림 권한 요청
  Future<void> requestPermissions() async {
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
    Logger.userAction(
      'Notification tapped',
      data: {'payload': response.payload},
    );
    // 알림 탭 시 처리 로직 (필요시 구현)
  }

  // 미루기 작업 알림 예약
  Future<void> scheduleNotification(MiruTask task) async {
    if (!task.hasNotification ||
        task.notificationTime == null ||
        !task.isEnabled) {
      return;
    }

    // 알림 설정이 비활성화된 경우에만 차단
    if (!_isNotificationEnabled) {
      Logger.info(
        'Notification scheduling skipped: global notification disabled',
      );
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
          importance: Importance.max, // 최고 중요도
          priority: Priority.max, // 최고 우선순위
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
          showWhen: true,
          when: task.notificationTime!.millisecondsSinceEpoch,
          usesChronometer: false,
          timeoutAfter: 0, // 타임아웃 없음
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

    // 정확한 시간으로 알림 스케줄링
    final scheduledTime = tz.TZDateTime.from(task.notificationTime!, tz.local);

    await _notifications.zonedSchedule(
      task.id.hashCode, // 고유한 ID
      notificationContent['title'], // 미루기 특유의 제목
      notificationContent['body'], // 미루기 특유의 내용
      scheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: task.id,
      matchDateTimeComponents: DateTimeComponents.time, // 정확한 시간 매칭
    );

    Logger.userAction(
      'Notification scheduled',
      data: {
        'taskId': task.id,
        'title': task.title,
        'scheduledTime': task.notificationTime?.toIso8601String(),
      },
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

  // 알림 설정 로드
  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedValue = prefs.getBool(_notificationEnabledKey);
    _isNotificationEnabled = savedValue ?? true; // 저장된 값이 없으면 기본값 true
  }

  // 알림 설정 저장
  Future<void> _saveNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationEnabledKey, _isNotificationEnabled);
      Logger.userAction(
        'Notification settings saved',
        data: {'enabled': _isNotificationEnabled},
      );
    } catch (e) {
      Logger.error('Failed to save notification settings', error: e);
    }
  }

  // 알림 활성화/비활성화
  Future<void> setNotificationEnabled(bool enabled) async {
    _isNotificationEnabled = enabled;
    await _saveNotificationSettings();

    if (!enabled) {
      // 알림 비활성화 시 모든 예약된 알림 취소
      await cancelAllNotifications();
    }
  }

  // 알림 활성화 상태 확인
  bool get isNotificationEnabled => _isNotificationEnabled;

  // 알림 설정 리셋 (디버깅용)
  Future<void> resetNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationEnabledKey);
    _isNotificationEnabled = true;
  }
}
