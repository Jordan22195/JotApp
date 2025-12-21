import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'AppData.dart';
import 'noteCard.dart';
import 'categoryPicker.dart';
import 'dataStorage.dart';
import 'appDataController.dart';

void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => AppDataController(), child: MyApp()),
  );
}

enum MenuAction { toggleChecklist, toggleTimestamps }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: ColorScheme.light()),
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
      ret = Text("Uncategorized Notes");
    } else {
      for (Category l in appData.categories) {
        if (l.id == filterCategoryId) {
          ret = Text(l.name);
        }
      }
    }
    return ret;
  }

  Widget buildNewNoteButton() {
    return FloatingActionButton(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      tooltip: 'New Note',
      child: const Icon(Icons.add),
      onPressed: () {
        setState(() {
          addNewNoteCard();
          buildFilteredNotesList();
        });

        scrollToTop();
      },
    );
  }

  ListTile buildAllCategoriesTile() {
    bool selected = filterCategoryId == CATAGORY_FILTER_ALL;
    return ListTile(
      title: Text("All Notes"),
      trailing: categoryEditMode
          ? null
          : selected
          ? const Icon(Icons.check)
          : null,
      onTap: () {
        setState(() {
          setCatagoryFilter(CATAGORY_FILTER_ALL);
          Navigator.of(context).pop();
        });
      },
    );
  }

  ListTile buildUncategorizedTile() {
    bool selected = filterCategoryId == CATAGORY_FILTER_UNSORTED;
    return ListTile(
      title: Text("Uncategorized Notes"),
      trailing: categoryEditMode
          ? null
          : selected
          ? const Icon(Icons.check)
          : null,
      onTap: () {
        setState(() {
          setCatagoryFilter(CATAGORY_FILTER_UNSORTED);
          Navigator.of(context).pop();
        });
      },
    );
  }

  List<Widget> buildCategoryListTile(Function setSheetState) {
    List<ListTile> tiles = [];
    for (Category category in appData.categories) {
      final selected = filterCategoryId == category.id;
      final controller = TextEditingController();
      controller.text = category.name;

      tiles.add(
        ListTile(
          title: categoryEditMode
              ? TextField(
                  controller: controller,
                  onChanged: (value) {
                    setCatagoryName(category.id, value);
                  },
                )
              : Text(category.name),
          trailing: categoryEditMode
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      deleteCategory(category.id);
                    });
                    setSheetState(() {});
                  },
                  icon: Icon(Icons.delete),
                )
              : selected
              ? const Icon(Icons.check)
              : null,
          //   trailing: categoryEditMode ? {selected ? const Icon(Icons.check) : null} : const IconButton(icon: Icon(Icons.delete))
          onTap: () {
            setState(() {
              setCatagoryFilter(category.id);
            });

            Navigator.of(context).pop();
          },
        ),
      );
    }
    return tiles;
  }

  bool categoryEditMode = false;

  void _openFilterPicker(BuildContext context, String cateogryId) {
    categoryEditMode = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        // Use StatefulBuilder so we can call setState inside the sheet
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: MediaQuery.of(
                context,
              ).viewInsets.add(const EdgeInsets.all(16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            "Categories",
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: categoryEditMode
                            ? Icon(Icons.check)
                            : Icon(Icons.edit),
                        onPressed: () {
                          setState(() {
                            categoryEditMode = !categoryEditMode;
                          });
                          setSheetState(() {});
                        },
                      ),
                    ],
                  ),

                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Create New Category'),
                    onTap: () async {
                      // Ask for name
                      final name = await showDialog<String?>(
                        context: context,
                        builder: (context) {
                          final controller = TextEditingController();
                          return AlertDialog(
                            title: const Text('Create Category'),
                            content: TextField(
                              controller: controller,
                              autofocus: true,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, null),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  final txt = controller.text.trim();
                                  if (txt.isNotEmpty)
                                    Navigator.pop(context, txt);
                                },
                                child: const Text('Create'),
                              ),
                            ],
                          );
                        },
                      );

                      if (name != null && name.isNotEmpty) {
                        setState(() {
                          createNewCategory(name);
                          setSheetState(() {});
                        });
                      }
                    },
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  buildUncategorizedTile(),
                  buildAllCategoriesTile(),
                  const Divider(),

                  Expanded(
                    child: ListView(
                      shrinkWrap: true,
                      children: buildCategoryListTile(setSheetState),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    appData = context.watch<AppDataController>().data;
    setState(() => buildFilteredNotesList());
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            setState(() {
              _openFilterPicker(context, filterCategoryId);
            });
          },
        ),
        title: getBannerText(),
        actions: [
          IconButton(
            onPressed: () => exportJson(context),
            icon: Icon(Icons.download),
          ),
          if (filterCategoryId != CATAGORY_FILTER_ALL &&
              filterCategoryId != CATAGORY_FILTER_UNSORTED)
            PopupMenuButton<MenuAction>(
              icon: Icon(Icons.more_horiz),
              onSelected: (action) {
                if (action == MenuAction.toggleChecklist) {
                  setState(() {
                    setCategoryAsChecklist(
                      filterCategoryId,
                      !getCategory(filterCategoryId).checklist,
                    );
                  });
                }
                if (action == MenuAction.toggleTimestamps) {
                  setState(() {
                    setCategoryShowTimestamps(
                      filterCategoryId,
                      !getCategory(filterCategoryId).showTimestamps,
                    );
                  });
                }
              },
              itemBuilder: (context) => [
                CheckedPopupMenuItem(
                  value: MenuAction.toggleChecklist,
                  checked: getCategory(filterCategoryId).checklist,
                  child: const Text('Checklist'),
                ),
                CheckedPopupMenuItem(
                  value: MenuAction.toggleTimestamps,
                  checked: getCategory(filterCategoryId).showTimestamps,
                  child: const Text('Show Timestamps'),
                ),
              ],
            ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: ReorderableListView.builder(
                scrollController: _scrollController,
                itemCount: filteredNotes.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    moveNoteItemInlist(
                      filteredNotes[newIndex].id,
                      filteredNotes[oldIndex].id,
                    );
                    //if (newIndex > oldIndex) newIndex--;

                    //get index in master list
                    //calculate new index in big list based on notes around it.
                    //do the move in the main list

                    //final note = filteredNotes.removeAt(oldIndex);
                    //filteredNotes.insert(newIndex, note);
                  });
                },
                itemBuilder: (context, index) {
                  final note = filteredNotes[index];

                  return NoteCard(
                    key: ValueKey(note.id), // 🔑 REQUIRED
                    note: note,
                    startInEditMode: note.isEditing,
                    initialText: "",
                    onSave: (newText) {
                      setState(() => note.text = newText);
                    },
                    onDelete: () {
                      setState(() => deleteNote(note.id));
                    },
                    onFavorite: () {},
                    onCheck: () {
                      setState(() {});
                    },
                    dragIndex: index, // 👈 pass index down
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(child: buildNewNoteButton()),
    );
  }
}
