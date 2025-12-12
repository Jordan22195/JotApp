import 'package:flutter/material.dart';
import 'AppData.dart';

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
          ...appData.labels.map((label) {
            return ListTile(
              title: Text(label.name),
              onTap: () {
                setState(() => widget.onSelectLabel(label.id));
              },
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
