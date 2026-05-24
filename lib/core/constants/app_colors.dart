import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF00897B);
  static const Color background = Color(0xFFF8F9FA);
  static const Color gradient1 = Color(0xFF00897B);
  static const Color gradient2 = Color(0xFF43A047);
  static const Color textDark = Color(0xFF212121);
  static const Color textMuted = Color(0xFF9E9E9E);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradient1, gradient2],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
