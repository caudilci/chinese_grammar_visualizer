import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flash_card_provider.dart';
import '../providers/word_list_provider.dart';
import 'flash_card_review_screen.dart';

class FlashCardSetupScreen extends StatefulWidget {
  const FlashCardSetupScreen({Key? key}) : super(key: key);

  @override
  State<FlashCardSetupScreen> createState() => _FlashCardSetupScreenState();
}

class _FlashCardSetupScreenState extends State<FlashCardSetupScreen> {
  final List<String> _selectedListIds = [];
  int _numberOfCards = 10;
  bool _isEndless = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize providers
      Provider.of<WordListProvider>(context, listen: false).initialize();
      Provider.of<FlashCardProvider>(context, listen: false).initialize();
    });
  }

  void _toggleListSelection(String listId) {
    setState(() {
      if (_selectedListIds.contains(listId)) {
        _selectedListIds.remove(listId);
      } else {
        _selectedListIds.add(listId);
      }
    });
  }

  void _startSession() async {
    if (_selectedListIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one word list'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final flashCardProvider = Provider.of<FlashCardProvider>(
      context,
      listen: false,
    );

    // Check if there's already an active session
    if (flashCardProvider.isSessionActive) {
      // Show confirmation dialog
      bool shouldContinue = await _showSessionOverwriteConfirmation();
      if (!shouldContinue) {
        return; // User canceled, do not start a new session
      }

      // End the current session before starting a new one
      flashCardProvider.endSession();
    }

    setState(() {
      _isLoading = true;
    });

    final success = await flashCardProvider.startSession(
      wordListIds: _selectedListIds,
      numberOfCards: _numberOfCards,
      isEndless: _isEndless,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const FlashCardReviewScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to start session. Make sure the selected lists contain words.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
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

  // Add method to continue an ongoing session
  void _continueSession() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const FlashCardReviewScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Flash Cards',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer2<WordListProvider, FlashCardProvider>(
        builder: (context, wordListProvider, flashCardProvider, child) {
          if (wordListProvider.isLoading ||
              flashCardProvider.isLoading ||
              _isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Check if there's an active session to continue
          final hasActiveSession = flashCardProvider.isSessionActive;

          final wordLists = wordListProvider.wordLists;

          if (wordLists.isEmpty) {
            return const Center(
              child: Text(
                'No word lists found. Create some lists in the Word Lists section.',
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display continue session button if there's an active session
                if (hasActiveSession) ...[
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.play_circle_filled,
                                color: Colors.green,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Active Session Available',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You have an unfinished flash card session. Would you like to continue where you left off?',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _continueSession,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Continue Session',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                ],

                const Text(
                  'Select Word Lists',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose one or more lists to study:',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: wordLists.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final wordList = wordLists[index];
                      final stats = flashCardProvider.getStatsForWordList(
                        wordList.id,
                      );
                      final isSelected = _selectedListIds.contains(wordList.id);

                      return CheckboxListTile(
                        title: Text(
                          wordList.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${wordList.entries.length} words · ${stats['dueCards']} due for review',
                        ),
                        secondary: CircleAvatar(
                          backgroundColor: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade300,
                          child: Text(
                            wordList.name.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                        value: isSelected,
                        onChanged: (value) {
                          _toggleListSelection(wordList.id);
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'Study Options',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Number of cards
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Number of Cards',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  'Endless Mode',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Switch(
                                  value: _isEndless,
                                  onChanged: (value) {
                                    setState(() {
                                      _isEndless = value;
                                    });
                                  },
                                  activeColor: Theme.of(context).primaryColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          _isEndless ? 'Endless Mode' : '$_numberOfCards cards',
                          style: TextStyle(
                            color: _isEndless
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade700,
                            fontWeight: _isEndless
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        if (!_isEndless) ...[
                          const SizedBox(height: 8),
                          Slider(
                            value: _numberOfCards.toDouble(),
                            min: 5,
                            max: 50,
                            divisions: 9,
                            label: _numberOfCards.toString(),
                            onChanged: (value) {
                              setState(() {
                                _numberOfCards = value.round();
                              });
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [Text('5'), Text('50')],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                // Study statistics
                if (_selectedListIds.isNotEmpty) ...[
                  _buildSessionSummary(flashCardProvider),
                  const SizedBox(height: 24),
                ],

                // Start button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    // Always disable button when no lists selected, regardless of active session
                    onPressed: _selectedListIds.isEmpty ? null : _startSession,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: hasActiveSession
                          ? Colors
                                .orange // Use a different color if there's already an active session
                          : Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      // Ensure disabled style is consistent and readable
                      disabledForegroundColor:
                          Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[300]
                          : Colors.white.withValues(alpha: 0.7),
                      disabledBackgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade800
                          : Colors.grey.shade400,
                    ),
                    child: Text(
                      _selectedListIds.isEmpty
                          ? 'Select at least one list'
                          : hasActiveSession
                          ? 'Start New Session'
                          : 'Start Studying',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionSummary(FlashCardProvider flashCardProvider) {
    int totalCards = 0;
    int dueCards = 0;
    int masteredCards = 0;
    int learningCards = 0;
    int difficultCards = 0;

    for (final listId in _selectedListIds) {
      final stats = flashCardProvider.getStatsForWordList(listId);
      totalCards += stats['totalCards'] as int;
      dueCards += stats['dueCards'] as int;
      masteredCards += stats['masterLevel'] as int;
      learningCards += stats['learningLevel'] as int;
      difficultCards += stats['difficultLevel'] as int;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Session Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    label: 'Total Words',
                    value: totalCards.toString(),
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    label: 'Due for Review',
                    value: dueCards.toString(),
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    label: 'Difficult',
                    value: difficultCards.toString(),
                    color: Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    label: 'Learning',
                    value: learningCards.toString(),
                    color: Colors.amber,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    label: 'Mastered',
                    value: masteredCards.toString(),
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
