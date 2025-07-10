import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
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
  }) : _wordListProvider = wordListProvider,
       _flashCardProvider = flashCardProvider,
       _dictionaryProvider = dictionaryProvider;

  /// Import a word list from a file
  ///
  /// Returns a Future that completes with a list of WordLists or null if import failed
  Future<List<WordList>?> importWordList({
    required String name,
    required String format,
    required String content,
  }) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    debugPrint(
      'Starting import of word list "$name" in $format format (size: ${content.length} bytes)',
    );

    try {
      // Parse content based on format
      Map<String, List<DictionaryEntry>> categorizedEntries = {};

      if (format == formatPlecoText) {
        debugPrint('Parsing Pleco text format...');
        categorizedEntries = _parsePlecoTextFormat(content);
      } else if (format == formatPlecoXml) {
        debugPrint('Parsing Pleco XML format...');
        categorizedEntries = _parsePlecoXmlFormat(content);
      } else if (format == formatAppJson) {
        debugPrint('Parsing App JSON format...');
        // For app JSON format, we handle it differently as it has full word list data
        return [
          await _importAppJsonFormat(content),
        ].whereType<WordList>().toList();
      }

      // If no categories were found, use the file name as default category
      if (categorizedEntries.isEmpty) {
        debugPrint('No entries found in the import file');
        return [];
      }

      // If entries have no category, put them in a word list with the provided name
      if (categorizedEntries.containsKey('')) {
        categorizedEntries[name] = categorizedEntries['']!;
        categorizedEntries.remove('');
      }

      debugPrint('Parsed entries into ${categorizedEntries.length} categories');

      List<WordList> createdWordLists = [];
      Map<String, WordList> categoryToWordList = {};

      // Process each category
      for (final category in categorizedEntries.keys) {
        final validEntries = categorizedEntries[category]!
            .where((e) => e.isValid)
            .toList();

        if (validEntries.isEmpty) {
          debugPrint('No valid entries found for category: $category');
          continue;
        }

        debugPrint(
          'Processing category "$category" with ${validEntries.length} entries',
        );

        // Check if we already created this word list in this import operation
        if (categoryToWordList.containsKey(category)) {
          final wordList = categoryToWordList[category]!;
          debugPrint(
            'Adding entries to existing word list "${wordList.name}" (created during this import)',
          );
          await _wordListProvider.addEntriesToList(wordList.id, validEntries);
          continue;
        }

        // Check if this word list already exists in the app
        WordList? wordList = _wordListProvider.getWordListByName(category);
        if (wordList != null) {
          debugPrint(
            'Found existing word list for category "$category" with ID: ${wordList.id}',
          );
        } else {
          // Create the hierarchy if needed
          if (category.contains('/')) {
            debugPrint('Creating hierarchical categories for path: $category');
            final createdHierarchy = await _wordListProvider
                .createWordListsForPath(category);
            wordList = createdHierarchy.last;

            // Track all created lists
            for (final list in createdHierarchy) {
              if (!categoryToWordList.containsKey(list.name)) {
                categoryToWordList[list.name] = list;
                if (!createdWordLists.contains(list)) {
                  createdWordLists.add(list);
                }
              }
            }
          } else {
            // Create a regular word list
            wordList = await _wordListProvider.createWordList(category);
            categoryToWordList[category] = wordList;
            createdWordLists.add(wordList);
          }
          debugPrint('Created new word list with ID: ${wordList.id}');
        }

        // Batch add entries to the word list
        debugPrint('Adding entries in batch to word list "$category"...');
        final Stopwatch batchStopwatch = Stopwatch()..start();
        await _wordListProvider.addEntriesToList(wordList.id, validEntries);
        final batchElapsedMs = batchStopwatch.elapsedMilliseconds;
        debugPrint(
          'Batch import completed in ${batchElapsedMs}ms (${validEntries.length} entries)',
        );

        // Only add to created lists if it's new
        if (!createdWordLists.contains(wordList)) {
          createdWordLists.add(wordList);
        }
      }

      final elapsedMs = stopwatch.elapsedMilliseconds;
      int totalEntries = categorizedEntries.values
          .expand((e) => e)
          .where((e) => e.isValid)
          .length;
      debugPrint(
        'Import completed successfully in ${elapsedMs}ms. Added $totalEntries entries across ${createdWordLists.length} word lists',
      );
      return createdWordLists;
    } catch (e, stackTrace) {
      debugPrint('Error importing word list: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    } finally {
      stopwatch.stop();
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
          ArchiveFile(
            textFileName,
            textContent.length,
            utf8.encode(textContent),
          ),
        );

        // XML format
        final xmlContent = _exportAsPlecoXml(wordList);
        final xmlFileName = '${_sanitizeFileName(wordList.name)}.xml';
        archive.addFile(
          ArchiveFile(xmlFileName, xmlContent.length, utf8.encode(xmlContent)),
        );

        // JSON format
        final jsonContent = _exportAsAppJson(wordList);
        final jsonFileName = '${_sanitizeFileName(wordList.name)}.json';
        archive.addFile(
          ArchiveFile(
            jsonFileName,
            jsonContent.length,
            utf8.encode(jsonContent),
          ),
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
          ArchiveFile(
            'all_lists.txt',
            allTextContent.length,
            utf8.encode(allTextContent),
          ),
        );

        // Combined XML file
        final allXmlContent = _exportAllAsPlecoXml(wordLists);
        archive.addFile(
          ArchiveFile(
            'all_lists.xml',
            allXmlContent.length,
            utf8.encode(allXmlContent),
          ),
        );

        // Combined JSON file
        final allJsonContent = _exportAllAsAppJson(wordLists);
        archive.addFile(
          ArchiveFile(
            'all_lists.json',
            allJsonContent.length,
            utf8.encode(allJsonContent),
          ),
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
      await Share.shareXFiles([XFile(file.path)], text: 'Exported word list');
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

        return {'name': file.name, 'content': content, 'format': format};
      }
      // For mobile/desktop platforms
      else {
        if (file.path == null) {
          return null;
        }

        final fileObj = File(file.path!);
        final content = await fileObj.readAsString();
        final String format = _detectFormatType(file.name, content);

        return {'name': file.name, 'content': content, 'format': format};
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
    } else if (extension == 'xml' ||
        (content.trim().isNotEmpty && content.trim().startsWith('<?xml'))) {
      return formatPlecoXml;
    } else {
      // Default to Pleco text format
      return formatPlecoText;
    }
  }

  // Parse content in Pleco text format
  /// Returns a map of category names to lists of entries
  Map<String, List<DictionaryEntry>> _parsePlecoTextFormat(String content) {
    final Map<String, List<DictionaryEntry>> categorizedEntries = {'': []};
    String currentCategory = '';
    final lines = content.split('\n');

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      // Check if this line defines a category (starts with "//" followed by category name)
      if (trimmedLine.startsWith('//')) {
        currentCategory = trimmedLine.substring(2).trim();
        // Normalize slashes for consistent path handling
        currentCategory = currentCategory.replaceAll(r'\', '/');

        if (!categorizedEntries.containsKey(currentCategory)) {
          categorizedEntries[currentCategory] = [];
          debugPrint('Found category: "$currentCategory"');
        }
        continue;
      }

      try {
        // Pleco text format is typically:
        // traditional[simplified]<tab>pinyin<tab>definition
        // or
        // simplified[traditional]<tab>pinyin<tab>definition (if primary charset in Pleco is set to simplified)
        // or just
        // characters<tab>pinyin<tab>definition (when no distinction is made)
        final parts = line.split('\t');

        if (parts.length < 2) continue;

        // Extract Chinese characters
        final charPart = parts[0].trim();
        String traditional = '';
        String simplified = '';

        // Parse Chinese characters part
        if (charPart.contains('[') && charPart.contains(']')) {
          // Format: first[second] - could be either traditional[simplified] or simplified[traditional]
          final startBracket = charPart.indexOf('[');
          final endBracket = charPart.indexOf(']');

          final firstChars = charPart.substring(0, startBracket).trim();
          final secondChars = charPart
              .substring(startBracket + 1, endBracket)
              .trim();

          // Try to detect which is which by checking with dictionary
          if (_dictionaryProvider != null) {
            // First try assuming first is simplified (more common in our app)
            final firstAsSimplified = _dictionaryProvider.lookupWord(
              firstChars,
            );
            final secondAsSimplified = _dictionaryProvider.lookupWord(
              secondChars,
            );

            if (firstAsSimplified != null &&
                firstAsSimplified.traditional == secondChars) {
              // First entry is simplified, second is traditional
              simplified = firstChars;
              traditional = secondChars;
            } else if (secondAsSimplified != null &&
                secondAsSimplified.traditional == firstChars) {
              // Second entry is simplified, first is traditional
              traditional = firstChars;
              simplified = secondChars;
            } else {
              // Can't determine, make best guess:
              // Simplified characters typically have fewer strokes
              if (_isLikelySimplified(firstChars, secondChars)) {
                simplified = firstChars;
                traditional = secondChars;
              } else {
                traditional = firstChars;
                simplified = secondChars;
              }
            }
          } else {
            // No dictionary to check, assume format is traditional[simplified]
            traditional = firstChars;
            simplified = secondChars;
          }
        } else {
          // Format: characters (no distinction between simplified and traditional)
          // Try to look up to see if we know this character
          if (_dictionaryProvider != null) {
            final entry = _dictionaryProvider.lookupWord(charPart);
            if (entry != null) {
              simplified = entry.simplified;
              traditional = entry.traditional;
            } else {
              traditional = charPart;
              simplified = charPart;
            }
          } else {
            traditional = charPart;
            simplified = charPart;
          }
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
          categorizedEntries[currentCategory]!.add(entry);
        }
      } catch (e) {
        // Continue with next line
      }
    }

    // Log the number of entries found for each category
    for (final category in categorizedEntries.keys) {
      final count = categorizedEntries[category]!.length;
      if (count > 0) {
        debugPrint(
          'Found $count entries in category "${category.isEmpty ? 'default' : category}"',
        );
      }
    }

    return categorizedEntries;
  }

  // Helper method to guess if the first string is likely simplified compared to the second
  bool _isLikelySimplified(String first, String second) {
    // Simple heuristic: simplified characters typically have fewer strokes
    // We'll just compare the character count as a rough approximation
    return first.length <= second.length;
  }

  /// Parse content in Pleco XML format
  /// Returns a map of category names to lists of entries
  Map<String, List<DictionaryEntry>> _parsePlecoXmlFormat(String content) {
    final Map<String, List<DictionaryEntry>> categorizedEntries = {'': []};
    final Stopwatch stopwatch = Stopwatch()..start();

    debugPrint(
      'Starting to parse Pleco XML format. Content length: ${content.length} bytes',
    );

    try {
      debugPrint('Parsing XML document...');
      final document = XmlDocument.parse(content);

      // Get all category names from the file first
      final categoryElements = document.findAllElements('category').toList();
      for (final categoryElement in categoryElements) {
        final categoryName = categoryElement.getAttribute('name') ?? '';
        if (categoryName.isNotEmpty) {
          // Normalize slashes for consistent path handling
          final normalizedCategory = categoryName.replaceAll(r'\', '/');
          if (!categorizedEntries.containsKey(normalizedCategory)) {
            categorizedEntries[normalizedCategory] = [];
            debugPrint('Found category: "$normalizedCategory"');
          }
        }
      }

      final cardElements = document.findAllElements('card').toList();
      debugPrint(
        'Found ${cardElements.length} card elements and ${categoryElements.length} categories. Parsing will begin now.',
      );

      int processedCards = 0;
      int validEntries = 0;
      int logInterval = math.max(
        1,
        cardElements.length ~/ 20,
      ); // Log progress at 5% intervals

      for (final cardElement in cardElements) {
        try {
          processedCards++;

          // Log progress periodically
          if (processedCards % logInterval == 0) {
            final progress = (processedCards / cardElements.length * 100)
                .toStringAsFixed(1);
            debugPrint(
              'Processing card $processedCards/${cardElements.length} ($progress%). Valid entries so far: $validEntries',
            );
          }

          // Extract category assignment(s)
          final categoryAssignments = cardElement
              .findAllElements('catassign')
              .toList();
          List<String> categories = [];
          for (final catAssign in categoryAssignments) {
            final category = catAssign.getAttribute('category') ?? '';
            if (category.isNotEmpty) {
              // Normalize slashes for consistent path handling
              final normalizedCategory = category.replaceAll(r'\', '/');
              categories.add(normalizedCategory);
              // Ensure category exists in the map
              if (!categorizedEntries.containsKey(normalizedCategory)) {
                categorizedEntries[normalizedCategory] = [];
              }
            }
          }

          // If no category assignments, use default category
          if (categories.isEmpty) {
            categories.add('');
          }

          final entryElement = cardElement.findElements('entry').firstOrNull;
          if (entryElement == null) {
            if (processedCards <= 10)
              debugPrint(
                'Card #$processedCards: No entry element found, skipping',
              );
            continue;
          }

          // Extract headwords
          final headwords = entryElement.findElements('headword').toList();
          if (headwords.isEmpty) {
            if (processedCards <= 10)
              debugPrint('Card #$processedCards: No headwords found, skipping');
            continue;
          }

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
              final chars = headword.innerText;

              // Try to identify simplified vs traditional from our dictionary
              if (_dictionaryProvider != null) {
                final entry = _dictionaryProvider.lookupWord(chars);
                if (entry != null) {
                  simplified = entry.simplified;
                  traditional = entry.traditional;
                } else {
                  simplified = chars;
                  traditional = chars;
                }
              } else {
                simplified = chars;
                traditional = chars;
              }
            }
          }

          // If we didn't find both, use the same for both
          if (simplified.isEmpty && traditional.isNotEmpty) {
            simplified = traditional;
          } else if (traditional.isEmpty && simplified.isNotEmpty) {
            traditional = simplified;
          }

          // Cross-check with dictionary if possible
          if (_dictionaryProvider != null && simplified != traditional) {
            // Verify our mapping is correct by checking dictionary
            final entry = _dictionaryProvider.lookupWord(simplified);
            if (entry != null && entry.traditional != traditional) {
              // Our mapping conflicts with the dictionary, try the other way around
              final reversedEntry = _dictionaryProvider.lookupWord(traditional);
              if (reversedEntry != null &&
                  reversedEntry.simplified == simplified) {
                // The mapping is reversed but consistent, keep as is
              } else {
                // Dictionary doesn't agree, trust the explicit charset markers from the file
                debugPrint(
                  'Dictionary mapping differs from XML charset markers for: $simplified / $traditional',
                );
              }
            }
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
              // Add the entry to all of its assigned categories
              for (final category in categories) {
                categorizedEntries[category]!.add(entry);
              }
              validEntries++;

              // Log a few sample entries at the start
              if (validEntries <= 5) {
                debugPrint(
                  'Sample entry #$validEntries: ${entry.simplified} [${entry.pinyin}] (Categories: ${categories.isEmpty ? "default" : categories.join(", ")})',
                );
              }
            } else if (processedCards <= 10) {
              debugPrint(
                'Card #$processedCards: Created invalid entry for "$simplified"',
              );
            }
          } else if (processedCards <= 10) {
            debugPrint(
              'Card #$processedCards: Missing required fields - simplified: ${simplified.isNotEmpty}, pinyin: ${pinyin.isNotEmpty}',
            );
          }
        } catch (e, stackTrace) {
          debugPrint(
            'Error parsing card #$processedCards in Pleco XML format: $e',
          );
          debugPrint('Stack trace: $stackTrace');
          // Continue with next card
        }
      }

      final elapsedMs = stopwatch.elapsedMilliseconds;
      int totalEntries = categorizedEntries.values.expand((e) => e).length;
      debugPrint(
        'XML parsing completed in ${elapsedMs}ms. Processed $processedCards cards, found $totalEntries valid entries across ${categorizedEntries.length} categories.',
      );
      debugPrint(
        'Performance: ${processedCards / (elapsedMs / 1000)} cards/second',
      );

      // Log the number of entries found for each category
      for (final category in categorizedEntries.keys) {
        final count = categorizedEntries[category]!.length;
        if (count > 0) {
          debugPrint(
            'Found $count entries in category "${category.isEmpty ? 'default' : category}"',
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Critical error parsing Pleco XML format: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      stopwatch.stop();
    }

    return categorizedEntries;
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
      final WordList wordList = await _wordListProvider.createWordList(
        json['name'],
      );

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
      buffer.write(
        '${entry.traditional}[${entry.simplified}]\t${entry.pinyin}',
      );

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
        buffer.write(
          '${entry.traditional}[${entry.simplified}]\t${entry.pinyin}',
        );

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
    builder.element(
      'plecoflash',
      attributes: {
        'formatversion': '2',
        'creator': 'Chinese Grammar Visualizer',
        'generator': 'Chinese Grammar Visualizer Export',
        'platform': 'Cross-Platform',
        'created': DateTime.now().millisecondsSinceEpoch.toString(),
      },
      nest: () {
        // Add categories section
        builder.element(
          'categories',
          nest: () {
            builder.element('category', attributes: {'name': wordList.name});
          },
        );

        // Add cards section
        builder.element(
          'cards',
          nest: () {
            for (final entry in wordList.entries) {
              builder.element(
                'card',
                attributes: {'language': 'chinese'},
                nest: () {
                  builder.element(
                    'entry',
                    nest: () {
                      // Add traditional character
                      builder.element(
                        'headword',
                        attributes: {'charset': 'tc'},
                        nest: entry.traditional,
                      );

                      // Add simplified character
                      builder.element(
                        'headword',
                        attributes: {'charset': 'sc'},
                        nest: entry.simplified,
                      );

                      // Add pinyin
                      builder.element(
                        'pron',
                        attributes: {'type': 'hypy', 'tones': 'numbers'},
                        nest: entry.pinyin,
                      );

                      // Add definition if available
                      if (entry.definitions.isNotEmpty) {
                        builder.element(
                          'defn',
                          nest: entry.definitions.join('; '),
                        );
                      }
                    },
                  );

                  // Add category assignment
                  builder.element(
                    'catassign',
                    attributes: {'category': wordList.name},
                  );

                  // Get card data if available
                  final entryId = '${entry.simplified}:${entry.pinyin}';
                  final cards = _flashCardProvider.cards;
                  if (cards.containsKey(entryId)) {
                    final card = cards[entryId]!;

                    // Add score info if the card has been reviewed
                    if (card.totalReviews > 0) {
                      builder.element(
                        'scoreinfo',
                        attributes: {
                          'scorefile': 'Default',
                          'score': '${(card.accuracy).round()}',
                          'difficulty': '100',
                          'history': card.reviewHistory
                              .map((r) => r.wasCorrect ? '6' : '2')
                              .join(''),
                          'correct': '${card.correctReviews}',
                          'incorrect':
                              '${card.totalReviews - card.correctReviews}',
                          'reviewed': '${card.totalReviews}',
                          'sincelast': '${card.reviewHistory.length}',
                          'firstreviewedtime':
                              '${card.createdAt.millisecondsSinceEpoch ~/ 1000}',
                          'lastreviewedtime':
                              '${(card.lastReviewedAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch) ~/ 1000}',
                        },
                      );
                    }
                  }
                },
              );
            }
          },
        );
      },
    );

    return builder.buildDocument().toXmlString(pretty: true);
  }

  /// Export all word lists as a combined Pleco XML format
  String _exportAllAsPlecoXml(List<WordList> wordLists) {
    final builder = XmlBuilder();

    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element(
      'plecoflash',
      attributes: {
        'formatversion': '2',
        'creator': 'Chinese Grammar Visualizer',
        'generator': 'Chinese Grammar Visualizer Export',
        'platform': 'Cross-Platform',
        'created': DateTime.now().millisecondsSinceEpoch.toString(),
      },
      nest: () {
        // Add categories section with all word list names
        builder.element(
          'categories',
          nest: () {
            for (final wordList in wordLists) {
              builder.element('category', attributes: {'name': wordList.name});
            }
          },
        );

        // Add cards section with all entries from all word lists
        builder.element(
          'cards',
          nest: () {
            for (final wordList in wordLists) {
              for (final entry in wordList.entries) {
                builder.element(
                  'card',
                  attributes: {'language': 'chinese'},
                  nest: () {
                    builder.element(
                      'entry',
                      nest: () {
                        // Add traditional character
                        builder.element(
                          'headword',
                          attributes: {'charset': 'tc'},
                          nest: entry.traditional,
                        );

                        // Add simplified character
                        builder.element(
                          'headword',
                          attributes: {'charset': 'sc'},
                          nest: entry.simplified,
                        );

                        // Add pinyin
                        builder.element(
                          'pron',
                          attributes: {'type': 'hypy', 'tones': 'numbers'},
                          nest: entry.pinyin,
                        );

                        // Add definition if available
                        if (entry.definitions.isNotEmpty) {
                          builder.element(
                            'defn',
                            nest: entry.definitions.join('; '),
                          );
                        }
                      },
                    );

                    // Add category assignment
                    builder.element(
                      'catassign',
                      attributes: {'category': wordList.name},
                    );

                    // Get card data if available
                    final entryId = '${entry.simplified}:${entry.pinyin}';
                    final cards = _flashCardProvider.cards;
                    if (cards.containsKey(entryId)) {
                      final card = cards[entryId]!;

                      // Add score info if the card has been reviewed
                      if (card.totalReviews > 0) {
                        builder.element(
                          'scoreinfo',
                          attributes: {
                            'scorefile': 'Default',
                            'score': '${(card.accuracy).round()}',
                            'difficulty': '100',
                            'history': card.reviewHistory
                                .map((r) => r.wasCorrect ? '6' : '2')
                                .join(''),
                            'correct': '${card.correctReviews}',
                            'incorrect':
                                '${card.totalReviews - card.correctReviews}',
                            'reviewed': '${card.totalReviews}',
                            'sincelast': '${card.reviewHistory.length}',
                            'firstreviewedtime':
                                '${card.createdAt.millisecondsSinceEpoch ~/ 1000}',
                            'lastreviewedtime':
                                '${(card.lastReviewedAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch) ~/ 1000}',
                          },
                        );
                      }
                    }
                  },
                );
              }
            }
          },
        );
      },
    );

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
