import 'package:uuid/uuid.dart';

var uuid = Uuid();

AppData appData = AppData(notes: [], categories: []);

class AppData {
  final List<Note> notes;
  final List<Category> categories;

  AppData({required this.notes, required this.categories});

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

  Map<String, dynamic> toJson() => {
    'notes': notes.map((n) => n.toJson()).toList(),
    'categories': categories.map((c) => c.toJson()).toList(),
  };
}

class Note {
  final String id;
  String categoryId = "";
  String text;
  bool isEditing;
  bool isFavorite;
  List<String> categories = [];

  Note({
    String? id,
    this.categoryId = "",
    this.text = "",
    this.isEditing = false,
    this.isFavorite = false,
  }) : id = id ?? uuid.v4(); // generates unique ID

  factory Note.fromJson(Map<String, dynamic> json) =>
      Note(id: json['id'], text: json['text'], categoryId: json['categoryId']);

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'categoryId': categoryId,
  };
}

class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) =>
      Category(id: json['id'], name: json['name']);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
