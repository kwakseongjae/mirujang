import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'app.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // timezone 초기화
  tz.initializeTimeZones();

  // 알림 서비스 초기화
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(const MirugangApp());
}
