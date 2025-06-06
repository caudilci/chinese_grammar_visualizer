import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

import '../models/word_list.dart';
import '../providers/word_list_provider.dart';
import '../providers/flash_card_provider.dart';
import '../providers/dictionary_provider.dart';
import '../services/import_export/import_export_service.dart';
import '../widgets/loading_indicator.dart';

class ImportExportScreen extends StatefulWidget {
  static const routeName = '/import-export';

  const ImportExportScreen({Key? key}) : super(key: key);

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  bool _isImporting = false;
  bool _isExporting = false;
  String? _statusMessage;
  bool _isError = false;
  
  late ImportExportService _importExportService;
  late WordListProvider _wordListProvider;
  late FlashCardProvider _flashCardProvider;
  late DictionaryProvider _dictionaryProvider;
  
  @override
  void initState() {
    super.initState();
    _wordListProvider = Provider.of<WordListProvider>(context, listen: false);
    _flashCardProvider = Provider.of<FlashCardProvider>(context, listen: false);
    _dictionaryProvider = Provider.of<DictionaryProvider>(context, listen: false);
    _importExportService = ImportExportService(
      wordListProvider: _wordListProvider,
      flashCardProvider: _flashCardProvider,
      dictionaryProvider: _dictionaryProvider,
    );
  }
  
  Future<void> _importWordList() async {
    setState(() {
      _isImporting = true;
      _statusMessage = 'Selecting file...';
      _isError = false;
    });

    try {
      // Pick file for import
      final fileData = await _importExportService.pickFileForImport();
      
      if (fileData == null) {
        setState(() {
          _statusMessage = 'Import cancelled';
          _isImporting = false;
        });
        return;
      }
      
      setState(() {
        _statusMessage = 'Importing ${fileData['name']}...';
      });
      
      // Generate a name for the word list from the file name
      String listName = path.basenameWithoutExtension(fileData['name']);
      if (listName.isEmpty) {
        listName = 'Imported List ${DateTime.now().toIso8601String()}';
      }
      
      // Import the word list
      final wordList = await _importExportService.importWordList(
        name: listName,
        format: fileData['format'],
        content: fileData['content'],
      );
      
      if (wordList != null) {
        setState(() {
          _statusMessage = 'Successfully imported ${wordList.entries.length} words to "$listName"';
          _isImporting = false;
        });
      } else {
        setState(() {
          _statusMessage = 'Failed to import word list';
          _isImporting = false;
          _isError = true;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error importing word list: $e';
        _isImporting = false;
        _isError = true;
      });
    }
  }
  
  Future<void> _exportWordList(WordList wordList, String formatType) async {
    setState(() {
      _isExporting = true;
      _statusMessage = 'Exporting ${wordList.name}...';
      _isError = false;
    });

    try {
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
      
      // Export the word list
      final content = await _importExportService.exportWordList(
        wordListId: wordList.id,
        format: formatType,
      );
      
      // Save and share the exported file
      await _importExportService.saveAndShareExport(
        fileName: fileName,
        content: content,
      );
      
      setState(() {
        _statusMessage = 'Successfully exported "${wordList.name}"';
        _isExporting = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error exporting word list: $e';
        _isExporting = false;
        _isError = true;
      });
    }
  }
  
  Future<void> _exportAllWordLists() async {
    setState(() {
      _isExporting = true;
      _statusMessage = 'Exporting all word lists...';
      _isError = false;
    });

    try {
      // Export all word lists to a zip file
      final zipFilePath = await _importExportService.exportAllWordLists();
      
      // Share the zip file
      await Share.shareXFiles(
        [XFile(zipFilePath)],
        text: 'All word lists export',
      );
      
      setState(() {
        _statusMessage = 'Successfully exported all word lists';
        _isExporting = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error exporting word lists: $e';
        _isExporting = false;
        _isError = true;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import & Export'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
            onPressed: null, // TODO: Add help dialog
          ),
        ],
      ),
      body: _isImporting || _isExporting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const LoadingIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage ?? 'Processing...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _isError ? Colors.red : null,
                    ),
                  ),
                ],
              ),
            )
          : _buildMainContent(),
    );
  }
  
  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_statusMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: _isError ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: _isError ? Colors.red : Colors.green,
                    width: 1.0,
                  ),
                ),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(
                    color: _isError ? Colors.red : Colors.green[700],
                  ),
                ),
              ),
            ),
          
          // Import section
          _buildSection(
            title: 'Import Word List',
            description: 'Import a word list from a file. Supported formats include Pleco text (.txt), Pleco XML (.xml), and this app\'s native format (.json).',
            child: ElevatedButton.icon(
              icon: const Icon(Icons.file_upload),
              label: const Text('Select File to Import'),
              onPressed: _importWordList,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Export section
          _buildSection(
            title: 'Export Word Lists',
            description: 'Export word lists to various formats for use in other apps or for backup.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Export all word lists option
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export All Word Lists',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Export all word lists in a single package with multiple formats',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.download),
                          label: const Text('Export All Word Lists'),
                          onPressed: _exportAllWordLists,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Individual word lists
                const Padding(
                  padding: EdgeInsets.only(top: 8.0, bottom: 16.0),
                  child: Text('Or export individual word lists:'),
                ),
                
                Consumer<WordListProvider>(
                  builder: (ctx, wordListProvider, _) {
                    final wordLists = wordListProvider.wordLists;
                    
                    if (wordLists.isEmpty) {
                      return const Text('No word lists available to export');
                    }
                    
                    return Column(
                      children: [
                        ...wordLists.map((wordList) => _buildWordListExportCard(wordList)),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Format information section
          _buildSection(
            title: 'Supported Formats',
            description: 'Information about the supported import/export formats:',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormatInfo(
                  title: 'Pleco Text (.txt)',
                  description: 'Simple format with characters, pinyin, and optionally definitions. Compatible with Pleco Dictionary app.',
                ),
                _buildFormatInfo(
                  title: 'Pleco XML (.xml)',
                  description: 'Rich format with detailed card data including review history. Compatible with Pleco Dictionary app.',
                ),
                _buildFormatInfo(
                  title: 'App Native (.json)',
                  description: 'Complete format containing all word list and flash card data. Best for backups and transferring between devices.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSection({
    required String title,
    required String description,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
  
  Widget _buildWordListExportCard(WordList wordList) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wordList.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${wordList.entries.length} words · Created ${_formatDate(wordList.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.text_format, size: 18),
                  label: const Text('Text'),
                  onPressed: () => _exportWordList(
                    wordList,
                    ImportExportService.formatPlecoText,
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.code, size: 18),
                  label: const Text('XML'),
                  onPressed: () => _exportWordList(
                    wordList,
                    ImportExportService.formatPlecoXml,
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.backup, size: 18),
                  label: const Text('JSON'),
                  onPressed: () => _exportWordList(
                    wordList,
                    ImportExportService.formatAppJson,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFormatInfo({
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) {
      return 'today';
    } else if (difference.inDays < 2) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}