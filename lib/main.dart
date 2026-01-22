import 'package:flutter/material.dart';
import 'package:notes_app/categoryMenu.dart';
import 'package:notes_app/fileListener.dart';
import 'package:provider/provider.dart';
import 'AppData.dart';
import 'noteCard.dart';
import 'dataStorage.dart';
import 'appDataController.dart';
import 'selectableIcon.dart';

void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => AppDataController(), child: MyApp()),
  );
}

enum ColorPalettes { green, brown, red }

const List<Color> greenPalette = [
  Color(0xffEBF4DD), //background
  Color(0xff90AB8B), //app bar
  Color(0xff5A7863), //button
  Color(0xff3B4953),
];

const List<Color> brownPalette = [
  Color(0xffF9F8F6),
  Color(0xffEFE9E3),
  Color(0xffD9CFC7),
  Color(0xffC9B59C),
];

const List<Color> redPalette = [
  Color(0xffE17564),
  Color(0xffBE3144),
  Color(0xff872341),
  Color(0xff09122C),
];

const ColorPalettes currentPallete = ColorPalettes.green;

const Map<ColorPalettes, List<Color>> colorPalettes = {
  ColorPalettes.green: greenPalette,
  ColorPalettes.brown: brownPalette,
  ColorPalettes.red: redPalette,
};

enum MenuAction { saveAppData, loadAppData }

