import 'package:shared_preferences/shared_preferences.dart';

class FirstRunService {
  static const String _firstRunKey = 'is_first_run';

  /// 최초 실행 여부를 확인합니다.
  static Future<bool> isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstRunKey) ?? true; // 기본값은 true (최초 실행)
  }

  /// 최초 실행 완료를 표시합니다.
  static Future<void> setFirstRunCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstRunKey, false);
    await prefs.setBool('is_first_run', false); // 알림 서비스에서 참조
  }

  /// 최초 실행 상태를 리셋합니다. (개발/테스트용)
  static Future<void> resetFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_firstRunKey);
    await prefs.remove('is_first_run');
  }
}
