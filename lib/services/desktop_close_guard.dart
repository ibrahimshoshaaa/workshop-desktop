import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/mutation_provider.dart';
import '../screens/close_backup_dialog.dart';
import 'backup_service.dart';

/// The native runner intercepts the main window before Flutter's delegates.
/// This also works when a plugin creates another invisible top-level window.
class DesktopCloseBridge {
  static const channel = MethodChannel('workshop/close_guard');

  Future<void> initialize(Future<void> Function(bool) onRequest) async {
    if (!Platform.isWindows) return;
    channel.setMethodCallHandler((call) async {
      if (call.method != 'closeRequested') return;
      final arguments = call.arguments as Map?;
      await onRequest(arguments?['shutdown'] == true);
    });
    await channel.invokeMethod<void>('ready');
  }

  Future<void> finish(bool close) async {
    if (Platform.isWindows) {
      await channel.invokeMethod<void>('finishClose', close);
    }
  }

  void dispose() => channel.setMethodCallHandler(null);
}

class DesktopCloseGuard {
  DesktopCloseGuard({
    required this.navigatorKey,
    required this.backup,
    required this.mutations,
    DesktopCloseBridge? bridge,
  }) : bridge = bridge ?? DesktopCloseBridge();

  final GlobalKey<NavigatorState> navigatorKey;
  final BackupService backup;
  final MutationState mutations;
  final DesktopCloseBridge bridge;
  bool _asking = false;
  bool _disposed = false;

  Future<void> start() async {
    try {
      await bridge.initialize(requestClose);
    } catch (error) {
      debugPrint('Close guard could not start: $error');
    }
  }

  Future<void> requestClose(bool shutdown) async {
    if (_asking || _disposed) return;
    _asking = true;
    var close = false;
    try {
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        // Staging restore already required a current recovery backup. A new
        // backup is intentionally disabled until the process restarts.
        if (backup.restorePending && !backup.busy && !mutations.busy) {
          close = true;
        } else {
          close = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (_) => CloseBackupDialog(
                  backup: backup,
                  mutations: mutations,
                  shutdown: shutdown,
                ),
              ) ==
              true;
        }
      }
      if (backup.busy || mutations.busy) close = false;
      await bridge.finish(close);
    } catch (error) {
      debugPrint('Close request stayed open: $error');
      try {
        await bridge.finish(false);
      } catch (_) {
        // Native default remains protected if the channel cannot answer.
      }
    } finally {
      _asking = false;
    }
  }

  void dispose() {
    _disposed = true;
    bridge.dispose();
  }
}