Color? getColor(int index) {
  return colorPalettes[currentPallete]?[index];
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    Color c1 = greenPalette[3]; // primary
    Color c2 = greenPalette[2]; // secondary
    Color c3 = greenPalette[1]; // tertiary
    Color c4 = greenPalette[0]; // background
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: c1,
          onPrimary: Colors.white,
          secondary: c2,
          onSecondary: Colors.white,
          tertiary: c3,
          onTertiary: Colors.white,

          background: c4,
          onBackground: const Color(0xFF111827),

          surface: Colors.white, // or a tinted surface from your palette
          onSurface: const Color(0xFF111827),

          error: const Color(0xFFDC2626),
          onError: Colors.white,

          // These help outlines/dividers
          outline: const Color(0xFFE5E7EB),
          shadow: Colors.black,
          surfaceTint: c1, // nice M3 tint behavior
        ),

        //bottom sheet
        bottomSheetTheme: BottomSheetThemeData(backgroundColor: getColor(0)),
        scaffoldBackgroundColor: getColor(0),
        popupMenuTheme: PopupMenuThemeData(color: getColor(0)),

        //app bar
        appBarTheme: AppBarThemeData(
          backgroundColor: getColor(1),
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
            color: Colors.black,
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return getColor(1); // checked color
            }
            return getColor(0); // unchecked border
          }),
          checkColor: WidgetStateProperty.all(Colors.black),
          //shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),

        //big button
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: colorPalettes[currentPallete]?[2],
        ),

        iconTheme: IconThemeData(color: getColor(3)),

        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            iconColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return getColor(1);
              }
              if (states.contains(WidgetState.selected)) {
                return getColor(2); // primary
              }
              return getColor(3); // default
            }),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return getColor(0);
              }
              return Colors.transparent;
            }),
          ),
        ),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String latestInputText = "";
  final TextEditingController controller = TextEditingController();

  late final ScrollController _scrollController;
  late AppDataController dataController;
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  void scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Text getBannerText() {
    Text ret = Text("");
    if (filterCategoryId == CATAGORY_FILTER_ALL) {
      ret = Text("All Notes");
    } else if (filterCategoryId == CATAGORY_FILTER_UNSORTED) {
      ret = Text("Uncategorized");
    } else {
      for (Category l in dataController.data.categories) {
        if (l.id == filterCategoryId) {
          ret = Text(l.name);
        }
      }
    }
    return ret;
  }

  Widget buildNoteFinshEditButton() {
    bool hasText = noteEditText.isNotEmpty;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: FloatingActionButton(
        backgroundColor: getColor(1),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        tooltip: 'New Note',
        child: hasText ? Icon(Icons.check) : Icon(Icons.close),
        onPressed: () {
          setState(() {
            if (hasText) {
              noteInEditMode = false;
              dataController.getNote(noteIdInEditMode).isEditing = false;
              dataController.setNoteText(noteIdInEditMode, noteEditText);
            } else {
              dataController.deleteNote(noteIdInEditMode);
              noteInEditMode = false;
            }
          });

          //setState(
          //    () => dataController.getNote(noteIdInEditMode).text = noteEditText,
          //   );
        },
      ),
    );
  }

  Widget buildNoteDeleteButton() {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: FloatingActionButton(
        backgroundColor: getColor(1),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        tooltip: 'New Note',
        child: const Icon(Icons.delete),
        onPressed: () {
          setState(() {});
        },
      ),
    );
  }

  Widget buildNewNoteButton() {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: FloatingActionButton(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        tooltip: 'New Note',
        child: const Icon(Icons.add),
        onPressed: () {
          String id = dataController.addNewNoteCard(
            categoryId: filterCategoryId == CATAGORY_FILTER_ALL
                ? CATAGORY_FILTER_UNSORTED
                : filterCategoryId,
          );
          noteIdInEditMode = id;
          noteInEditMode = true;
          noteEditText = "";

          scrollToTop();
        },
      ),
    );
  }

  void _openFilterPicker(BuildContext context, String cateogryId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => CategoryMenu(
        currentSelectedCategoryId: filterCategoryId,
        onSelected: (selectedCategoryId) {
          setState(() {
            setCatagoryFilter(selectedCategoryId);
          });
        },
      ),
    );
  }

  void nudgeListUp() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final currentOffset = _scrollController.offset;
      const double nudgeAmount = 80; // FAB overlap buffer

      _scrollController.animateTo(
        (currentOffset + nudgeAmount).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  bool isFilterSetToCategory() {
    if (filterCategoryId != CATAGORY_FILTER_ALL &&
        filterCategoryId != CATAGORY_FILTER_UNSORTED) {
      return true;
    }
    return false;
  }

  bool showChecked = true;
  Widget buildNoteCardList() {
    List<Note> uncheckedNotes = [];
    List<Note> checkedNotes = [];
    setState(() {
      uncheckedNotes = dataController.buildFilteredNotesList(
        filterCategoryId,
        false,
      );
      checkedNotes = dataController.buildFilteredNotesList(
        filterCategoryId,
        true,
      );
    });

    final dividerIndex = uncheckedNotes.length;
    final toggleIndex = uncheckedNotes.length + 1;
    final checkedStartIndex = uncheckedNotes.length + 2;

    final itemCount =
        uncheckedNotes.length + 2 + (showChecked ? checkedNotes.length : 0);

    bool isNoteIndex(int i) =>
        i < dividerIndex || (showChecked && i >= checkedStartIndex);

    Note noteForIndex(int i) {
      if (i < dividerIndex) return uncheckedNotes[i];
      // checked section
      return checkedNotes[i - checkedStartIndex];
    }

    // Prevent moving a note across divider / toggle rows
    bool inUncheckedSection(int i) => i < dividerIndex;
    bool inCheckedSection(int i) => showChecked && i >= checkedStartIndex;

    return Expanded(
      child: ReorderableListView.builder(
        scrollController: _scrollController,
        itemCount: itemCount,
        padding: const EdgeInsets.only(
          bottom: 128, // 👈 FAB height + breathing room
        ),
        onReorder: (oldIndex, newIndex) {
          // ReorderableListView reports the "drop" index as if the item was removed.
          if (newIndex > oldIndex) newIndex -= 1;

          // Only allow note->note moves, not onto divider/toggle
          if (!isNoteIndex(oldIndex)) return;

          // If user tries to drop onto divider/toggle, clamp into same section.
          if (!isNoteIndex(newIndex)) {
            if (inUncheckedSection(oldIndex)) {
              newIndex = (newIndex <= dividerIndex)
                  ? (dividerIndex - 1).clamp(0, dividerIndex - 1)
                  : dividerIndex - 1;
            } else {
              // checked section
              newIndex = checkedStartIndex;
            }
          }

          // Disallow crossing sections
          if (inUncheckedSection(oldIndex) && !inUncheckedSection(newIndex)) {
            return;
          }
          if (inCheckedSection(oldIndex) && !inCheckedSection(newIndex)) return;

          setState(() {
            // Apply reorder within the appropriate sublist
            if (inUncheckedSection(oldIndex)) {
              dataController.moveNoteItemInlist(
                uncheckedNotes[newIndex].id,
                uncheckedNotes[oldIndex].id,
              );
            } else {
              dataController.moveNoteItemInlist(
                checkedNotes[newIndex].id,
                checkedNotes[oldIndex].id,
              );
            }
          });
        },
        itemBuilder: (context, index) {
          // Divider row
          if (index == dividerIndex) {
            if (checkedNotes.isEmpty) {
              return SizedBox(key: ValueKey('divider_placeholder'), width: 0);
            }
            return ListTile(
              key: const ValueKey('__checked_divider__'),
              title: const Divider(),
              dense: true,
              contentPadding: EdgeInsets.zero,
            );
          }

          // Toggle row
          if (index == toggleIndex) {
            if (checkedNotes.isEmpty) {
              return SizedBox(
                key: ValueKey('toggle_row_placeholder'),
                width: 0,
              );
            }
            return ListTile(
              key: const ValueKey('__checked_toggle__'),
              title: Text(
                showChecked ? 'Checked' : 'Checked (${checkedNotes.length})',
              ),
              trailing: TextButton(
                onPressed: () => setState(() => showChecked = !showChecked),
                child: Text(showChecked ? 'Hide' : 'Show'),
              ),
            );
          }

          final note = noteForIndex(index);

          return NoteCard(
            key: ValueKey(note.id),
            titleCard: note.isTitle,
            note: note,
            startInEditMode: note.isEditing,
            initialText: "",
            onSave: (newText) {
              setState(() {
                note.text = newText;
                noteEditText = newText;
              });
            },
            onDelete: () {
              dataController.deleteNote(note.id);
              setState(() {
                noteInEditMode = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Note Deleted'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            onNewNote: (noteId) {
              setState(() {
                noteEditText = "";
                noteInEditMode = true;
                noteIdInEditMode = noteId;
              });
            },
            onTitleToggle: () {
              dataController.toggleNoteTitle(note.id);
            },
            onCategorize: (catId) {
              setState(() {
                noteInEditMode = false;
                dataController.setNoteCatagory(note.id, catId);
              });
              String name = dataController.getCategoryName(catId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Moved Note to $name'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            onCheck: (checked) {
              setState(() {});
            },
            onTap: () {
              setState(() {
                noteInEditMode = true;
                noteIdInEditMode = note.id;
              });
            },
          );
        },
      ),
    );
  }

  bool noteInEditMode = false;
  String noteIdInEditMode = "";
  String noteEditText = "";

  @override
  Widget build(BuildContext context) {
    dataController = context.watch<AppDataController>();

    return JotFileListener(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              _openFilterPicker(context, filterCategoryId);
            },
          ),
          centerTitle: false,
          title: getBannerText(),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isFilterSetToCategory())
                    SelectableIconButton(
                      icon: Icons.timer_outlined,
                      selected: dataController
                          .getCategory(filterCategoryId)
                          .showTimestamps,
                      onChanged: (val) {
                        dataController.setCategoryShowTimestamps(
                          filterCategoryId,
                          val,
                        );
                      },
                    ),
                  if (isFilterSetToCategory())
                    SelectableIconButton(
                      selected: dataController
                          .getCategory(filterCategoryId)
                          .checklist,

                      onChanged: (val) {
                        dataController.setCategoryAsChecklist(
                          filterCategoryId,
                          val,
                        );
                      },
                      icon: Icons.checklist,
                    ),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                exportJotFileAndShare(
                  context,
                  payload: dataController.categoryToJson(filterCategoryId),
                  baseFileName: dataController.getCategoryName(
                    filterCategoryId,
                  ),
                );
              },
              icon: Icon(Icons.ios_share),
            ),
            PopupMenuButton<MenuAction>(
              icon: Icon(Icons.more_vert),
              onSelected: (action) {
                if (action == MenuAction.loadAppData) {
                  pickAndLoadJson(context);
                }
              },
              itemBuilder: (context) => [
                CheckedPopupMenuItem(
                  value: MenuAction.loadAppData,
                  child: const Text('Load App Data'),
                ),
              ],
            ),
          ],
        ),
        body: Center(child: Column(children: [buildNoteCardList()])),
        bottomNavigationBar: SafeArea(
          child: Row(
            children: [
              Expanded(child: buildNewNoteButton()),
              if (noteInEditMode) buildNoteFinshEditButton(),
            ],
          ),
        ),
      ),
    );
  }
}
