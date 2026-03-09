import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2563EB); // Blue
  static const Color secondary = Color(0xFF7C3AED); // Purple
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF334155)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Redesign Colors
  static const Color backgroundLight = Color(0xFFF6F6F6);
  static const Color cardDark = Color(0xFF151515); // Almost black for cards
  static const Color accentDark = Color(0xFF222222); // Slightly lighter for inner shapes
  
  // Pastel colors for recent search circles
  static const Color pastelBlue = Color(0xFFB6C8E6);
  static const Color pastelOrange = Color(0xFFE5A67C);
  static const Color pastelPink = Color(0xFFEAB8D8);
  static const Color pastelGreen = Color(0xFFA5B46D);

}