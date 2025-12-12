import 'package:uuid/uuid.dart';

var uuid = Uuid();

AppData appData = AppData(notes: [], labels: []);

class AppData {
  final List<Note> notes;
  final List<Label> labels;

  AppData({required this.notes, required this.labels});

  factory AppData.fromJson(Map<String, dynamic> json) {
    List<dynamic> safeList(dynamic value) {
      if (value == null || value is! List) return [];
      return value;
    }

    return AppData(
      notes: safeList(
        json['notes'],
      ).map((e) => Note.fromJson(e as Map<String, dynamic>)).toList(),
      labels: safeList(
        json['categories'],
      ).map((e) => Label.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'notes': notes.map((n) => n.toJson()).toList(),
    'categories': labels.map((c) => c.toJson()).toList(),
  };
}

class Note {
  final String id;
  String labelId = "";
  String text;
  bool isEditing;
  bool isFavorite;
  List<String> labels = [];

  Note({
    String? id,
    this.labelId = "",
    this.text = "",
    this.isEditing = false,
    this.isFavorite = false,
  }) : id = id ?? uuid.v4(); // generates unique ID

  factory Note.fromJson(Map<String, dynamic> json) =>
      Note(id: json['id'], text: json['text'], labelId: json['labelId']);

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'labelId': labelId};
}

class Label {
  final String id;
  final String name;

  Label({required this.id, required this.name});

  factory Label.fromJson(Map<String, dynamic> json) =>
      Label(id: json['id'], name: json['name']);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
