import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/search_bar.dart';
import '../core/theme.dart';
import '../providers/data_providers.dart';
import '../data/database.dart';
import 'customers_screen.dart' show CustomerOrdersDialog;

class CustomerArchiveScreen extends ConsumerStatefulWidget {
  const CustomerArchiveScreen({super.key});

  @override
  ConsumerState<CustomerArchiveScreen> createState() => _CustomerArchiveScreenState();
}

class _CustomerArchiveScreenState extends ConsumerState<CustomerArchiveScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _restore(Customer customer) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استرجاع العميل'),
        content: Text('هل تريد استرجاع "${customer.name}" من الأرشيف؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton.icon(
            icon: const Icon(Icons.restore_rounded),
            label: const Text('استرجاع'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(repositoryProvider).updateCustomer(
      customer,
      name: customer.name,
      phone: customer.phone,
      address: customer.address,
    );
  }

  @override
  Widget build(BuildContext context) {
    final archivedAsync = ref.watch(archivedCustomersProvider);

    return Container(
      color: const Color(0xFFFAF6F0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.wood.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.archive_rounded, color: AppColors.wood, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('أرشيف العملاء', style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF2A2320))),
                      const SizedBox(height: 4),
                      Text('العملاء الذين تم أرشفتهم ويمكن استرجاعهم في أي وقت', style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                archivedAsync.when(
                  data: (items) => _CountBadge(count: items.length),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
            child: AppSearchBar(
              controller: _searchController,
              hintText: 'ابحث باسم العميل أو رقم الهاتف...',
              onChanged: (v) => setState(() => _query = v),
              onClear: () => setState(() => _query = ''),
            ),
          ),
          Expanded(
            child: archivedAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.wood)),
              error: (e, _) => Center(child: Text('خطأ: $e')),
              data: (customers) {
                final q = normalizeForSearch(_query);
                final filtered = q.isEmpty
                    ? customers
                    : customers.where((c) => normalizeForSearch(c.name).contains(q) || normalizeForSearch(c.phone).contains(q) || normalizeForSearch(c.address).contains(q)).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(q.isEmpty ? Icons.archive_outlined : Icons.search_off_rounded, size: 54, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(q.isEmpty ? 'لا يوجد عملاء في الأرشيف' : 'لا توجد نتائج مطابقة', style: GoogleFonts.cairo(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final c = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => showDialog(context: context, builder: (_) => CustomerOrdersDialog(customer: c)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.wood.withValues(alpha: 0.1),
                                  child: Text(c.name.isNotEmpty ? c.name[0] : '?', style: const TextStyle(color: AppColors.wood, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(child: Text(c.name, overflow: TextOverflow.ellipsis, style: GoogleFonts.cairo(fontWeight: FontWeight.w800, color: const Color(0xFF2A2320)))),
                                          const SizedBox(width: 8),
                                          Text('#${c.serialNumber}', style: const TextStyle(fontSize: 11, color: AppColors.wood, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text('${c.phone}${c.address.isNotEmpty ? ' • ${c.address}' : ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade500)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'استرجاع العميل',
                                  onPressed: () => _restore(c),
                                  icon: const Icon(Icons.restore_rounded, color: AppColors.success),
                                ),
                                const Icon(Icons.chevron_left_rounded, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppColors.wood.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text('$count عميل', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.wood)),
    );
  }
}
