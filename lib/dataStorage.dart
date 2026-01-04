import 'package:flutter/material.dart';
import 'package:notes_app/appDataController.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'AppData.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

/// Exports [payload] as a .jot file (JSON inside) and opens the share sheet.
/// Returns the created File.
Future<File?> exportJotFileAndShare(
  BuildContext context, {
  required Map<String, dynamic> payload,
  required String baseFileName, // e.g. "Groceries"
}) async {
  // 1) Encode as JSON (pretty-printed is optional, but nice for debugging)
  final String jsonText = const JsonEncoder.withIndent('  ').convert(payload);

  // 2) Pick a write location your app can access
  //    - getTemporaryDirectory() is fine for "share then discard"
  //    - getApplicationDocumentsDirectory() if you want it to persist
  final Directory dir = await getTemporaryDirectory();

  // 3) Sanitize file name and add custom extension
  final safeName = _sanitizeFileName(baseFileName);
  final filePath =
      '${dir.path}/$safeName-${DateTime.now().millisecondsSinceEpoch}.jot';

  // 4) Write the file
  final File file = File(filePath);
  await file.writeAsString(jsonText, flush: true);

  // 5) Share it

  // Get the RenderBox of the button / context
  if (!context.mounted) return null; // Guard again before using box
  final box = context.findRenderObject() as RenderBox?;

  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'application/json', name: '$safeName.jot')],
    subject: safeName,
    //text: 'Jot export: $safeName',
    sharePositionOrigin: box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : Rect.zero,
  );

  return file;
}

String _sanitizeFileName(String input) {
  // Keeps it simple; prevents weird characters on different OSes.
  final cleaned = input.trim().replaceAll(RegExp(r'[^\w\s-]'), '');
  return cleaned.replaceAll(RegExp(r'\s+'), '_').take(60);
}

extension _Take on String {
  String take(int max) => length <= max ? this : substring(0, max);
}

// save a copy of the app data from the application directory
Future<void> exportAppData(BuildContext context) async {
  // Make sure the widget is still mounted before doing anything
  if (!context.mounted) return;

  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/appdata.json');

    if (!await file.exists()) return;

    // Get the RenderBox of the button / context
    if (!context.mounted) return; // Guard again before using box
    final box = context.findRenderObject() as RenderBox?;

    await Share.shareXFiles(
      [XFile(file.path)],
      sharePositionOrigin: box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : Rect.zero,
    );
  } catch (e) {
    // Optional: show error to user
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to export JSON: $e')));
    }
  }
}

Future<void> loadJson(BuildContext context, String path) async {
  File file = File(path);

  // Read the JSON content
  String jsonString = await file.readAsString();
  final Map<String, dynamic> json = jsonDecode(jsonString);

  if (!context.mounted) return;

  final controller = context.read<AppDataController>();
  List<String> status = controller.appendAppDataFromJson(json);

  for (String s in status) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(s), duration: Duration(seconds: 1)));
  }
}

Future<void> pickAndLoadJson(BuildContext context) async {
  // Open file picker
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
  );

  if (result != null && result.files.single.path != null) {
    String path = result.files.single.path!;
    loadJson(context, path);
  } else {
    // User canceled the picker
  }
}

// save the current app data to the app folder
Future<void> saveAppData(AppData appData) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/appdata.json');

  final jsonString = jsonEncode(appData.toJson());
  await file.writeAsString(jsonString);
}

// create new instance of app data from saved json
// in app folder
Future<AppData> loadAppData() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/appdata.json');

  if (!file.existsSync()) {
    // Return an empty structure on first run
    return AppData(notes: [], categories: []);
  }

  final jsonString = await file.readAsString();
  final Map<String, dynamic> json = jsonDecode(jsonString);

  return AppData.fromJson(json);
}
