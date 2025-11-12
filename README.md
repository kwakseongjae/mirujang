![미루장](./assets/images/miru_thumbnail.png)

# 🦥 미루장 

## 갓생을 위한 나만의 미루기 메모장

미룬 일을 놓치지 않고 처리할 수 있게 도와주는 똑똑한 할 일 관리 앱입니다.  
하기 싫거나 지금 할 수 없는 일을 효율적으로 미루고, 결국 놓치지 않고 처리할 수 있게 도와드립니다.

🔗 **앱 다운로드**: [App Store에서 다운로드](https://apps.apple.com/kr/app/%EB%AF%B8%EB%A3%A8%EC%9E%A5-%EA%B0%93%EC%83%9D%EC%9D%84-%EC%9C%84%ED%95%9C-%EB%82%98%EB%A7%8C%EC%9D%98-%EB%AF%B8%EB%A3%A8%EA%B8%B0-%EB%A9%94%EB%AA%A8%EC%9E%A5/id6753706803)

## 프로젝트 소개

### 🎯 왜 미루장을 만들었나요?

일상에서 "나중에 하자", "시간이 있을 때 하자"라고 미루는 일들이 많습니다. 하지만 미룬 일들은 결국 잊혀지거나 우선순위에서 밀려나게 되죠. 특히 저는 일에 집중하기 시작하면 다른 일이 들어와도 일단 메모장에 적어놓고 지금 하고 있는 일에 집중하는 편입니다. 그러다가 해야할 일을 까먹는 경우가 많았어요 🥲 <br>미루장은 저의 이러한 개인적 경험을 바탕으로, **미룬 일도 놓치지 않는 똑똑한 관리**를 통해 사용자들이 체계적으로 할 일을 관리할 수 있도록 도와주는 어플입니다.

### 🚀 주요 기능

- **똑똑한 알림 시스템**: 할 일을 등록하면 설정한 시간에 알림을 보내고, 다시 미루고 싶다면 알람 재설정이 가능합니다
- **할 일 관리**: 등록, 수정, 삭제, 완료 표시까지 한 앱에서 간편하게 관리
- **미루장 캐릭터**: 귀여운 미루장 캐릭터와 함께하는 재미있는 할 일 관리 경험
- **가이드 시스템**: 4단계 가이드로 앱 사용법을 쉽게 배울 수 있습니다
- **다크모드 지원**: 라이트모드와 다크모드를 선택할 수 있으며, 시스템 설정과 자동 연동됩니다
- **히스토리 관리**: 완료된 할 일들을 히스토리에서 확인할 수 있습니다

## 기술 스택

### Frontend

<img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white">
<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white">

### Backend & Storage

<img src="https://img.shields.io/badge/Shared_Preferences-4285F4?style=for-the-badge&logo=google&logoColor=white">
<img src="https://img.shields.io/badge/Local_Notifications-FF6B6B?style=for-the-badge&logo=flutter&logoColor=white">

### Development Tools

<img src="https://img.shields.io/badge/Cursor_AI-000000?style=for-the-badge&logo=cursor&logoColor=white">
<img src="https://img.shields.io/badge/Shorebird-00D4AA?style=for-the-badge&logo=flutter&logoColor=white">

## 성과 및 최적화

### 🎯 사용자 경험 개선

1. **직관적인 UI/UX**

   - Material Design 3 기반의 모던한 디자인
   - Pretendard 폰트를 활용한 가독성 향상
   - 미루장 캐릭터를 통한 친근한 사용자 경험

2. **알림 시스템 최적화**

   - 로컬 알림을 통한 즉각적인 알림 제공
   - 알림 재설정 기능으로 유연한 일정 관리
   - 시스템 알림과의 완벽한 연동

3. **성능 최적화**
   - SharedPreferences를 활용한 효율적인 로컬 데이터 관리
   - 앱 생명주기 관리로 배터리 최적화
   - 화면 회전 제한으로 일관된 사용자 경험

## 프로젝트 구조

```
mirujang/
├── lib/
│   ├── main.dart                 # 앱 진입점
│   ├── app.dart                  # 메인 앱 위젯
│   ├── models/                   # 데이터 모델
│   │   └── miru_task.dart        # 미루기 작업 모델
│   ├── presentation/             # UI 레이어
│   │   └── views/                # 화면별 뷰
│   │       ├── home/             # 홈 화면
│   │       ├── create/           # 할 일 생성
│   │       ├── edit/             # 할 일 수정
│   │       ├── detail/           # 할 일 상세
│   │       ├── history/          # 히스토리
│   │       ├── guide/            # 가이드
│   │       ├── settings/         # 설정
│   │       └── splash/           # 스플래시
│   ├── services/                 # 비즈니스 로직
│   │   ├── storage_service.dart  # 데이터 저장
│   │   ├── notification_service.dart # 알림 관리
│   │   ├── theme_service.dart    # 테마 관리
│   │   └── first_run_service.dart # 첫 실행 관리
│   └── theme/                    # 테마 설정
├── assets/                       # 정적 자원
│   ├── images/                   # 이미지 파일
│   └── fonts/                    # 폰트 파일
└── pubspec.yaml                  # 프로젝트 설정
```

## 설치 및 실행

```bash
# Flutter SDK 설치 (3.9.2 이상)
# https://flutter.dev/docs/get-started/install

# 의존성 설치
flutter pub get

# 개발 서버 실행
flutter run

# 릴리즈 빌드(현재는 iOS만 제공)
flutter build ios --release
```

### 개발 환경 설정

1. **Flutter SDK 설치**

   - Flutter 3.9.2 이상 필요
   - Dart SDK 자동 포함

2. **플랫폼별 설정**

   - iOS: Xcode 및 iOS SDK (macOS에서만)

3. **의존성 관리**
   - `shared_preferences`: 로컬 데이터 저장
   - `flutter_local_notifications`: 로컬 알림
   - `url_launcher`: 외부 링크 열기
   - `flutter_email_sender`: 이메일 전송

### 💡 앞으로의 계획

1. **상태 관리 최적화**

   - 현재: Provider 패턴을 활용한 상태 관리
   - 향후 계획: Riverpod으로 상태 관리 시스템 고도화 예정

2. **크로스 플랫폼 호환성**

   - 현재는 iOS만 제공하고 있지만, Android 서비스도 개발할 예정
   - 플랫폼별 네이티브 기능 최적화

3. **앱 배포 및 업데이트**
   - Shorebird를 활용한 긴급 배포 파이프라인 구축
   - App Store 배포를 통한 안정적인 서비스 제공

## Contact

**이메일**: gkffhdnls13@gmail.com  
**GitHub**: [@kwakseongjae](https://github.com/kwakseongjae)  
**블로그**: [lambda-log.tistory.com](https://lambda-log.tistory.com)


