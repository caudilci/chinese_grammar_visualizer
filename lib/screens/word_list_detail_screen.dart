import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dictionary_entry.dart';
import '../models/word_list.dart';
import '../providers/word_list_provider.dart';
import '../providers/flash_card_provider.dart';
import '../providers/language_provider.dart';
import '../providers/dictionary_provider.dart';
import '../utils/app_theme.dart';
import '../utils/pinyin_utils.dart';
import '../widgets/dictionary_entry_details.dart';
import '../services/import_export/import_export_service.dart';

class WordListDetailScreen extends StatelessWidget {
  final WordList wordList;

  const WordListDetailScreen({Key? key, required this.wordList})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(wordList.name),
        titleTextStyle: AppTheme.appBarTitleStyle(),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Export List',
            onPressed: () => _showExportOptions(context),
          ),
        ],
      ),
      body: Consumer<WordListProvider>(
        builder: (context, provider, child) {
          if (wordList.entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No words in this list yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add words from the dictionary',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: wordList.entries.length,
            itemBuilder: (context, index) {
              final entry = wordList.entries[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Consumer<LanguageProvider>(
                  builder: (context, languageProvider, _) {
                    final primaryText = languageProvider.useTraditionalCharacters
                        ? entry.traditional
                        : entry.simplified;
                    final secondaryText = languageProvider.useTraditionalCharacters
                        ? entry.simplified
                        : entry.traditional;
                    final showSecondary = primaryText != secondaryText;
                    
                    return ListTile(
                      title: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: primaryText,
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeMediumLarge,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            if (showSecondary)
                              TextSpan(
                                text: ' ($secondaryText)',
                                style: TextStyle(
                                  fontSize: AppTheme.fontSizeSmall,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            PinyinUtils.toDiacriticPinyin(entry.pinyin),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: AppTheme.fontSizeSmall,
                            ),
                          ),
                          Text(
                            entry.definitions.first,
                            style: AppTheme.bodySmall(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          _showRemoveConfirmation(context, entry);
                        },
                      ),
                      onTap: () {
                        _showEntryDetails(context, entry);
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showRemoveConfirmation(BuildContext context, DictionaryEntry entry) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final displayText = languageProvider.useTraditionalCharacters
        ? entry.traditional
        : entry.simplified;
        
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from List'),
        content: Text(
          'Remove "$displayText" from this list? '
          'This will not delete the dictionary entry itself.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Provider.of<WordListProvider>(
                context,
                listen: false,
              ).removeEntryFromList(wordList.id, entry);
              Navigator.of(ctx).pop();
            },
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );
  }

  void _showEntryDetails(BuildContext context, DictionaryEntry entry) {
    DictionaryEntryDetails.showEntryDetailsModal(context, entry);
  }
  
  void _showExportOptions(BuildContext context) {
    final flashCardProvider = Provider.of<FlashCardProvider>(context, listen: false);
    final wordListProvider = Provider.of<WordListProvider>(context, listen: false);
    final dictionaryProvider = Provider.of<DictionaryProvider>(context, listen: false);
    
    final importExportService = ImportExportService(
      wordListProvider: wordListProvider,
      flashCardProvider: flashCardProvider,
      dictionaryProvider: dictionaryProvider,
    );
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Text(
                        'Export "${wordList.name}"',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      Text(
                        '${wordList.entries.length} words',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 24),
                ListTile(
                  leading: const Icon(Icons.text_format),
                  title: const Text('Export as Pleco Text (.txt)'),
                  subtitle: const Text('Simple format with characters, pinyin, and definitions'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    _exportWordList(context, importExportService, ImportExportService.formatPlecoText);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('Export as Pleco XML (.xml)'),
                  subtitle: const Text('Rich format with detailed card data and review history'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    _exportWordList(context, importExportService, ImportExportService.formatPlecoXml);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('Export as App Format (.json)'),
                  subtitle: const Text('Complete format with all word list and flash card data'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    _exportWordList(context, importExportService, ImportExportService.formatAppJson);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Future<void> _exportWordList(
    BuildContext context, 
    ImportExportService importExportService, 
    String formatType
  ) async {
    final scaffold = ScaffoldMessenger.of(context);
    
    try {
      scaffold.showSnackBar(
        const SnackBar(
          content: Text('Preparing export...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      await importExportService.exportWordList(
        wordListId: wordList.id,
        format: formatType,
      ).then((content) async {
        // Generate file extension based on format
        String extension = 'txt';
        if (formatType == ImportExportService.formatPlecoText) {
          extension = 'txt';
        } else if (formatType == ImportExportService.formatPlecoXml) {
          extension = 'xml';
        } else if (formatType == ImportExportService.formatAppJson) {
          extension = 'json';
        }
        
        // Generate file name
        final sanitizedName = wordList.name.replaceAll(RegExp(r'[^\w\s\-]'), '_');
        final fileName = '${sanitizedName}_export.$extension';
        
        await importExportService.saveAndShareExport(
          fileName: fileName,
          content: content,
        );
      });
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}