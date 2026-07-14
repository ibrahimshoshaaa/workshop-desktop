import 'package:flutter/material.dart';

/// نفس ألوان هوية الورشة بتاعة تطبيق الموبايل، عشان يبقى فيه اتساق بصري
class AppColors {
  AppColors._();
  static const Color wood = Color(0xFF8B5E34);
  static const Color woodDark = Color(0xFF5C3D21);
  static const Color amber = Color(0xFFD9A441);
  static const Color navy = Color(0xFF1F3A5F);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFC9962C);
  static const Color danger = Color(0xFFB3261E);
}

ThemeData buildAppTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: const Color(0xFFFAF6F0),
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.wood,
      secondary: AppColors.amber,
      error: AppColors.danger,
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.wood,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}
