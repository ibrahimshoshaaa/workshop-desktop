import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../providers/data_providers.dart';
import '../data/database.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../core/search_bar.dart';
import '../core/whatsapp.dart';
import '../core/order_calculations.dart';
import '../core/other_dropdown.dart';
import '../services/cloudinary_service.dart';
import '../services/pdf_export_service.dart';

/// بعد تسجيل أي دفعة، بيسأل المستخدم لو عايز يطبع إيصال استلام فورًا
Future<void> _offerReceiptPrint(
  BuildContext context, {
  required String customerName,
  required String itemType,
  required double amount,
  required String method,
  required DateTime date,
  String status = 'completed',
}) async {
  final shouldPrint = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('تسجيل الدفعة تم بنجاح'),
      content: const Text('هل تريد طباعة إيصال استلام الآن؟'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لا')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('طباعة إيصال')),
      ],
    ),
  );
  if (shouldPrint == true && context.mounted) {
    final bytes = await PdfExportService.instance.buildPaymentReceipt(
      customerName: customerName,
      itemType: itemType,
      amount: amount,
      method: paymentMethods[method] ?? method,
      status: paymentStatuses[status] ?? status,
      date: date,
    );
    if (context.mounted) await PdfExportService.instance.preview(context, bytes, 'إيصال_استلام.pdf');
  }
}

/// بيحوّل نص JSON مخزّن في imagesJson لقائمة روابط صور
List<String> _parseOrderImages(String imagesJson) {
  try {
    return (jsonDecode(imagesJson) as List).map((e) => e.toString()).toList();
  } catch (_) {
    return [];
  }
}

/// يفتح الصورة في نافذة كبيرة لعرضها بوضوح
void _showFullImage(BuildContext context, String url) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.black,
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    ),
  );
}

/// عرض صف من الصور (Thumbnails) القابلة للضغط والحذف - مستخدم في نافذة
/// إضافة الطلب (على bytes محلية لسه ما اتبعتتش) وفي تفاصيل الطلب (روابط
/// Cloudinary بعد الرفع)
class _ImageThumb extends StatelessWidget {
  final Widget image;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  const _ImageThumb({required this.image, this.onTap, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: GestureDetector(
            onTap: onTap,
            child: SizedBox(width: 72, height: 72, child: image),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
              ),
            ),
          ),
      ],
    );
  }
}

const _itemTypes = ['أنتريه', 'صالون', 'ركنة', 'ستائر', 'سرير', 'كنب', 'أخرى'];

/// طرق استلام الدفعات المتاحة

/// حالات الدفعة المتاحة
const Map<String, String> paymentStatuses = {'completed': 'مكتملة', 'pending': 'معلقة'};

/// بيبني نص الرسالة اللي هتتبعت للصنايعي على واتساب - نوع الصنف
/// والمواصفات وتاريخ التسليم بس، من غير أي مبالغ (إجمالي/متبقي) لأن
/// دي بيانات مالية خاصة بصاحب الطلب مش شغلانة الصنايعي
String _buildOrderShareTextForWorker(Order order) {
  final buffer = StringBuffer()
    ..writeln('طلب: ${order.itemType}')
    ..writeln('العميل: ${order.customerName}');
  if (order.details.trim().isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('المواصفات:')
      ..writeln(order.details.trim());
  }
  buffer
    ..writeln()
    ..writeln('تاريخ التسليم: ${DateFormat('d/M/yyyy').format(DateTime.fromMillisecondsSinceEpoch(order.deliveryDate))}');
  return buffer.toString();
}

