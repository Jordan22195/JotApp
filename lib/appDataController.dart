import 'AppData.dart';
import 'noteCard.dart';
import 'dataStorage.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

List<Note> filteredNotes = [];
List<String> existingCategories = [];
List<NoteCard> noteCards = [];
const String CATAGORY_FILTER_ALL = "ALL";
const String CATAGORY_FILTER_UNSORTED = "";
String filterCategoryId = CATAGORY_FILTER_ALL;

void setCatagoryFilter(String filterId) {
  filterCategoryId = filterId;
}

class AppDataController extends ChangeNotifier {
  AppData _data = AppData(notes: [], categories: []);
  bool _loaded = false;

  AppData get data => _data;
  bool get isLoaded => _loaded;

  AppDataController() {
    _initialize();
  }

  Future<void> _initialize() async {
    _data = await loadAppData();
    _loaded = true;
    notifyListeners();
  }

  Map<String, dynamic> categoryToJson(String categoryId) {
    final Map<String, dynamic> ret = {
      'notes': <Map<String, dynamic>>[],
      'categories': <Map<String, dynamic>>[],
    };

    final bool isAll = categoryId == CATAGORY_FILTER_ALL;

    // Export notes
    for (final note in _data.notes) {
      if (isAll || note.categoryId == categoryId) {
        ret['notes'].add(note.toJson());
      }
    }

    // Export categories
    for (final category in _data.categories) {
      if (isAll || category.id == categoryId) {
        ret['categories'].add(category.toJson());
      }
    }

    return ret;
  }

  List<String> appendAppDataFromJson(Map<String, dynamic> json) {
    List<dynamic> safeList(dynamic value) {
      if (value == null || value is! List) return [];
      return value;
    }

    List<String> status = [];

    int insertIndex = 0;

    List<Category> newCategories = safeList(
      json['categories'],
    ).map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();

    for (int i = 0; i < newCategories.length; i++) {
      Category newCategory = newCategories[i];
      //duplciate id detection
      if (!_data.categoryIdMap.containsKey(newCategory.id)) {
        _data.categoryIdMap[newCategories[i].id] = newCategories[i];
        _data.categories.insert(insertIndex, newCategories[i]);
        status.add("Imported New Category ${newCategories[i].name}");

        insertIndex++;
      }
    }

    String fallbackImportedCategoryId = "";
    List<Note> newNotes = safeList(
      json['notes'],
    ).map((e) => Note.fromJson(e as Map<String, dynamic>)).toList();

    insertIndex = 0;
    for (int i = 0; i < newNotes.length; i++) {
      Note newNote = newNotes[i];

      //duplciate id detection
      if (!_data.noteIdMap.containsKey(newNote.id)) {
        _data.noteIdMap[newNotes[i].id] = newNotes[i];
        _data.notes.insert(insertIndex, newNotes[i]);
        insertIndex++;

        if (!_data.categoryIdMap.containsKey(newNote.categoryId) &&
            newNote.categoryId != "") {
          if (fallbackImportedCategoryId == "") {
            fallbackImportedCategoryId = createNewCategory("Imported");
          }
          newNote.categoryId = fallbackImportedCategoryId;
        }
      }
    }
    notifyListeners();
    saveAppData(_data);
    status.add("Imported $insertIndex New Notes");
    return status;
  }

  String getCategoryName(String categoryId) {
    if (categoryId == CATAGORY_FILTER_ALL)
      return "All Notes";
    else if (categoryId == CATAGORY_FILTER_UNSORTED)
      return "Uncategorized";
    else if (data.categoryIdMap.containsKey(categoryId)) {
      return data.categoryIdMap[categoryId]!.name;
    } else {
      return "Unknown Category";
    }
  }

  void addNote(Note note) {
    _data.notes.insert(0, note);
    saveAppData(_data);
    notifyListeners();
  }

  void importFromJson(Map<String, dynamic> json) {
    appendAppDataFromJson(json);
    saveAppData(_data);
    notifyListeners();
  }

  void setNoteCatagory(String noteId, String categoryId) {
    getNote(noteId).categoryId = categoryId;
    moveCategoryToTopOfList(categoryId);
    saveAppData(_data);
    notifyListeners();
  }

