import 'package:flutter/material.dart';
import 'AppData.dart';
import 'dataStorage.dart';
import 'appDataController.dart';

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

  void _openCategoryPicker(
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
                  const Text('Labels', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),

                  // Build the list from the parent's labels list (capture by reference)
                  ...appData.labels.map((label) {
                    final selected = labelId == label.id;
                    return ListTile(
                      title: Text(label.name),
                      trailing: selected ? const Icon(Icons.check) : null,
                      onTap: () {
                        if (filter != null && filter) {
                          filterLabelId = label.id;
                        } else if (note != null) {
                          setState(
                            () => setNoteCatagory(note.id, label.id),
                          ); // parent setState
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
                        // 1) Add to parent labels list
                        final newLabel = Label(id: uuid.v4(), name: name);
                        setState(() => createNewLabel(name)); // parent setState
                        // 2) Also update the sheet's UI immediately
                        setSheetState(() {
                          /* no-op, labels has been mutated; this forces rebuild */
                        });

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

  Text getCardCategory(String labelId) {
    Text ret = Text("");
    for (Label l in appData.labels) {
      if (l.id == widget.note.labelId) {
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
                      decoration: InputDecoration(border: OutlineInputBorder()),
                    )
                  : Text(widget.note.text, style: TextStyle(fontSize: 16)),
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
                  saveAppData();
                },
              ),

            IconButton(icon: Icon(Icons.delete), onPressed: widget.onDelete),
            IconButton(
              icon: Icon(Icons.menu),
              onPressed: () => _openCategoryPicker(
                context,
                widget.note.labelId,
                note: widget.note,
              ),
            ),
            getCardCategory(widget.note.labelId),
          ],
        ),
      ),
    );
  }
}
