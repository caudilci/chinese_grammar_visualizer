import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/dictionary_entry.dart';
import '../providers/dictionary_provider.dart';
import '../providers/word_list_provider.dart';
import '../providers/tts_provider.dart';
import '../services/search_isolate.dart';
import '../utils/app_theme.dart';
import '../utils/pinyin_utils.dart';
import '../widgets/dictionary_search_result.dart';
import '../widgets/word_list_selector.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({Key? key}) : super(key: key);

  @override
  DictionaryScreenState createState() => DictionaryScreenState();
}

class DictionaryScreenState extends State<DictionaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load dictionary data on first build
      Provider.of<DictionaryProvider>(context, listen: false).loadDictionary();
      // Initialize word list provider
      Provider.of<WordListProvider>(context, listen: false).initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildSearchBar(),
          _buildSearchResults(),
          _buildCreditsFooter(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Consumer<DictionaryProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: AppTheme.bodyDefault(
                  context,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: provider.searchMode == SearchMode.english
                      ? 'Search in English'
                      : provider.searchMode == SearchMode.chinese
                      ? 'Search in Chinese or Pinyin'
                      : 'Auto-detect search language',
                  hintStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            provider.setSearchQuery('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : Colors.grey[100],
                  helperText: provider.searchMode == SearchMode.auto
                      ? 'Auto-detecting search type'
                      : provider.searchMode == SearchMode.chinese
                      ? 'Searching in Chinese characters or Pinyin (with or without tones)'
                      : 'Searching in English',
                  helperStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Theme.of(context).primaryColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                onChanged: (value) {
                  provider.setSearchQuery(value);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: Text(
                      'Auto',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    selected: provider.searchMode == SearchMode.auto,
                    selectedColor: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.2),
                    avatar: provider.searchMode == SearchMode.auto
                        ? Icon(
                            Icons.auto_awesome,
                            color: Theme.of(context).primaryColor,
                            size: 18,
                          )
                        : null,
                    onSelected: (selected) {
                      if (selected) {
                        provider.setSearchMode(SearchMode.auto);
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  ChoiceChip(
                    label: Text(
                      'Chinese/Pinyin',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    selected: provider.searchMode == SearchMode.chinese,
                    selectedColor: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.2),
                    avatar: provider.searchMode == SearchMode.chinese
                        ? Icon(
                            Icons.language,
                            color: Theme.of(context).primaryColor,
                            size: 18,
                          )
                        : null,
                    onSelected: (selected) {
                      if (selected) {
                        provider.setSearchMode(SearchMode.chinese);
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  ChoiceChip(
                    label: Text(
                      'English',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    selected: provider.searchMode == SearchMode.english,
                    selectedColor: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.2),
                    avatar: provider.searchMode == SearchMode.english
                        ? Icon(
                            Icons.abc,
                            color: Theme.of(context).primaryColor,
                            size: 18,
                          )
                        : null,
                    onSelected: (selected) {
                      if (selected) {
                        provider.setSearchMode(SearchMode.english);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return Consumer<DictionaryProvider>(
      builder: (context, provider, child) {
        if (!provider.isInitialized) {
          return Expanded(
            child: Center(
              child: Builder(
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Dictionary is loading...',
                      style: AppTheme.bodyDefault(
                        context,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final searchResults = provider.searchResults;

        if (_searchController.text.isEmpty) {
          return Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Enter a search term to find words',
                    style: AppTheme.bodyDefault(context),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Builder(
                      builder: (context) => Column(
                        children: [
                          Text(
                            'Pinyin Search Tips:',
                            style: AppTheme.bodySmall(
                              context,
                              weight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Search with or without tone marks\n'
                            '• Use numbers for tones (e.g., "ni3")\n'
                            '• Search by English meaning\n'
                            '• Search by Chinese characters',
                            style: AppTheme.caption(
                              context,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.isLoading && searchResults.isEmpty) {
          return Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Dictionary is loading...',
                    style: AppTheme.bodyDefault(
                      context,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (searchResults.isEmpty && !provider.isLoading) {
          final String modeText = provider.searchMode == SearchMode.english
              ? "English"
              : provider.searchMode == SearchMode.chinese
              ? "Chinese/Pinyin"
              : "any language";

          return Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No results found for "${_searchController.text}"',
                    style: AppTheme.bodyDefault(
                      context,
                      weight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current search mode: $modeText',
                    style: AppTheme.bodySmall(
                      context,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (provider.searchMode != SearchMode.auto)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Try Auto-Detect'),
                      onPressed: () {
                        provider.setSearchMode(SearchMode.auto);
                      },
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        }

        return Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels ==
                      scrollInfo.metrics.maxScrollExtent &&
                  provider.hasMoreResults &&
                  !provider.isLoading) {
                // Load more results when reaching the end of the list
                provider.loadMoreResults();
              }
              return false;
            },
            child: ListView.builder(
              itemCount:
                  searchResults.length +
                  (provider.hasMoreResults || provider.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                // Show loading indicator at the bottom while more results are loading
                if (index >= searchResults.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.0),
                      ),
                    ),
                  );
                }

                final entry = searchResults[index];
                return DictionarySearchResult(
                  entry: entry,
                  onTap: () {
                    // Show dictionary entry details
                    provider.selectEntry(entry);
                    _showEntryDetails(context, entry);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCreditsFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      alignment: Alignment.center,
      child: InkWell(
        onTap: _launchCCCedictWebsite,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            'Powered by CC-CEDICT',
            style: AppTheme.caption(
              context,
              color: Theme.of(context).colorScheme.primary,
            ).copyWith(decoration: TextDecoration.underline),
          ),
        ),
      ),
    );
  }

  void _showEntryDetails(BuildContext context, DictionaryEntry entry) {
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
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surfaceContainer
                  : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, -3),
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
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[600]
                                : Colors.grey[300],
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
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.simplified,
                                        style: AppTheme.headingXXLarge(
                                          context,
                                          weight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      if (entry.traditional != entry.simplified)
                                        Text(
                                          '(${entry.traditional})',
                                          style: AppTheme.headingLarge(
                                            context,
                                            weight: FontWeight.w300,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.8),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Consumer<TtsProvider>(
                                  builder: (context, ttsProvider, _) {
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.volume_up),
                                          onPressed: ttsProvider.isSupported
                                              ? () {
                                                  ttsProvider.speak(entry.simplified);
                                                }
                                              : null,
                                          tooltip: ttsProvider.isSupported
                                              ? 'Pronounce Chinese'
                                              : 'TTS not supported on this platform',
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ],
                                    );
                                  },
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              PinyinUtils.toDiacriticPinyin(entry.pinyin),
                              style: AppTheme.headingMedium(
                                context,
                                weight: FontWeight.normal,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox.shrink(), // No additional TTS buttons
                        ],
                      ),
                      const Divider(height: 32),
                      Text(
                        'Definitions:',
                        style: AppTheme.bodyDefault(
                          context,
                          weight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...entry.definitions.map(
                        (definition) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            '• $definition',
                            style: AppTheme.bodyDefault(
                              context,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
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

  Widget _buildWordListChips(BuildContext context, DictionaryEntry entry) {
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
            Text(
              'In Word Lists:',
              style: AppTheme.bodyDefault(
                context,
                weight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: containingLists.map((list) {
                return Chip(
                  label: Text(list.name),
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.1),
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

  void _showWordListSelection(BuildContext context, DictionaryEntry entry) {
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

  void _launchCCCedictWebsite() async {
    final Uri url = Uri.parse('https://cc-cedict.org/');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      print('Error launching URL: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open CC-CEDICT website: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
