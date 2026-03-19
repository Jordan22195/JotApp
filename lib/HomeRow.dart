enum HomeRowType { header, note, divider, toggle }

/// For checklist categories only
enum ChecklistRegion { normal, unchecked, checked }

class HomeRow {
  final HomeRowType type;
  final String key;

  // Context
  final String? categoryId; // null/'' means Inbox/Uncategorized
  final String? noteId;

  // Only meaningful for HomeRowType.note (and checklist categories)
  final ChecklistRegion region;

  const HomeRow._({
    required this.type,
    required this.key,
    this.categoryId,
    this.noteId,
    this.region = ChecklistRegion.normal,
  });

  factory HomeRow.header(String? categoryId) => HomeRow._(
    type: HomeRowType.header,
    key: 'header:${categoryId ?? "__inbox__"}',
    categoryId: categoryId,
  );

  factory HomeRow.note({
    required String noteId,
    required String? categoryId,
    required ChecklistRegion region,
  }) => HomeRow._(
    type: HomeRowType.note,
    key: 'note:$noteId',
    noteId: noteId,
    categoryId: categoryId,
    region: region,
  );

  factory HomeRow.divider(String categoryId) => HomeRow._(
    type: HomeRowType.divider,
    key: 'divider:$categoryId',
    categoryId: categoryId,
  );

  factory HomeRow.toggle(String categoryId) => HomeRow._(
    type: HomeRowType.toggle,
    key: 'toggle:$categoryId',
    categoryId: categoryId,
  );

  bool get isDraggableNote => type == HomeRowType.note && noteId != null;
}
