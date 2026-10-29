import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/backup_provider.dart';
import '../providers/database_provider.dart';
import '../services/legacy_import_service.dart';
import '../services/local_media_service.dart';
import '../services/data_integrity_service.dart';

class LocalDataPanel extends ConsumerStatefulWidget {
  const LocalDataPanel({super.key});
  @override
  ConsumerState<LocalDataPanel> createState() => _LocalDataPanelState();
}

class _LocalDataPanelState extends ConsumerState<LocalDataPanel> {
  bool working = false;
  String? message;
  Future<void> _run(Future<String> Function() action) async {
    if (working) return;
    setState(() {
      working = true;
      message = null;
    });
    try {
      final result = await action();
      if (mounted) setState(() => message = result);
    } catch (e) {
      if (mounted) setState(() => message = 'تعذر تنفيذ العملية: $e');
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> _restore() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wbackup'],
    );
    final path = result?.files.single.path;
    if (path == null || !mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استرجاع نسخة احتياطية'),
        content: const Text(
          'سيتم استبدال البيانات والحسابات بمحتوى النسخة بعد إعادة التشغيل. سيتم حفظ نسخة رجوع من البيانات الحالية أولًا. ستحتاج لتسجيل الدخول بحساب موجود داخل النسخة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تجهيز الاسترجاع'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(backupServiceProvider).stageRestore(File(path));
  }

  Future<String> _import() async {
    final selected = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    final path = selected?.files.single.path;
    if (path == null) return 'تم إلغاء الاستيراد';
    final service = LegacyImportService(
      ref.read(databaseProvider),
      ref.read(backupServiceProvider),
    );
    final preview = await service.preview(File(path));
    if (!mounted) return '';
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('مراجعة بيانات Firebase'),
          content: SizedBox(
            width: 720,
            height: 440,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'جديد: ${preview.additions} — مطابق: ${preview.unchanged} — مختلف: ${preview.conflicts.length}',
                ),
                const SizedBox(height: 8),
                const Text(
                  'السجلات المحلية غير الموجودة في الملف ستظل محفوظة. حسابات Firebase وكلمات مرورها لا تُنقل؛ حسابات النسخة المحلية مستقلة.',
                ),
                const SizedBox(height: 8),
                const Text(
                  'لكل اختلاف اختر النسخة المطلوبة. اختيار بيانات اللاب هو الافتراضي. اضغط على السجل لعرض القيم.',
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    children: preview.conflicts
                        .map(
                          (r) => ListTile(
                            title: Text('${r.node}: ${r.label}'),
                            subtitle: Text('المعرّف: ${r.incoming['id']}'),
                            onTap: () => showDialog<void>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(r.label),
                                content: SizedBox(
                                  width: 640,
                                  child: SingleChildScrollView(
                                    child: SelectableText(
                                      'اللاب:\n${const JsonEncoder.withIndent('  ').convert(r.existing)}\n\nFirebase:\n${const JsonEncoder.withIndent('  ').convert(r.incoming)}',
                                      textDirection: TextDirection.ltr,
                                    ),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('إغلاق'),
                                  ),
                                ],
                              ),
                            ),
                            trailing: DropdownButton<bool>(
                              value: r.useIncoming,
                              items: const [
                                DropdownMenuItem(
                                  value: false,
                                  child: Text('بيانات اللاب'),
                                ),
                                DropdownMenuItem(
                                  value: true,
                                  child: Text('بيانات الملف'),
                                ),
                              ],
                              onChanged: (v) =>
                                  update(() => r.useIncoming = v ?? false),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حفظ نسخة رجوع واستيراد المختار'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return 'تم إلغاء الاستيراد';
    final count = await service.apply(preview);
    return 'تم استيراد $count سجل. البيانات السابقة والملف الأصلي محفوظان. احفظ الصور القديمة ثم أنشئ نسخة احتياطية جديدة.';
  }

  Future<String> _cacheImages() async {
    final db = ref.read(databaseProvider);
    final orders = await db.select(db.orders).get();
    final references = <String>{};
    for (final order in orders) {
      references.addAll(
        (jsonDecode(order.imagesJson) as List).map((e) => e.toString()),
      );
    }
    final media = LocalMediaService(ref.read(localPathsProvider));
    var saved = 0;
    for (final reference in references) {
      try {
        if (await media.cacheLegacy(reference)) saved++;
      } catch (_) {
        /* Report every missing asset in the result. */
      }
    }
    return 'الصور المحفوظة: $saved من ${references.length}. المتبقي: ${references.length - saved}. الصور القديمة تحتاج إنترنت لحفظها أول مرة.';
  }

  Future<String> _scanData() async {
    final issues = await DataIntegrityService(
      ref.read(databaseProvider),
    ).scan();
    if (issues.isEmpty)
      return 'الفحص لم يجد اختلافات في الحسابات والروابط التي تم اختبارها.';
    return 'تنبيهات الفحص: ${issues.length}\n${issues.map((i) => '• ${i.message}').join('\n')}';
  }

  Future<String> _repairDerived() async {
    final service = DataIntegrityService(ref.read(databaseProvider));
    final before = await service.scan();
    final ids = before
        .map((i) => i.repairOrderId)
        .whereType<String>()
        .toSet()
        .toList();
    if (ids.isEmpty)
      return 'لا توجد إجماليات قابلة لإعادة البناء الآمن. التنبيهات الأخرى تحتاج مراجعة السجلات الأصلية.';
    await ref.read(backupServiceProvider).createBackup();
    final count = await service.repairDerivedOrders(ids);
    return 'تم تحديث إجماليات $count طلب من دفتر الدفعات بعد حفظ نسخة رجوع.\n${await _scanData()}';
  }

  @override
  Widget build(BuildContext context) {
    final backup = ref.watch(backupServiceProvider);
    final disabled = working || backup.busy;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'البيانات المحلية والنسخ الاحتياطي',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'البيانات محفوظة على هذا اللاب. لا توجد مزامنة مع الموبايل أو Firebase. نسخة تلقائية عند التشغيل وكل ساعة أثناء تشغيل البرنامج؛ نحتفظ بآخر 30 نسخة محلية.',
            ),
            const SizedBox(height: 8),
            SelectableText(
              'آخر نسخة محلية: ${backup.lastBackup ?? 'لم يتم النسخ بعد'}',
            ),
            SelectableText(
              'المجلد الإضافي: ${backup.secondaryFolder?.isNotEmpty == true ? backup.secondaryFolder : 'غير محدد'}',
            ),
            const Text(
              'اختار مجلدًا متزامنًا باستخدام Google Drive لو عايز نسخة خارج اللاب. الحفظ في المجلد لا يؤكد اكتمال الرفع؛ راجع حالة Google Drive. مجلد قاعدة البيانات الأساسية يفضل محليًا.',
            ),
            if (backup.error != null)
              Text(backup.error!, style: const TextStyle(color: Colors.red)),
            if (message != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SelectableText(message!),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: disabled ? null : () => _run(_scanData),
                  icon: const Icon(Icons.fact_check),
                  label: const Text('فحص الحسابات والروابط'),
                ),
                OutlinedButton.icon(
                  onPressed: disabled ? null : () => _run(_repairDerived),
                  icon: const Icon(Icons.calculate),
                  label: const Text('تحديث الإجماليات من الدفعات'),
                ),

                OutlinedButton.icon(
                  onPressed: disabled
                      ? null
                      : () => _run(() async {
                          await backup.createBackup();
                          return backup.error ??
                              'تم حفظ نسخة احتياطية وفحص سلامتها';
                        }),
                  icon: const Icon(Icons.backup),
                  label: const Text('نسخ احتياطي الآن'),
                ),
                OutlinedButton.icon(
                  onPressed: disabled
                      ? null
                      : () => _run(() async {
                          final folder = await FilePicker.platform
                              .getDirectoryPath(
                                dialogTitle: 'اختار مجلد النسخ الإضافية',
                              );
                          if (folder != null)
                            await backup.setSecondaryFolder(folder);
                          return folder == null
                              ? 'تم الإلغاء'
                              : 'تم حفظ المجلد. اضغط نسخ احتياطي الآن لاختباره.';
                        }),
                  icon: const Icon(Icons.folder),
                  label: const Text('اختيار مجلد Drive'),
                ),
                if (backup.secondaryFolder?.isNotEmpty == true)
                  TextButton(
                    onPressed: disabled
                        ? null
                        : () => _run(() async {
                            await backup.setSecondaryFolder(null);
                            return 'تم إيقاف النسخ للمجلد الإضافي';
                          }),
                    child: const Text('إيقاف النسخة الإضافية'),
                  ),
                OutlinedButton.icon(
                  onPressed: disabled
                      ? null
                      : () => _run(() async {
                          await _restore();
                          return 'تم تجهيز الاسترجاع';
                        }),
                  icon: const Icon(Icons.restore),
                  label: const Text('استرجاع نسخة'),
                ),
                OutlinedButton.icon(
                  onPressed: disabled ? null : () => _run(_import),
                  icon: const Icon(Icons.file_open),
                  label: const Text('استيراد تصدير Firebase'),
                ),
                OutlinedButton.icon(
                  onPressed: disabled ? null : () => _run(_cacheImages),
                  icon: const Icon(Icons.download),
                  label: const Text('حفظ الصور القديمة محليًا'),
                ),
              ],
            ),
            if (working)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
