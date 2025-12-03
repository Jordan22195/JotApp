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
  String text;
  bool isEditing;
  bool isFavorite;

  Note({
    String? id,
    this.text = "",
    this.isEditing = false,
    this.isFavorite = false,
  }) : id = id ?? uuid.v4(); // generates unique ID
}


List<Note> notes = [];
List<NoteCard> noteCards = [];

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

class _NoteCardState extends State<NoteCard> {
  late TextEditingController controller;


  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.note.text);
  
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
            IconButton(icon: Icon(Icons.menu), onPressed: widget.onFavorite),
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
        text: _counter.toString(),
        isEditing: true,     // ← starts as TextField
    );
    print("new note");
    print(n.id);
    for (Note note in notes){
      note.isEditing = false;}

    notes.insert(0,n);
    
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
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(

          mainAxisAlignment: .center,
          children: [
            FloatingActionButton(
            onPressed: addNewNoteCard,
            tooltip: 'Increment',
            child: const Icon(Icons.add),
      ),

      // ListView.builder inside Expanded
          Expanded(
            child: ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                return NoteCard(
                  key: ValueKey(notes[index].id),
                  note: notes[index], 
                  startInEditMode: notes[index].isEditing,
                  initialText: "", 
                  onSave: (newText) {
                    setState(() => notes[index].text = newText);
                  },
                  onDelete: (){}, 
                  onFavorite: (){},);
              }
            ),
        ),

        ]

          ,
        ),
      ),
      
    );
  }
}
