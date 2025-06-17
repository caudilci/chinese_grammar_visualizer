import 'package:flutter/material.dart';
import '../models/word_list.dart';

/// A tree view for displaying and navigating hierarchical categories
class CategoryTreeView extends StatefulWidget {
  final List<WordList> wordLists;
  final Function(WordList) onCategorySelected;
  final String? selectedCategoryId;
  final bool enableMultiSelect;
  final Function(List<WordList>)? onMultiSelectionChanged;
  final Function()? onDeleteSelected;

  const CategoryTreeView({
    Key? key,
    required this.wordLists,
    required this.onCategorySelected,
    this.selectedCategoryId,
    this.enableMultiSelect = false,
    this.onMultiSelectionChanged,
    this.onDeleteSelected,
  }) : super(key: key);

  @override
  _CategoryTreeViewState createState() => _CategoryTreeViewState();
}

class _CategoryTreeViewState extends State<CategoryTreeView> {
  static const String _pathSeparator = '/';
  Map<String, bool> _expandedNodes = {};
  Set<String> _selectedListIds = {};
  bool _isInSelectionMode = false;

  @override
  void initState() {
    super.initState();
    // Initially expand the parent of the selected category
    if (widget.selectedCategoryId != null) {
      final selectedList = widget.wordLists.firstWhere(
        (list) => list.id == widget.selectedCategoryId,
        orElse: () => WordList(id: '', name: ''),
      );

      if (selectedList.name.contains(_pathSeparator)) {
        final segments = selectedList.name.split(_pathSeparator);
        for (int i = 1; i < segments.length; i++) {
          final parentPath = segments.sublist(0, i).join(_pathSeparator);
          _expandedNodes[parentPath] = true;
        }
      }
    }
  }

  void _toggleSelection(WordList wordList) {
    setState(() {
      if (_selectedListIds.contains(wordList.id)) {
        _selectedListIds.remove(wordList.id);
      } else {
        _selectedListIds.add(wordList.id);
      }

      if (_selectedListIds.isEmpty) {
        _isInSelectionMode = false;
      }

      if (widget.onMultiSelectionChanged != null) {
        final selectedLists = widget.wordLists.where(
          (list) => _selectedListIds.contains(list.id),
        ).toList();
        widget.onMultiSelectionChanged!(selectedLists);
      }
    });
  }

  void _enterSelectionMode(WordList initialSelection) {
    setState(() {
      _isInSelectionMode = true;
      _selectedListIds.add(initialSelection.id);

      if (widget.onMultiSelectionChanged != null) {
        final selectedLists = widget.wordLists.where(
          (list) => _selectedListIds.contains(list.id),
        ).toList();
        widget.onMultiSelectionChanged!(selectedLists);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isInSelectionMode = false;
      _selectedListIds.clear();

      if (widget.onMultiSelectionChanged != null) {
        widget.onMultiSelectionChanged!([]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Build the tree from word lists
    return Column(
      children: [
        if (_isInSelectionMode && widget.enableMultiSelect)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text(
                  '${_selectedListIds.length} categories selected',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                TextButton(
                  onPressed: _exitSelectionMode,
                  child: const Text('Cancel'),
                ),
                if (widget.onDeleteSelected != null)
                  ElevatedButton.icon(
                    onPressed: widget.onDeleteSelected,
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: _buildTree(context),
        ),
      ],
    );
  }

  Widget _buildTree(BuildContext context) {
    // Group word lists by their path segments
    final Map<String, List<WordList>> categoriesMap = _buildCategoriesMap();

    // Build the tree starting from the root level
    return SingleChildScrollView(
      child: _buildTreeNodes(context, '', categoriesMap, 0),
    );
  }

  Widget _buildTreeNodes(
    BuildContext context,
    String currentPath,
    Map<String, List<WordList>> categoriesMap,
    int level,
  ) {
    final List<Widget> children = [];
    final List<WordList> currentLevelLists = categoriesMap[currentPath] ?? [];

    // Sort lists by name
    currentLevelLists.sort((a, b) => a.name.compareTo(b.name));

    // Add items for this level
    for (final wordList in currentLevelLists) {
      final bool isParent = categoriesMap.containsKey(wordList.name);
      final bool isExpanded = _expandedNodes[wordList.name] ?? false;
      final bool isSelected = wordList.id == widget.selectedCategoryId;

      // Extract just the name for this level (not the full path)
      String displayName = wordList.name;
      if (displayName.contains(_pathSeparator)) {
        final parts = displayName.split(_pathSeparator);
        displayName = parts.last;
      }

      children.add(
        Padding(
          padding: EdgeInsets.only(left: level * 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  if (_isInSelectionMode && widget.enableMultiSelect) {
                    _toggleSelection(wordList);
                  } else {
                    widget.onCategorySelected(wordList);
                  }
                },
                onLongPress: widget.enableMultiSelect && !_isInSelectionMode
                  ? () => _enterSelectionMode(wordList)
                  : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _isInSelectionMode && _selectedListIds.contains(wordList.id)
                        ? Theme.of(context).colorScheme.primaryContainer
                        : isSelected && !_isInSelectionMode
                            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
                            : null,
                  ),
                  child: Row(
                    children: [
                      if (_isInSelectionMode)
                        Checkbox(
                          value: _selectedListIds.contains(wordList.id),
                          onChanged: (_) => _toggleSelection(wordList),
                        )
                      else
                        const SizedBox(width: 24),
                      if (isParent) ...[
                        InkWell(
                          onTap: () {
                            setState(() {
                              _expandedNodes[wordList.name] = !isExpanded;
                            });
                          },
                          child: Icon(
                            isExpanded
                                ? Icons.arrow_drop_down
                                : Icons.arrow_right,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ] else ...[
                        const SizedBox(width: 24),
                      ],
                      Icon(
                        isParent
                            ? Icons.folder
                            : Icons.list,
                        size: 18,
                        color: isSelected && !_isInSelectionMode
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          displayName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isSelected && !_isInSelectionMode ? FontWeight.bold : null,
                            color: isSelected && !_isInSelectionMode
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                        ),
                      ),
                      Text(
                        '(${wordList.entries.length})',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              // If this node is expanded, show its children
              if (isParent && isExpanded)
                _buildTreeNodes(
                  context,
                  wordList.name,
                  categoriesMap,
                  level + 1,
                ),
            ],
          ),
        ),
      );
    }

    return Column(children: children);
  }

  /// Build a map of categories to their direct child word lists
  Map<String, List<WordList>> _buildCategoriesMap() {
    final Map<String, List<WordList>> result = {'': []};

    for (final wordList in widget.wordLists) {
      final String name = wordList.name;

      if (name.contains(_pathSeparator)) {
        // This is a path with separators
        final segments = name.split(_pathSeparator);
        String currentPath = '';

        // Add this list to its parent
        for (int i = 0; i < segments.length - 1; i++) {
          currentPath = i == 0
              ? segments[0]
              : currentPath + _pathSeparator + segments[i];

          if (!result.containsKey(currentPath)) {
            result[currentPath] = [];
          }
        }

        final String parentPath = segments.length > 1
            ? segments.sublist(0, segments.length - 1).join(_pathSeparator)
            : '';

        if (!result.containsKey(parentPath)) {
          result[parentPath] = [];
        }
        result[parentPath]!.add(wordList);
      } else {
        // Top level category
        result['']!.add(wordList);
      }
    }

    return result;
  }
}