/// بينزّل صور الطلب من Cloudinary لفولدر مؤقت على الجهاز - واتساب مش
/// بيسمح إن الصور تتبعت أوتوماتيك عن طريق رابط (لا wa.me ولا حتى
/// تطبيق سطح المكتب)، فأقرب حل إن الصور تتحط جاهزة في فولدر بيتفتح
/// جنب الشات عشان تتسحب بسهولة على الرسالة
Future<Directory?> _downloadOrderImagesToFolder(Order order) async {
  final urls = _parseOrderImages(order.imagesJson);
  if (urls.isEmpty) return null;
  try {
    final tempDir = await getTemporaryDirectory();
    final folder = Directory('${tempDir.path}${Platform.pathSeparator}order_${order.id}_images');
    if (!await folder.exists()) await folder.create(recursive: true);
    for (var i = 0; i < urls.length; i++) {
      try {
        final response = await http.get(Uri.parse(urls[i]));
        if (response.statusCode == 200) {
          final ext = urls[i].split('.').last.split('?').first;
          final file = File('${folder.path}${Platform.pathSeparator}صورة_${i + 1}.$ext');
          await file.writeAsBytes(response.bodyBytes);
        }
      } catch (_) {
        // نتجاهل أي صورة فشل تنزيلها ونكمل الباقي
      }
    }
    return folder;
  } catch (_) {
    return null;
  }
}

/// بيبعت مواصفات الطلب لصنايعي معيّن على واتساب، وبيفتح فولدر صور
/// الطلب (لو فيه صور) عشان تتسحب في الشات يدويًا
Future<void> _shareOrderWithWorker(BuildContext context, WidgetRef ref, Order order, Worker worker) async {
  final hasImages = _parseOrderImages(order.imagesJson).isNotEmpty;
  Directory? imagesFolder;
  if (hasImages) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('بننزّل صور الطلب...')));
    }
    imagesFolder = await _downloadOrderImagesToFolder(order);
  }
  final ok = await shareTextOnWhatsApp(_buildOrderShareTextForWorker(order), phone: worker.phone);
  if (imagesFolder != null) {
    await Process.run('explorer', [imagesFolder.path]);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فتحنا فولدر فيه صور الطلب - اسحبها في شات واتساب مع الرسالة (واتساب مش بيسمح بإرفاق صور تلقائي عن طريق رابط)')),
      );
    }
  }
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('مقدرش أفتح واتساب - تأكد إنه متثبت على الجهاز')));
  }
}