  List<Note> buildFilteredNotesList(String categoryId, bool checked) {
    List<Note> list = [];

    if (categoryId == CATAGORY_FILTER_ALL && checked == false) {
      for (Note n in _data.notes) {
        if (n.categoryId == CATAGORY_FILTER_UNSORTED) {
          list.add(n);
        }
      }
      for (Category c in _data.categories) {
        for (Note n in _data.notes) {
          if (n.categoryId == c.id &&
              n.categoryId != CATAGORY_FILTER_UNSORTED) {
            list.add(n);
          }
        }
      }
      return list;
    }
    //if category is not checklist get all items if you want unchecked items
    if (!getCategory(categoryId).checklist) {
      //if category is not checklist and want checked items

      if (checked) {
        return list;
      }
      for (Note n in _data.notes) {
        if (n.categoryId == categoryId ||
            filterCategoryId == CATAGORY_FILTER_ALL) {
          list.add(n);
        }
      }
      //if category is checklist, return checked/unchecked item
    } else {
      for (Note n in _data.notes) {
        if (n.categoryId == categoryId && n.checked == checked) {
          list.add(n);
        }
      }
    }

    return list;
  }

  String addNewNoteCard({
    String categoryId = CATAGORY_FILTER_UNSORTED,
    int insertIndex = 0,
  }) {
    Note n = Note(
      text: "",
      categoryId: categoryId,
      isEditing: true, // starts as TextField
    );
    endEditForAllNotes();

    _data.notes.insert(insertIndex, n);
    _data.noteIdMap[n.id] = n;
    if (n.categoryId != CATAGORY_FILTER_ALL &&
        n.categoryId != CATAGORY_FILTER_UNSORTED &&
        filterCategoryId != CATAGORY_FILTER_ALL) {
      moveCategoryToTopOfList(n.categoryId);
    }
    saveAppData(_data);
    notifyListeners();
    return n.id;
  }

  void deleteNote(String noteId) {
    for (int i = 0; i < _data.notes.length; i++) {
      if (_data.notes[i].id == noteId) {
        _data.notes.removeAt(i);
      }
    }
    _data.noteIdMap.remove(noteId);
    saveAppData(_data);
    notifyListeners();
  }

  void deleteCategory(String categoryId) {
    for (Note n in _data.notes) {
      if (n.categoryId == categoryId) {
        n.categoryId = CATAGORY_FILTER_UNSORTED;
      }
    }
    for (int i = 0; i < _data.categories.length; i++) {
      if (_data.categories[i].id == categoryId) {
        _data.categories.removeAt(i);
      }
    }
    _data.categoryIdMap.remove(categoryId);
    saveAppData(_data);
    notifyListeners();
  }

  // Returns new category Id
  String createNewCategory(
    String name, {
    bool checklist = false,
    bool timestamps = false,
  }) {
    Category newCategory = Category(
      id: uuid.v4(),
      name: name,
      checklist: checklist,
      showTimestamps: timestamps,
    );
    _data.categories.insert(0, newCategory);
    _data.categoryIdMap[newCategory.id] = newCategory;
    saveAppData(_data);
    notifyListeners();
    return newCategory.id;
  }

  void setCategoryAsChecklist(String categoryId, bool value) {
    getCategory(categoryId).checklist = value;
    saveAppData(_data);
    notifyListeners();
  }

  void setCategoryShowTimestamps(String categoryId, bool value) {
    for (Category c in _data.categories) {
      if (c.id == categoryId) {
        c.showTimestamps = value;
      }
    }
    saveAppData(_data);
    notifyListeners();
  }

  Category getCategory(String categoryId) {
    Category ret = Category(id: "", name: "");
    if (_data.categoryIdMap.containsKey(categoryId)) {
      return _data.categoryIdMap[categoryId]!;
    }
    return ret;
  }

  void moveCategoryToTopOfList(String id) {
    for (Category c in _data.categories) {
      if (c.id == id) {
        Category temp = c;
        _data.categories.remove(c);
        _data.categories.insert(0, temp);
      }
    }

    saveAppData(_data);
    // notifyListeners();
  }

