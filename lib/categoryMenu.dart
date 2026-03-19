import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'AppData.dart';
import 'appDataController.dart';
import 'selectableIcon.dart';
import 'main.dart';

bool isNewCategoryChecklist = false;
bool isNewCategoryTimestamo = false;

class CategoryMenu extends StatefulWidget {
  final String currentSelectedCategoryId;
  final void Function(String) onSelected;
  static bool categoryEditMode = false;

  CategoryMenu({
    super.key,
    required this.currentSelectedCategoryId,
    required this.onSelected,
  });

  @override
  State<CategoryMenu> createState() => _CategoryMenuState();
}

class _CategoryMenuState extends State<CategoryMenu> {
  ListTile buildAllCategoriesTile() {
    bool selected = widget.currentSelectedCategoryId == CATAGORY_FILTER_ALL;
    return ListTile(
      title: Text("All Notes"),
      trailing: CategoryMenu.categoryEditMode
          ? null
          : selected
          ? const Icon(Icons.check)
          : null,
      onTap: () {
        setState(() {
          widget.onSelected(CATAGORY_FILTER_ALL);
        });

        Navigator.of(context).pop();
      },
    );
  }

  ListTile buildUncategorizedTile() {
    bool selected =
        widget.currentSelectedCategoryId == CATAGORY_FILTER_UNSORTED;
    return ListTile(
      title: Text("Uncategorized"),
      trailing: CategoryMenu.categoryEditMode
          ? null
          : selected
          ? const Icon(Icons.check)
          : null,
      onTap: () {
        setState(() {
          widget.onSelected(CATAGORY_FILTER_UNSORTED);
        });

        Navigator.of(context).pop();
      },
    );
  }

  List<Widget> buildCategoryListTile(Function setSheetState) {
    List<ListTile> tiles = [];
    final dataController = context.watch<AppDataController>();
    final data = dataController.data;
    for (Category category in data.categories) {
      if (category.id == CATAGORY_FILTER_UNSORTED) {
        continue;
      }
      final selected = widget.currentSelectedCategoryId == category.id;
      final controller = TextEditingController();
      controller.text = category.name;

      tiles.add(
        ListTile(
          title: CategoryMenu.categoryEditMode
              ? TextField(
                  controller: controller,
                  onChanged: (value) {
                    category.name = value;
                  },
                )
              : Text(category.name),
          trailing: CategoryMenu.categoryEditMode
              ? IconButton(
                  onPressed: () {
                    dataController.deleteCategory(category.id);
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
              widget.onSelected(category.id);
            });

            Navigator.of(context).pop();
          },
        ),
      );
    }
    return tiles;
  }

  @override
  Widget build(BuildContext context) {
    final dataController = context.watch<AppDataController>();

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
                  IconButton(
                    icon: CategoryMenu.categoryEditMode
                        ? Icon(Icons.check)
                        : Icon(Icons.edit),
                    onPressed: () {
                      setState(() {});
                      if (CategoryMenu.categoryEditMode) {
                        dataController.commitData();
                      }
                      CategoryMenu.categoryEditMode =
                          !CategoryMenu.categoryEditMode;

                      setSheetState(() {});
                    },
                  ),
                  Expanded(
                    child: Center(
                      child: Text("Categories", style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop();
                      setSheetState(() {
                        CategoryMenu.categoryEditMode = false;
                      });
                    },
                  ),
                ],
              ),

              // create category button at top
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Create New Category'),
                onTap: () async {
                  isNewCategoryChecklist = false;
                  isNewCategoryTimestamo = false;
                  // popup for new catagory
                  final name = await showDialog<String?>(
                    context: context,
                    builder: (context) {
                      final controller = TextEditingController();

                      return StatefulBuilder(
                        builder: (context, setDialogState) {
                          return AlertDialog(
                            title: const Text('Create Category'),

                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: controller,
                                        autofocus: true,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    SelectableIconButton(
                                      selected: isNewCategoryChecklist,
                                      icon: Icons.checklist,
                                      onChanged: (value) {
                                        setDialogState(() {
                                          isNewCategoryChecklist = value;
                                        });
                                      },
                                    ),
                                    SelectableIconButton(
                                      selected: isNewCategoryTimestamo,
                                      icon: Icons.timer_outlined,
                                      onChanged: (value) {
                                        setDialogState(() {
                                          isNewCategoryTimestamo = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
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
                    },
                  );

                  if (name != null && name.isNotEmpty) {
                    String id = dataController.createNewCategory(
                      name,
                      checklist: isNewCategoryChecklist,
                      timestamps: isNewCategoryTimestamo,
                    );
                    setSheetState(() {});
                    widget.onSelected(id);
                    Navigator.of(context).pop();
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
  }
}
