import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/sleep_session_model.dart';
import '../../../providers/dream_provider.dart';
import '../../../providers/sleep_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/sleep_quality_indicator.dart';

class SleepTrackingScreen extends StatefulWidget {
  const SleepTrackingScreen({super.key});

  @override
  State<SleepTrackingScreen> createState() => _SleepTrackingScreenState();
}

class _SleepTrackingScreenState extends State<SleepTrackingScreen> {
  bool _isStarting = false;
  bool _isStopping = false;
  bool _stopFailed = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SleepProvider>();
    final session = provider.lastCompletedSession;

    return Scaffold(
      appBar: AppBar(title: const Text('Theo dõi giấc ngủ')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.nightSkyGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: session != null
                    ? _CompletedView(
                        key: const ValueKey('completed'),
                        session: session,
                        saveWarning: _stopFailed,
                        onRecordDream: () {
                          provider.clearLastCompletedSession();
                          context.push(AppRoutes.addDream);
                        },
                        onFinish: () {
                          provider.clearLastCompletedSession();
                          context.go(AppRoutes.home);
                        },
                      )
                    : provider.isTracking
                        ? _TrackingView(
                            key: const ValueKey('tracking'),
                            provider: provider,
                            isStopping: _isStopping,
                            onStop: () => _stopTracking(provider),
                          )
                        : _ReadyView(
                            key: const ValueKey('ready'),
                            isStarting: _isStarting,
                            onStart: () => _startTracking(provider),
                          ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startTracking(SleepProvider provider) async {
    if (_isStarting || _isStopping || provider.isTracking) return;
    setState(() => _isStarting = true);
    try {
      await provider.startTracking();
    } catch (_) {
      if (mounted) _showMessage('Không thể bắt đầu theo dõi. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  Future<void> _stopTracking(SleepProvider provider) async {
    if (_isStopping || _isStarting || !provider.isTracking) return;
    final shouldStop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Kết thúc phiên ngủ?'),
            content: const Text('Thời gian ngủ hiện tại sẽ được ghi nhận.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Tiếp tục ngủ'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Kết thúc'),
              ),
            ],
          ),
        ) ??
        false;
    if (!shouldStop || !mounted) return;

    setState(() {
      _isStopping = true;
      _stopFailed = false;
    });
    try {
      final dreams = context.read<DreamProvider>().allDreams;
      final completed = await provider.stopTracking(dreams: dreams);
      if (completed == null && mounted) {
        setState(() => _stopFailed = true);
        _showMessage('Chưa thể ghi nhận phiên ngủ. Hãy kiểm tra trạng thái theo dõi.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _stopFailed = true);
        _showMessage('Không thể xác nhận lưu phiên ngủ vào lịch sử.');
      }
    } finally {
      if (mounted) setState(() => _isStopping = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ReadyView extends StatelessWidget {
  const _ReadyView({super.key, required this.isStarting, required this.onStart});
  final bool isStarting;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height -
              MediaQuery.paddingOf(context).vertical -
              kToolbarHeight -
              48,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _MoonIllustration(),
            const SizedBox(height: 26),
            Text(DateFormatter.formatTime(now),
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5)),
            const SizedBox(height: 5),
            Text(DateFormatter.formatWeekday(now),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 22),
            const Text('Sẵn sàng nghỉ ngơi?',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Bắt đầu ghi lại thời gian ngủ của bạn.\nBạn có thể kết thúc phiên vào buổi sáng.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.5, fontSize: 14),
            ),
            const SizedBox(height: 26),
            _PrimaryAction(
              icon: isStarting ? null : Icons.bedtime_rounded,
              label: isStarting ? 'Đang bắt đầu…' : 'Bắt đầu ngủ',
              isLoading: isStarting,
              onPressed: isStarting ? null : onStart,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: _cardDecoration(color: AppColors.surface.withOpacity(.82)),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      color: AppColors.starGold, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Một không gian yên tĩnh và thói quen đều đặn có thể giúp bạn thư giãn trước giờ ngủ.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoonIllustration extends StatelessWidget {
  const _MoonIllustration();

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 116,
        width: 170,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(.09),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(.12),
                    blurRadius: 35,
                    spreadRadius: 9,
                  ),
                ],
              ),
            ),
            const Icon(Icons.nightlight_round, size: 76, color: AppColors.moonSilver),
            const Positioned(
              top: 17,
              right: 28,
              child: Icon(Icons.star_rounded, color: AppColors.starGold, size: 17),
            ),
            const Positioned(
              bottom: 19,
              left: 26,
              child: Icon(Icons.star_rounded, color: AppColors.primaryLight, size: 13),
            ),
          ],
        ),
      );
}

class _TrackingView extends StatelessWidget {
  const _TrackingView({
    super.key,
    required this.provider,
    required this.isStopping,
    required this.onStop,
  });

