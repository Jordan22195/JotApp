import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'AppData.dart';
import 'dataStorage.dart';
import 'appDataController.dart';
import 'categoryMenu.dart';

class NoteCard extends StatefulWidget {
  final String initialText;
  final ValueChanged<String> onSave;
  final VoidCallback onDelete;
  final VoidCallback onFavorite;
  final VoidCallback onTap;
  final void Function(bool) onCheck;
  final VoidCallback onEdit;
  final void Function(String) onCategorize;
  final bool startInEditMode;
  final Note note;
  final int dragIndex;
  final bool animateRemoval;
  bool isHighlighted = true;

  NoteCard({
    required super.key,
    required this.note,
    required this.initialText,
    required this.onSave,
    required this.onDelete,
    required this.onFavorite,
    required this.onTap,
    required this.onCheck,
    required this.onEdit,
    required this.onCategorize,
    required this.dragIndex,

    this.startInEditMode = false,
    this.animateRemoval = false,
  });

  @override
  _NoteCardState createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard>
    with SingleTickerProviderStateMixin {
  late TextEditingController controller;
  bool categoryTapped = false;
  late AppDataController dataController;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.note.text);

    if (widget.animateRemoval) {
      _playRemovalAnimation();
    }
  }

  void _playRemovalAnimation() async {
    await _controller.forward();
    widget.onDelete();
  }

  // Call this when you want to remove the card with animation
  void removeWithAnimation() {
    _playRemovalAnimation();
  }

  void _playCategorizeAnimation(String newCategoryId) async {
    await _controller.forward();
    widget.onCategorize(newCategoryId);
  }

  // Call this when you want to remove the card with animation
  void categorizeWithAnimation(String newCategoryId) {
    _playCategorizeAnimation(newCategoryId);
  }

  @override
  void dispose() {
    controller.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Animation controller for slide/fade
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  late final Animation<Offset> _slideAnimation = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(1, 0), // slide to right
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  late final Animation<double> _fadeAnimation = Tween<double>(
    begin: 1,
    end: 0,
  ).animate(_controller);

  String newCategoryId = "";

  List<Widget> buildCategoryListTiles(Note note) {
    List<ListTile> tiles = [];
    for (Category category in dataController.data.categories) {
      final selected = note.categoryId == category.id;
      tiles.add(
        ListTile(
          title: Text(category.name),
          trailing: selected ? const Icon(Icons.check) : null,
          onTap: () {
            if (note != null) {
              setState(() {
                categoryTapped = true;
                // if a cateogy is tapped it will always change lists.
                selected
                    ? newCategoryId = CATAGORY_FILTER_UNSORTED
                    : newCategoryId = category.id;
              }); // parent setState
              //widget.onCheck();
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
      builder: (_) => CategoryMenu(
        currentSelectedCategoryId: widget.note.categoryId,
        onSelected: (selectedCategoryId) {
          // card will always leave view outside of All
          if (filterCategoryId != CATAGORY_FILTER_ALL) {
            Future.delayed(const Duration(milliseconds: 300), () {
              categorizeWithAnimation(selectedCategoryId);
            });
          } else {
            widget.onCategorize(selectedCategoryId);
          }
        },
      ),
    ).then((_) {});
  }

  final TextStyle noteTextStyle = const TextStyle(
    fontSize: 16,
    height: 1.2,
    letterSpacing: 0.0,
  );

  String getCardCategory(String categoryId) {
    String ret = "";
    for (Category l in dataController.data.categories) {
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
          widget.onSave(value);
        },
      );
    }
    return Text(widget.note.text, style: noteTextStyle, maxLines: 6);
  }

  double _opacity = 1.0;
  bool newCheckedValue = false;
  Widget buildCheckBox() {
    if (isNoteCheckboxCategory(widget.note.categoryId)) {
      return Checkbox(
        value: widget.note.checked,
        onChanged: (_) {
          newCheckedValue = !widget.note.checked;

          setState(() {
            setState(() {
              _opacity = 0; // fade out
              dataController.setNoteChecked(widget.note.id, newCheckedValue);
            });
          });
          Future.delayed(const Duration(milliseconds: 400), () {
            widget.onCheck(newCheckedValue);

            setState(() {
              _opacity = 1;
            });
          });
        },
      );
    }
    return SizedBox(width: 10);
  }

  Widget buildEditIcon() {
    if (!widget.note.isEditing) {
      return IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () {
          dataController.endEditForAllNotes();
          widget.onSave(controller.text);
          widget.note.isEditing = true;
          widget.onEdit();
        },
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.check),
        onPressed: () {
          setState(() => widget.note.isEditing = false);
          widget.onSave(controller.text);
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
        onPressed: () => removeWithAnimation(),
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
    for (Category c in dataController.data.categories) {
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
    dataController = context.watch<AppDataController>();

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _opacity,
          child: Card(
            elevation: 1.5,
            surfaceTintColor: Colors.transparent,
            color: Color(0xFFFFFFFF),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: () {
                widget.onTap();
                dataController.endEditForAllNotes();
                widget.onSave(controller.text);
                widget.note.isEditing = true;
                widget.onEdit();
              },
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

                        //buildEditIcon(),
                        buildCategoryPickerIcon(),
                      ],
                    ),

                    // BOTTOM ROW
                    Row(
                      children: [
                        const SizedBox(width: 40),
                        buildCategoryLabel(),
                        if (dataController
                            .getCategory(widget.note.categoryId)
                            .showTimestamps)
                          Expanded(
                            child: Text(
                              dataController.getNoteCreationDateTime(
                                widget.note.id,
                              ),
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
            ),
          ),
        ),
      ),
    );
  }
}
