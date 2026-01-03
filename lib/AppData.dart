import 'dart:ffi';

import 'package:notes_app/appDataController.dart';
import 'package:uuid/uuid.dart';

var uuid = Uuid();

class AppData {
  final List<Note> notes;
  Map<String, Note> noteIdMap = {};
  final List<Category> categories;
  Map<String, Category> categoryIdMap = {};

  AppData({required this.notes, required this.categories}) {
    for (Note n in notes) {
      noteIdMap[n.id] = n;
    }
    for (Category c in categories) {
      categoryIdMap[c.id] = c;
    }
  }

  Map<String, dynamic> toJson() => {
    'notes': notes.map((n) => n.toJson()).toList(),
    'categories': categories.map((c) => c.toJson()).toList(),
  };

  factory AppData.fromJson(Map<String, dynamic> json) {
    List<dynamic> safeList(dynamic value) {
      if (value == null || value is! List) return [];
      return value;
    }

    return AppData(
      notes: safeList(
        json['notes'],
      ).map((e) => Note.fromJson(e as Map<String, dynamic>)).toList(),
      categories: safeList(
        json['categories'],
      ).map((e) => Category.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class Note {
  final String id;
  String categoryId = "";
  String text;
  bool isEditing;
  bool isFavorite;
  bool checked;
  List<String> categories = [];
  final int noteCreationTimeMs;

  Note({
    String? id,
    this.categoryId = "",
    this.text = "",
    this.isEditing = false,
    this.isFavorite = false,
    this.checked = false,
    int? noteCreationTimeMs,
  }) : id = id ?? uuid.v4(),
       noteCreationTimeMs =
           noteCreationTimeMs ?? DateTime.now().toUtc().millisecondsSinceEpoch;

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'] is String ? json['id'] as String : '',
    text: json['text'] is String ? json['text'] as String : '',
    categoryId: json['categoryId'] is String
        ? json['categoryId'] as String
        : '',
    checked: json['checked'] is bool ? json['checked'] as bool : false,
    noteCreationTimeMs: json['noteCreationTimeMs'] is int
        ? json['noteCreationTimeMs'] as int
        : DateTime.now().toUtc().millisecondsSinceEpoch,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'categoryId': categoryId,
    'checked': checked,
    'noteCreationTimeMs': noteCreationTimeMs,
  };
}

class Category {
  final String id;
  String name;
  bool checklist = false;
  bool showTimestamps = false;

  Category({
    required this.id,
    required this.name,
    this.checklist = false,
    this.showTimestamps = false,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] is String ? json['id'] as String : '',
      name: json['name'] is String ? json['name'] as String : '',
      checklist: json['checklist'] is bool ? json['checklist'] as bool : false,
      showTimestamps: json['showTimestamps'] is bool
          ? json['showTimestamps'] as bool
          : false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'checklist': checklist,
    'showTimestamps': showTimestamps,
  };
}
