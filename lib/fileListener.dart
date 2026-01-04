import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'appDataController.dart';
import 'dart:io';
import 'dart:convert';

class JotFileListener extends StatefulWidget {
  final Widget child;
  //final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  const JotFileListener({
    super.key,
    required this.child,
    //required this.scaffoldMessengerKey,
  });

  @override
  State<JotFileListener> createState() => _JotFileListenerState();
}

class _JotFileListenerState extends State<JotFileListener> {
  StreamSubscription<List<SharedMediaFile>>? _sub;
  bool _handledInitial = false;

  @override
  void initState() {
    super.initState();
    print("init state");
    // While running
    _sub = ReceiveSharingIntent.instance.getMediaStream().listen(_handleFiles);

    // Cold start: wait until the widget tree is mounted + first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitial();
    });
  }

  Future<void> _handleInitial() async {
    if (_handledInitial) return;
    _handledInitial = true;
    print("handle initial");
    final files = await ReceiveSharingIntent.instance.getInitialMedia();
    await _handleFiles(files);
  }

  Future<void> _handleFiles(List<SharedMediaFile> files) async {
    print("handle files");
    if (files.isEmpty) return;

    final controller = context.read<AppDataController>();

    for (final f in files) {
      final path = f.path;
      if (path.isEmpty) continue;

      if (!path.toLowerCase().endsWith('.jot')) continue;

      print("handle files path: $path");
      File file = File(path);

      String jsonString = await file.readAsString();
      final Map<String, dynamic> json = jsonDecode(jsonString);
      print("json decoded");

      try {
        await controller.appendAppDataFromJson(json);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imported Jot file'),
            duration: Duration(seconds: 1),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

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
