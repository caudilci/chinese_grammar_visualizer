import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word_list.dart';
import '../providers/flash_card_provider.dart';
import '../providers/word_list_provider.dart';
import '../utils/app_theme.dart';
import 'flash_card_review_screen.dart';
import 'flash_card_setup_screen.dart';
import 'word_list_detail_screen.dart';

class WordListsScreen extends StatefulWidget {
  const WordListsScreen({Key? key}) : super(key: key);

  @override
  State<WordListsScreen> createState() => _WordListsScreenState();
}

class _WordListsScreenState extends State<WordListsScreen> {
  final TextEditingController _newListController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WordListProvider>(context, listen: false).initialize();
      Provider.of<FlashCardProvider>(context, listen: false).initialize();
    });
  }

  @override
  void dispose() {
    _newListController.dispose();
    super.dispose();
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
            onPressed: () {
              final name = _newListController.text.trim();
              if (name.isNotEmpty) {
                Provider.of<WordListProvider>(
                  context,
                  listen: false,
                ).createWordList(name);
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

  void _showRenameListDialog(WordList wordList) {
    final TextEditingController controller = TextEditingController(
      text: wordList.name,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Word List'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'New Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty && name != wordList.name) {
                Provider.of<WordListProvider>(
                  context,
                  listen: false,
                ).renameWordList(wordList.id, name);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('RENAME'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(WordList wordList) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Word List'),
        content: Text(
          'Are you sure you want to delete "${wordList.name}"? '
          'This will remove the list but not the dictionary entries themselves.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Provider.of<WordListProvider>(
                context,
                listen: false,
              ).deleteWordList(wordList.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _showWordListDetails(WordList wordList) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WordListDetailScreen(wordList: wordList),
      ),
    );
  }

  // Continue an ongoing flash card session
  void _continueSession() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const FlashCardReviewScreen()),
    );
  }

  // Start a new session with a confirmation if needed
  void _startNewSession() async {
    final flashCardProvider = Provider.of<FlashCardProvider>(
      context,
      listen: false,
    );

    // Check if there's already an active session
    if (flashCardProvider.isSessionActive) {
      bool shouldContinue = await _showSessionOverwriteConfirmation();
      if (!shouldContinue) {
        return; // User canceled, do not start a new session
      }

      // End the current session before starting a new one
      flashCardProvider.endSession();
    }

    // Navigate to flash card setup screen
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const FlashCardSetupScreen()),
    );
  }

  // Show confirmation dialog when trying to start a new session while one is ongoing
  Future<bool> _showSessionOverwriteConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Session Already in Progress'),
            content: const Text(
              'You have an active flash card session. Starting a new session will end the current one.\n\n'
              'Do you want to continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false), // Cancel
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true), // Proceed
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('END CURRENT & START NEW'),
              ),
            ],
          ),
        ) ??
        false; // Default to false if dialog is dismissed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Lists'),
        titleTextStyle: AppTheme.appBarTitleStyle(),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create new list',
            onPressed: _showCreateListDialog,
          ),
        ],
      ),
      body: Consumer2<WordListProvider, FlashCardProvider>(
        builder: (context, wordListProvider, flashCardProvider, child) {
          if (wordListProvider.isLoading || flashCardProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Check if there's an active session to continue
          final hasActiveSession = flashCardProvider.isSessionActive;

          if (wordListProvider.wordLists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasActiveSession) ...[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Color(0xFF313244) // Dark mode surface variant
                            : Colors.green.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.play_circle_filled,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Active Session Available',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.green[300]
                                          : Colors.green.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _continueSession,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  elevation:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? 4
                                      : 1,
                                ),
                                child: const Text('Continue Session'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  const Text('No word lists found. Create your first list!'),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Show continue session banner if there's an active session
              if (hasActiveSession)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Color(0xFF313244) // Dark mode surface variant
                        : Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.play_circle_filled,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Active Flash Card Session',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.green[300]
                                      : Colors.green.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You have an unfinished flash card session. Would you like to continue where you left off?',
                            style: TextStyle(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[300]
                                  : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _continueSession,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Continue Session'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _startNewSession,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Color(
                                          0xFFF5A97F,
                                        ) // Catppuccin macchiato peach
                                      : Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('New Session'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Word lists
              Expanded(
                child: ListView.builder(
                  itemCount: wordListProvider.wordLists.length,
                  itemBuilder: (context, index) {
                    final wordList = wordListProvider.wordLists[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(
                          wordList.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${wordList.entries.length} words'),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            wordList.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        trailing: wordList.id == 'uncategorized'
                            ? null
                            : PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'rename',
                                    child: Text('Rename'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'rename') {
                                    _showRenameListDialog(wordList);
                                  } else if (value == 'delete') {
                                    _showDeleteConfirmation(wordList);
                                  }
                                },
                              ),
                        onTap: () => _showWordListDetails(wordList),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<FlashCardProvider>(
        builder: (context, flashCardProvider, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!flashCardProvider.isSessionActive)
                FloatingActionButton(
                  heroTag: 'startFlashCardsFAB',
                  onPressed: _startNewSession,
                  tooltip: 'Start flash cards',
                  backgroundColor: Colors.orange,
                  mini: true,
                  child: const Icon(Icons.school),
                ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'createListFAB',
                onPressed: _showCreateListDialog,
                tooltip: 'Create new list',
                child: const Icon(Icons.add),
              ),
            ],
          );
        },
      ),
    );
  }
}

// WordListDetailScreen has been moved to a separate file
