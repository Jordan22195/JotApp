import 'package:flutter/material.dart';
import 'main.dart';

class SelectableIconButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final EdgeInsets padding;
  final ValueChanged<bool>? onChanged;
  final bool selected;

  const SelectableIconButton({
    super.key,
    required this.icon,
    required this.selected,
    this.size = 24,
    this.padding = const EdgeInsets.all(8),
    this.onChanged,
  });

  @override
  State<SelectableIconButton> createState() => _SelectableIconButtonState();
}

class _SelectableIconButtonState extends State<SelectableIconButton> {
  bool isSelected = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = theme.iconTheme.color;
    final unselectedColor = theme.iconTheme.color ?? Colors.grey;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: widget.selected ? getColor(0) : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        isSelected: widget.selected,
        icon: Icon(
          widget.icon,
          color: widget.selected ? selectedColor : unselectedColor,
          size: widget.size,
        ),
        padding: widget.padding,
        onPressed: () {
          //setState(() => isSelected = !isSelected);
          setState(() {});
          widget.onChanged?.call(!widget.selected);
        },
      ),
    );
  }
}
