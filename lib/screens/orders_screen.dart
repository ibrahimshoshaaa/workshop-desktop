import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:collection/collection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../providers/data_providers.dart';
import '../providers/navigation_provider.dart';
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('تسجيل الدفعة تم بنجاح', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
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
          borderRadius: BorderRadius.circular(12),
          child: GestureDetector(
            onTap: onTap,
            child: SizedBox(width: 76, height: 76, child: image),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
              ),
            ),
          ),
      ],
    );
  }
}

/// مربع رفع/إضافة صورة موحّد الشكل - نفس مقاس _ImageThumb بالظبط
class _AddImageTile extends StatelessWidget {
  final VoidCallback? onTap;
  final bool loading;
  const _AddImageTile({this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: loading
            ? const Padding(padding: EdgeInsets.all(22), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.wood))
            : Icon(Icons.add_photo_alternate_rounded, color: Colors.grey.shade400),
      ),
    );
  }
}

const _itemTypes = ['أنتريه', 'صالون', 'ركنة', 'ستائر', 'سرير', 'كنب', 'أخرى'];

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
Future<void> showShareToWorkerDialog(BuildContext context, WidgetRef ref, Order order) async {
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('ابعت المواصفات لأي صنايعي؟', style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 16)),
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
                      ? const _EmptyState(icon: Icons.engineering_rounded, text: 'لا يوجد صنايعي بالاسم ده')
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final w = filtered[index];
                            return _MiniRow(
                              icon: Icons.engineering_rounded,
                              title: w.name,
                              subtitle: w.jobTitle.isNotEmpty ? '${w.jobTitle} - ${w.phone}' : w.phone,
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
  // بنحتفظ بالـ context الأصلي بتاع الشاشة (مش بتاع نافذة الحوار) عشان
  // نستخدمه بعد قفل الحوار - لو استخدمنا نفس context بتاع الحوار بعد ما
  // يتقفل، بيبقى unmounted وأي حاجة بعده (زي عرض شاشة طباعة الإيصال)
  // بتتجاهل بصمت من غير أي رسالة خطأ.
  final parentContext = context;
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(presetCustomer == null ? 'طلب جديد' : 'طلب جديد لـ ${presetCustomer.name}',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 17)),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (presetCustomer == null)
                    DropdownButtonFormField<String>(
                      value: customerId,
                      decoration: _fieldDecoration('العميل', Icons.person_outline_rounded),
                      items: customers.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name} - ${c.phone}'))).toList(),
                      onChanged: (v) => setDialogState(() => customerId = v),
                    )
                  else
                    TextFormField(
                      initialValue: '${presetCustomer.name} - ${presetCustomer.phone}',
                      enabled: false,
                      decoration: _fieldDecoration('العميل', Icons.person_outline_rounded),
                    ),
                  const SizedBox(height: 14),
                  OtherCapableDropdown(
                    options: _itemTypes.where((t) => t != kOtherOptionValue).toList(),
                    label: 'نوع الصنف',
                    value: itemType,
                    onChanged: (v) => setDialogState(() => itemType = v),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: detailsController,
                    maxLines: 2,
                    decoration: _fieldDecoration('المواصفات', Icons.notes_rounded),
                  ),
                  const SizedBox(height: 16),
                  _FieldLabel('صور الطلب'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ...pickedImages.map((f) => _ImageThumb(
                            image: Image.memory(f.bytes!, fit: BoxFit.cover),
                            onRemove: () => setDialogState(() => pickedImages.remove(f)),
                          )),
                      _AddImageTile(
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DatePickerRow(
                    label: 'تاريخ التسليم',
                    date: deliveryDate,
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
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: totalController,
                    keyboardType: TextInputType.number,
                    decoration: _fieldDecoration('إجمالي الاتفاق (ج.م)', Icons.request_quote_outlined),
                    validator: (v) => (v == null || double.tryParse(v) == null) ? 'أدخل مبلغ صحيح' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: depositController,
                    keyboardType: TextInputType.number,
                    decoration: _fieldDecoration('العربون المدفوع الآن (اختياري)', Icons.savings_outlined),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: depositMethod,
                    decoration: _fieldDecoration('طريقة الاستلام', Icons.payments_outlined),
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
                      if (deposit > 0 && depositTxId != null && parentContext.mounted) {
                        await _offerReceiptPrint(
                          parentContext,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (context) => orderStatuses.map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(order.status, style: GoogleFonts.cairo(color: color, fontWeight: FontWeight.w700, fontSize: 11.5)),
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

    return Container(
      color: const Color(0xFFFAF6F0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
            child: _PageHeader(
              title: 'الطلبات',
              subtitle: 'متابعة كل طلبات العملاء وحالتها',
              icon: Icons.checkroom_rounded,
              badge: ordersAsync.value != null ? '${ordersAsync.value!.length} طلب' : null,
              actionLabel: 'طلب جديد',
              actionIcon: Icons.add_rounded,
              onAction: () => showAddOrderDialog(context, ref),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
            child: SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(label: 'الكل', selected: _statusFilter == null, onTap: () => setState(() => _statusFilter = null)),
                  const SizedBox(width: 8),
                  ...orderStatuses.map((s) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _FilterChip(
                          label: s,
                          color: _statusColor(s),
                          selected: _statusFilter == s,
                          onTap: () => setState(() => _statusFilter = s),
                        ),
                      )),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 14, 28, 0),
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
                if (filtered.isEmpty) {
                  return const _EmptyState(icon: Icons.checkroom_outlined, text: 'لا توجد طلبات');
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final o = filtered[index];
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
                                width: 4,
                                height: 40,
                                decoration: BoxDecoration(color: _statusColor(o.status), borderRadius: BorderRadius.circular(4)),
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
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('تسليم: ${DateFormat('d/M/yyyy').format(DateTime.fromMillisecondsSinceEpoch(o.deliveryDate))}',
                                            style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey.shade500)),
                                        const SizedBox(width: 8),
                                        _StatusChip(order: o),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                remaining > 0 ? 'متبقي ${remaining.toStringAsFixed(0)}' : 'مكتمل',
                                style: TextStyle(
                                  color: remaining > 0 ? AppColors.danger : AppColors.success,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                              ),
                              IconButton(
                                tooltip: 'مشاركة على واتساب',
                                icon: const Icon(Icons.share_rounded, color: AppColors.success, size: 20),
                                onPressed: () => showShareToWorkerDialog(context, ref, o),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.wood)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Row(
        children: [
          Expanded(
            child: Text('${currentOrder.customerName} - ${currentOrder.itemType}',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
          IconButton(
            tooltip: 'مشاركة على واتساب',
            icon: const Icon(Icons.share_rounded, color: AppColors.success),
            onPressed: () => showShareToWorkerDialog(context, ref, currentOrder),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (currentOrder.details.isNotEmpty)
                Text(currentOrder.details, style: GoogleFonts.cairo(color: Colors.grey.shade700, fontSize: 13)),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: currentOrder.status,
                decoration: _fieldDecoration('حالة الطلب', Icons.flag_outlined),
                items: orderStatuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) {
                  if (v != null) ref.read(repositoryProvider).updateOrderStatus(currentOrder.id, v);
                },
              ),
              if (currentOrder.discountAmount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'الاتفاق الأصلي: ${currentOrder.totalAmount.toStringAsFixed(0)} ج.م - خصم ${currentOrder.discountAmount.toStringAsFixed(0)} ج.م'
                    '${currentOrder.discountReason.isNotEmpty ? ' (${currentOrder.discountReason})' : ''}',
                    style: GoogleFonts.cairo(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(height: 18),
              _HoverCard(
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MoneyBox(label: 'الإجمالي', value: currentOrder.effectiveTotal),
                      _MoneyBox(label: 'المدفوع', value: currentOrder.totalPaid, color: AppColors.success),
                      _MoneyBox(label: 'المتبقي', value: remaining, color: remaining > 0 ? AppColors.danger : AppColors.success),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.warning, side: const BorderSide(color: AppColors.warning)),
                  onPressed: () => _showDiscountDialog(context, ref, currentOrder),
                  icon: const Icon(Icons.percent_rounded),
                  label: Text(currentOrder.discountAmount > 0 ? 'تعديل الخصم' : 'عمل خصم'),
                ),
              ),
              if (remaining < 0) ...[
                const SizedBox(height: 14),
                Builder(builder: (context) {
                  final linkedDebt = (ref.watch(workshopDebtsProvider).value ?? [])
                      .firstWhereOrNull((d) => d.orderId == currentOrder.id);
                  final owed = linkedDebt?.remaining ?? remaining.abs();
                  if (owed <= 0) return const SizedBox.shrink();
                  return _HoverCard(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => ref.read(selectedTabProvider.notifier).state = 4,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.wood.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          const Icon(Icons.storefront_rounded, color: AppColors.wood, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'العميل دفع ${owed.toStringAsFixed(0)} ج.م زيادة عن الاتفاق الحالي - '
                              'مسجّلة كمديونية ورشة، سدّدها من هناك وهتتظبط تلقائي',
                              style: GoogleFonts.cairo(fontSize: 12, color: AppColors.wood, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const Icon(Icons.chevron_left_rounded, color: AppColors.wood, size: 18),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 20),
              _FieldLabel('صور الطلب'),
              const SizedBox(height: 10),
              _OrderImagesSection(order: currentOrder),
              const SizedBox(height: 20),
              _FieldLabel('سجل الدفعات'),
              const SizedBox(height: 10),
              if (orderTransactions.isEmpty)
                const _EmptyState(icon: Icons.receipt_outlined, text: 'لا توجد دفعات مسجلة بعد')
              else
                ...orderTransactions.map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _MiniRow(
                        icon: t.paymentType == 'deposit' ? Icons.savings_rounded : Icons.payments_rounded,
                        title: '${t.amountPaid.toStringAsFixed(0)} ج.م',
                        subtitle: '${t.paymentType == 'deposit' ? 'عربون' : 'قسط/دفعة'} - ${paymentMethods[t.paymentMethod] ?? t.paymentMethod}',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                final next = t.status == 'completed' ? 'pending' : 'completed';
                                ref.read(repositoryProvider).updatePaymentStatus(t.id, next);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: t.status == 'completed'
                                      ? AppColors.success.withValues(alpha: 0.15)
                                      : AppColors.warning.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  paymentStatuses[t.status] ?? t.status,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: t.status == 'completed' ? AppColors.success : AppColors.warning,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(DateFormat('d/M/yyyy').format(DateTime.fromMillisecondsSinceEpoch(t.paymentDate)),
                                style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                    )),
              const SizedBox(height: 20),
              _FieldLabel('سجل المصروفات'),
              const SizedBox(height: 10),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('خصم على الطلب', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
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
                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: _fieldDecoration('مبلغ الخصم (ج.م)', Icons.percent_rounded),
                  validator: (v) {
                    final amount = double.tryParse(v ?? '');
                    if (amount == null || amount < 0) return 'أدخل مبلغ صحيح';
                    if (amount > maxDiscount) return 'الخصم أكبر من المتبقي (${maxDiscount.toStringAsFixed(0)} ج.م)';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(controller: reasonController, decoration: _fieldDecoration('السبب (اختياري)', Icons.notes_rounded)),
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
    // نفس ملاحظة showAddOrderDialog: بنمسك context الشاشة قبل ما نفتح الحوار
    final parentContext = context;
    final controller = TextEditingController();
    String method = 'cash';
    String status = 'completed';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('تسجيل دفعة', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: _fieldDecoration('المبلغ (المتبقي ${maxAmount.toStringAsFixed(0)} ج.م)', Icons.payments_outlined),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: method,
                  decoration: _fieldDecoration('طريقة الاستلام', Icons.account_balance_wallet_outlined),
                  items: paymentMethods.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                  onChanged: (v) => setDialogState(() => method = v!),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: _fieldDecoration('حالة الدفعة', Icons.flag_outlined),
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
                if (parentContext.mounted) {
                  await _offerReceiptPrint(
                    parentContext,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('تسجيل مصروف على الطلب', style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 16)),
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
                    const SizedBox(height: 14),
                    if (category == 'wages')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: TextFormField(controller: workerController, decoration: _fieldDecoration('اسم الصنايعي', Icons.engineering_outlined)),
                      ),
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: _fieldDecoration('المبلغ (ج.م)', Icons.payments_outlined),
                      validator: (v) => (v == null || double.tryParse(v) == null) ? 'أدخل مبلغ صحيح' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                        controller: descriptionController, maxLines: 2, decoration: _fieldDecoration('الوصف (اختياري)', Icons.notes_rounded)),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: paymentMethod,
                      decoration: _fieldDecoration('اتخصم من (مصدر الدفع)', Icons.account_balance_wallet_outlined),
                      items: paymentMethods.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                      onChanged: (v) => setDialogState(() => paymentMethod = v ?? paymentMethod),
                    ),
                    const SizedBox(height: 14),
                    _DatePickerRow(
                      label: 'التاريخ',
                      date: date,
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
                      paymentMethod: paymentMethod,
                      orderAllocations: [
                        ExpenseOrderAllocation(
                          orderId: order.id,
                          customerId: order.customerId,
                          customerName: order.customerName,
                          amount: double.parse(amountController.text.trim()),
                        ),
                      ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
      spacing: 10,
      runSpacing: 10,
      children: [
        ...images.map((url) => _ImageThumb(
              image: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded)),
              onTap: () => _showFullImage(context, url),
              onRemove: () => _removeImage(url),
            )),
        _AddImageTile(onTap: _pickAndUpload, loading: _isUploading),
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
    final shares = ref.watch(orderExpensesProvider(orderId));
    if (shares.isEmpty) {
      return const _EmptyState(icon: Icons.receipt_long_outlined, text: 'لا توجد مصروفات مسجلة على الطلب ده بعد');
    }
    final sorted = [...shares]..sort((a, b) => b.expense.date.compareTo(a.expense.date));
    return Column(
      children: sorted
          .map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MiniRow(
                  icon: Icons.receipt_long_rounded,
                  iconColor: AppColors.warning,
                  title: s.totalOrdersCount > 1
                      ? '${s.shareAmount.toStringAsFixed(0)} ج.م (نصيبك من ${s.expense.amount.toStringAsFixed(0)} ج.م) - ${expenseCategories[s.expense.category] ?? s.expense.category}'
                      : '${s.shareAmount.toStringAsFixed(0)} ج.م - ${expenseCategories[s.expense.category] ?? s.expense.category}',
                  subtitle: [
                    if (s.expense.description.isNotEmpty) s.expense.description,
                    if (s.expense.workerName != null) 'الصنايعي: ${s.expense.workerName}',
                    if (s.totalOrdersCount > 1) 'مقسّم على ${s.totalOrdersCount} طلبات',
                  ].join(' - '),
                  trailing: Text(DateFormat('d/M/yyyy').format(DateTime.fromMillisecondsSinceEpoch(s.expense.date)),
                      style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey.shade500)),
                ),
              ))
          .toList(),
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
        Text(label, style: GoogleFonts.cairo(color: Colors.grey.shade500, fontSize: 12)),
        const SizedBox(height: 5),
        Text(value.toStringAsFixed(0), style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 16, color: color ?? const Color(0xFF2A2320))),
      ],
    );
  }
}

// ==================== الويدجت المشتركة (نفس أسلوب الداشبورد) ====================

InputDecoration _fieldDecoration(String label, [IconData? icon]) {
  return InputDecoration(
    labelText: label,
    prefixIcon: icon != null ? Icon(icon, size: 20, color: AppColors.wood) : null,
    filled: true,
    fillColor: Colors.grey.shade50,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
    focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppColors.wood, width: 1.5)),
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(text, style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.w800, color: const Color(0xFF2A2320))),
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DatePickerRow({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: AppColors.wood, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade500)),
                  Text('${date.year}/${date.month}/${date.day}', style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Icon(Icons.chevron_left_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.wood;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? c : Colors.grey.shade300),
        ),
        child: Text(label,
            style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w700, color: selected ? Colors.white : Colors.grey.shade700)),
      ),
    );
  }
}

class _MiniRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _MiniRow({required this.icon, required this.title, required this.subtitle, this.iconColor, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return _HoverCard(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: (iconColor ?? AppColors.wood).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: iconColor ?? AppColors.wood),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF2A2320))),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey.shade500)),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? badge;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;
  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < 620;
      final title0 = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.wood.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: AppColors.wood, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF2A2320))),
                  if (badge != null) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.wood.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(badge!, style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.wood)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade600)),
            ],
          ),
        ],
      );

      final action = _HoverCard(
        onTap: onAction,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.wood, AppColors.woodDark]), borderRadius: BorderRadius.circular(14)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(actionIcon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(actionLabel, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
        ),
      );

      if (narrow) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title0, const SizedBox(height: 16), action]);
      }
      return Row(children: [Expanded(child: title0), action]);
    });
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
          Icon(icon, size: 42, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(text, style: GoogleFonts.cairo(fontSize: 13.5, color: Colors.grey.shade400)),
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