  Note getNote(String noteId) {
    Note ret = Note(id: "");
    if (_data.noteIdMap.containsKey(noteId)) {
      return _data.noteIdMap[noteId]!;
    }
    return ret;
  }

  void toggleNoteTitle(String noteId) {
    Note n = getNote(noteId);
    n.isTitle = !n.isTitle;
    saveAppData(_data);
    notifyListeners();
  }

  void setNoteText(String noteId, String text) {
    Note n = getNote(noteId);
    n.text = text;
    saveAppData(_data);
    notifyListeners();
  }

  void setNoteChecked(String noteId, bool checked) {
    Note n = getNote(noteId);
    n.checked = checked;
    moveCategoryToTopOfList(getNote(noteId).categoryId);
    saveAppData(_data);
  }

  String getNoteCreationDateTime(String noteId) {
    Note note = getNote(noteId);
    final int epochMs = note.noteCreationTimeMs;
    final dateTime = DateTime.fromMillisecondsSinceEpoch(epochMs);
    final formatted = DateFormat.yMMMd().format(dateTime);
    return formatted;
  }

  void endEditForAllNotes() {
    for (Note n in _data.notes) {
      n.isEditing = false;
    }
    saveAppData(_data);
    notifyListeners();
  }

  void setCatagoryName(String id, String name) {
    Category cat = getCategory(id);
    cat.name = name;
    saveAppData(_data);
    notifyListeners();
  }

  // move note source to the index after noteIdDest
  void moveNoteItemInlist(String noteIdDest, String noteIdSource) {
    int newIndex = getNoteIndexInList(noteIdDest);

    int oldIndex = getNoteIndexInList(noteIdSource);

    _data.notes.removeAt(oldIndex);
    _data.notes.insert(newIndex, getNote(noteIdSource));
    saveAppData(_data);
    notifyListeners();
  }

  // return the index in _data.notes of the NoteId
  // returns -1 if not found
  int getNoteIndexInList(String noteId) {
    for (int i = 0; i < _data.notes.length; i++) {
      if (_data.notes[i].id == noteId) {
        return i;
      }
    }
    return -1;
  }

  // move checked notes after all the unchecked notes
  void sortCheckedList(String categoryId) {
    int insertIndex = 0;
    int currNoteIndex = 0;
    int nextNoteIndex = 0;

    int getNextNoteIndex(int i) {
      for (int y = i + 1; y < _data.notes.length; y++) {
        if (_data.notes[y].categoryId == categoryId) {
          return y;
        }
      }
      return i;
    }

    for (int i = 0; i < _data.notes.length; i++) {
      // get index of first note in the category
      if (_data.notes[i].categoryId == categoryId) {
        currNoteIndex = i;
        if (insertIndex < 0) {
          insertIndex = currNoteIndex;
        }

        //get index of the next note in category
        nextNoteIndex = getNextNoteIndex(i);

        // if note is not checked, incremennt insert index,
        //
        if (!_data.notes[i].checked && currNoteIndex == insertIndex) {
          insertIndex = nextNoteIndex;
        }
        // if note is checked, set insert index
        //if !checked and i > insert Index, do insert, increase insert index
        else if (!_data.notes[i].checked && insertIndex != currNoteIndex) {
          Note n = _data.notes[i];
          _data.notes.removeAt(i);
          _data.notes.insert(insertIndex, n);

          //increase insertIndex
          for (int y = insertIndex; y < _data.notes.length; y++) {
            if (_data.notes[y].categoryId == categoryId) {
              insertIndex = y;
              break;
            }
          }
        }
      }
    }
    saveAppData(_data);
    notifyListeners();
  }

  void moveNoteToEndOfList(String noteId) {
    int oldIndex = getNoteIndexInList(noteId);
    _data.notes.removeAt(oldIndex);
    _data.notes.add(getNote(noteId));
    saveAppData(_data);
    notifyListeners();
  }

  void moveNoteToStartOfList(String noteId) {
    int oldIndex = getNoteIndexInList(noteId);
    _data.notes.removeAt(oldIndex);
    _data.notes.insert(0, getNote(noteId));
    saveAppData(_data);
    notifyListeners();
  }

  void commitData() {
    saveAppData(_data);
    notifyListeners();
  }
}
