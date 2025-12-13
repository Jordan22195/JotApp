import 'AppData.dart';
import 'noteCard.dart';
import 'dataStorage.dart';

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
    print('${n.categoryId} , $filterCategoryId');
    if (n.categoryId == filterCategoryId ||
        filterCategoryId == CATAGORY_FILTER_ALL) {
      filteredNotes.add(n);
    }
  }
  print(
    'buildFilteredNotesList  len=${filteredNotes.length} / ${appData.notes.length}',
  );
}

void addNewNoteCard() {
  Note n = Note(
    text: "",
    categoryId: filterCategoryId,
    isEditing: true, // ← starts as TextField
  );
  print("new note");
  print(n.id);
  for (Note note in appData.notes) {
    note.isEditing = false;
  }

  appData.notes.insert(0, n);
  saveAppData();
}

void deleteNote(String noteId) {
  for (int i = 0; i < appData.notes.length; i++) {
    if (appData.notes[i].id == noteId) {
      appData.notes.removeAt(i);
    }
  }
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

void createNewCategory(String name) {
  appData.categories.add(Category(id: uuid.v4(), name: name));
  saveAppData();
}
