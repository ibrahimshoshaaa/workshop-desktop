import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import '../data/database.dart';
import '../core/theme.dart';
import '../core/search_bar.dart';
import '../core/other_dropdown.dart';

const _units = ['متر', 'كيلو', 'قطعة', 'لفة', 'لتر'];

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});
  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showMaterialDialog(BuildContext context, WidgetRef ref, {MaterialItem? material}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: material?.name ?? '');
    String unit = material?.unit ?? _units.first;
    final quantityController = TextEditingController(text: material?.quantity.toStringAsFixed(1) ?? '');
    final minController = TextEditingController(text: material?.minThreshold.toStringAsFixed(1) ?? '');

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(material == null ? 'إضافة خامة' : 'تعديل خامة'),
          content: SizedBox(
            width: 380,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الخامة'), validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null),
                  const SizedBox(height: 12),
                  OtherCapableDropdown(
                    options: _units,
                    label: 'الوحدة',
                    value: unit,
                    onChanged: (v) => setDialogState(() => unit = v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(controller: quantityController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الكمية الحالية'), validator: (v) => (v == null || double.tryParse(v) == null) ? 'أدخل رقم صحيح' : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: minController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الحد الأدنى للتنبيه'), validator: (v) => (v == null || double.tryParse(v) == null) ? 'أدخل رقم صحيح' : null),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                if (unit.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب الوحدة')));
                  return;
                }
                final repo = ref.read(repositoryProvider);
                final quantity = double.parse(quantityController.text.trim());
                final minThreshold = double.parse(minController.text.trim());
                if (material == null) {
                  await repo.addMaterial(name: nameController.text.trim(), unit: unit, quantity: quantity, minThreshold: minThreshold);
                } else {
                  await repo.updateMaterial(material, name: nameController.text.trim(), unit: unit, quantity: quantity, minThreshold: minThreshold);
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAdjustDialog(BuildContext context, WidgetRef ref, MaterialItem item) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('الكمية الحالية: ${item.quantity.toStringAsFixed(1)} ${item.unit}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true), decoration: const InputDecoration(labelText: 'الكمية (+ للإضافة، - للخصم)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final delta = double.tryParse(controller.text.trim());
              if (delta == null || delta == 0) return;
              await ref.read(repositoryProvider).adjustMaterialQuantity(item, delta);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('تحديث'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final materialsAsync = ref.watch(materialsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مخزون الخامات'),
        backgroundColor: AppColors.wood,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _showMaterialDialog(context, ref))],
      ),
      body: Column(
        children: [
          AppSearchBar(
            controller: _searchController,
            hintText: 'ابحث باسم الخامة...',
            onChanged: (v) => setState(() => _query = v),
            onClear: () => setState(() => _query = ''),
          ),
          Expanded(
            child: materialsAsync.when(
              data: (materials) {
                if (materials.isEmpty) return const Center(child: Text('لا توجد خامات مسجلة بعد', style: TextStyle(color: Colors.grey)));
                final q = normalizeForSearch(_query);
                final filtered = q.isEmpty ? materials : materials.where((m) => normalizeForSearch(m.name).contains(q)).toList();
                if (filtered.isEmpty) return const Center(child: Text('لا توجد نتائج مطابقة', style: TextStyle(color: Colors.grey)));
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final m = filtered[index];
                    final isLow = m.quantity <= m.minThreshold;
                    return Card(
                      color: isLow ? AppColors.danger.withValues(alpha: 0.08) : null,
                      child: ListTile(
                        onTap: () => _showAdjustDialog(context, ref, m),
                        onLongPress: () => _showMaterialDialog(context, ref, material: m),
                        leading: CircleAvatar(backgroundColor: (isLow ? AppColors.danger : AppColors.wood).withValues(alpha: 0.15), child: Icon(Icons.inventory_2_rounded, color: isLow ? AppColors.danger : AppColors.wood)),
                        title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('الحد الأدنى: ${m.minThreshold.toStringAsFixed(1)} ${m.unit}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${m.quantity.toStringAsFixed(1)} ${m.unit}', style: TextStyle(fontWeight: FontWeight.bold, color: isLow ? AppColors.danger : AppColors.success)),
                            if (isLow) const Text('على وشك النفاد', style: TextStyle(fontSize: 11, color: AppColors.danger)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('خطأ: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
