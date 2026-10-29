import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Covers actual database transactions, including nested repository calls.
/// Confirmation dialogs can remain interactive before a write begins.
class MutationState extends ChangeNotifier {
  int _count = 0;
  bool _disposed = false;
  bool get busy => _count > 0;
  void changed(bool entering) {
    _count += entering ? 1 : -1;
    assert(_count >= 0);
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

final mutationStateProvider = ChangeNotifierProvider<MutationState>(
  (ref) => MutationState(),
);