/// ديالوج اختيار الصنايعي اللي هتتبعتله مواصفات الطلب - فيه بحث
/// بالاسم أو المهنة عشان يبقى سهل لو عدد العمال كبير
Future<void> _showShareToWorkerDialog(BuildContext context, WidgetRef ref, Order order) async {
  final workers = ref.read(workersProvider).value ?? [];
  if (workers.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أضف صنايعي أولًا من صفحة العمال')));
    return;
  }
  final searchController = TextEditingController();
  String query = '';
  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        final q = normalizeForSearch(query);
        final filtered = q.isEmpty
            ? workers
            : workers.where((w) => normalizeForSearch(w.name).contains(q) || normalizeForSearch(w.jobTitle).contains(q)).toList();
        return AlertDialog(
          title: const Text('ابعت المواصفات لأي صنايعي؟'),
          content: SizedBox(
            width: 380,
            height: 420,
            child: Column(
              children: [
                AppSearchBar(
                  controller: searchController,
                  hintText: 'ابحث باسم الصنايعي أو مهنته...',
                  onChanged: (v) => setDialogState(() => query = v),
                  onClear: () => setDialogState(() => query = ''),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('لا يوجد صنايعي بالاسم ده', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final w = filtered[index];
                            return ListTile(
                              leading: const Icon(Icons.engineering_rounded, color: AppColors.wood),
                              title: Text(w.name),
                              subtitle: Text(w.jobTitle.isNotEmpty ? '${w.jobTitle} - ${w.phone}' : w.phone),
                              onTap: () {
                                Navigator.pop(context);
                                _shareOrderWithWorker(context, ref, order, w);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ],
        );
      },
    ),
  );
}

/// ديالوج إضافة طلب جديد - قابل لإعادة الاستخدام من أي صفحة. لو اتبعتله
/// [presetCustomer] (زي لما بيتفتح من ديالوج طلبات عميل معيّن في صفحة
/// العملاء) بيثبّت العميل ده تلقائيًا من غير ما يوريلك قايمة الاختيار
Future<void> showAddOrderDialog(BuildContext context, WidgetRef ref, {Customer? presetCustomer}) async {
  final customers = ref.read(customersProvider).value ?? [];
  if (presetCustomer == null && customers.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أضف عميل أولًا')));
    return;
  }
  final formKey = GlobalKey<FormState>();
  String? customerId = presetCustomer?.id ?? customers.first.id;
  String itemType = _itemTypes.first;
  final detailsController = TextEditingController();
  final totalController = TextEditingController();
  final depositController = TextEditingController();
  String depositMethod = 'cash';
  DateTime deliveryDate = DateTime.now().add(const Duration(days: 7));
  final pickedImages = <PlatformFile>[];
  bool isSaving = false;

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(presetCustomer == null ? 'طلب جديد' : 'طلب جديد لـ ${presetCustomer.name}'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (presetCustomer == null)
                    DropdownButtonFormField<String>(
                      value: customerId,
                      decoration: const InputDecoration(labelText: 'العميل'),
                      items: customers.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name} - ${c.phone}'))).toList(),
                      onChanged: (v) => setDialogState(() => customerId = v),
                    )
                  else
                    TextFormField(
                      initialValue: '${presetCustomer.name} - ${presetCustomer.phone}',
                      enabled: false,
                      decoration: const InputDecoration(labelText: 'العميل'),
                    ),
                  const SizedBox(height: 12),
                  OtherCapableDropdown(
                    options: _itemTypes.where((t) => t != kOtherOptionValue).toList(),
                    label: 'نوع الصنف',
                    value: itemType,
                    onChanged: (v) => setDialogState(() => itemType = v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(controller: detailsController, maxLines: 2, decoration: const InputDecoration(labelText: 'المواصفات')),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('صور الطلب', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...pickedImages.map((f) => _ImageThumb(
                            image: Image.memory(f.bytes!, fit: BoxFit.cover),
                            onRemove: () => setDialogState(() => pickedImages.remove(f)),
                          )),
                      InkWell(
                        onTap: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            allowMultiple: true,
                            withData: true,
                          );
                          if (result != null) {
                            setDialogState(() => pickedImages.addAll(result.files.where((f) => f.bytes != null)));
                          }
                        },
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add_photo_alternate_rounded, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('تاريخ التسليم'),
                    subtitle: Text('${deliveryDate.year}/${deliveryDate.month}/${deliveryDate.day}'),
                    trailing: const Icon(Icons.calendar_month_rounded),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: deliveryDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setDialogState(() => deliveryDate = picked);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: totalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'إجمالي الاتفاق (ج.م)'),
                    validator: (v) => (v == null || double.tryParse(v) == null) ? 'أدخل مبلغ صحيح' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: depositController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'العربون المدفوع الآن (اختياري)'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: depositMethod,
                    decoration: const InputDecoration(labelText: 'طريقة الاستلام'),
                    items: paymentMethods.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                    onChanged: (v) => setDialogState(() => depositMethod = v!),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: isSaving ? null : () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: isSaving
                ? null
                : () async {
                    if (!formKey.currentState!.validate() || customerId == null) return;
                    if (itemType.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب نوع الصنف')));
                      return;
                    }
                    setDialogState(() => isSaving = true);
                    try {
                      final imageUrls = pickedImages.isEmpty
                          ? <String>[]
                          : await CloudinaryService.instance.uploadMultiple(
                              pickedImages.map((f) => f.bytes!.toList()).toList(),
                              folder: 'orders',
                            );
                      final customer = presetCustomer ?? customers.firstWhere((c) => c.id == customerId);
                      final repo = ref.read(repositoryProvider);
                      final orderId = await repo.addOrder(
                        customerId: customer.id,
                        customerName: customer.name,
                        itemType: itemType,
                        details: detailsController.text.trim(),
                        totalAmount: double.parse(totalController.text.trim()),
                        deliveryDate: deliveryDate,
                        imageUrls: imageUrls,
                      );
                      final deposit = double.tryParse(depositController.text.trim()) ?? 0;
                      String? depositTxId;
                      if (deposit > 0) {
                        depositTxId = await repo.addPayment(
                          orderId: orderId,
                          customerId: customer.id,
                          amount: deposit,
                          paymentType: 'deposit',
                          paymentMethod: depositMethod,
                        );
                      }
                      if (context.mounted) Navigator.pop(context);
                      if (deposit > 0 && depositTxId != null && context.mounted) {
                        await _offerReceiptPrint(
                          context,
                          customerName: customer.name,
                          itemType: itemType,
                          amount: deposit,
                          method: depositMethod,
                          date: DateTime.now(),
                        );
                      }
                    } catch (e) {
                      setDialogState(() => isSaving = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل حفظ الطلب: $e')));
                      }
                    }
                  },
            child: isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('حفظ'),
          ),
        ],
      ),
    ),
  );
}

