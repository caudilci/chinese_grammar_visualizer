import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:archive/archive.dart';

import '../../models/dictionary_entry.dart';
import '../../models/flash_card.dart';
import '../../models/word_list.dart';
import '../../providers/word_list_provider.dart';
import '../../providers/flash_card_provider.dart';
import '../../providers/dictionary_provider.dart';

/// Service for importing and exporting word lists in various formats
class ImportExportService {
  final WordListProvider _wordListProvider;
  final FlashCardProvider _flashCardProvider;
  final DictionaryProvider? _dictionaryProvider;

  /// Format types supported for import/export
  /// String constants for format types
  static const String formatPlecoText = 'plecoText';
  static const String formatPlecoXml = 'plecoXml';
  static const String formatAppJson = 'appJson';
  static const String formatAllCategoriesZip = 'allCategoriesZip';

  ImportExportService({
    required WordListProvider wordListProvider,
    required FlashCardProvider flashCardProvider,
    DictionaryProvider? dictionaryProvider,
  })  : _wordListProvider = wordListProvider,
        _flashCardProvider = flashCardProvider,
        _dictionaryProvider = dictionaryProvider;

  /// Import a word list from a file
  /// 
  /// Returns a Future that completes with the new WordList or null if import failed
  Future<WordList?> importWordList({
    required String name,
    required String format,
    required String content,
  }) async {
    try {
      // Create a new word list
      final WordList wordList = await _wordListProvider.createWordList(name);

      // Parse content based on format
      List<DictionaryEntry> entries = [];
      
      if (format == formatPlecoText) {
        entries = _parsePlecoTextFormat(content);
      } else if (format == formatPlecoXml) {
        entries = _parsePlecoXmlFormat(content);
      } else if (format == formatAppJson) {
        // For app JSON format, we handle it differently as it has full word list data
        return _importAppJsonFormat(content);
      }

      // Add entries to the word list
      for (final entry in entries) {
        if (entry.isValid) {
          await _wordListProvider.addEntryToList(wordList.id, entry);
        }
      }

      return wordList;
    } catch (e) {
      debugPrint('Error importing word list: $e');
      return null;
    }
  }

  /// Export a word list to a specific format
  /// 
  /// Returns a Future that completes with the exported content as a string
  Future<String> exportWordList({
    required String wordListId,
    required String format,
  }) async {
    final wordList = _wordListProvider.getWordListById(wordListId);
    if (wordList == null) {
      throw Exception('Word list not found');
    }

    if (format == formatPlecoText) {
      return _exportAsPlecoText(wordList);
    } else if (format == formatPlecoXml) {
      return _exportAsPlecoXml(wordList);
    } else {
      return _exportAsAppJson(wordList);
    }
  }
  
  /// Export all word lists to a zip file containing multiple formats
  ///
  /// Returns a Future that completes with the path to the zip file
  Future<String> exportAllWordLists() async {
    final tempDir = await getTemporaryDirectory();
    final zipFile = File('${tempDir.path}/all_word_lists_export.zip');
    
    // Create an Archive object
    final archive = Archive();
    
    // Get all word lists
    final wordLists = _wordListProvider.wordLists;
    
    for (final wordList in wordLists) {
      // Export each word list in each format
      try {
        // Text format
        final textContent = _exportAsPlecoText(wordList);
        final textFileName = '${_sanitizeFileName(wordList.name)}.txt';
        archive.addFile(
          ArchiveFile(textFileName, textContent.length, utf8.encode(textContent))
        );
        
        // XML format
        final xmlContent = _exportAsPlecoXml(wordList);
        final xmlFileName = '${_sanitizeFileName(wordList.name)}.xml';
        archive.addFile(
          ArchiveFile(xmlFileName, xmlContent.length, utf8.encode(xmlContent))
        );
        
        // JSON format
        final jsonContent = _exportAsAppJson(wordList);
        final jsonFileName = '${_sanitizeFileName(wordList.name)}.json';
        archive.addFile(
          ArchiveFile(jsonFileName, jsonContent.length, utf8.encode(jsonContent))
        );
      } catch (e) {
        debugPrint('Error exporting word list ${wordList.name}: $e');
        // Continue with the next word list
      }
    }
    
    // Add a combined export with all word lists in one file
    if (wordLists.isNotEmpty) {
      try {
        // Combined text file
        final allTextContent = _exportAllAsPlecoText(wordLists);
        archive.addFile(
          ArchiveFile('all_lists.txt', allTextContent.length, utf8.encode(allTextContent))
        );
        
        // Combined XML file
        final allXmlContent = _exportAllAsPlecoXml(wordLists);
        archive.addFile(
          ArchiveFile('all_lists.xml', allXmlContent.length, utf8.encode(allXmlContent))
        );
        
        // Combined JSON file
        final allJsonContent = _exportAllAsAppJson(wordLists);
        archive.addFile(
          ArchiveFile('all_lists.json', allJsonContent.length, utf8.encode(allJsonContent))
        );
      } catch (e) {
        debugPrint('Error exporting combined word lists: $e');
      }
    }
    
    // Write the zip file
    final bytes = ZipEncoder().encode(archive);
    if (bytes != null) {
      await zipFile.writeAsBytes(bytes);
      return zipFile.path;
    } else {
      throw Exception('Failed to create zip file');
    }
  }
  
