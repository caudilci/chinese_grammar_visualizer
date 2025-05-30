import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dictionary_entry.dart';
import '../providers/word_list_provider.dart';

class WordListSelector extends StatefulWidget {
  final DictionaryEntry entry;
  final VoidCallback? onSaved;

  const WordListSelector({
    Key? key,
    required this.entry,
    this.onSaved,
  }) : super(key: key);

  @override
  State<WordListSelector> createState() => _WordListSelectorState();
}

class _WordListSelectorState extends State<WordListSelector> {
  final TextEditingController _newListController = TextEditingController();
  Set<String> _selectedLists = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSelectedLists();
    });
  }

  @override
  void dispose() {
    _newListController.dispose();
    super.dispose();
  }

  void _initializeSelectedLists() {
    final provider = Provider.of<WordListProvider>(context, listen: false);
    
    // Find which lists already contain this entry
    final containingLists = provider.getListsContainingEntry(widget.entry);
    setState(() {
      _selectedLists = containingLists.map((list) => list.id).toSet();
    });
  }

  void _saveChanges() async {
    final provider = Provider.of<WordListProvider>(context, listen: false);
    final allLists = provider.wordLists;
    
    // Handle each list
    for (final list in allLists) {
      final isSelected = _selectedLists.contains(list.id);
      final isCurrentlyInList = list.containsEntry(widget.entry);
      
      if (isSelected && !isCurrentlyInList) {
        // Add to list
        await provider.addEntryToList(list.id, widget.entry);
      } else if (!isSelected && isCurrentlyInList) {
        // Remove from list
        await provider.removeEntryFromList(list.id, widget.entry);
      }
    }
    
    if (widget.onSaved != null) {
      widget.onSaved!();
    }
    
    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Word lists updated'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showCreateListDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Word List'),
        content: TextField(
          controller: _newListController,
          decoration: const InputDecoration(
            labelText: 'List Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _newListController.clear();
            },
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              final name = _newListController.text.trim();
              if (name.isNotEmpty) {
                final provider = Provider.of<WordListProvider>(context, listen: false);
                final newList = await provider.createWordList(name);
                
                // Automatically select the new list
                setState(() {
                  _selectedLists.add(newList.id);
                });
                
                Navigator.of(ctx).pop();
                _newListController.clear();
              }
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WordListProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add to Word Lists',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('NEW LIST'),
                    onPressed: _showCreateListDialog,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            provider.isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : provider.wordLists.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No word lists available'),
                        ),
                      )
                    : Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: provider.wordLists.length,
                          itemBuilder: (context, index) {
                            final wordList = provider.wordLists[index];
                            return CheckboxListTile(
                              title: Text(wordList.name),
                              subtitle: Text('${wordList.entries.length} words'),
                              value: _selectedLists.contains(wordList.id),
                              onChanged: (isChecked) {
                                setState(() {
                                  if (isChecked == true) {
                                    _selectedLists.add(wordList.id);
                                  } else {
                                    _selectedLists.remove(wordList.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('CANCEL'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      _saveChanges();
                      Navigator.of(context).pop();
                    },
                    child: const Text('SAVE'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}