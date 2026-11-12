import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _handleLogout(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Đăng xuất',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng không?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await authProvider.logout();
      if (context.mounted) {
        context.go(AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    final userName = user?.name ?? 'Người dùng Dream Diary';
    final userEmail = user?.email ?? 'user@dreamdiary.vn';
    final sleepGoal = user?.sleepGoalHours ?? 8;
    final notificationsEnabled = user?.notificationsEnabled ?? true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Lịch sử',
            onPressed: () => context.push(AppRoutes.history),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.nightSkyGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // Header Avatar & Tên
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.35),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.person_rounded,
                                size: 54,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userEmail,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Card Mục tiêu giấc ngủ
                _buildCardSection(
                  title: 'Mục tiêu giấc ngủ',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runSpacing: 8,
                        children: [
                          const Text(
                            'Thời lượng ngủ mục tiêu:',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$sleepGoal giờ / đêm',
                              style: const TextStyle(
                                color: AppColors.primaryLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: sleepGoal.toDouble(),
                        min: AppConstants.minSleepGoalHours.toDouble(),
                        max: AppConstants.maxSleepGoalHours.toDouble(),
                        divisions: 7,
                        activeColor: AppColors.primary,
                        inactiveColor: AppColors.divider,
                        onChanged: (val) {
                          authProvider.updateSleepGoal(val.round());
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Card Cài đặt thông báo & Ứng dụng
                _buildCardSection(
                  title: 'Cài đặt ứng dụng',
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(
                          Icons.notifications_active_outlined,
                          color: AppColors.primaryLight,
                        ),
                        title: const Text(
                          'Nhắc nhở giờ ngủ',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: const Text(
                          'Nhận thông báo khi đến giờ ngủ lý tưởng',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        value: notificationsEnabled,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          authProvider.updateNotifications(val);
                        },
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.dark_mode_outlined,
                          color: AppColors.primaryLight,
                        ),
                        title: const Text(
                          'Giao diện ban đêm (Dark Theme)',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: const Text(
                          'Tối ưu hóa ánh sáng dịu mắt cho ban đêm',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.check_rounded,
                          color: AppColors.success,
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.language_rounded,
                          color: AppColors.primaryLight,
                        ),
                        title: const Text(
                          'Ngôn ngữ',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                        trailing: const Text(
                          'Tiếng Việt',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.primaryLight,
                        ),
                        title: const Text(
                          'Phiên bản ứng dụng',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                        trailing: const Text(
                          AppConstants.appVersion,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Nút Đăng xuất
                Material(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.divider),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                    ),
                    title: const Text(
                      'Đăng xuất',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    onTap: () => _handleLogout(context, authProvider),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
