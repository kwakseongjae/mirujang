import 'dart:developer' as developer;

/// 프로덕션 모드용 로깅 유틸리티
class Logger {
  static const String _appName = 'MiruApp';

  /// 정보 로그
  static void info(String message, {String? tag}) {
    developer.log(
      message,
      name: _appName,
      level: 800, // INFO level
      time: DateTime.now(),
      error: null,
      stackTrace: null,
    );
  }

  /// 경고 로그
  static void warning(String message, {String? tag}) {
    developer.log(
      message,
      name: _appName,
      level: 900, // WARNING level
      time: DateTime.now(),
      error: null,
      stackTrace: null,
    );
  }

  /// 에러 로그
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: _appName,
      level: 1000, // ERROR level
      time: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 디버그 로그 (개발 모드에서만)
  static void debug(String message, {String? tag}) {
    developer.log(
      message,
      name: _appName,
      level: 500, // DEBUG level
      time: DateTime.now(),
      error: null,
      stackTrace: null,
    );
  }

  /// 성능 측정 로그
  static void performance(String operation, Duration duration) {
    developer.log(
      'Performance: $operation took ${duration.inMilliseconds}ms',
      name: _appName,
      level: 800,
      time: DateTime.now(),
      error: null,
      stackTrace: null,
    );
  }

  /// 사용자 액션 로그
  static void userAction(String action, {Map<String, dynamic>? data}) {
    final dataStr = data != null ? ' | Data: $data' : '';
    developer.log(
      'User Action: $action$dataStr',
      name: _appName,
      level: 800,
      time: DateTime.now(),
      error: null,
      stackTrace: null,
    );
  }
}
