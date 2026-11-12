import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  void _onItemTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
          border: const Border(
            top: BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: _NavItem(
                    icon: Icons.nightlight_round,
                    activeIcon: Icons.nightlight_round,
                    label: 'Trang chủ',
                    isSelected: navigationShell.currentIndex == 0,
                    onTap: () => _onItemTapped(0),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.auto_stories_outlined,
                    activeIcon: Icons.auto_stories,
                    label: 'Giấc mơ',
                    isSelected: navigationShell.currentIndex == 1,
                    onTap: () => _onItemTapped(1),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.bedtime_outlined,
                    activeIcon: Icons.bedtime,
                    label: 'Giấc ngủ',
                    isSelected: navigationShell.currentIndex == 2,
                    onTap: () => _onItemTapped(2),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.bar_chart_outlined,
                    activeIcon: Icons.bar_chart,
                    label: 'Phân tích',
                    isSelected: navigationShell.currentIndex == 3,
                    onTap: () => _onItemTapped(3),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Cá nhân',
                    isSelected: navigationShell.currentIndex == 4,
                    onTap: () => _onItemTapped(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.textMuted;
    final compact = MediaQuery.sizeOf(context).width < 380;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 6, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : icon, color: color, size: 22),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: compact ? 10 : 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
