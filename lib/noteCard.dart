import 'package:flutter/material.dart';
import 'AppData.dart';
import 'dataStorage.dart';
import 'appDataController.dart';

class NoteCard extends StatefulWidget {
  final String initialText;
  final ValueChanged<String> onSave;
  final VoidCallback onDelete;
  final VoidCallback onFavorite;
  final VoidCallback onCheck;
  final bool startInEditMode;
  final Note note;
  final int dragIndex;

  NoteCard({
    required super.key,
    required this.note,
    required this.initialText,
    required this.onSave,
    required this.onDelete,
    required this.onFavorite,
    required this.onCheck,
    required this.dragIndex,
    this.startInEditMode = false,
  });

  @override
  _NoteCardState createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  late TextEditingController controller;

  List<Widget> buildCategoryListTiles(Note note) {
    List<ListTile> tiles = [];
    for (Category category in appData.categories) {
      final selected = note.categoryId == category.id;
      tiles.add(
        ListTile(
          title: Text(category.name),
          trailing: selected ? const Icon(Icons.check) : null,
          onTap: () {
            if (note != null) {
              setState(() {
                selected
                    ? setNoteCatagory(note.id, CATAGORY_FILTER_UNSORTED)
                    : setNoteCatagory(note.id, category.id);
              }); // parent setState
            }
            // Assign category to note in parent state
            // Also close the sheet (or keep open if you prefer)
            Navigator.of(context).pop();
          },
        ),
      );
    }

    return tiles;
  }

  void _openCategoryPicker(BuildContext context, Note note) {
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

                  const Text('Categories', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  // Create new category tile
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
                        // 1) Add to parent category list
                        setState(() {
                          String newId = createNewCategory(name);
                          if (note != null) {
                            setNoteCatagory(note.id, newId); // parent setState
                          }
                        });

                        // 2) Also update the sheet's UI immediately
                        setSheetState(() {});
                        Navigator.of(context).pop();
                      }
                    },
                  ),

                  const Divider(),
                  // Build the list from the parent's category's list (capture by reference)
                  Expanded(
                    child: ListView(
                      shrinkWrap: true,
                      children: buildCategoryListTiles(note),
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

  final TextStyle noteTextStyle = const TextStyle(
    fontSize: 16,
    height: 1.2,
    letterSpacing: 0.0,
  );

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.note.text);
  }

  String getCardCategory(String categoryId) {
    String ret = "";
    for (Category l in appData.categories) {
      if (l.id == categoryId) {
        ret = l.name;
      }
    }
    return ret;
  }

  Widget getCardTextContent() {
    if (widget.note.isEditing) {
      return TextField(
        controller: controller,
        style: noteTextStyle,
        textAlignVertical: TextAlignVertical.top,
        decoration: const InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        autofocus: true,
        maxLines: null, // ← auto grows
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        onChanged: (value) {
          widget.note.text = value;
        },
      );
    }
    return Text(widget.note.text, style: noteTextStyle);
  }

  Widget buildCheckBox() {
    if (isNoteCheckboxCategory(widget.note.categoryId)) {
      return Checkbox(
        value: widget.note.checked,
        onChanged: (_) {
          setState(() {
            setNoteChecked(widget.note.id, !widget.note.checked);
            if (widget.note.checked) {
              moveNoteToEndOfList(widget.note.id);
            } else {
              moveNoteToStartOfList(widget.note.id);
            }
          });
          widget.onCheck();
        },
      );
    }
    return SizedBox(width: 40);
  }

  Widget buildEditIcon() {
    if (!widget.note.isEditing) {
      return IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () => setState(() {
          endEditForAllNotes();
          widget.onSave(controller.text);
          widget.note.isEditing = true;
        }),
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.check),
        onPressed: () {
          setState(() => widget.note.isEditing = false);
          widget.onSave(controller.text);
          saveAppData();
        },
      );
    }
  }

  Widget buildCategoryPickerIcon() {
    return IconButton(
      icon: const Icon(Icons.menu),
      onPressed: () {
        _openCategoryPicker(context, widget.note);
        setState(() {
          widget.note.isEditing = false;
        });
      },
    );
  }

  Widget buildDeleteIcon() {
    if (widget.note.isEditing) {
      return IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () => setState(widget.onDelete),
      );
    } else {
      return SizedBox(width: 40);
    }
  }

  Widget buildCategoryLabel() {
    if (filterCategoryId == CATAGORY_FILTER_ALL ||
        filterCategoryId == CATAGORY_FILTER_UNSORTED) {
      return Expanded(
        child: Text(
          getCardCategory(widget.note.categoryId),
          style: const TextStyle(fontSize: 11),
        ),
      );
    }
    return Spacer();
  }

  bool isNoteCheckboxCategory(String categoryId) {
    bool ret = false;
    for (Category c in appData.categories) {
      if (c.id == categoryId) {
        if (c.checklist) {
          return true;
        }
      }
    }
    return ret;
  }

  bool testCheck = true;
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TOP ROW
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.note.isEditing
                    ? const SizedBox(width: 0)
                    : ReorderableDelayedDragStartListener(
                        index: widget.dragIndex,
                        child: const SizedBox(width: 0),
                      ),

                Padding(
                  padding: const EdgeInsets.only(top: 0),
                  child: buildCheckBox(),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: getCardTextContent(),
                  ),
                ),

                buildEditIcon(),
                buildCategoryPickerIcon(),
              ],
            ),

            // BOTTOM ROW
            Row(
              children: [
                const SizedBox(width: 40),
                buildCategoryLabel(),
                if (getCategory(widget.note.categoryId).showTimestamps)
                  Expanded(
                    child: Text(
                      getNoteCreationDateTime(widget.note.id),
                      style: const TextStyle(fontSize: 11),
                      textAlign: TextAlign.right,
                    ),
                  ),
                if (widget.note.isEditing) buildDeleteIcon(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
