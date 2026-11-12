import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/sleep_session_model.dart';
import '../../../providers/sleep_provider.dart';
import '../../../providers/dream_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/sleep_quality_indicator.dart';

class SleepTrackingScreen extends StatelessWidget {
  const SleepTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sleepProvider = context.watch<SleepProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theo dõi giấc ngủ'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.nightSkyGradient,
        ),
        child: SafeArea(
          child: sleepProvider.lastCompletedSession != null
              ? _buildCompletedView(context, sleepProvider, sleepProvider.lastCompletedSession!)
              : sleepProvider.isTracking
                  ? _buildTrackingView(context, sleepProvider)
                  : _buildReadyToSleepView(context, sleepProvider),
        ),
      ),
    );
  }

  // 1. GIAO DIỆN CHUẨN BỊ NGỦ
  Widget _buildReadyToSleepView(BuildContext context, SleepProvider sleepProvider) {
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          // Đồng hồ hiện tại
          Text(
            DateFormatter.formatTime(now),
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            DateFormatter.formatWeekday(now),
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 48),

          // Vòng tròn nút Bắt đầu ngủ
          GestureDetector(
            onTap: () => sleepProvider.startTracking(),
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF8B5CF6),
                    Color(0xFF3B82F6),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 36,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bedtime_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Bắt đầu ngủ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),

          // Lời khuyên giấc ngủ
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: AppColors.starGold, size: 24),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Khuyến nghị: Hãy để điện thoại cách xa giường ngủ ít nhất 1m để có giấc ngủ sâu và trọn vẹn hơn.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // 2. GIAO DIỆN ĐANG THEO DÕI
  Widget _buildTrackingView(BuildContext context, SleepProvider sleepProvider) {
    final elapsed = sleepProvider.currentElapsed;
    final hours = elapsed.inHours.toString().padLeft(2, '0');
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryLight.withOpacity(0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.nightlight_round, color: AppColors.starGold, size: 16),
                SizedBox(width: 8),
                Text(
                  'Đang trong phiên ngủ...',
                  style: TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // Hiển thị Timer
          Text(
            '$hours:$minutes:$seconds',
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Thời lượng giấc ngủ hiện tại',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 50),

          // Nút Kết thúc
          GestureDetector(
            onTap: () async {
              final dreams = context.read<DreamProvider>().allDreams;
              await sleepProvider.stopTracking(dreams: dreams);
            },
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withOpacity(0.4),
                    blurRadius: 28,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wb_sunny_rounded, size: 44, color: Colors.white),
                  SizedBox(height: 6),
                  Text(
                    'Thức dậy',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),

          const Text(
            'Chúc bạn có những giấc mơ thật đẹp 🌙',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // 3. GIAO DIỆN KẾT THÚC PHIÊN NGỦ
  Widget _buildCompletedView(
    BuildContext context,
    SleepProvider sleepProvider,
    SleepSessionModel session,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wb_sunny_rounded,
              color: AppColors.starGold,
              size: 56,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chào buổi sáng!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Phiên ngủ đã được ghi nhận vào lịch sử',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 30),

          // Thẻ tóm tắt kết quả phiên ngủ
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          DateFormatter.formatDurationMinutes(session.totalMinutes),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tổng thời gian ngủ',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    SleepQualityIndicator(score: session.qualityScore, size: 84),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 18),

                // Các giai đoạn ngủ ước lượng
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSleepStage(
                      label: 'Ngủ sâu',
                      duration: '${session.deepSleepMinutes}m',
                      color: AppColors.primary,
                    ),
                    _buildSleepStage(
                      label: 'Ngủ nhẹ',
                      duration: '${session.lightSleepMinutes}m',
                      color: AppColors.secondary,
                    ),
                    _buildSleepStage(
                      label: 'Ngủ mơ (REM)',
                      duration: '${session.remSleepMinutes}m',
                      color: AppColors.starGold,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Nút Ghi lại giấc mơ & Về trang chủ
          AppButton(
            label: 'Ghi lại giấc mơ đêm qua',
            icon: Icons.edit_note_rounded,
            onPressed: () {
              sleepProvider.clearLastCompletedSession();
              context.push(AppRoutes.addDream);
            },
          ),
          const SizedBox(height: 14),
          AppButton(
            label: 'Hoàn tất & Về trang chủ',
            variant: AppButtonVariant.secondary,
            onPressed: () {
              sleepProvider.clearLastCompletedSession();
              context.go(AppRoutes.home);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSleepStage({
    required String label,
    required String duration,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          duration,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