  final SleepProvider provider;
  final bool isStopping;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final elapsed = provider.currentElapsed;
    final hours = elapsed.inHours.toString().padLeft(2, '0');
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final startedAt = provider.activeSession?.startTime;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 30),
      child: Column(
        children: [
          const _StatusPill(label: 'Đang theo dõi', active: true),
          const SizedBox(height: 28),
          _ElapsedClock(value: '$hours:$minutes:$seconds'),
          const SizedBox(height: 12),
          const Text('Thời gian đã trôi qua',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          if (startedAt != null) ...[
            const SizedBox(height: 8),
            Text('Bắt đầu lúc ${DateFormatter.formatTime(startedAt)}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ],
          const SizedBox(height: 30),
          const _RestingIllustration(),
          const SizedBox(height: 30),
          _PrimaryAction(
            icon: isStopping ? null : Icons.wb_sunny_rounded,
            label: isStopping ? 'Đang lưu phiên ngủ…' : 'Kết thúc giấc ngủ',
            isLoading: isStopping,
            isDestructive: true,
            onPressed: isStopping ? null : onStop,
          ),
          const SizedBox(height: 18),
          const Text('Chúc bạn có một đêm yên bình',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ElapsedClock extends StatelessWidget {
  const _ElapsedClock({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.primary.withOpacity(.25)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 54,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3,
                  fontFeatures: [FontFeature.tabularFigures()])),
        ),
      );
}

class _RestingIllustration extends StatelessWidget {
  const _RestingIllustration();

  @override
  Widget build(BuildContext context) => Container(
        height: 150,
        width: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withOpacity(.08),
          border: Border.all(color: AppColors.primary.withOpacity(.14)),
        ),
        child: const Icon(Icons.bedtime_outlined,
            size: 70, color: AppColors.primaryLight),
      );
}

class _CompletedView extends StatelessWidget {
  const _CompletedView({
    super.key,
    required this.session,
    required this.saveWarning,
    required this.onRecordDream,
    required this.onFinish,
  });

  final SleepSessionModel session;
  final bool saveWarning;
  final VoidCallback onRecordDream;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(.13),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wb_twilight_rounded,
                  color: AppColors.starGold, size: 38),
            ),
            const SizedBox(height: 16),
            const Text('Chào buổi sáng',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 25,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
                saveWarning
                    ? 'Không xác nhận được việc lưu phiên ngủ vào lịch sử.'
                    : 'Phiên ngủ đã được ghi nhận trong lịch sử.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: saveWarning ? AppColors.warning : AppColors.textSecondary,
                    fontSize: 13)),
            const SizedBox(height: 22),
            _SessionSummary(session: session),
            const SizedBox(height: 20),
            AppButton(
              label: 'Ghi lại giấc mơ đêm qua',
              icon: Icons.edit_note_rounded,
              onPressed: onRecordDream,
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Hoàn tất và về trang chủ',
              variant: AppButtonVariant.secondary,
              onPressed: onFinish,
            ),
          ],
        ),
      );
}

class _SessionSummary extends StatelessWidget {
  const _SessionSummary({required this.session});
  final SleepSessionModel session;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Thời lượng ngủ',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      const SizedBox(height: 5),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(DateFormatter.formatDurationMinutes(session.totalMinutes),
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 27,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SleepQualityIndicator(score: session.qualityScore, size: 72),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _TimeInfo(label: 'Bắt đầu', value: _time(session.startTime))),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeInfo(
                      label: 'Kết thúc',
                      value: session.endTime == null ? '—' : _time(session.endTime!)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Giai đoạn ngủ ước tính',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _StageValue(
                        label: 'Sâu', minutes: session.deepSleepMinutes, color: AppColors.primaryLight)),
                Expanded(
                    child: _StageValue(
                        label: 'Nông', minutes: session.lightSleepMinutes, color: AppColors.secondary)),
                Expanded(
                    child: _StageValue(
                        label: 'REM', minutes: session.remSleepMinutes, color: AppColors.starGold)),
              ],
            ),
            const SizedBox(height: 10),
            const Text('Điểm và giai đoạn được ước tính bởi logic hiện tại của ứng dụng.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10, height: 1.4)),
          ],
        ),
      );
}

class _TimeInfo extends StatelessWidget {
  const _TimeInfo({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ],
      );
}

class _StageValue extends StatelessWidget {
  const _StageValue({required this.label, required this.minutes, required this.color});
  final String label;
  final int minutes;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(height: 7),
          Text('${minutes}p',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.active});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(.13),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.primaryLight.withOpacity(.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 8,
                color: active ? AppColors.success : AppColors.textMuted),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.icon,
    required this.label,
    required this.isLoading,
    required this.onPressed,
    this.isDestructive = false,
  });

  final IconData? icon;
  final String label;
  final bool isLoading;
  final bool isDestructive;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final gradient = isDestructive
        ? const LinearGradient(colors: [Color(0xFFE87987), Color(0xFFC95771)])
        : AppColors.primaryGradient;
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed == null ? null : gradient,
          color: onPressed == null ? AppColors.surfaceLight : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: onPressed == null
              ? null
              : [
                  BoxShadow(
                    color: (isDestructive ? AppColors.error : AppColors.primary)
                        .withOpacity(.2),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
        ),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: AppColors.textMuted,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              else if (icon != null)
                Icon(icon, size: 21),
              const SizedBox(width: 9),
              Text(label,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

String _time(DateTime time) => DateFormatter.formatTime(time);

BoxDecoration _cardDecoration({Color? color}) => BoxDecoration(
      color: color ?? AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.divider),
    );
