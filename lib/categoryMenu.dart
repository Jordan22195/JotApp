import 'package:flutter/material.dart';
import 'AppData.dart';
import 'appDataController.dart';

bool categoryEditMode = false;

class CategoryMenu extends StatefulWidget {
  final String currentSelectedCategoryId;
  final VoidCallback onSelected;

  const CategoryMenu({
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
    bool selected =
        widget.currentSelectedCategoryId == CATAGORY_FILTER_UNSORTED;
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
      final selected = widget.currentSelectedCategoryId == category.id;
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

  @override
  Widget build(BuildContext context) {
    categoryEditMode = false;

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
                      child: Text("Categories", style: TextStyle(fontSize: 18)),
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
                              if (txt.isNotEmpty) Navigator.pop(context, txt);
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
  }
}
