enum MiruTaskStatus {
  noNotification, // 1. 알림 없음
  notificationScheduled, // 2. 알림 있음 - 시간 설정 O
  notificationPaused, // 3. 알림 있음 - 시간 설정 O - 알림 off 상태
  notificationCompleted, // 4. 알림 완료 (시간이 지나서 알림이 완료된 상태)
}

class MiruTask {
  final String id;
  String title; // 미루기 타이틀 (30글자 이내)
  String memo; // 메모
  final DateTime createdAt;
  DateTime? notificationTime;
  bool hasNotification;
  bool isEnabled; // 알림 활성화 여부 (토글)
  bool isCompleted; // 알림 완료 여부
  DateTime? completedAt; // 완료 처리 시점

  MiruTask({
    required this.id,
    required this.title,
    required this.memo,
    required this.createdAt,
    this.notificationTime,
    required this.hasNotification,
    this.isEnabled = true,
    this.isCompleted = false,
    this.completedAt,
  });

  // JSON 변환 메서드
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'memo': memo,
      'createdAt': createdAt.toIso8601String(),
      'notificationTime': notificationTime?.toIso8601String(),
      'hasNotification': hasNotification,
      'isEnabled': isEnabled,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  // JSON에서 객체 생성
  factory MiruTask.fromJson(Map<String, dynamic> json) {
    return MiruTask(
      id: json['id'],
      title: json['title'] ?? '', // 기본값 빈 문자열 (기존 데이터 호환성)
      memo: json['memo'],
      createdAt: DateTime.parse(json['createdAt']),
      notificationTime: json['notificationTime'] != null
          ? DateTime.parse(json['notificationTime'])
          : null,
      hasNotification: json['hasNotification'],
      isEnabled: json['isEnabled'] ?? true, // 기본값 true
      isCompleted: json['isCompleted'] ?? false, // 기본값 false
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null, // 기존 데이터 호환성을 위해 null 허용
    );
  }

  // 현재 상태를 반환하는 메서드
  MiruTaskStatus get status {
    // 1. 알림 없음
    if (!hasNotification) {
      return MiruTaskStatus.noNotification;
    }

    // 완료된 작업은 히스토리로 이동하므로 여기서는 처리하지 않음

    // 4. 알림 완료 상태 (알림 시간이 지났고 isEnabled가 false인 경우)
    if (notificationTime != null && !isEnabled) {
      final now = DateTime.now();
      if (notificationTime!.isBefore(now)) {
        return MiruTaskStatus.notificationCompleted;
      }
    }

    // 2. 알림 있음 - 시간 설정 O - isEnabled가 true (재설정된 경우도 포함)
    if (isEnabled) {
      return MiruTaskStatus.notificationScheduled;
    }

    // 3. 알림 있음 - 시간 설정 O - 알림 off 상태 - isEnabled가 false (시간이 아직 안 지남)
    return MiruTaskStatus.notificationPaused;
  }

  // 상태에 따른 텍스트를 반환하는 메서드
  String getTimeUntilNotification() {
    switch (status) {
      case MiruTaskStatus.noNotification:
        return '알림 없음';

      case MiruTaskStatus.notificationScheduled:
        return _getTimeText();

      case MiruTaskStatus.notificationPaused:
        return _getTimeText();

      case MiruTaskStatus.notificationCompleted:
        return '알림 완료';
    }
  }

  // 시간 텍스트를 계산하는 메서드
  String _getTimeText() {
    if (notificationTime == null) return '알림 없음';

    // 분 단위까지 동일한 기준으로 계산하여 화면 간 일관성 유지 (초 무시)
    final now = DateTime.now();
    final nowNormalized = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );

    final difference = notificationTime!.difference(nowNormalized);

    if (difference.isNegative) {
      // 알림 시간이 지났으면 "알림 완료" 표시
      return '알림 완료';
    }

    final totalMinutes = difference.inMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours == 0) {
      if (minutes == 0) {
        return '1분 이내에 알림을 받아요';
      }
      return '$minutes분 후에 알림을 받아요';
    }

    return '$hours시간 $minutes분 후에 알림을 받아요';
  }

  // 가운데선이 필요한지 확인하는 메서드 (시간 정보에만 적용)
  bool get needsStrikethrough {
    // 알림 시간이 지났으면 취소선 없음 (알림 완료 상태)
    if (hasNotification && notificationTime != null && !isEnabled) {
      final now = DateTime.now();
      if (notificationTime!.isBefore(now)) {
        return false; // 알림 완료 - 취소선 없음
      }
    }

    // 사용자가 수동으로 토글을 Off한 경우에만 취소선 표시
    return status == MiruTaskStatus.notificationPaused;
  }

  // 알림 시간이 지났는지 확인
  bool get isNotificationOverdue {
    if (!hasNotification || notificationTime == null) {
      return false;
    }
    return DateTime.now().isAfter(notificationTime!);
  }
}
