import 'package:flutter/material.dart';
import '../models/dictionary_entry.dart';
import '../models/grammar_pattern.dart';
import '../providers/dictionary_provider.dart';
import '../utils/pinyin_utils.dart';
import '../widgets/dictionary_entry_details.dart';
import 'package:provider/provider.dart';

class DictionaryUtils {
  /// Find dictionary entries for a given SentencePart
  static void findAndShowDictionaryEntry(
    BuildContext context,
    SentencePart part,
  ) {
    final dictionaryProvider = Provider.of<DictionaryProvider>(
      context,
      listen: false,
    );

    // Debug information
    print('Finding dictionary entry for:');
    print('Character: "${part.text}"');
    print('Pinyin: "${part.pinyin}"');

    // Always do exact tone matching for examples
    List<DictionaryEntry> entries;

    // First get all character matches
    entries = dictionaryProvider.getDictionaryEntriesForWord(
      part.text,
      searchWithNormalization: false,
    );

    // Filter for exact numerical pinyin match
    if (entries.isNotEmpty && part.pinyin.isNotEmpty) {
      final String expectedNumericalPinyin = PinyinUtils.toNumericalPinyin(
        part.pinyin,
      );
      print(
        'Looking for exact tone match: $expectedNumericalPinyin for ${part.text}',
      );

      final exactMatches = entries.where((entry) {
        final entryNumericalPinyin = PinyinUtils.toNumericalPinyin(
          entry.pinyin,
        );
        final isMatch = entryNumericalPinyin == expectedNumericalPinyin;
        print(
          '  Comparing: [${entry.pinyin}] -> $entryNumericalPinyin - Match: $isMatch',
        );
        return isMatch;
      }).toList();

      if (exactMatches.isNotEmpty) {
        print('Found ${exactMatches.length} exact tone matches');
        entries = exactMatches;
      }
    }

    // Print the results for debugging
    if (entries.isNotEmpty) {
      print('Found ${entries.length} entries:');
      for (var i = 0; i < entries.length; i++) {
        print(
          'Entry $i: ${entries[i].simplified} [${entries[i].pinyin}] - ${entries[i].definitions.join('; ')}',
        );
      }
    } else {
      print('No entries found');
    }

    if (entries.isEmpty) {
      // Show message if no entries found
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No dictionary entries found for "${part.text}"'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // The entries are already sorted by pinyin match relevance by getDictionaryEntriesForWord

    // Select the first entry (most relevant)
    dictionaryProvider.selectEntry(entries.first);

    // Special debug for shang case
    if (part.text == '上') {
      print(
        'SHANG DEBUG: Selected entry: ${entries.first.simplified} [${entries.first.pinyin}]',
      );
    }

    // Show dictionary entry details
    _showDictionaryEntryDetails(context, entries.first);
  }

  /// Shows the dictionary entry details in a modal bottom sheet
  static void _showDictionaryEntryDetails(
    BuildContext context,
    DictionaryEntry entry,
  ) {
    DictionaryEntryDetails.showEntryDetailsModal(
      context, 
      entry,
    );
  }

  // Using DictionaryEntryDetails.showWordListSelection instead

  // Using the common widget now, so we can remove this method
}
