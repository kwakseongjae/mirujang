import 'package:flutter/material.dart';
import '../../../services/theme_service.dart';

class ThemeSettingsView extends StatefulWidget {
  const ThemeSettingsView({super.key});

  @override
  State<ThemeSettingsView> createState() => _ThemeSettingsViewState();
}

class _ThemeSettingsViewState extends State<ThemeSettingsView> {
  final ThemeService _themeService = ThemeService();
  String _selectedTheme = 'auto'; // auto, light, dark

  @override
  void initState() {
    super.initState();
    _loadCurrentTheme();
  }

  void _loadCurrentTheme() {
    _selectedTheme = _themeService.currentThemeString;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '테마 설정',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 테마 옵션들을 하나의 박스에
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2D3748) // 다크모드용 pale slate
                    : const Color(0xFFF7FAFC), // 라이트모드용 pale slate
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1),
                ),
              ),
              child: Column(
                children: [
                  _buildThemeOption(
                    context,
                    imagePath: 'assets/images/mode/light_mode.png',
                    title: '라이트 모드',
                    value: 'light',
                    isFirst: true,
                  ),
                  _buildDivider(context),
                  _buildThemeOption(
                    context,
                    imagePath: 'assets/images/mode/dark_mode.png',
                    title: '다크 모드',
                    value: 'dark',
                    isFirst: false,
                  ),
                  _buildDivider(context),
                  _buildThemeOption(
                    context,
                    imagePath: 'assets/images/mode/auto_mode.png',
                    title: '기기 설정 따라가기',
                    value: 'auto',
                    isFirst: false,
                    isLast: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String imagePath,
    required String title,
    required String value,
    required bool isFirst,
    bool isLast = false,
  }) {
    final isSelected = _selectedTheme == value;

    return InkWell(
      onTap: () async {
        setState(() {
          _selectedTheme = value;
        });
        await _themeService.setThemeModeFromString(value);
      },
      borderRadius: BorderRadius.only(
        topLeft: isFirst ? const Radius.circular(12) : Radius.zero,
        topRight: isFirst ? const Radius.circular(12) : Radius.zero,
        bottomLeft: isLast ? const Radius.circular(12) : Radius.zero,
        bottomRight: isLast ? const Radius.circular(12) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // 이미지 (크기 증가)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF4A5568).withOpacity(0.3)
                    : const Color(0xFFE2E8F0).withOpacity(0.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(imagePath, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 20),
            // 텍스트 (크기 증가)
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // 라디오 버튼
            _buildRadioButton(isSelected),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withOpacity(0.1)
          : Colors.black.withOpacity(0.1),
    );
  }

  Widget _buildRadioButton(bool isSelected) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey,
          width: 2,
        ),
        color: Colors.transparent,
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
              ),
            )
          : null,
    );
  }
}
