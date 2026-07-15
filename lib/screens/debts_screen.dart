import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/data_providers.dart';
import '../core/theme.dart';
import '../core/search_bar.dart';
import '../core/order_calculations.dart';

class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});
  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final debtors = ref.watch(debtorOrdersProvider);
    final q = normalizeForSearch(_query);
    final filteredDebtors = q.isEmpty
        ? debtors
        : debtors.where((o) {
            return normalizeForSearch(o.customerName).contains(q) || normalizeForSearch(o.itemType).contains(q);
          }).toList();
    // إجمالي المديونيات دايمًا بيتحسب من كل المديونين، مش من نتيجة البحث،
    // عشان الرقم يفضل يعكس الموقف الحقيقي حتى لو المستخدم بيدور على عميل معين
    final totalDebt = debtors.fold<double>(0, (s, o) => s + o.remaining);

    return Scaffold(
      appBar: AppBar(title: const Text('المديونيات'), backgroundColor: AppColors.wood, foregroundColor: Colors.white),
      body: debtors.isEmpty
          ? const Center(child: Text('لا توجد مديونيات حاليًا 🎉', style: TextStyle(color: Colors.grey, fontSize: 16)))
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      const Text('إجمالي المديونيات المستحقة', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 6),
                      Text('${totalDebt.toStringAsFixed(0)} ج.م', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.danger)),
                    ],
                  ),
                ),
                AppSearchBar(
                  controller: _searchController,
                  hintText: 'ابحث باسم العميل أو نوع الصنف...',
                  onChanged: (v) => setState(() => _query = v),
                  onClear: () => setState(() => _query = ''),
                ),
                Expanded(
                  child: filteredDebtors.isEmpty
                      ? const Center(child: Text('لا توجد نتائج مطابقة', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredDebtors.length,
                          itemBuilder: (context, index) {
                            final o = filteredDebtors[index];
                            final remaining = o.remaining;
                            return Card(
                              child: ListTile(
                                leading: const CircleAvatar(backgroundColor: Color(0x1AB3261E), child: Icon(Icons.priority_high_rounded, color: AppColors.danger)),
                                title: Text('${o.customerName} - ${o.itemType}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('تسليم: ${DateFormat('d/M/yyyy').format(DateTime.fromMillisecondsSinceEpoch(o.deliveryDate))}'),
                                trailing: Text('${remaining.toStringAsFixed(0)} ج.م', style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 15)),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
