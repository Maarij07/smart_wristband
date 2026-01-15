import 'package:flutter/material.dart';

class AppColors {
  // Shadcn Dark Theme Colors
  static const Color background = Color(0xFF020817);
  static const Color foreground = Color(0xFFf1f5f9);
  static const Color card = Color(0xFF1e293b);
  static const Color cardForeground = Color(0xFFf1f5f9);
  static const Color popover = Color(0xFF1e293b);
  static const Color popoverForeground = Color(0xFFf1f5f9);
  static const Color primary = Color(0xFF3b82f6);
  static const Color primaryForeground = Color(0xFFf8fafc);
  static const Color secondary = Color(0xFF1e293b);
  static const Color secondaryForeground = Color(0xFFe2e8f0);
  static const Color muted = Color(0xFFcbd5e1);
  static const Color mutedForeground = Color(0xFF94a3b8);
  static const Color accent = Color(0xFF334155);
  static const Color accentForeground = Color(0xFFe2e8f0);
  static const Color destructive = Color(0xFFef4444);
  static const Color destructiveForeground = Color(0xFFf8fafc);
  static const Color border = Color(0xFF334155);
  static const Color input = Color(0xFF0f172a);
  static const Color ring = Color(0xFF3b82f6);

  // Chart colors
  static const Color chart1 = Color(0xFF3b82f6);
  static const Color chart2 = Color(0xFF8b5cf6);
  static const Color chart3 = Color(0xFFec4899);
  static const Color chart4 = Color(0xFFf59e0b);
  static const Color chart5 = Color(0xFF10b981);

  // Legacy colors (keeping for backward compatibility)
  static const Color black = Color(0xFF000000);
  static const Color darkGrey = Color(0xFF121212);
  static const Color smokeBlack = Color(0xFF1a1a1a);
  static const Color smokeyGrey = Color(0xFF2d2d2d);
  static const Color lightSmokeyGrey = Color(0xFF404040);
  static const Color mediumGrey = Color(0xFF666666);
  static const Color ashGrey = Color(0xFF808080);
  static const Color charcoal = Color(0xFF2f2f2f);
  static const Color slate = Color(0xFF3c3c3c);
  static const Color graphite = Color(0xFF4a4a4a);
  static const Color stone = Color(0xFF555555);
  static const Color white = Color(0xFFFFFFFF);
  static const Color successMain = Color(0xFF4caf50);
  static const Color successLight = Color(0xFF66bb6a);
  static const Color warningMain = Color(0xFFff9800);
  static const Color warningLight = Color(0xFFffa726);
  static const Color errorMain = Color(0xFFf44336);
  static const Color errorLight = Color(0xFFef5350);
  static const Color infoMain = Color(0xFF2196f3);
  static const Color infoLight = Color(0xFF42a5f5);

  // Opacity variants
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  // Helper methods for common color combinations
  static BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: border, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration inputDecoration() {
    return BoxDecoration(
      color: input,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: border, width: 1),
    );
  }

  static InputDecoration textFieldInputDecoration({
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: mutedForeground),
      hintText: hintText,
      hintStyle: const TextStyle(color: mutedForeground),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: input,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    );
  }

  static ButtonStyle primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: primary,
      foregroundColor: primaryForeground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 0,
    );
  }

  static ButtonStyle outlineButtonStyle() {
    return OutlinedButton.styleFrom(
      side: const BorderSide(color: border, width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      backgroundColor: card,
    );
  }
}