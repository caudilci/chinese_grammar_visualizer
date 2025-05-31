import 'package:flutter/material.dart';
import '../models/grammar_pattern.dart';
import '../utils/app_theme.dart';
import '../screens/practice_screen.dart';
import '../utils/catppuccin_theme.dart';

class PatternCard extends StatelessWidget {
  final GrammarPattern pattern;
  final VoidCallback onTap;
  final bool showPracticeButton;

  const PatternCard({
    super.key,
    required this.pattern,
    required this.onTap,
    this.showPracticeButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      pattern.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildDifficultyIndicator(pattern.difficultyLevel),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                pattern.chineseTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                pattern.englishTitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                pattern.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              _buildStructurePreview(pattern.structure),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text(
                      pattern.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  Row(
                    children: [
                      if (showPracticeButton && pattern.examples.isNotEmpty)
                        IconButton(
                          icon: Icon(
                            Icons.fitness_center,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          tooltip: 'Practice this pattern',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PracticeScreen(
                                  grammarPatternId: pattern.id,
                                ),
                              ),
                            );
                          },
                        ),
                      Icon(
                        Icons.arrow_forward,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyIndicator(int level) {
    return Builder(
      builder: (context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          return Icon(
            index < level ? Icons.star : Icons.star_border,
            color: index < level
                ? Theme.of(context).brightness == Brightness.dark
                      ? CatppuccinTheme.mochaPeach
                      : AppTheme.getDifficultyColor(level)
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.3),
            size: 16,
          );
        }),
      ),
    );
  }

  Widget _buildStructurePreview(String structure) {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.surfaceContainer
              : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          structure,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.primary,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
