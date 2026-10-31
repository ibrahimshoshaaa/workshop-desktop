import 'package:flutter/material.dart';
import '../providers/mutation_provider.dart';
import '../services/backup_service.dart';

/// Every ordinary exit gets one reminder. We cannot infer whether Drive has
/// uploaded a file merely because the file was copied to its local folder.
class CloseBackupDialog extends StatefulWidget {
  const CloseBackupDialog({
    super.key,
    required this.backup,
    required this.mutations,
    this.shutdown = false,
  });

  final BackupService backup;
  final MutationState mutations;
  final bool shutdown;

  @override
  State<CloseBackupDialog> createState() => _CloseBackupDialogState();
}

class _CloseBackupDialogState extends State<CloseBackupDialog> {
  bool _working = false;
  bool _saved = false;
  bool _copiedToDriveFolder = false;
  bool _driveConfirmed = false;
  String? _error;

  bool get _busy => _working || widget.backup.busy || widget.mutations.busy;
  bool get _hasDrive => widget.backup.secondaryFolder?.isNotEmpty == true;
  bool get _needsSave => !_saved || (_hasDrive && !_copiedToDriveFolder);

  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _working = true;
      _driveConfirmed = false;
      _error = null;
    });
    try {
      await widget.backup.createBackup();
      if (!mounted) return;
      setState(() {
        _saved = true;
        _copiedToDriveFolder = _hasDrive && widget.backup.error == null;
        _error = widget.backup.error;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _saved = false;
          _error = widget.backup.error ?? 'تعذر حفظ النسخة: $error';
        });
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _skip() async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إغلاق بدون نسخة احتياطية جديدة؟'),
        content: const Text(
          'البيانات المحفوظة ستظل على اللاب، لكن آخر التعديلات قد لا تكون ضمن نسخة احتياطية خارجية. هل تريد الإغلاق الآن؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('رجوع'),
          ),
          TextButton(
            onPressed: () {
              if (!_busy) Navigator.pop(dialogContext, true);
            },
            child: const Text('إغلاق بدون نسخة'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted && !_busy) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([widget.backup, widget.mutations]),
        builder: (context, _) => PopScope(
          canPop: false,
          child: AlertDialog(
            scrollable: true,
            title: const Text('قبل إغلاق البرنامج'),
            content: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'احفظ نسخة احتياطية حديثة قبل الخروج. النسخة تشمل البيانات التي ضغطت لها حفظ داخل البرنامج.',
                  ),
                  if (widget.shutdown) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'ويندوز طلب الإغلاق. اختر إلغاء في شاشة إغلاق ويندوز، ثم أكمل النسخ هنا. بعد إغلاق البرنامج يمكنك طلب إغلاق ويندوز مرة أخرى.',
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text('آخر نسخة محلية: ${widget.backup.lastBackup ?? 'لم يتم النسخ بعد'}'),
                  const SizedBox(height: 10),
                  if (_busy)
                    const Text('انتظر انتهاء الحفظ أو النسخ الجاري قبل الإغلاق.'),
                  if (_saved)
                    const Text('تم حفظ نسخة محلية وفحص سلامتها.'),
                  if (_saved && _copiedToDriveFolder) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'تم النسخ إلى مجلد Drive. افتح Google Drive بجوار الساعة وانتظر اكتمال المزامنة؛ البرنامج لا يستطيع تأكيد الرفع إلى السحابة.',
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _driveConfirmed,
                      onChanged: _busy ? null : (value) => setState(() => _driveConfirmed = value ?? false),
                      title: const Text('راجعت Google Drive واكتمل رفع النسخة'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                  if (!_hasDrive) ...[
                    const SizedBox(height: 8),
                    const Text('لم يتم اختيار مجلد Drive؛ النسخة ستُحفظ محليًا فقط. يمكنك الرجوع للإعدادات لربط المجلد.'),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: _busy ? null : () => Navigator.pop(context, false),
                child: const Text('رجوع للبرنامج'),
              ),
              TextButton(
                onPressed: _busy ? null : _skip,
                child: const Text('إغلاق بدون نسخة جديدة'),
              ),
              FilledButton(
                onPressed: _busy
                    ? null
                    : _needsSave
                        ? _save
                        : (!_hasDrive || _driveConfirmed)
                            ? () => Navigator.pop(context, true)
                            : null,
                child: Text(_needsSave ? 'نسخ احتياطي الآن' : 'إغلاق البرنامج'),
              ),
            ],
          ),
        ),
      );
}
