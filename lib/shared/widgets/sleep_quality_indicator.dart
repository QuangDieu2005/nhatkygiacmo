import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SleepQualityIndicator extends StatelessWidget {
  final int score;
  final double size;

  const SleepQualityIndicator({
    super.key,
    required this.score,
    this.size = 90,
  });

  Color get _scoreColor {
    if (score >= 85) return AppColors.success;
    if (score >= 70) return AppColors.secondary;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  String get _qualityText {
    if (score >= 85) return 'Rất tốt';
    if (score >= 70) return 'Tốt';
    if (score >= 50) return 'Trung bình';
    return 'Cần cải thiện';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: (score / 100).clamp(0.0, 1.0),
              strokeWidth: size * 0.09,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(_scoreColor),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                _qualityText,
                style: TextStyle(
                  fontSize: size * 0.12,
                  color: _scoreColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
