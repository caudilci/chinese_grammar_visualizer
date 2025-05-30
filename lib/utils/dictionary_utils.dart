import 'package:flutter/material.dart';
import '../models/dictionary_entry.dart';
import '../models/grammar_pattern.dart';
import '../providers/dictionary_provider.dart';
import '../providers/word_list_provider.dart';
import '../utils/pinyin_utils.dart';
import '../widgets/word_list_selector.dart';
import 'package:provider/provider.dart';

class DictionaryUtils {
  /// Find dictionary entries for a given SentencePart
  static void findAndShowDictionaryEntry(
    BuildContext context, 
    SentencePart part,
  ) {
    final dictionaryProvider = Provider.of<DictionaryProvider>(context, listen: false);
    
    // Debug information
    print('Finding dictionary entry for:');
    print('Character: "${part.text}"');
    print('Pinyin: "${part.pinyin}"');
    
    // Always do exact tone matching for examples
    List<DictionaryEntry> entries;
    
    // First get all character matches
    entries = dictionaryProvider.getDictionaryEntriesForWord(part.text, searchWithNormalization: false);
    
    // Filter for exact numerical pinyin match
    if (entries.isNotEmpty && part.pinyin.isNotEmpty) {
      final String expectedNumericalPinyin = PinyinUtils.toNumericalPinyin(part.pinyin);
      print('Looking for exact tone match: $expectedNumericalPinyin for ${part.text}');
      
      final exactMatches = entries.where((entry) {
        final entryNumericalPinyin = PinyinUtils.toNumericalPinyin(entry.pinyin);
        final isMatch = entryNumericalPinyin == expectedNumericalPinyin;
        print('  Comparing: [${entry.pinyin}] -> $entryNumericalPinyin - Match: $isMatch');
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
        print('Entry $i: ${entries[i].simplified} [${entries[i].pinyin}] - ${entries[i].definitions.join('; ')}');
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
      print('SHANG DEBUG: Selected entry: ${entries.first.simplified} [${entries.first.pinyin}]');
    }
    
    // Show dictionary entry details
    _showDictionaryEntryDetails(context, entries.first);
  }
  
  /// Get simplified numerical version of pinyin for comparison
  /// Normalizes spacing and removes any extra characters
  static String _getNormalizedNumericalPinyin(String pinyin) {
    // Convert to numerical format
    String numerical = PinyinUtils.toNumericalPinyin(pinyin);
    
    // Normalize spacing and trim
    numerical = numerical.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    return numerical;
  }
  
  /// Shows the dictionary entry details in a modal bottom sheet
  static void _showDictionaryEntryDetails(BuildContext context, DictionaryEntry entry) {
    // Initialize the word list provider if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WordListProvider>(context, listen: false).initialize();
    });
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (_, controller) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: const EdgeInsets.only(bottom: 16),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.simplified,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (entry.traditional != entry.simplified)
                                  Text(
                                    '(${entry.traditional})',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.playlist_add),
                            label: const Text('Add to List'),
                            onPressed: () {
                              _showWordListSelection(context, entry);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        PinyinUtils.toDiacriticPinyin(entry.pinyin),
                        style: const TextStyle(fontSize: 20, color: Colors.blue),
                      ),
                      const Divider(height: 32),
                      const Text(
                        'Definitions:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...entry.definitions.map(
                        (definition) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            '• $definition',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildWordListChips(context, entry),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  /// Show word list selection dialog
  static void _showWordListSelection(BuildContext context, DictionaryEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: WordListSelector(entry: entry),
        );
      },
    );
  }
  
  /// Build word list chips showing which lists this entry belongs to
  static Widget _buildWordListChips(BuildContext context, DictionaryEntry entry) {
    return Consumer<WordListProvider>(
      builder: (context, provider, child) {
        final containingLists = provider.getListsContainingEntry(entry);
        
        if (!provider.isInitialized) {
          provider.initialize();
          return const SizedBox.shrink();
        }
        
        if (containingLists.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'In Word Lists:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: containingLists.map((list) {
                return Chip(
                  label: Text(list.name),
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () {
                    provider.removeEntryFromList(list.id, entry);
                  },
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}