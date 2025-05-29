import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/dictionary_entry.dart';
import '../providers/dictionary_provider.dart';
import '../services/search_isolate.dart';
import '../utils/pinyin_utils.dart';
import '../widgets/dictionary_search_result.dart';

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
      appBar: AppBar(title: const Text('Chinese Dictionary')),
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
                decoration: InputDecoration(
                  hintText: provider.searchMode == SearchMode.english 
                      ? 'Search in English' 
                      : provider.searchMode == SearchMode.chinese
                          ? 'Search in Chinese or Pinyin'
                          : 'Auto-detect search language',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            provider.setSearchQuery('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  filled: true,
                  fillColor: Colors.grey[100],
                  helperText: provider.searchMode == SearchMode.auto
                      ? 'Auto-detecting search type'
                      : provider.searchMode == SearchMode.chinese
                          ? 'Searching in Chinese characters or Pinyin (with or without tones)'
                          : 'Searching in English',
                  helperStyle: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                onChanged: (value) {
                  provider.setSearchQuery(value);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Auto'),
                    selected: provider.searchMode == SearchMode.auto,
                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    avatar: provider.searchMode == SearchMode.auto 
                        ? Icon(Icons.auto_awesome, color: Theme.of(context).primaryColor, size: 18)
                        : null,
                    onSelected: (selected) {
                      if (selected) {
                        provider.setSearchMode(SearchMode.auto);
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  ChoiceChip(
                    label: const Text('Chinese/Pinyin'),
                    selected: provider.searchMode == SearchMode.chinese,
                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    avatar: provider.searchMode == SearchMode.chinese 
                        ? Icon(Icons.language, color: Theme.of(context).primaryColor, size: 18)
                        : null,
                    onSelected: (selected) {
                      if (selected) {
                        provider.setSearchMode(SearchMode.chinese);
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  ChoiceChip(
                    label: const Text('English'),
                    selected: provider.searchMode == SearchMode.english,
                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    avatar: provider.searchMode == SearchMode.english 
                        ? Icon(Icons.abc, color: Theme.of(context).primaryColor, size: 18)
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
          return const Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Dictionary is loading...',
                    style: TextStyle(fontSize: 16.0),
                  ),
                ],
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
                    const Text(
                      'Enter a search term to find words',
                      style: TextStyle(fontSize: 16.0),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: const [
                          Text(
                            'Pinyin Search Tips:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '• Search with or without tone marks\n'
                            '• Try single syllables like "hao" or full words like "ni hao"\n'
                            '• First-letter search: "nh" → "ni hao"',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.isLoading && searchResults.isEmpty) {
            return const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Searching...',
                      style: TextStyle(fontSize: 16.0),
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
                      style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Current search mode: $modeText',
                      style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
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
              if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
                  provider.hasMoreResults && !provider.isLoading) {
                // Load more results when reaching the end of the list
                provider.loadMoreResults();
              }
              return false;
            },
            child: ListView.builder(
              itemCount: searchResults.length + (provider.hasMoreResults || provider.isLoading ? 1 : 0),
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
          child: const Text(
            'Powered by CC-CEDICT',
            style: TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.underline,
              fontSize: 12.0,
            ),
          ),
        ),
      ),
    );
  }

  void _showEntryDetails(BuildContext context, DictionaryEntry entry) {
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
              ],
            ),
          );
        },
      ),
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
