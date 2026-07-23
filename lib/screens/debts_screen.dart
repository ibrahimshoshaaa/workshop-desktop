import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../providers/data_providers.dart';
import '../core/theme.dart';
import '../core/search_bar.dart';
import '../core/order_calculations.dart';
import 'orders_screen.dart';

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

    return Container(
      color: const Color(0xFFFAF6F0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.wood.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.wood, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('المديونيات', style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF2A2320))),
                    const SizedBox(height: 4),
                    Text('الطلبات اللي لسه عليها متبقٍ من العملاء',
                        style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          if (debtors.isEmpty)
            const Expanded(child: _EmptyState(icon: Icons.celebration_rounded, text: 'لا توجد مديونيات حاليًا 🎉'))
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: _HeroStatCard(
                label: 'إجمالي المديونيات المستحقة',
                value: '${totalDebt.toStringAsFixed(0)} ج.م',
                caption: '${debtors.length} عميل عليه مديونية',
                icon: Icons.priority_high_rounded,
                color: AppColors.danger,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 18, 28, 0),
              child: _HoverCard(
                borderRadius: BorderRadius.circular(16),
                child: AppSearchBar(
                  controller: _searchController,
                  hintText: 'ابحث باسم العميل أو نوع الصنف...',
                  onChanged: (v) => setState(() => _query = v),
                  onClear: () => setState(() => _query = ''),
                ),
              ),
            ),
            Expanded(
              child: filteredDebtors.isEmpty
                  ? const _EmptyState(icon: Icons.search_off_rounded, text: 'لا توجد نتائج مطابقة')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
                      itemCount: filteredDebtors.length,
                      itemBuilder: (context, index) {
                        final o = filteredDebtors[index];
                        final remaining = o.remaining;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _HoverCard(
                            onTap: () => showDialog(context: context, builder: (context) => OrderDetailDialog(order: o)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), shape: BoxShape.circle),
                                    child: const Icon(Icons.priority_high_rounded, color: AppColors.danger, size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${o.customerName} - ${o.itemType}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF2A2320))),
                                        const SizedBox(height: 4),
                                        Text('تسليم: ${DateFormat('d/M/yyyy').format(DateTime.fromMillisecondsSinceEpoch(o.deliveryDate))}',
                                            style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey.shade500)),
                                      ],
                                    ),
                                  ),
                                  Text('${remaining.toStringAsFixed(0)} ج.م',
                                      style: GoogleFonts.cairo(color: AppColors.danger, fontWeight: FontWeight.w800, fontSize: 15)),
                                  const SizedBox(width: 4),
                                  Icon(Icons.chevron_left_rounded, color: Colors.grey.shade300),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;
  const _HeroStatCard({required this.label, required this.value, required this.caption, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return _HoverCard(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withValues(alpha: 0.10), color.withValues(alpha: 0.03)]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                Text(value, style: GoogleFonts.cairo(fontSize: 30, fontWeight: FontWeight.w800, color: color)),
                const SizedBox(height: 4),
                Text(caption, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text(text, style: GoogleFonts.cairo(fontSize: 14.5, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

/// كارت بأثر hover ناعم (رفعة خفيفة + ظل أكبر) - نفس فكرة اللي في
/// dashboard_screen.dart بالظبط، بس متكرر هنا لأن الويدجتس الخاصة
/// (بادئة _) ملهاش مشاركة بين الملفات في دارت
class _HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  const _HoverCard({required this.child, this.onTap, this.borderRadius = const BorderRadius.all(Radius.circular(18))});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovering ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: widget.borderRadius,
          boxShadow: [
            BoxShadow(
              color: AppColors.wood.withValues(alpha: _hovering ? 0.14 : 0.06),
              blurRadius: _hovering ? 26 : 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: widget.borderRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: widget.onTap, borderRadius: widget.borderRadius, child: widget.child),
        ),
      ),
    );
  }
}
