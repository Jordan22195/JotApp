import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:notes_app/selectableIcon.dart';
import 'package:provider/provider.dart';
import 'AppData.dart';
import 'dataStorage.dart';
import 'appDataController.dart';
import 'categoryMenu.dart';
import 'package:flutter/services.dart';

class NoteCard extends StatefulWidget {
  final String initialText;
  final ValueChanged<String> onSave;
  final VoidCallback onDelete;
  final VoidCallback onTitleToggle;
  final VoidCallback onTap;
  final void Function(bool) onCheck;
  final void Function(String) onNewNote;
  final void Function(String) onCategorize;
  final bool startInEditMode;
  final Note note;
  final bool animateRemoval;
  bool titleCard;
  bool isHighlighted = true;

  NoteCard({
    required super.key,
    required this.note,
    required this.initialText,
    required this.onSave,
    required this.onDelete,
    required this.onTitleToggle,
    required this.onTap,
    required this.onCheck,
    required this.onNewNote,
    required this.onCategorize,

    this.startInEditMode = false,
    this.animateRemoval = false,
    this.titleCard = false,
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
    duration: const Duration(milliseconds: 250),
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
            Future.delayed(const Duration(milliseconds: 200), () {
              if (selectedCategoryId == filterCategoryId ||
                  selectedCategoryId == CATAGORY_FILTER_ALL) {
                categorizeWithAnimation(CATAGORY_FILTER_UNSORTED);
              } else {
                categorizeWithAnimation(selectedCategoryId);
              }
            });
          } else {
            widget.onCategorize(selectedCategoryId);
          }
        },
      ),
    ).then((_) {});
  }

  final TextStyle sectionTitleTextStyle = const TextStyle(
    fontSize: 24,
    height: 1.2,
    letterSpacing: 0.0,
  );

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

  bool cardTextOverflow = false;
  bool cardStateExpanded = false;
  Widget getCardTextContent(constraints) {
    if (widget.note.isEditing) {
      return TextField(
        controller: controller,
        style: widget.titleCard ? sectionTitleTextStyle : noteTextStyle,
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

    if (cardStateExpanded) {
      return Text(
        widget.note.text,
        style: widget.titleCard ? sectionTitleTextStyle : noteTextStyle,
      );
    }

    final t = Text(
      widget.note.text,
      style: widget.titleCard ? sectionTitleTextStyle : noteTextStyle,
      maxLines: 6,
      overflow: TextOverflow.ellipsis,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.note.text,
        style: widget.titleCard ? sectionTitleTextStyle : noteTextStyle,
      ),
      maxLines: 6,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: constraints.maxWidth);

    cardTextOverflow = textPainter.didExceedMaxLines;

    return t;
  }

  double _opacity = 1.0;
  bool newCheckedValue = false;
  Widget buildCheckBox() {
    if (widget.titleCard) {
      return SizedBox(width: 10);
    }
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
          Future.delayed(const Duration(milliseconds: 250), () {
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

  Widget buildExpandIcon() {
    double widgetWidth = 1;
    IconButton button;
    if (cardTextOverflow && !cardStateExpanded) {
      button = IconButton(
        icon: const Icon(Icons.expand_more),
        onPressed: () {
          setState(() {
            cardStateExpanded = true;
          });
        },
      );
    } else if (cardStateExpanded) {
      button = IconButton(
        icon: const Icon(Icons.expand_less_outlined),
        onPressed: () {
          setState(() {
            cardStateExpanded = false;
          });
        },
      );
    } else {
      return SizedBox(width: widgetWidth);
    }
    return SizedBox(width: widgetWidth, child: button);
  }

  Widget buildCategoryLabel() {
    double textWidth = 80;
    if (filterCategoryId == CATAGORY_FILTER_ALL) {
      return SizedBox(
        width: textWidth,
        child: Text(
          getCardCategory(widget.note.categoryId),
          style: const TextStyle(fontSize: 11),
        ),
      );
    }
    return SizedBox(width: textWidth);
  }

  Widget buildTimestampLabel() {
    double widgetWidth = 80;
    if (dataController.getCategory(widget.note.categoryId).showTimestamps) {
      // return Expanded(
      return SizedBox(
        width: widgetWidth,
        child: Text(
          dataController.getNoteCreationDateTime(widget.note.id),
          style: const TextStyle(fontSize: 11),
          textAlign: TextAlign.right,
        ),
      );
      //  );
    }
    return SizedBox(width: widgetWidth);
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
            elevation: widget.titleCard ? 0 : 1.5,
            surfaceTintColor: Colors.transparent,
            color: widget.titleCard ? Colors.transparent : Color(0xFFFFFFFF),
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
                if (cardTextOverflow) {
                  cardStateExpanded = true;
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),

                child: Column(
                  children: [
                    //Row 1 - content
                    // CheckBox | Text | category picker
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Column 1: left icon (fixed)
                        SizedBox(
                          width:
                              (!dataController
                                      .getCategory(widget.note.categoryId)
                                      .checklist ||
                                  widget.titleCard)
                              ? 0
                              : 30, // pick a consistent tap target width
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: buildCheckBox(),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Column 2: text
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 14),

                                  getCardTextContent(constraints),
                                ],
                              );
                            },
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Column 3: icons stacked (fixed)\
                        SizedBox(
                          width: 44, // consistent width for icon column
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              widget.titleCard
                                  ? IconButton(
                                      onPressed: () {
                                        String
                                        id = dataController.addNewNoteCard(
                                          categoryId: widget.note.categoryId,
                                          insertIndex:
                                              dataController.getNoteIndexInList(
                                                widget.note.id,
                                              ) +
                                              1,
                                        );
                                        widget.onNewNote(id);
                                      },
                                      icon: Icon(Icons.add),
                                    )
                                  : buildCategoryPickerIcon(),
                            ],
                          ),
                        ),
                      ],
                    ),

                    //Row 2 - status
                    // cat label | expand | datetime
                    Row(
                      children: [
                        buildCategoryLabel(),
                        Expanded(child: buildExpandIcon()),
                        if (!widget.titleCard) buildTimestampLabel(),
                      ],
                    ),

                    //Row 3 - edit button
                    // tite | copy | trash
                    if (widget.note.isEditing)
                      Row(
                        children: [
                          // title
                          IconButton(
                            icon: Icon(Icons.text_format),
                            onPressed: () {
                              setState(() {
                                widget.onTitleToggle();
                              });
                            },
                          ),
                          // copy
                          IconButton(
                            icon: Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: widget.note.text),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Copied to clipboard'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                          Spacer(),
                          //delete
                          buildDeleteIcon(),
                        ],
                      ),
                  ],
                ),
                /*
                Column(
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
                            child: getCardTextContent(constraints),
                          ),
                        ),

                        //buildEditIcon(),
                        buildCategoryPickerIcon(),
                      ],
                    ),

                    // BOTTOM ROW
                    Row(
                      children: [
                        const SizedBox(width: 10),
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
                        buildExpandIcon(),
                      ],
                    ),
                  ],
                ),*/
              ),
            ),
          ),
        ),
      ),
    );
  }
}
