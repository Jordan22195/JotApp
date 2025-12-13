import 'package:flutter/material.dart';
import 'AppData.dart';

class CategoryPickerSheet extends StatefulWidget {
  final Function(String) onCreateCategory;
  final Function(String) onSelectCategory;

  const CategoryPickerSheet({
    required this.onCreateCategory,
    required this.onSelectCategory,
    super.key,
  });

  @override
  State<CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<CategoryPickerSheet> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Categories", style: TextStyle(fontSize: 20)),
          const SizedBox(height: 12),

          ...appData.categories.map((category) {
            return ListTile(
              title: Text(category.name),
              onTap: () {
                setState(() => widget.onSelectCategory(category.id));
              },
            );
          }),

          const Divider(),

          // Create new category button
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text("Create New Category"),
            onTap: () async {
              final newCategory = await _openCreateCategoryDialog(context);
              if (newCategory != null && newCategory.isNotEmpty) {
                widget.onCreateCategory(newCategory);
              }
            },
          ),
        ],
      ),
    );
  }
}

Future<String?> _openCreateCategoryDialog(BuildContext context) {
  final controller = TextEditingController();
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("New Category"),
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