  /// Sanitizes a file name by removing illegal characters
  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[^\w\s\-]'), '_');
  }

  /// Save exported content to a file and share it
  Future<void> saveAndShareExport({
    required String fileName, 
    required String content,
  }) async {
    try {
      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      
      // Write content to file
      await file.writeAsString(content);
      
      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Exported word list',
      );
    } catch (e) {
      debugPrint('Error sharing exported file: $e');
      rethrow;
    }
  }

  /// Pick a file for import
  /// 
  /// Returns a Future that completes with the file content as a string
  Future<Map<String, dynamic>?> pickFileForImport() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'xml', 'json'],
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;
      
      // For web platform
      if (kIsWeb) {
        if (file.bytes == null) {
          return null;
        }
        
        final content = utf8.decode(file.bytes!);
        final String format = _detectFormatType(file.name, content);
        
        return {
          'name': file.name,
          'content': content,
          'format': format,
        };
      } 
      // For mobile/desktop platforms
      else {
        if (file.path == null) {
          return null;
        }
        
        final fileObj = File(file.path!);
        final content = await fileObj.readAsString();
        final String format = _detectFormatType(file.name, content);
        
        return {
          'name': file.name,
          'content': content,
          'format': format,
        };
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      return null;
    }
  }

  /// Detect the format type based on file extension and content
  String _detectFormatType(String fileName, String content) {
    final extension = fileName.split('.').last.toLowerCase();
    
    if (extension == 'json') {
      return formatAppJson;
    } else if (extension == 'xml' || (content.trim().isNotEmpty && content.trim().startsWith('<?xml'))) {
      return formatPlecoXml;
    } else {
      // Default to Pleco text format
      return formatPlecoText;
    }
  }

  /// Parse content in Pleco text format
  List<DictionaryEntry> _parsePlecoTextFormat(String content) {
    final List<DictionaryEntry> entries = [];
    final lines = content.split('\n');
    
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      
      try {
        // Pleco text format is typically:
        // traditional[simplified]<tab>pinyin<tab>definition
        // or
        // traditional[simplified]<tab>pinyin
        final parts = line.split('\t');
        
        if (parts.length < 2) continue;
        
        // Extract Chinese characters
        final charPart = parts[0].trim();
        String traditional = '';
        String simplified = '';
        
        // Parse Chinese characters part
        if (charPart.contains('[') && charPart.contains(']')) {
          // Format: traditional[simplified]
          final startBracket = charPart.indexOf('[');
          final endBracket = charPart.indexOf(']');
          
          traditional = charPart.substring(0, startBracket).trim();
          simplified = charPart.substring(startBracket + 1, endBracket).trim();
        } else {
          // No brackets, assume same for both
          traditional = charPart;
          simplified = charPart;
        }
        
        // Extract pinyin
        final pinyin = parts[1].trim();
        
        // Extract definition if present
        List<String> definitions = [];
        if (parts.length > 2) {
          definitions = [parts.sublist(2).join('\t').trim()];
        }
        
        // Try to find in dictionary if available and entry has no definitions
        if (definitions.isEmpty && _dictionaryProvider != null) {
          final dictionaryEntry = _dictionaryProvider.lookupWord(simplified);
          if (dictionaryEntry != null) {
            definitions = dictionaryEntry.definitions;
          }
        }
        
        // Create entry
        final entry = DictionaryEntry(
          traditional: traditional,
          simplified: simplified,
          pinyin: pinyin,
          definitions: definitions,
        );
        
        if (entry.isValid) {
          entries.add(entry);
        }
      } catch (e) {
        debugPrint('Error parsing line in Pleco text format: $e');
        // Continue with next line
      }
    }
    
    return entries;
  }

  /// Parse content in Pleco XML format
  List<DictionaryEntry> _parsePlecoXmlFormat(String content) {
    final List<DictionaryEntry> entries = [];
    
    try {
      final document = XmlDocument.parse(content);
      final cardElements = document.findAllElements('card');
      
      for (final cardElement in cardElements) {
        try {
          final entryElement = cardElement.findElements('entry').firstOrNull;
          if (entryElement == null) continue;
          
          // Extract headwords
          final headwords = entryElement.findElements('headword').toList();
          if (headwords.isEmpty) continue;
          
          String simplified = '';
          String traditional = '';
          
          // Find simplified and traditional characters
          for (final headword in headwords) {
            final charset = headword.getAttribute('charset');
            if (charset == 'sc') {
              simplified = headword.innerText;
            } else if (charset == 'tc') {
              traditional = headword.innerText;
            } else if (charset == null && headwords.length == 1) {
              // If there's only one headword and no charset, use it for both
              simplified = headword.innerText;
              traditional = headword.innerText;
            }
          }
          
          // If we didn't find both, use the same for both
          if (simplified.isEmpty && traditional.isNotEmpty) {
            simplified = traditional;
          } else if (traditional.isEmpty && simplified.isNotEmpty) {
            traditional = simplified;
          }
          
          // Extract pinyin
          String pinyin = '';
          final pronElement = entryElement.findElements('pron').firstOrNull;
          if (pronElement != null) {
            pinyin = pronElement.innerText;
          }
          
          // Extract definition
          List<String> definitions = [];
          final defnElement = entryElement.findElements('defn').firstOrNull;
          if (defnElement != null && defnElement.innerText.isNotEmpty) {
            definitions = [defnElement.innerText];
          }
          
          // Try to find in dictionary if available and entry has no definitions
          if (definitions.isEmpty && _dictionaryProvider != null) {
            final dictionaryEntry = _dictionaryProvider.lookupWord(simplified);
            if (dictionaryEntry != null) {
              definitions = dictionaryEntry.definitions;
            }
          }
          
          // Create entry
          if (simplified.isNotEmpty && pinyin.isNotEmpty) {
            final entry = DictionaryEntry(
              traditional: traditional,
              simplified: simplified,
              pinyin: pinyin,
              definitions: definitions,
            );
            
            if (entry.isValid) {
              entries.add(entry);
            }
          }
        } catch (e) {
          debugPrint('Error parsing card in Pleco XML format: $e');
          // Continue with next card
        }
      }
    } catch (e) {
      debugPrint('Error parsing Pleco XML format: $e');
    }
    
    return entries;
  }

  /// Import a word list from the app's JSON format
  Future<WordList?> _importAppJsonFormat(String content) async {
    try {
      final Map<String, dynamic> json = jsonDecode(content);
      
      // Check if it's a valid word list JSON
      if (!json.containsKey('name') || !json.containsKey('entries')) {
        throw FormatException('Invalid JSON format: missing required fields');
      }
      
      // Create a new word list
      final WordList wordList = await _wordListProvider.createWordList(json['name']);
      
      // Parse entries
      final List<dynamic> entriesJson = json['entries'];
      for (final entryJson in entriesJson) {
        try {
          final entry = DictionaryEntry.fromJson(entryJson);
          if (entry.isValid) {
            await _wordListProvider.addEntryToList(wordList.id, entry);
          }
        } catch (e) {
          debugPrint('Error parsing entry in JSON format: $e');
          // Continue with next entry
        }
      }
      
      // If flash card data is included, import it
      if (json.containsKey('cards')) {
        final Map<String, dynamic> cardsJson = json['cards'];
        for (final entry in wordList.entries) {
          final entryId = '${entry.simplified}:${entry.pinyin}';
          if (cardsJson.containsKey(entryId)) {
            try {
              // We don't have a direct API to add cards, so they'll be created as needed
              // when the user studies the word list
              FlashCard.fromJson(cardsJson[entryId]);
            } catch (e) {
              debugPrint('Error parsing card in JSON format: $e');
            }
          }
        }
      }
      
      return wordList;
    } catch (e) {
      debugPrint('Error importing app JSON format: $e');
      return null;
    }
  }

  /// Export a word list in Pleco text format
  String _exportAsPlecoText(WordList wordList) {
    final buffer = StringBuffer();
    
    for (final entry in wordList.entries) {
      // Format: traditional[simplified]<tab>pinyin<tab>definition
      buffer.write('${entry.traditional}[${entry.simplified}]\t${entry.pinyin}');
      
      // Add definition if available
      if (entry.definitions.isNotEmpty) {
        buffer.write('\t${entry.definitions.join('; ')}');
      }
      
      buffer.writeln();
    }
    
    return buffer.toString();
  }
  
  /// Export all word lists as a combined Pleco text format
  String _exportAllAsPlecoText(List<WordList> wordLists) {
    final buffer = StringBuffer();
    
    for (final wordList in wordLists) {
      // Add a comment line with the word list name
      buffer.writeln('# ${wordList.name}');
      
      for (final entry in wordList.entries) {
        // Format: traditional[simplified]<tab>pinyin<tab>definition
        buffer.write('${entry.traditional}[${entry.simplified}]\t${entry.pinyin}');
        
        // Add definition if available
        if (entry.definitions.isNotEmpty) {
          buffer.write('\t${entry.definitions.join('; ')}');
        }
        
        buffer.writeln();
      }
      
      // Add a blank line between word lists
      buffer.writeln();
    }
    
    return buffer.toString();
  }

  /// Export a word list in Pleco XML format
  String _exportAsPlecoXml(WordList wordList) {
    final builder = XmlBuilder();
    
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('plecoflash', attributes: {
      'formatversion': '2',
      'creator': 'Chinese Grammar Visualizer',
      'generator': 'Chinese Grammar Visualizer Export',
      'platform': 'Cross-Platform',
      'created': DateTime.now().millisecondsSinceEpoch.toString(),
    }, nest: () {
      
      // Add categories section
      builder.element('categories', nest: () {
        builder.element('category', attributes: {
          'name': wordList.name,
        });
      });
      
      // Add cards section
      builder.element('cards', nest: () {
        for (final entry in wordList.entries) {
          builder.element('card', attributes: {
            'language': 'chinese',
          }, nest: () {
            builder.element('entry', nest: () {
              // Add traditional character
              builder.element('headword', attributes: {
                'charset': 'tc',
              }, nest: entry.traditional);
              
              // Add simplified character
              builder.element('headword', attributes: {
                'charset': 'sc',
              }, nest: entry.simplified);
              
              // Add pinyin
              builder.element('pron', attributes: {
                'type': 'hypy',
                'tones': 'numbers',
              }, nest: entry.pinyin);
              
              // Add definition if available
              if (entry.definitions.isNotEmpty) {
                builder.element('defn', nest: entry.definitions.join('; '));
              }
            });
            
            // Add category assignment
            builder.element('catassign', attributes: {
              'category': wordList.name,
            });
            
            // Get card data if available
            final entryId = '${entry.simplified}:${entry.pinyin}';
            final cards = _flashCardProvider.cards;
            if (cards.containsKey(entryId)) {
              final card = cards[entryId]!;
              
              // Add score info if the card has been reviewed
              if (card.totalReviews > 0) {
                builder.element('scoreinfo', attributes: {
                  'scorefile': 'Default',
                  'score': '${(card.accuracy).round()}',
                  'difficulty': '100',
                  'history': card.reviewHistory.map((r) => r.wasCorrect ? '6' : '2').join(''),
                  'correct': '${card.correctReviews}',
                  'incorrect': '${card.totalReviews - card.correctReviews}',
                  'reviewed': '${card.totalReviews}',
                  'sincelast': '${card.reviewHistory.length}',
                  'firstreviewedtime': '${card.createdAt.millisecondsSinceEpoch ~/ 1000}',
                  'lastreviewedtime': '${(card.lastReviewedAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch) ~/ 1000}',
                });
              }
            }
          });
        }
      });
    });
    
    return builder.buildDocument().toXmlString(pretty: true);
  }
  
  /// Export all word lists as a combined Pleco XML format
  String _exportAllAsPlecoXml(List<WordList> wordLists) {
    final builder = XmlBuilder();
    
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('plecoflash', attributes: {
      'formatversion': '2',
      'creator': 'Chinese Grammar Visualizer',
      'generator': 'Chinese Grammar Visualizer Export',
      'platform': 'Cross-Platform',
      'created': DateTime.now().millisecondsSinceEpoch.toString(),
    }, nest: () {
      
      // Add categories section with all word list names
      builder.element('categories', nest: () {
        for (final wordList in wordLists) {
          builder.element('category', attributes: {
            'name': wordList.name,
          });
        }
      });
      
      // Add cards section with all entries from all word lists
      builder.element('cards', nest: () {
        for (final wordList in wordLists) {
          for (final entry in wordList.entries) {
            builder.element('card', attributes: {
              'language': 'chinese',
            }, nest: () {
              builder.element('entry', nest: () {
                // Add traditional character
                builder.element('headword', attributes: {
                  'charset': 'tc',
                }, nest: entry.traditional);
                
                // Add simplified character
                builder.element('headword', attributes: {
                  'charset': 'sc',
                }, nest: entry.simplified);
                
                // Add pinyin
                builder.element('pron', attributes: {
                  'type': 'hypy',
                  'tones': 'numbers',
                }, nest: entry.pinyin);
                
                // Add definition if available
                if (entry.definitions.isNotEmpty) {
                  builder.element('defn', nest: entry.definitions.join('; '));
                }
              });
              
              // Add category assignment
              builder.element('catassign', attributes: {
                'category': wordList.name,
              });
              
              // Get card data if available
              final entryId = '${entry.simplified}:${entry.pinyin}';
              final cards = _flashCardProvider.cards;
              if (cards.containsKey(entryId)) {
                final card = cards[entryId]!;
                
                // Add score info if the card has been reviewed
                if (card.totalReviews > 0) {
                  builder.element('scoreinfo', attributes: {
                    'scorefile': 'Default',
                    'score': '${(card.accuracy).round()}',
                    'difficulty': '100',
                    'history': card.reviewHistory.map((r) => r.wasCorrect ? '6' : '2').join(''),
                    'correct': '${card.correctReviews}',
                    'incorrect': '${card.totalReviews - card.correctReviews}',
                    'reviewed': '${card.totalReviews}',
                    'sincelast': '${card.reviewHistory.length}',
                    'firstreviewedtime': '${card.createdAt.millisecondsSinceEpoch ~/ 1000}',
                    'lastreviewedtime': '${(card.lastReviewedAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch) ~/ 1000}',
                  });
                }
              }
            });
          }
        }
      });
    });
    
    return builder.buildDocument().toXmlString(pretty: true);
  }

  /// Export a word list in the app's JSON format
  String _exportAsAppJson(WordList wordList) {
    // Create a map with word list data
    final Map<String, dynamic> json = {
      'name': wordList.name,
      'createdAt': wordList.createdAt.toIso8601String(),
      'updatedAt': wordList.updatedAt.toIso8601String(),
      'entries': wordList.entries.map((e) => e.toJson()).toList(),
    };
    
    // Include flash card data if available
    final Map<String, dynamic> cardsJson = {};
    for (final entry in wordList.entries) {
      final entryId = '${entry.simplified}:${entry.pinyin}';
      final cards = _flashCardProvider.cards;
      if (cards.containsKey(entryId)) {
        cardsJson[entryId] = cards[entryId]!.toJson();
      }
    }
    
    if (cardsJson.isNotEmpty) {
      json['cards'] = cardsJson;
    }
    
    return jsonEncode(json);
  }
  
  /// Export all word lists in the app's JSON format
  String _exportAllAsAppJson(List<WordList> wordLists) {
    final List<Map<String, dynamic>> wordListsJson = [];
    
    for (final wordList in wordLists) {
      final Map<String, dynamic> wordListJson = {
        'id': wordList.id,
        'name': wordList.name,
        'createdAt': wordList.createdAt.toIso8601String(),
        'updatedAt': wordList.updatedAt.toIso8601String(),
        'entries': wordList.entries.map((e) => e.toJson()).toList(),
      };
      
      // Include flash card data if available
      final Map<String, dynamic> cardsJson = {};
      for (final entry in wordList.entries) {
        final entryId = '${entry.simplified}:${entry.pinyin}';
        final cards = _flashCardProvider.cards;
        if (cards.containsKey(entryId)) {
          cardsJson[entryId] = cards[entryId]!.toJson();
        }
      }
      
      if (cardsJson.isNotEmpty) {
        wordListJson['cards'] = cardsJson;
      }
      
      wordListsJson.add(wordListJson);
    }
    
    return jsonEncode({
      'wordLists': wordListsJson,
      'exportedAt': DateTime.now().toIso8601String(),
      'appVersion': '1.0.0',
    });
  }
}