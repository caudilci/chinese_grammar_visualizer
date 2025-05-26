import 'package:flutter/material.dart';
import '../models/grammar_pattern.dart';
import '../utils/app_theme.dart';

class PatternCard extends StatelessWidget {
  final GrammarPattern pattern;
  final VoidCallback onTap;

  const PatternCard({
    super.key,
    required this.pattern,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
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
                style: AppTheme.chineseTextStyle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 4),
              Text(
                pattern.englishTitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                pattern.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: AppTheme.primaryColor,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const Icon(
                    Icons.arrow_forward,
                    color: AppTheme.primaryColor,
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < level ? Icons.star : Icons.star_border,
          color: index < level
              ? AppTheme.getDifficultyColor(level)
              : AppTheme.textLight,
          size: 16,
        );
      }),
    );
  }

  Widget _buildStructurePreview(String structure) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.textLight.withOpacity(0.3),
        ),
      ),
      child: Text(
        structure,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppTheme.primaryColor,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}