import 'dart:async';
import 'package:flutter/material.dart';

/// Reports a failed action after a confirmation dialog has already closed.
Future<bool> runGuardedSave(
  BuildContext context,
  FutureOr<void> Function() action,
) async {
  try {
    await action();
    return true;
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذر تنفيذ العملية: $error')));
    }
    return false;
  }
}

/// Serializes one button action and reports failures. App-level mutation state
/// blocks interaction only while the repository actually writes, so a callback
/// may safely open a confirmation dialog before starting its transaction.
class SafeSaveButton extends StatefulWidget {
  const SafeSaveButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  }) : textOnly = false;
  const SafeSaveButton.text({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  }) : textOnly = true;
  final FutureOr<void> Function()? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool textOnly;
  @override
  State<SafeSaveButton> createState() => _SafeSaveButtonState();
}

class _SafeSaveButtonState extends State<SafeSaveButton> {
  bool _busy = false;
  Future<void> _save() async {
    if (_busy || widget.onPressed == null) return;
    setState(() => _busy = true);
    try {
      await widget.onPressed!();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر تنفيذ العملية: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => widget.textOnly
      ? TextButton(
          onPressed: _busy || widget.onPressed == null ? null : _save,
          style: widget.style,
          child: widget.child,
        )
      : ElevatedButton(
          onPressed: _busy || widget.onPressed == null ? null : _save,
          style: widget.style,
          child: widget.child,
        );
}
