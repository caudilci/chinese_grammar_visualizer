import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dictionary_entry.dart';
import '../providers/dictionary_provider.dart';
import '../providers/language_provider.dart';
import '../services/search_isolate.dart';
import '../utils/pinyin_utils.dart';
import '../utils/app_theme.dart';

class DictionarySearchResult extends StatelessWidget {
  final DictionaryEntry entry;
  final VoidCallback onTap;

  const DictionarySearchResult({
    Key? key,
    required this.entry,
    required this.onTap,
  }) : super(key: key);

  // Helper method to highlight the matched terms
  Widget _highlightText(
    String text,
    String query,
    TextStyle style,
    BuildContext context,
  ) {
    if (query.isEmpty) return Text(text, style: style);

    final String normalizedQuery = query.toLowerCase();
    final String normalizedText = text.toLowerCase();

    if (!normalizedText.contains(normalizedQuery)) {
      return Text(text, style: style);
    }

    final int startIndex = normalizedText.indexOf(normalizedQuery);
    final int endIndex = startIndex + normalizedQuery.length;

    // Safety check to ensure we don't go out of bounds
    if (startIndex < 0 || endIndex > text.length) {
      return Text(text, style: style);
    }

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: text.substring(0, startIndex), style: style),
          TextSpan(
            text: text.substring(startIndex, endIndex),
            style: style.copyWith(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.2),
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: text.substring(endIndex), style: style),
        ],
      ),
    );
  }

  // Simplified helper for highlighting pinyin matches
  Widget _buildPinyinHighlight(
    String originalPinyin,
    String query,
    BuildContext context,
  ) {
    // If no query or not a valid pinyin query, just show formatted pinyin
    if (query.isEmpty || !PinyinUtils.isPotentialPinyin(query)) {
      return Text(
        PinyinUtils.toDiacriticPinyin(originalPinyin),
        style: TextStyle(
          fontSize: 16.0,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    final formattedPinyin = PinyinUtils.toDiacriticPinyin(originalPinyin);
    final baseStyle = TextStyle(
      fontSize: 16.0,
      color: Theme.of(context).colorScheme.primary,
    );

    // Check if we need to use plain pinyin (without tones) for matching
    final bool hasTones =
        PinyinUtils.containsToneMarks(query) ||
        PinyinUtils.containsToneNumbers(query);

    if (!hasTones) {
      // For searches without tones, highlight the whole string
      // (we can't easily align the matches with tones visually)
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Text(formattedPinyin, style: baseStyle),
      );
    }

    // For searches with tones, try to highlight the exact match
    final queryLower = query.toLowerCase();
    final originalLower = originalPinyin.toLowerCase();

    if (originalLower.contains(queryLower)) {
      final int startIndex = originalLower.indexOf(queryLower);
      final int endIndex = startIndex + queryLower.length;

      // Safety check to ensure we don't go out of bounds
      if (startIndex < 0 || endIndex > formattedPinyin.length) {
        // Fallback to regular display
        return Text(formattedPinyin, style: baseStyle);
      }

      // Find corresponding positions in the formatted pinyin
      final String beforeMatch = formattedPinyin.substring(0, startIndex);
      final String matchPart = formattedPinyin.substring(startIndex, endIndex);
      final String afterMatch = formattedPinyin.substring(endIndex);

      return RichText(
        text: TextSpan(
          children: [
            TextSpan(text: beforeMatch, style: baseStyle),
            TextSpan(
              text: matchPart,
              style: baseStyle.copyWith(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.2),
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(text: afterMatch, style: baseStyle),
          ],
        ),
      );
    }

    // Default case - just show the pinyin
    return Text(formattedPinyin, style: baseStyle);
  }

  @override
  Widget build(BuildContext context) {
    // Get the current search query
    final dictionaryProvider = Provider.of<DictionaryProvider>(
      context,
      listen: false,
    );
    final String searchQuery = dictionaryProvider.searchQuery;
    final searchMode = dictionaryProvider.searchMode;

    // Convert numerical pinyin to diacritic pinyin
    final String formattedPinyin = PinyinUtils.toDiacriticPinyin(entry.pinyin);

    // Get first definition for preview
    final String firstDefinition = entry.definitions.isNotEmpty
        ? entry.definitions.first
        : '';

    // If there are more definitions, add an ellipsis
    final String definitionPreview = entry.definitions.length > 1
        ? '$firstDefinition ...'
        : firstDefinition;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      elevation: 2.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<LanguageProvider>(
                builder: (context, languageProvider, _) {
                  final primaryText = languageProvider.useTraditionalCharacters
                      ? entry.traditional
                      : entry.simplified;
                  final secondaryText = languageProvider.useTraditionalCharacters
                      ? entry.simplified
                      : entry.traditional;
                  final showSecondary = primaryText != secondaryText;
                  
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.ideographic,
                    children: [
                      // Highlight matched Chinese characters if in Chinese search mode
                      (searchMode == SearchMode.chinese ||
                              (searchMode == SearchMode.auto &&
                                  PinyinUtils.containsChineseCharacters(
                                    searchQuery,
                                  )))
                          ? _highlightText(
                              primaryText,
                              searchQuery,
                              AppTheme.headingLarge(
                                context, 
                                weight: FontWeight.bold,
                              ),
                              context,
                            )
                          : Text(
                              primaryText,
                              style: AppTheme.headingLarge(
                                context,
                                weight: FontWeight.bold,
                              ),
                            ),
                      const SizedBox(width: 8.0),
                      if (showSecondary)
                        Text(
                          '($secondaryText)',
                          style: AppTheme.bodySmall(
                            context,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[500]
                            : Colors.grey[400],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 4.0),
              // Highlight pinyin if in Chinese mode or auto mode with pinyin query
              (searchMode == SearchMode.chinese ||
                      (searchMode == SearchMode.auto &&
                          PinyinUtils.isPotentialPinyin(searchQuery)))
                  ? _buildPinyinHighlight(entry.pinyin, searchQuery, context)
                  : Text(
                      formattedPinyin,
                      style: AppTheme.bodyDefault(
                        context,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
              const SizedBox(height: 4.0),
              // Highlight definition if in English mode
              (searchMode == SearchMode.english ||
                      (searchMode == SearchMode.auto &&
                          !PinyinUtils.isPotentialPinyin(searchQuery) &&
                          !PinyinUtils.containsChineseCharacters(searchQuery)))
                  ? _highlightText(
                      definitionPreview,
                      searchQuery,
                      AppTheme.bodySmall(
                        context,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      context,
                    )
                  : Text(
                      definitionPreview,
                      style: AppTheme.bodySmall(
                        context,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
