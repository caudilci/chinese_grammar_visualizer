import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/practice_provider.dart';
import '../utils/pinyin_utils.dart';
import '../utils/app_theme.dart';
import '../models/practice_item.dart';

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
            appBar: AppBar(
              title: const Text('Practice'),
              titleTextStyle: AppTheme.appBarTitleStyle(),
            ),
            body: const Center(child: Text('No active practice session.')),
          );
        }

        final session = provider.activeSession!;
        final currentItem = session.currentItem;

        return Scaffold(
          appBar: AppBar(
            title: Text('${currentItem.grammarPattern.name} Practice'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            actions: [
              TextButton.icon(
                icon: Icon(
                  Icons.close,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                label: Text(
                  'End',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '${(session.completionPercentage * 100).toStringAsFixed(0)}% Complete',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: session.completionPercentage,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
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
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Arrange the words in the correct order to form a sentence. Drag words from the word bank below to the empty slots.',
              style: TextStyle(
                fontSize: 16.0,
                color: Theme.of(context).colorScheme.onSurface,
              ),
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
          Text(
            'English Translation:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              item.englishTranslation,
              style: TextStyle(
                fontSize: 16.0,
                color: Theme.of(context).colorScheme.onSurface,
              ),
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
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
                      ? Theme.of(context).colorScheme.surfaceVariant
                      : isSubmitted
                      ? isCorrectPosition
                            ? Theme.of(context).brightness == Brightness.dark
                                  ? Color(0xFF1E392A) // dark green background
                                  : Color(0xFFE6F4EA) // light green background
                            : Theme.of(context).brightness == Brightness.dark
                            ? Color(0xFF3B1D1D) // dark red background
                            : Color(0xFFFBEDED) // light red background
                      : Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: word == null
                        ? Theme.of(context).colorScheme.outline
                        : isSubmitted
                        ? isCorrectPosition
                              ? Theme.of(context).brightness == Brightness.dark
                                    ? Color(0xFF81C995) // dark green border
                                    : Color(0xFF34A853) // light green border
                              : Theme.of(context).brightness == Brightness.dark
                              ? Color(0xFFE07676) // dark red border
                              : Color(0xFFEA4335) // light red border
                        : Theme.of(context).colorScheme.primary,
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
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  PinyinUtils.toDiacriticPinyin(word.pinyin),
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
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
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.2),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Word Bank:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
              color: Theme.of(context).colorScheme.onSurface,
            ),
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
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                  );
                }

                return Draggable<PracticeWordItem>(
                  data: word,
                  feedback: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(4.0),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.shadow.withValues(alpha: 0.2),
                          blurRadius: 2.0,
                          spreadRadius: 0.0,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          word.text,
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          PinyinUtils.toDiacriticPinyin(word.pinyin),
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  childWhenDragging: Container(
                    width: 80,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  child: Container(
                    width: 80,
                    height: 60,
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            word.text,
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            PinyinUtils.toDiacriticPinyin(word.pinyin),
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Theme.of(context).colorScheme.primary,
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
                color: isCorrect
                    ? Theme.of(context).brightness == Brightness.dark
                          ? Color(0xFF1E392A) // dark green background
                          : Color(0xFFE6F4EA) // light green background
                    : Theme.of(context).brightness == Brightness.dark
                    ? Color(0xFF3B1D1D) // dark red background
                    : Color(0xFFFBEDED), // light red background
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: isCorrect
                      ? Theme.of(context).brightness == Brightness.dark
                            ? Color(0xFF81C995) // dark green border
                            : Color(0xFF34A853) // light green border
                      : Theme.of(context).brightness == Brightness.dark
                      ? Color(0xFFE07676) // dark red border
                      : Color(0xFFEA4335), // light red border
                  width: 2.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: isCorrect
                        ? Theme.of(context).brightness == Brightness.dark
                              ? Color(0xFF81C995) // dark green icon
                              : Color(0xFF34A853) // light green icon
                        : Theme.of(context).brightness == Brightness.dark
                        ? Color(0xFFE07676) // dark red icon
                        : Color(0xFFEA4335), // light red icon
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isCorrect
                          ? 'Correct! Great job!'
                          : 'Not quite right. Try again or check the solution.',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: isCorrect
                            ? Theme.of(context).brightness == Brightness.dark
                                  ? Color(0xFF81C995) // dark green text
                                  : Color(
                                      0xFF0D652D,
                                    ) // light green text (darker for readability)
                            : Theme.of(context).brightness == Brightness.dark
                            ? Color(0xFFE07676) // dark red text
                            : Color(
                                0xFFC5221F,
                              ), // light red text (darker for readability)
                        fontWeight: FontWeight.bold,
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
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                    ),
                    child: Text(
                      'Check Answer',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: () => provider.retryCurrentItem(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                    ),
                    child: Text(
                      'Try Again',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),

                const SizedBox(width: 8),

                if (isSubmitted && !isCorrect)
                  ElevatedButton(
                    onPressed: () => provider.showSolution(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                    ),
                    child: Text(
                      'Show Solution',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondary,
                      ),
                    ),
                  ),

                if (isSubmitted && isCorrect)
                  ElevatedButton(
                    onPressed: () => provider.moveToNextItem(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onSecondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                    ),
                    child: Text(
                      'Next',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondary,
                      ),
                    ),
                  ),

                const SizedBox(width: 16),

                // Navigation buttons
                if (provider.activeSession!.currentItemIndex > 0)
                  TextButton.icon(
                    icon: Icon(
                      Icons.arrow_back,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    label: Text(
                      'Previous',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    onPressed: () => provider.moveToPreviousItem(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    ),
                  ),

                if (provider.activeSession!.currentItemIndex <
                    provider.activeSession!.items.length - 1)
                  TextButton.icon(
                    icon: Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    label: Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
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
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showInstructions = true;
                });
              },
              icon: Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              label: Text(
                'Show Instructions',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
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
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'End Practice Session?',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          content: Text(
            'Are you sure you want to end this practice session? Your progress will not be saved.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text(
                'End Session',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
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
