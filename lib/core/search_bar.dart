import 'package:flutter/material.dart';
import 'theme.dart';

/// خانة بحث موحّدة الشكل بتستخدم في كل الصفحات (العملاء، الطلبات،
/// المديونيات، المصروفات، المخزون) عشان يبقى فيه اتساق بصري وسلوك واحد
class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: controller,
        textDirection: TextDirection.rtl,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.wood),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    controller.clear();
                    onClear?.call();
                  },
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.wood, width: 1.5),
          ),
        ),
      ),
    );
  }
}

/// بيشيل التشكيل/المسافات الزايدة ويحوّل لحروف صغيرة عشان البحث يشتغل
/// صح بالعربي والإنجليزي من غير ما يبقى حساس لحالة الحروف
String normalizeForSearch(String input) => input.trim().toLowerCase();
