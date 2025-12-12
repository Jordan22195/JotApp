import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'AppData.dart';
import 'noteCard.dart';
import 'labelPicker.dart';
import 'dataStorage.dart';
import 'appDataController.dart';

void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => AppDataController(), child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
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

  Text getBannerText() {
    Text ret = Text("");
    if (filterLabelId == CATAGORY_FILTER_ALL) {
      ret = Text("All Notes");
    } else if (filterLabelId == CATAGORY_FILTER_UNSORTED) {
      ret = Text("Uncategorized Notes");
    } else {
      for (Label l in appData.labels) {
        if (l.id == filterLabelId) {
          ret = Text(l.name);
        }
      }
    }
    return ret;
  }

  ListTile buildAllCategoriesTile() {
    bool selected = filterLabelId == CATAGORY_FILTER_ALL;
    return ListTile(
      title: Text("All Notes"),
      trailing: selected ? const Icon(Icons.check) : null,
      onTap: () {
        setState(() {
          setCatagoryFilter(CATAGORY_FILTER_ALL);
          Navigator.of(context).pop();
        });
      },
    );
  }

  ListTile buildUncategorizedTile() {
    bool selected = filterLabelId == CATAGORY_FILTER_UNSORTED;
    return ListTile(
      title: Text("Uncatgorized Notes"),
      trailing: selected ? const Icon(Icons.check) : null,
      onTap: () {
        setState(() {
          setCatagoryFilter(CATAGORY_FILTER_UNSORTED);
          Navigator.of(context).pop();
        });
      },
    );
  }

  void _openFilterPicker(
    BuildContext context,
    String labelId, {
    bool? filter = false,
    Note? note,
  }) {
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
                  const Text('Categories', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  buildUncategorizedTile(),
                  buildAllCategoriesTile(),

                  // Build the list from the parent's labels list (capture by reference)
                  ...appData.labels.map((label) {
                    final selected = filterLabelId == label.id;
                    return ListTile(
                      title: Text(label.name),
                      trailing: selected ? const Icon(Icons.check) : null,
                      onTap: () {
                        setState(() {
                          if (filter != null && filter) {
                            setCatagoryFilter(label.id);
                          }
                        });

                        Navigator.of(context).pop();
                      },
                    );
                  }).toList(),

                  const Divider(),

                  // Create new label tile
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Create new label'),
                    onTap: () async {
                      // Ask for name
                      final name = await showDialog<String?>(
                        context: context,
                        builder: (context) {
                          final controller = TextEditingController();
                          return AlertDialog(
                            title: const Text('Create label'),
                            content: TextField(controller: controller),
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
                          createNewLabel(name);
                          setSheetState(() {});
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 8),
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

        title: getBannerText(),
        actions: [
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              setState(() {
                _openFilterPicker(context, filterLabelId, filter: true);
              });
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            FloatingActionButton(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),

              onPressed: () {
                setState(() {
                  addNewNoteCard();
                  buildFilteredNotesList();
                });
              },
              tooltip: 'New Note',
              child: const Icon(Icons.add),
            ),

            Expanded(
              child: ListView.builder(
                itemCount: filteredNotes.length,
                itemBuilder: (context, index) {
                  return NoteCard(
                    key: ValueKey(filteredNotes[index].id),
                    note: filteredNotes[index],
                    startInEditMode: filteredNotes[index].isEditing,
                    initialText: "",
                    onSave: (newText) {
                      setState(() => filteredNotes[index].text = newText);
                    },
                    onDelete: () {},
                    onFavorite: () {},
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
