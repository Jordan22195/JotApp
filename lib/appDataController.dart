import 'AppData.dart';
import 'noteCard.dart';
import 'dataStorage.dart';

List<Note> filteredNotes = [];
List<String> existingLabels = [];
List<NoteCard> noteCards = [];
const String CATAGORY_FILTER_ALL = "ALL";
const String CATAGORY_FILTER_UNSORTED = "";
String filterLabelId = "";

void setCatagoryFilter(String filterId) {
  filterLabelId = filterId;
}

void setNoteCatagory(String noteId, String catagoryId) {
  for (Note n in appData.notes) {
    if (n.id == noteId) {
      n.labelId = catagoryId;
    }
  }
  saveAppData();
}

void buildFilteredNotesList() {
  filteredNotes.clear();
  for (Note n in appData.notes) {
    print('${n.labelId} , $filterLabelId');
    if (n.labelId == filterLabelId || filterLabelId == CATAGORY_FILTER_ALL) {
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
    labelId: filterLabelId,
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

void createNewLabel(String name) {
  appData.labels.add(Label(id: uuid.v4(), name: name));
}
