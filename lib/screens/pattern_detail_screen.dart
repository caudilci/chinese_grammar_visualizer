import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/grammar_pattern.dart';
import '../providers/grammar_provider.dart';
import '../utils/app_theme.dart';
import '../utils/catppuccin_theme.dart';
import '../widgets/grammar_visualizer.dart';
import '../widgets/sentence_breakdown.dart';
import 'practice_screen.dart';

class PatternDetailScreen extends StatefulWidget {
  final String patternId;

  const PatternDetailScreen({super.key, required this.patternId});

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
        titleTextStyle: AppTheme.appBarTitleStyle(),
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
                  icon: Icon(
                    Icons.fitness_center,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  label: Text(
                    'Practice',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
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
            return const Center(child: CircularProgressIndicator());
          }

          final pattern = provider.selectedPattern;
          if (pattern == null) {
            return const Center(child: Text('Pattern not found'));
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
                style: AppTheme.headingLarge(
                  context,
                  weight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            _buildDifficultyIndicator(pattern.difficultyLevel),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          pattern.chineseTitle,
          style: AppTheme.headingXLarge(
            context,
            weight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ).copyWith(height: 1.5),
        ),
        const SizedBox(height: 4),
        Text(
          pattern.englishTitle,
          style: AppTheme.bodyDefault(
            context,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ).copyWith(fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 8),
        Chip(
          label: Text(
            pattern.category,
            style: AppTheme.bodySmall(
              context,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
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
              ? Theme.of(context).brightness == Brightness.dark
                    ? CatppuccinTheme.mochaPeach
                    : AppTheme.getDifficultyColor(level)
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          size: 20,
        );
      }),
    );
  }

  Widget _buildDescription(GrammarPattern pattern) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: AppTheme.bodyLarge(
            context,
            weight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          pattern.description,
          style: AppTheme.bodyDefault(
            context,
            color: Theme.of(context).colorScheme.onSurface,
          ).copyWith(height: 1.5),
        ),
      ],
    );
  }

  Widget _buildStructure(GrammarPattern pattern) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Structure',
          style: AppTheme.bodyLarge(
            context,
            weight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
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
        Text(
          'Examples',
          style: AppTheme.bodyLarge(
            context,
            weight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.surfaceContainer
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.1),
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
                style: AppTheme.headingLarge(
                  context,
                  weight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ).copyWith(height: 1.5),
              ),
              const SizedBox(height: 8),
              Text(
                currentExample.pinyinSentence,
                style: AppTheme.bodyDefault(
                  context,
                  weight: FontWeight.normal,
                  color: Theme.of(context).colorScheme.primary,
                ).copyWith(height: 1.2),
              ),
              const SizedBox(height: 8),
              Text(
                currentExample.englishTranslation,
                style: AppTheme.bodyDefault(
                  context,
                  weight: FontWeight.normal,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ).copyWith(fontStyle: FontStyle.italic, height: 1.2),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Sentence Breakdown',
                style: AppTheme.bodyDefault(
                  context,
                  weight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
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
                    color: Theme.of(context).brightness == Brightness.dark
                        ? CatppuccinTheme.mochaYellow.withValues(alpha: 0.2)
                        : Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? CatppuccinTheme.mochaYellow
                          : Colors.amber,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? CatppuccinTheme.mochaYellow
                            : Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          currentExample.note!,
                          style: AppTheme.bodySmall(
                            context,
                            color: Theme.of(context).colorScheme.onSurface,
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
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
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
