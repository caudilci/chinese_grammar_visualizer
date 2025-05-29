import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/grammar_pattern.dart';
import '../providers/grammar_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/grammar_visualizer.dart';
import '../widgets/sentence_breakdown.dart';
import 'practice_screen.dart';

class PatternDetailScreen extends StatefulWidget {
  final String patternId;

  const PatternDetailScreen({
    super.key,
    required this.patternId,
  });

  @override
  State<PatternDetailScreen> createState() => _PatternDetailScreenState();
}

class _PatternDetailScreenState extends State<PatternDetailScreen> {
  int _currentExampleIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<GrammarProvider>(context, listen: false);
      provider.selectPattern(widget.patternId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grammar Pattern'),
        centerTitle: true,
        actions: [
          Consumer<GrammarProvider>(
            builder: (context, provider, child) {
              if (provider.selectedPattern != null) {
                return TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PracticeScreen(
                          grammarPatternId: provider.selectedPattern!.id,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.fitness_center, color: Colors.white),
                  label: const Text(
                    'Practice',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        ],
      ),
      body: Consumer<GrammarProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final pattern = provider.selectedPattern;
          if (pattern == null) {
            return const Center(
              child: Text('Pattern not found'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(pattern),
                const SizedBox(height: 24),
                _buildDescription(pattern),
                const SizedBox(height: 24),
                _buildStructure(pattern),
                const SizedBox(height: 24),
                _buildExamples(pattern),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(GrammarPattern pattern) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                pattern.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            _buildDifficultyIndicator(pattern.difficultyLevel),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          pattern.chineseTitle,
          style: AppTheme.chineseTextStyle.copyWith(fontSize: 28),
        ),
        const SizedBox(height: 4),
        Text(
          pattern.englishTitle,
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        Chip(
          label: Text(
            pattern.category,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildDifficultyIndicator(int level) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < level ? Icons.star : Icons.star_border,
          color: index < level
              ? AppTheme.getDifficultyColor(level)
              : AppTheme.textLight,
          size: 20,
        );
      }),
    );
  }

  Widget _buildDescription(GrammarPattern pattern) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          pattern.description,
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.textPrimary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStructure(GrammarPattern pattern) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Structure',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        GrammarVisualizer(
          structure: pattern.structure,
          structureBreakdown: pattern.structureBreakdown,
        ),
      ],
    );
  }

  Widget _buildExamples(GrammarPattern pattern) {
    if (pattern.examples.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentExample = pattern.examples[_currentExampleIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Examples',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentExample.chineseSentence,
                style: AppTheme.chineseTextStyle,
              ),
              const SizedBox(height: 8),
              Text(
                currentExample.pinyinSentence,
                style: AppTheme.pinyinTextStyle,
              ),
              const SizedBox(height: 8),
              Text(
                currentExample.englishTranslation,
                style: AppTheme.translationTextStyle,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Sentence Breakdown',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              SentenceBreakdown(
                parts: currentExample.breakdownParts,
                colorCoding: pattern.colorCoding,
              ),
              if (currentExample.note != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.amber,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          currentExample.note!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (pattern.examples.length > 1) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: _currentExampleIndex > 0
                    ? () {
                        setState(() {
                          _currentExampleIndex--;
                        });
                      }
                    : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
              ),
              const SizedBox(width: 16),
              Text(
                '${_currentExampleIndex + 1} / ${pattern.examples.length}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: _currentExampleIndex < pattern.examples.length - 1
                    ? () {
                        setState(() {
                          _currentExampleIndex++;
                        });
                      }
                    : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}