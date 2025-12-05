import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

var uuid = Uuid();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
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
    labelId = "",
    this.text = "",
    this.isEditing = false,
    this.isFavorite = false,
  }) : id = id ?? uuid.v4(); // generates unique ID
}

class Label {
  final String id;
  final String name;

  Label({
    required this.id,
    required this.name,
  });
}

List<Label> labels = [];

List<Note> notes = [];
List<Note> filteredNotes = [];
List<String> existingLabels = [];
List<NoteCard> noteCards = [];
String? activeFilter;

String filterLabelId = "";

class NoteCard extends StatefulWidget {
  final String initialText;
  final ValueChanged<String> onSave;
  final VoidCallback onDelete;
  final VoidCallback onFavorite;
  final bool startInEditMode;
  final Note note;

  NoteCard({
    required super.key,
    required this.note,
    required this.initialText,
    required this.onSave,
    required this.onDelete,
    required this.onFavorite,
    this.startInEditMode = false,
  });

  @override
  _NoteCardState createState() => _NoteCardState();
}

class LabelPickerSheet extends StatefulWidget {
  final Function(String) onCreateLabel;
  final Function(String) onSelectLabel;

  const LabelPickerSheet({
    required this.onCreateLabel,
    required this.onSelectLabel,
    super.key,
  });

  @override
  State<LabelPickerSheet> createState() => _LabelPickerSheetState();
}

class _LabelPickerSheetState extends State<LabelPickerSheet> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Labels", style: TextStyle(fontSize: 20)),
          const SizedBox(height: 12),

          // List of labels
          ...labels.map((label) {
            return ListTile(
              title: Text(label.name),
              onTap: (){
                setState(() =>  widget.onSelectLabel(label.id));},
            );
          }),

          const Divider(),

          // Create new label button
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text("Create new label"),
            onTap: () async {
              final newLabel = await _openCreateLabelDialog(context);
              if (newLabel != null && newLabel.isNotEmpty) {
                widget.onCreateLabel(newLabel);
              }
            },
          ),
        ],
      ),
    );
  }
}

Future<String?> _openCreateLabelDialog(BuildContext context) {
  final controller = TextEditingController();
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("New label"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Create"),
            onPressed: () => Navigator.pop(context, controller.text),
          ),
        ],
      );
    },
  );
}


class _NoteCardState extends State<NoteCard> {
  late TextEditingController controller;

void _openLabelPicker(BuildContext context, String labelId, {bool? filter=false, Note? note}) {
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
            padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Labels', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 8),

                // Build the list from the parent's labels list (capture by reference)
                ...labels.map((label) {
                  final selected = labelId == label.id;
                  return ListTile(
                    title: Text(label.name),
                    trailing: selected ? const Icon(Icons.check) : null,
                    onTap: () {
                      if(filter != null && filter){
                        filterLabelId = label.id;
                      }
                      else if(note != null){
                        setState(() => note.labelId = label.id); // parent setState

                      }
                      // Assign label to note in parent state
                      // Also close the sheet (or keep open if you prefer)
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
                            TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () {
                                final txt = controller.text.trim();
                                if (txt.isNotEmpty) Navigator.pop(context, txt);
                              },
                              child: const Text('Create'),
                            ),
                          ],
                        );
                      },
                    );

