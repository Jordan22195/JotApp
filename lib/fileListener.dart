import 'dart:async';
import 'package:notes_app/dataStorage.dart';

import 'appDataController.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class JotFileListener extends StatefulWidget {
  final Widget child;
  const JotFileListener({super.key, required this.child});

  @override
  State<JotFileListener> createState() => _JotFileListenerState();
}

class _JotFileListenerState extends State<JotFileListener> {
  StreamSubscription<List<SharedMediaFile>>? _sub;
  bool _handledInitial = false;

  @override
  void initState() {
    super.initState();

    // Files shared while app is running
    _sub = ReceiveSharingIntent.instance.getMediaStream().listen((files) {
      _handleFiles(files);
    });

    // Files that launched the app (cold start)
    _handleInitial();
  }

  Future<void> _handleInitial() async {
    if (_handledInitial) return;
    _handledInitial = true;

    final files = await ReceiveSharingIntent.instance.getInitialMedia();
    await _handleFiles(files);
  }

  Future<void> _handleFiles(List<SharedMediaFile> files) async {
    if (files.isEmpty) return;

    // We use read() (not watch) because we don't want rebuilds; we just want to act.

    for (final f in files) {
      final path = f.path;
      if (path.isEmpty) continue;

      // Only handle .jot
      if (!path.toLowerCase().endsWith('.jot')) continue;

      try {
        await loadJson(context, path);

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Imported Jot file')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }

    // Important: clear the intent so it doesn't re-import on resume
    ReceiveSharingIntent.instance.reset();
  }

  @override
  void dispose() {
    _sub?.cancel();
    ReceiveSharingIntent.instance.reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
