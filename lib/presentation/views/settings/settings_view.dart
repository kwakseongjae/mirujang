import 'package:flutter/material.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '설정',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 알림 설정 섹션
          _buildSection(context, '알림 설정', [
            _buildSettingItem(
              context,
              icon: Icons.notifications_rounded,
              title: '알림 허용',
              subtitle: '앱 알림을 받을 수 있습니다',
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  // 알림 설정 로직
                },
              ),
            ),
            _buildSettingItem(
              context,
              icon: Icons.schedule_rounded,
              title: '기본 알림 시간',
              subtitle: '새로운 일정의 기본 알림 시간',
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                // 기본 알림 시간 설정 페이지로 이동
              },
            ),
          ]),

          const SizedBox(height: 24),

          // 앱 정보 섹션
          _buildSection(context, '앱 정보', [
            _buildSettingItem(
              context,
              icon: Icons.info_rounded,
              title: '앱 버전',
              subtitle: '1.0.0',
            ),
            _buildSettingItem(
              context,
              icon: Icons.privacy_tip_rounded,
              title: '개인정보 처리방침',
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                // 개인정보 처리방침 페이지로 이동
              },
            ),
            _buildSettingItem(
              context,
              icon: Icons.description_rounded,
              title: '이용약관',
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                // 이용약관 페이지로 이동
              },
            ),
          ]),

          const SizedBox(height: 24),

          // 지원 섹션
          _buildSection(context, '지원', [
            _buildSettingItem(
              context,
              icon: Icons.help_rounded,
              title: '도움말',
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                // 도움말 페이지로 이동
              },
            ),
            _buildSettingItem(
              context,
              icon: Icons.feedback_rounded,
              title: '피드백 보내기',
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                // 피드백 페이지로 이동
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.7)
                  : Colors.black.withOpacity(0.7),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1C1C1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.6)
                            : Colors.black.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing],
          ],
        ),
      ),
    );
  }
}