Color _statusColor(String status) {
  switch (status) {
    case 'جاري التجهيز':
      return AppColors.warning;
    case 'قيد التنفيذ':
      return AppColors.navy;
    case 'جاهز للتسليم':
      return AppColors.success;
    case 'تم التسليم':
      return Colors.grey.shade600;
    default:
      return Colors.grey;
  }
}

/// شارة حالة الطلب - ملوّنة حسب الحالة وقابلة للضغط عليها مباشرة لتغيير
/// الحالة من غير ما تحتاج تدخل على تفاصيل الطلب
class _StatusChip extends ConsumerWidget {
  final Order order;
  const _StatusChip({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _statusColor(order.status);
    return PopupMenuButton<String>(
      tooltip: 'تغيير حالة الطلب',
      onSelected: (v) => ref.read(repositoryProvider).updateOrderStatus(order.id, v),
      itemBuilder: (context) => orderStatuses.map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(order.status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});
  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String? _statusFilter;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الطلبات'),
        backgroundColor: AppColors.wood,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => showAddOrderDialog(context, ref))],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                ChoiceChip(label: const Text('الكل'), selected: _statusFilter == null, onSelected: (_) => setState(() => _statusFilter = null)),
                const SizedBox(width: 8),
                ...orderStatuses.map((s) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(label: Text(s), selected: _statusFilter == s, onSelected: (_) => setState(() => _statusFilter = s)),
                    )),
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
            child: ordersAsync.when(
              data: (orders) {
                var filtered = _statusFilter == null ? orders : orders.where((o) => o.status == _statusFilter).toList();
                final q = normalizeForSearch(_query);
                if (q.isNotEmpty) {
                  filtered = filtered.where((o) {
                    return normalizeForSearch(o.customerName).contains(q) ||
                        normalizeForSearch(o.itemType).contains(q) ||
                        normalizeForSearch(o.details).contains(q);
                  }).toList();
                }
                if (filtered.isEmpty) return const Center(child: Text('لا توجد طلبات', style: TextStyle(color: Colors.grey)));
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final o = filtered[index];
                    final remaining = o.remaining;
                    return Card(
                      child: ListTile(
                        title: Text('${o.customerName} - ${o.itemType}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Text('تسليم: ${DateFormat('d/M/yyyy').format(DateTime.fromMillisecondsSinceEpoch(o.deliveryDate))}'),
                              const SizedBox(width: 8),
                              _StatusChip(order: o),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              remaining > 0 ? 'متبقي ${remaining.toStringAsFixed(0)}' : 'مكتمل',
                              style: TextStyle(color: remaining > 0 ? AppColors.danger : AppColors.success, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              tooltip: 'مشاركة على واتساب',
                              icon: const Icon(Icons.share_rounded, color: AppColors.success),
                              onPressed: () => _showShareToWorkerDialog(context, ref, o),
                            ),
                          ],
                        ),
                        onTap: () => showDialog(context: context, builder: (context) => OrderDetailDialog(order: o)),
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

class OrderDetailDialog extends ConsumerWidget {
  final Order order;
  const OrderDetailDialog({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);
    final currentOrder = (ordersAsync.value ?? []).firstWhereOrNull((o) => o.id == order.id) ?? order;
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final orderTransactions = (transactionsAsync.value ?? []).where((t) => t.orderId == order.id).toList()
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    final remaining = currentOrder.remaining;

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text('${currentOrder.customerName} - ${currentOrder.itemType}')),
          IconButton(
            tooltip: 'مشاركة على واتساب',
            icon: const Icon(Icons.share_rounded, color: AppColors.success),
            onPressed: () => _showShareToWorkerDialog(context, ref, currentOrder),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (currentOrder.details.isNotEmpty) Text(currentOrder.details, style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: currentOrder.status,
                decoration: const InputDecoration(labelText: 'حالة الطلب'),
                items: orderStatuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) {
                  if (v != null) ref.read(repositoryProvider).updateOrderStatus(currentOrder.id, v);
                },
              ),
              if (currentOrder.discountAmount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'الاتفاق الأصلي: ${currentOrder.totalAmount.toStringAsFixed(0)} ج.م - خصم ${currentOrder.discountAmount.toStringAsFixed(0)} ج.م'
                    '${currentOrder.discountReason.isNotEmpty ? ' (${currentOrder.discountReason})' : ''}',
                    style: const TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MoneyBox(label: 'الإجمالي', value: currentOrder.effectiveTotal),
                  _MoneyBox(label: 'المدفوع', value: currentOrder.totalPaid, color: AppColors.success),
                  _MoneyBox(label: 'المتبقي', value: remaining, color: remaining > 0 ? AppColors.danger : AppColors.success),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (remaining > 0)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddPaymentDialog(context, ref, currentOrder, remaining),
                        icon: const Icon(Icons.add_card_rounded),
                        label: const Text('تسجيل دفعة'),
                      ),
                    ),
                  if (remaining > 0) const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showAddExpenseDialog(context, ref, currentOrder),
                      icon: const Icon(Icons.receipt_long_rounded),
                      label: const Text('تسجيل مصروف'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.warning, side: const BorderSide(color: AppColors.warning)),
                  onPressed: () => _showDiscountDialog(context, ref, currentOrder),
                  icon: const Icon(Icons.percent_rounded),
                  label: Text(currentOrder.discountAmount > 0 ? 'تعديل الخصم' : 'عمل خصم'),
                ),
              ),
              const SizedBox(height: 16),
              const Align(alignment: Alignment.centerRight, child: Text('صور الطلب', style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(height: 8),
              _OrderImagesSection(order: currentOrder),
              const SizedBox(height: 16),
              const Align(alignment: Alignment.centerRight, child: Text('سجل الدفعات', style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(height: 8),
              if (orderTransactions.isEmpty)
                const Text('لا توجد دفعات مسجلة بعد', style: TextStyle(color: Colors.grey))
              else
                ...orderTransactions.map((t) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(t.paymentType == 'deposit' ? Icons.savings_rounded : Icons.payments_rounded, color: AppColors.wood),
                      title: Text('${t.amountPaid.toStringAsFixed(0)} ج.م'),
                      subtitle: Text(
                        '${t.paymentType == 'deposit' ? 'عربون' : 'قسط/دفعة'} - ${paymentMethods[t.paymentMethod] ?? t.paymentMethod}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              final next = t.status == 'completed' ? 'pending' : 'completed';
                              ref.read(repositoryProvider).updatePaymentStatus(t.id, next);
                            },
                            child: Chip(
                              label: Text(paymentStatuses[t.status] ?? t.status, style: const TextStyle(fontSize: 11)),
                              backgroundColor: t.status == 'completed'
                                  ? AppColors.success.withValues(alpha: 0.15)
                                  : AppColors.warning.withValues(alpha: 0.15),
                              labelStyle: TextStyle(color: t.status == 'completed' ? AppColors.success : AppColors.warning),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(DateFormat('d/M/yyyy').format(DateTime.fromMillisecondsSinceEpoch(t.paymentDate)), style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    )),
              const SizedBox(height: 16),
              const Align(alignment: Alignment.centerRight, child: Text('سجل المصروفات', style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(height: 8),
              _OrderExpensesList(orderId: order.id),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('حذف الطلب'),
                content: const Text('هل أنت متأكد من حذف هذا الطلب؟'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                  ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
                ],
              ),
            );
            if (confirm == true) {
              await ref.read(repositoryProvider).deleteOrder(currentOrder.id);
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: const Text('حذف الطلب', style: TextStyle(color: AppColors.danger)),
        ),
        ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
      ],
    );
  }

  void _showDiscountDialog(BuildContext context, WidgetRef ref, Order order) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController(
      text: order.discountAmount > 0 ? order.discountAmount.toStringAsFixed(0) : '',
    );
    final reasonController = TextEditingController(text: order.discountReason);
    final maxDiscount = order.totalAmount - order.totalPaid;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خصم على الطلب'),
        content: SizedBox(
          width: 380,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'الخصم مبلغ ثابت (مش نسبة) - بيتشال من الاتفاق الأصلي (${order.totalAmount.toStringAsFixed(0)} ج.م)، '
                    'ومش بيتحسب مديونية عليه ولا إيراد للورشة',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'مبلغ الخصم (ج.م)'),
                  validator: (v) {
                    final amount = double.tryParse(v ?? '');
                    if (amount == null || amount < 0) return 'أدخل مبلغ صحيح';
                    if (amount > maxDiscount) return 'الخصم أكبر من المتبقي (${maxDiscount.toStringAsFixed(0)} ج.م)';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(controller: reasonController, decoration: const InputDecoration(labelText: 'السبب (اختياري)')),
              ],
            ),
          ),
        ),
        actions: [
          if (order.discountAmount > 0)
            TextButton(
              onPressed: () async {
                await ref.read(repositoryProvider).setOrderDiscount(order, discountAmount: 0, reason: '');
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('إلغاء الخصم', style: TextStyle(color: AppColors.danger)),
            ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final amount = double.parse(amountController.text.trim());
              await ref.read(repositoryProvider).setOrderDiscount(order, discountAmount: amount, reason: reasonController.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showAddPaymentDialog(BuildContext context, WidgetRef ref, Order order, double maxAmount) {
    final controller = TextEditingController();
    String method = 'cash';
    String status = 'completed';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تسجيل دفعة'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'المبلغ (المتبقي ${maxAmount.toStringAsFixed(0)} ج.م)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: method,
                  decoration: const InputDecoration(labelText: 'طريقة الاستلام'),
                  items: paymentMethods.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                  onChanged: (v) => setDialogState(() => method = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'حالة الدفعة'),
                  items: paymentStatuses.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                  onChanged: (v) => setDialogState(() => status = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(controller.text.trim());
                if (amount == null || amount <= 0) return;
                await ref.read(repositoryProvider).addPayment(
                      orderId: order.id,
                      customerId: order.customerId,
                      amount: amount,
                      paymentType: 'installment',
                      paymentMethod: method,
                      status: status,
                    );
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  await _offerReceiptPrint(
                    context,
                    customerName: order.customerName,
                    itemType: order.itemType,
                    amount: amount,
                    method: method,
                    status: status,
                    date: DateTime.now(),
                  );
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, WidgetRef ref, Order order) {
    final formKey = GlobalKey<FormState>();
    final manualCategories = Map.fromEntries(expenseCategories.entries.where((e) => e.key != 'workshop_debt'));
    String category = manualCategories.keys.first;
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final workerController = TextEditingController();
    DateTime date = DateTime.now();
    String paymentMethod = 'cash';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تسجيل مصروف على الطلب'),
          content: SizedBox(
            width: 380,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OtherCapableDropdown(
                      options: manualCategories.entries.where((e) => e.key != 'other').map((e) => e.value).toList(),
                      label: 'الفئة',
                      value: manualCategories[category] ?? category,
                      onChanged: (v) => setDialogState(() => category = manualCategories.entries.firstWhereOrNull((e) => e.value == v)?.key ?? v),
                    ),
                    const SizedBox(height: 12),
                    if (category == 'wages')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(controller: workerController, decoration: const InputDecoration(labelText: 'اسم الصنايعي')),
                      ),
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'المبلغ (ج.م)'),
                      validator: (v) => (v == null || double.tryParse(v) == null) ? 'أدخل مبلغ صحيح' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(controller: descriptionController, maxLines: 2, decoration: const InputDecoration(labelText: 'الوصف (اختياري)')),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: paymentMethod,
                      decoration: const InputDecoration(labelText: 'اتخصم من (مصدر الدفع)'),
                      items: paymentMethods.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                      onChanged: (v) => setDialogState(() => paymentMethod = v ?? paymentMethod),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('التاريخ'),
                      subtitle: Text('${date.year}/${date.month}/${date.day}'),
                      trailing: const Icon(Icons.calendar_month_rounded),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setDialogState(() => date = picked);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                if (category.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب فئة المصروف')));
                  return;
                }
                final workerName = category == 'wages' && workerController.text.trim().isNotEmpty ? workerController.text.trim() : null;
                await ref.read(repositoryProvider).addExpense(
                      amount: double.parse(amountController.text.trim()),
                      category: category,
                      description: descriptionController.text.trim(),
                      workerName: workerName,
                      date: date,
                      orderId: order.id,
                      customerId: order.customerId,
                      customerName: order.customerName,
                      paymentMethod: paymentMethod,
                    );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}

/// قسم صور الطلب في نافذة التفاصيل - بيعرض الصور المرفوعة أصلًا (كـ
/// روابط Cloudinary)، وبيسمح برفع صور جديدة أو حذف صورة موجودة
class _OrderImagesSection extends ConsumerStatefulWidget {
  final Order order;
  const _OrderImagesSection({required this.order});

  @override
  ConsumerState<_OrderImagesSection> createState() => _OrderImagesSectionState();
}

class _OrderImagesSectionState extends ConsumerState<_OrderImagesSection> {
  bool _isUploading = false;

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: true, withData: true);
    if (result == null) return;
    final files = result.files.where((f) => f.bytes != null).toList();
    if (files.isEmpty) return;

    setState(() => _isUploading = true);
    try {
      final urls = await CloudinaryService.instance.uploadMultiple(
        files.map((f) => f.bytes!.toList()).toList(),
        folder: 'orders',
      );
      await ref.read(repositoryProvider).addImagesToOrder(widget.order, urls);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل رفع الصور: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _removeImage(String url) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الصورة'),
        content: const Text('هل أنت متأكد من حذف هذه الصورة من الطلب؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(repositoryProvider).removeImageFromOrder(widget.order, url);
    }
  }

  @override
  Widget build(BuildContext context) {
    // بنقرأ الطلب المحدّث دايمًا من الـ provider عشان الصور تظهر فورًا بعد الرفع
    final ordersAsync = ref.watch(ordersProvider);
    final currentOrder = (ordersAsync.value ?? []).firstWhereOrNull((o) => o.id == widget.order.id) ?? widget.order;
    final images = _parseOrderImages(currentOrder.imagesJson);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...images.map((url) => _ImageThumb(
              image: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded)),
              onTap: () => _showFullImage(context, url),
              onRemove: () => _removeImage(url),
            )),
        InkWell(
          onTap: _isUploading ? null : _pickAndUpload,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
            child: _isUploading
                ? const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.add_photo_alternate_rounded, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}

/// قائمة المصروفات المرتبطة بطلب معيّن - بتتحدث تلقائيًا لما نضيف مصروف جديد
class _OrderExpensesList extends ConsumerWidget {
  final String orderId;
  const _OrderExpensesList({required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(orderExpensesProvider(orderId));
    return expensesAsync.when(
      data: (expenses) {
        if (expenses.isEmpty) {
          return const Text('لا توجد مصروفات مسجلة على الطلب ده بعد', style: TextStyle(color: Colors.grey));
        }
        final sorted = [...expenses]..sort((a, b) => b.date.compareTo(a.date));
        return Column(
          children: sorted
              .map((e) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.receipt_long_rounded, color: AppColors.warning),
                    title: Text('${e.amount.toStringAsFixed(0)} ج.م - ${expenseCategories[e.category] ?? e.category}'),
                    subtitle: Text(
                      e.description.isNotEmpty
                          ? e.description
                          : (e.workerName != null ? 'الصنايعي: ${e.workerName}' : ''),
                    ),
                    trailing: Text(DateFormat('d/M/yyyy').format(DateTime.fromMillisecondsSinceEpoch(e.date))),
                  ))
              .toList(),
        );
      },
      loading: () => const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text('خطأ: $e', style: const TextStyle(color: AppColors.danger)),
    );
  }
}

class _MoneyBox extends StatelessWidget {
  final String label;
  final double value;
  final Color? color;
  const _MoneyBox({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value.toStringAsFixed(0), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
      ],
    );
  }
}
