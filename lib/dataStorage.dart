import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'AppData.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> exportJson(BuildContext context) async {
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

Future<void> saveAppData() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/appdata.json');

  final jsonString = jsonEncode(appData.toJson());
  await file.writeAsString(jsonString);
}

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

class AppDataController extends ChangeNotifier {
  AppData data = AppData(notes: [], categories: []);

  AppDataController() {
    _initialize();
  }

  Future<void> _initialize() async {
    data = await loadAppData();
    notifyListeners();
  }
}