                    if (name != null && name.isNotEmpty) {
                      // 1) Add to parent labels list
                      final newLabel = Label(id: uuid.v4(), name: name);
                      setState(() => labels.add(newLabel)); // parent setState

                      // 2) Also update the sheet's UI immediately
                      setSheetState(() { /* no-op, labels has been mutated; this forces rebuild */ });

                      // Optionally assign the new label to the note and close sheet
                      //setState(() => note.labelId = newLabel.id);
                      //Navigator.of(context).pop();
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
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.note.text);
  
  }

  Text getCardLable(String labelId){
    Text ret = Text("");
    for( Label l in labels){
      if ( l.id == widget.note.labelId){
          ret = Text(l.name);
      }
    }
    return ret;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: widget.note.isEditing
                  ? TextField(
                      controller: controller,
                      autofocus: true,
                      onChanged: (value) {
                        widget.note.text = value;
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    )
                  : Text(
                      widget.note.text,
                      style: TextStyle(fontSize: 16),
                    ),
            ),

            if (!widget.note.isEditing)
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () => setState(() => widget.note.isEditing = true),
              ),

            if (widget.note.isEditing)
              IconButton(
                icon: Icon(Icons.check),
                onPressed: () {
                  setState(() => widget.note.isEditing = false);
                  widget.onSave(controller.text);
                },
              ),

            IconButton(icon: Icon(Icons.delete), onPressed: widget.onDelete),
            IconButton(icon: Icon(Icons.menu), onPressed: () => _openLabelPicker(context,widget.note.labelId, note: widget.note)),
            getCardLable(widget.note.labelId),
            
            ],
        ),
      ),
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
  int _counter = 0;
  String latestInputText = "";
  final TextEditingController controller = TextEditingController();
  List<Note> notes = [];

  void addNewNoteCard() {
    _counter++;
  setState(() {
      Note n = Note(
        text: "",
        labelId: filterLabelId,
        isEditing: true,     // ← starts as TextField
    );
    print("new note");
    print(n.id);
    for (Note note in notes){
      note.isEditing = false;}

    notes.insert(0,n);
    filteredNotes.insert(0,n);
    
  });
}


  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  void _setTextInput() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }


  Text getBannerText(){
    Text ret = Text("Recent Notes");
    for (Label l in labels){
      if (l.id == filterLabelId){
        ret = Text(l.name);
      }
    }
    return  ret;
  }
  

  void _openLabelPicker(BuildContext context, String labelId, {bool? filter=false, Note? note}) {
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
            padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Labels', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 8),

                ListTile(
                  title: Text("All"),
                  trailing: (filterLabelId == "") ? const Icon(Icons.check) : null,
                  onTap : () {
                    setState(() {
                      filterLabelId = "";
                      filteredNotes.clear();
                      for (Note n in notes){
                        filteredNotes.insert(0, n);
                      }
                    });
                  }
                ),
                // Build the list from the parent's labels list (capture by reference)
                ...labels.map((label) {
                  final selected = labelId == label.id;
                  return ListTile(
                    title: Text(label.name),
                    trailing: selected ? const Icon(Icons.check) : null,
                    onTap: () {
                      setState(() {
                        if(filter != null && filter){
                        filterLabelId = label.id;
                        filteredNotes.clear();
                        for (Note n in notes){
                          if(n.labelId == filterLabelId){
                            filteredNotes.add(n);
                          }
                        }
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
                            TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () {
                                final txt = controller.text.trim();
                                if (txt.isNotEmpty) Navigator.pop(context, txt);
                              },
                              child: const Text('Create'),
                            ),
                          ],
                        );
                      },
                    );

                    if (name != null && name.isNotEmpty) {
                      // 1) Add to parent labels list
                      final newLabel = Label(id: uuid.v4(), name: name);
                      setState(() => labels.add(newLabel)); // parent setState

                      // 2) Also update the sheet's UI immediately
                      setSheetState(() { /* no-op, labels has been mutated; this forces rebuild */ });

                      // Optionally assign the new label to the note and close sheet
                      //setState(() => note.labelId = newLabel.id);
                      //Navigator.of(context).pop();
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
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
  
        title: getBannerText(),
        actions: [
            IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                setState(() {
                _openLabelPicker(context, filterLabelId, filter: true);
                  
                });
              },
              )
        ]
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(

          mainAxisAlignment: .center,
          children: [
            FloatingActionButton(
              
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20),),

              
            onPressed: addNewNoteCard,
            tooltip: 'New Note', 
           // padding : const EdgeInsets.all(16.0),
            child:  const Icon(Icons.add),
      ),

      // ListView.builder inside Expanded
          Expanded(
            child: 
                  ListView.builder(
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
                          onDelete: (){}, 
                          onFavorite: (){},);
                    }
                  )
              
            ),
        ]
          ,
        ),
      ),
      
    );
  }
}
