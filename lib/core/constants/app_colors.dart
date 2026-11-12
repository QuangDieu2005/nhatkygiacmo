import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Chủ đạo ban đêm
  static const Color background = Color(0xFF0B0E17);      // Đen xanh vũ trụ
  static const Color surface = Color(0xFF161B2E);         // Xanh đêm tím than (Card)
  static const Color surfaceLight = Color(0xFF222944);    // Tím than sáng nhẹ
  static const Color surfaceElevated = Color(0xFF2B3254); // Card elevated
  
  // Màu chính & phụ
  static const Color primary = Color(0xFF8B5CF6);         // Tím Lavender rực rỡ
  static const Color primaryLight = Color(0xFFA78BFA);    // Lavender nhạt
  static const Color primaryDark = Color(0xFF6D28D9);     // Tím than sâu
  static const Color secondary = Color(0xFF00B4D8);       // Xanh đêm tươi sáng
  static const Color secondaryDark = Color(0xFF0077B6);   // Xanh biển sâu

  // Màu trạng thái & điểm nhấn
  static const Color starGold = Color(0xFFFFD166);        // Vàng trăng sao
  static const Color moonSilver = Color(0xFFE2E8F0);      // Bạc ánh trăng
  static const Color success = Color(0xFF10B981);         // Xanh lá giấc ngủ ngon
  static const Color warning = Color(0xFFF59E0B);         // Vàng cảnh báo
  static const Color error = Color(0xFFEF4444);           // Đỏ cảnh báo

  // Màu chữ
  static const Color textPrimary = Color(0xFFF8FAFC);     // Chữ chính sáng rõ
  static const Color textSecondary = Color(0xFF94A3B8);   // Chữ phụ xám xanh
  static const Color textMuted = Color(0xFF64748B);       // Chữ mờ
  static const Color divider = Color(0xFF262E4A);         // Đường viền chia tách

  // Gradients mang phong cách ban đêm mộng mơ
  static const LinearGradient nightSkyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF090D1A),
      Color(0xFF13192F),
      Color(0xFF0B0E17),
    ],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1D233D),
      Color(0xFF14192D),
    ],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF8B5CF6),
      Color(0xFF6366F1),
    ],
  );

  static const LinearGradient sleepGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3B82F6),
      Color(0xFF8B5CF6),
    ],
  );

  static const LinearGradient dreamGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEC4899),
      Color(0xFF8B5CF6),
    ],
  );
}
