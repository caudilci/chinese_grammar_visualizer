import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/practice_item.dart';
import '../providers/practice_provider.dart';
import '../utils/app_theme.dart';
import '../utils/pinyin_utils.dart';

class PracticeScreen extends StatefulWidget {
  final String grammarPatternId;

  const PracticeScreen({Key? key, required this.grammarPatternId})
    : super(key: key);

  @override
  _PracticeScreenState createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  bool _showInstructions = true;

  @override
  void initState() {
    super.initState();
    // Initialize practice session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PracticeProvider>(
        context,
        listen: false,
      ).startPracticeForGrammarPattern(widget.grammarPatternId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PracticeProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!provider.hasActiveSession) {
          return Scaffold(
            appBar: AppBar(title: const Text('Practice')),
            body: const Center(child: Text('No active practice session.')),
          );
        }

        final session = provider.activeSession!;
        final currentItem = session.currentItem;

        return Scaffold(
          appBar: AppBar(
            title: Text('${currentItem.grammarPattern.name} Practice'),
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.close, color: Colors.white),
                label: const Text('End', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  _showEndSessionDialog(context, provider);
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                _buildProgressIndicator(session),
                if (_showInstructions) _buildInstructions(),
                _buildEnglishTranslation(currentItem),
                Expanded(child: _buildSentenceArea(provider)),
                _buildActionButtons(provider),
                _buildWordBank(provider),
              ],
            ),
          ),
        );
      },
    );
  }

  // New method to wrap the slot area in a scrollable container
  Widget _buildSentenceArea(PracticeProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Center(
        child: SingleChildScrollView(child: _buildSlotArea(provider)),
      ),
    );
  }

  Widget _buildProgressIndicator(PracticeSession session) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Item ${session.currentItemIndex + 1} of ${session.items.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${(session.completionPercentage * 100).toStringAsFixed(0)}% Complete',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: session.completionPercentage,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: const Text(
              'Arrange the words in the correct order to form a sentence. Drag words from the word bank below to the empty slots.',
              style: TextStyle(fontSize: 16.0),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {
              setState(() {
                _showInstructions = false;
              });
            },
            tooltip: 'Hide instructions',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildEnglishTranslation(PracticeItem item) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'English Translation:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              item.englishTranslation,
              style: const TextStyle(fontSize: 16.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotArea(PracticeProvider provider) {
    final currentArrangement = provider.currentArrangement;
    final isSubmitted = provider.isSubmitted;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 12.0,
        alignment: WrapAlignment.center,
        children: List.generate(currentArrangement.length, (index) {
          // Check if this slot has a word
          final word = currentArrangement[index];
          final bool isCorrectPosition = provider.isSlotCorrect(index);

          return DragTarget<PracticeWordItem>(
            builder: (context, candidateData, rejectedData) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: word == null
                      ? Colors.grey[100]
                      : isSubmitted
                      ? isCorrectPosition
                            ? Colors.green[50]
                            : Colors.red[50]
                      : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: word == null
                        ? Colors.grey[300]!
                        : isSubmitted
                        ? isCorrectPosition
                              ? Colors.green
                              : Colors.red
                        : Colors.blue,
                    width: 2.0,
                  ),
                ),
                child: word == null
                    ? const Center(child: Icon(Icons.add, color: Colors.grey))
                    : Stack(
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  word.text,
                                  style: const TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  PinyinUtils.toDiacriticPinyin(word.pinyin),
                                  style: const TextStyle(
                                    fontSize: 12.0,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isSubmitted)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: InkWell(
                                onTap: () => provider.removeWordFromSlot(index),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              );
            },
            onAccept: (draggedWord) {
              // Only allow dropping if not submitted
              if (!provider.isSubmitted) {
                provider.placeWordInSlot(draggedWord, index);
              }
            },
          );
        }),
      ),
    );
  }

  Widget _buildWordBank(PracticeProvider provider) {
    final shuffledWords = provider.shuffledWords;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Word Bank:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(
              spacing: 8.0,
              runSpacing: 12.0,
              children: shuffledWords.map((word) {
                if (word.isPlaced) {
                  // Show a placeholder for placed words
                  return Container(
                    width: 80,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                  );
                }

                return Draggable<PracticeWordItem>(
                  data: word,
                  feedback: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          word.text,
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          PinyinUtils.toDiacriticPinyin(word.pinyin),
                          style: const TextStyle(
                            fontSize: 12.0,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  childWhenDragging: Container(
                    width: 80,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                  ),
                  child: Container(
                    width: 80,
                    height: 60,
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            word.text,
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            PinyinUtils.toDiacriticPinyin(word.pinyin),
                            style: const TextStyle(
                              fontSize: 10.0,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(PracticeProvider provider) {
    final isSubmitted = provider.isSubmitted;
    final isCorrect = provider.isCorrect;
    final canSubmit = provider.areAllSlotsFilled && !isSubmitted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          // Result message
          if (isSubmitted)
            Container(
              padding: const EdgeInsets.all(12.0),
              margin: const EdgeInsets.only(bottom: 16.0),
              decoration: BoxDecoration(
                color: isCorrect ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: isCorrect ? Colors.green : Colors.red,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: isCorrect ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isCorrect
                          ? 'Correct! Great job!'
                          : 'Not quite right. Try again or check the solution.',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: isCorrect ? Colors.green[800] : Colors.red[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Main action buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isSubmitted)
                  ElevatedButton(
                    onPressed: canSubmit
                        ? () => provider.submitArrangement()
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                    ),
                    child: const Text('Check Answer'),
                  )
                else
                  ElevatedButton(
                    onPressed: () => provider.retryCurrentItem(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                    ),
                    child: const Text('Try Again'),
                  ),

                const SizedBox(width: 8),

                if (isSubmitted && !isCorrect)
                  ElevatedButton(
                    onPressed: () => provider.showSolution(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                    ),
                    child: const Text('Show Solution'),
                  ),

                if (isSubmitted && isCorrect)
                  ElevatedButton(
                    onPressed: () => provider.moveToNextItem(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                    ),
                    child: const Text('Next'),
                  ),

                const SizedBox(width: 16),

                // Navigation buttons
                if (provider.activeSession!.currentItemIndex > 0)
                  TextButton.icon(
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text(
                      'Previous',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: () => provider.moveToPreviousItem(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    ),
                  ),

                if (provider.activeSession!.currentItemIndex <
                    provider.activeSession!.items.length - 1)
                  TextButton.icon(
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('Skip', style: TextStyle(fontSize: 12)),
                    onPressed: () => provider.moveToNextItem(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    ),
                  ),
              ],
            ),
          ),

          // If instructions are hidden, show a button to display them again
          if (!_showInstructions)
            TextButton(
              onPressed: () {
                setState(() {
                  _showInstructions = true;
                });
              },
              child: const Text('Show Instructions'),
            ),
        ],
      ),
    );
  }

  Future<void> _showEndSessionDialog(
    BuildContext context,
    PracticeProvider provider,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('End Practice Session?'),
          content: const Text(
            'Are you sure you want to end this practice session? Your progress will not be saved.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('End Session'),
              onPressed: () {
                provider.endPracticeSession();
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
