import 'AppData.dart';
import 'noteCard.dart';
import 'dataStorage.dart';
import 'package:intl/intl.dart';

List<Note> filteredNotes = [];
List<String> existingCategories = [];
List<NoteCard> noteCards = [];
const String CATAGORY_FILTER_ALL = "ALL";
const String CATAGORY_FILTER_UNSORTED = "";
String filterCategoryId = "";

void setCatagoryFilter(String filterId) {
  filterCategoryId = filterId;
}

void setNoteCatagory(String noteId, String catagoryId) {
  for (Note n in appData.notes) {
    if (n.id == noteId) {
      n.categoryId = catagoryId;
    }
  }
  saveAppData();
}

void buildFilteredNotesList() {
  filteredNotes.clear();
  for (Note n in appData.notes) {
    if (n.categoryId == filterCategoryId ||
        filterCategoryId == CATAGORY_FILTER_ALL) {
      filteredNotes.add(n);
    }
  }
}

void addNewNoteCard() {
  Note n = Note(
    text: "",
    categoryId: filterCategoryId == CATAGORY_FILTER_ALL ? "" : filterCategoryId,
    isEditing: true, // starts as TextField
  );
  endEditForAllNotes();

  appData.notes.insert(0, n);
  appData.noteIdMap[n.id] = n;
  saveAppData();
}

void deleteNote(String noteId) {
  for (int i = 0; i < appData.notes.length; i++) {
    if (appData.notes[i].id == noteId) {
      appData.notes.removeAt(i);
    }
  }
  appData.noteIdMap.remove(noteId);
  saveAppData();
}

void deleteCategory(String categoryId) {
  for (Note n in appData.notes) {
    if (n.categoryId == categoryId) {
      n.categoryId = CATAGORY_FILTER_UNSORTED;
    }
  }
  for (int i = 0; i < appData.categories.length; i++) {
    if (appData.categories[i].id == categoryId) {
      appData.categories.removeAt(i);
    }
  }
  saveAppData();
}

// Returns new category Id
String createNewCategory(String name) {
  Category newCategory = Category(id: uuid.v4(), name: name);
  appData.categories.add(newCategory);
  saveAppData();
  return newCategory.id;
}

void setCategoryAsChecklist(String categoryId, bool value) {
  for (Category c in appData.categories) {
    if (c.id == categoryId) {
      c.checklist = value;
    }
  }
  saveAppData();
}

void setCategoryShowTimestamps(String categoryId, bool value) {
  for (Category c in appData.categories) {
    if (c.id == categoryId) {
      c.showTimestamps = value;
    }
  }
  saveAppData();
}

Category getCategory(String categoryId) {
  Category ret = Category(id: "", name: "");
  for (Category c in appData.categories) {
    if (c.id == categoryId) {
      return c;
    }
  }
  return ret;
}

Note getNote(String noteId) {
  Note ret = Note(id: "");
  if (appData.noteIdMap.containsKey(noteId)) {
    return appData.noteIdMap[noteId]!;
  }
  return ret;
}

void setNoteChecked(String noteId, bool checked) {
  Note n = getNote(noteId);
  n.checked = checked;
}

String getNoteCreationDateTime(String noteId) {
  Note note = getNote(noteId);
  final int epochMs = note.noteCreationTimeMs;
  final dateTime = DateTime.fromMillisecondsSinceEpoch(epochMs);
  final formatted = DateFormat.yMMMd().add_jm().format(dateTime);
  return formatted;
}

void endEditForAllNotes() {
  for (Note n in appData.notes) {
    n.isEditing = false;
  }
}

void setCatagoryName(String id, String name) {
  Category cat = getCategory(id);
  cat.name = name;
  saveAppData();
}

// move note source to the index after noteIdDest
void moveNoteItemInlist(String noteIdDest, String noteIdSource) {
  int newIndex = getNoteIndexInList(noteIdDest);

  int oldIndex = getNoteIndexInList(noteIdSource);
  print("move item from $oldIndex to $newIndex");

  appData.notes.removeAt(oldIndex);
  appData.notes.insert(newIndex, getNote(noteIdSource));
  saveAppData();
}

// return the index in appData.notes of the NoteId
// returns -1 if not found
int getNoteIndexInList(String noteId) {
  for (int i = 0; i < appData.notes.length; i++) {
    if (appData.notes[i].id == noteId) {
      return i;
    }
  }
  return -1;
}
