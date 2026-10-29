import 'dart:async';
import 'package:flutter/material.dart';

/// One submitted operation at a time. The overlay also prevents dismissing a
/// form and submitting the same operation again before persistence completes.
class SafeSaveButton extends StatefulWidget {
  const SafeSaveButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  });
  final FutureOr<void> Function()? onPressed;
  final Widget child;
  final ButtonStyle? style;
  @override
  State<SafeSaveButton> createState() => _SafeSaveButtonState();
}

class _SafeSaveButtonState extends State<SafeSaveButton> {
  bool _busy = false;
  OverlayEntry? _overlay;
  void _clearOverlay() {
    _overlay?.remove();
    _overlay?.dispose();
    _overlay = null;
  }

  Future<void> _save() async {
    if (_busy || widget.onPressed == null) return;
    setState(() => _busy = true);
    _overlay = OverlayEntry(
      builder: (_) => const Stack(
        children: [
          ModalBarrier(dismissible: false, color: Color(0x44000000)),
          Center(child: CircularProgressIndicator()),
        ],
      ),
    );
    Overlay.of(context).insert(_overlay!);
    try {
      await widget.onPressed!();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر تنفيذ العملية: $e')));
    } finally {
      _clearOverlay();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _clearOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: _busy || widget.onPressed == null ? null : _save,
    style: widget.style,
    child: widget.child,
  );
}
