import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/dictionary_entry.dart';
import '../providers/dictionary_provider.dart';
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Search dictionary (汉字, pinyin, or English)',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    Provider.of<DictionaryProvider>(
                      context,
                      listen: false,
                    ).setSearchQuery('');
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: (value) {
          Provider.of<DictionaryProvider>(
            context,
            listen: false,
          ).setSearchQuery(value);
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    return Consumer<DictionaryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Expanded(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!provider.isInitialized) {
          return const Expanded(
            child: Center(
              child: Text(
                'Dictionary is loading...',
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          );
        }

        final searchResults = provider.searchResults;

        if (_searchController.text.isEmpty) {
          return const Expanded(
            child: Center(
              child: Text(
                'Enter a search term to find words',
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          );
        }

        if (searchResults.isEmpty) {
          return Expanded(
            child: Center(
              child: Text(
                'No results found for "${_searchController.text}"',
                style: const TextStyle(fontSize: 16.0),
              ),
            ),
          );
        }

        return Expanded(
          child: ListView.builder(
            itemCount: searchResults.length,
            itemBuilder: (context, index) {
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
