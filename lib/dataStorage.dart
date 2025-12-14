import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'AppData.dart';
import 'package:share_plus/share_plus.dart';

Future<void> exportJson() async {
  print("export");
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/appdata.json');

  if (await file.exists()) {
    print("file found");
    await Share.shareXFiles([XFile(file.path)]);
  }
}

Future<void> saveAppData() async {
  print("enter save app data");
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/appdata.json');

  print('data saved to ${dir.path}');
  final jsonString = jsonEncode(appData.toJson());
  await file.writeAsString(jsonString);
}

Future<AppData> loadAppData() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/appdata.json');
  print("load app data");

  if (!file.existsSync()) {
    // Return an empty structure on first run
    return AppData(notes: [], categories: []);
  }
  print("file found");

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
