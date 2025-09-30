import 'package:flutter/material.dart';
import '../home/home_view.dart';
import '../history/history_view.dart';
import '../settings/settings_view.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0; // 홈이 첫 번째이므로 0으로 설정

  final List<Widget> _pages = [
    const HomeView(), // index 0
    const HistoryView(), // index 1
    const SettingsView(), // index 2
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF121212)
              : const Color(0xFFF8F9FA),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          border: Border(
            top: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.08),
              width: 0.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 4,
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          child: Row(
            children: [
              // 홈 탭
              _buildTabItem(
                index: 0,
                icon: Icons.home_rounded,
                label: '홈',
                isCenter: false,
              ),

              // 히스토리 탭
              _buildTabItem(
                index: 1,
                icon: Icons.history_rounded,
                label: '히스토리',
                isCenter: false,
              ),

              // 설정 탭
              _buildTabItem(
                index: 2,
                icon: Icons.settings_rounded,
                label: '설정',
                isCenter: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isCenter,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: isSelected ? 24 : 24,
                color: isSelected
                    ? Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Theme.of(context).primaryColor
                    : Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade600
                    : Colors.black.withOpacity(0.4),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: isSelected ? 12 : 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Theme.of(context).primaryColor
                      : Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade600
                      : Colors.black.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
