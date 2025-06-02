import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/grammar_provider.dart';
import '../utils/app_theme.dart';
import '../utils/catppuccin_theme.dart';
import '../widgets/pattern_card.dart';
import 'pattern_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  int? _selectedDifficultyLevel;
  List<String> _categories = [];
  int _maxDifficultyLevel = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _loadCategoriesAndLevels();
    });
  }

  Future<void> _loadData() async {
    await Provider.of<GrammarProvider>(
      context,
      listen: false,
    ).loadGrammarPatterns();
  }

  Future<void> _loadCategoriesAndLevels() async {
    final provider = Provider.of<GrammarProvider>(context, listen: false);

    final categories = await provider.getCategories();
    final maxLevel = await provider.getMaxDifficultyLevel();

    setState(() {
      _categories = categories;
      _maxDifficultyLevel = maxLevel;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterOptions(),
          _buildPatternsList(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: 'Search grammar patterns...',
          hintStyle: TextStyle(
            color: Theme.of(
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
                    Provider.of<GrammarProvider>(
                      context,
                      listen: false,
                    ).setSearchQuery('');
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.surfaceContainer
              : null,
        ),
        onChanged: (value) {
          Provider.of<GrammarProvider>(
            context,
            listen: false,
          ).setSearchQuery(value);
        },
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String?>(
              decoration: InputDecoration(
                labelText: 'Category',
                labelStyle: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.surfaceContainer
                    : null,
              ),
              value: _selectedCategory,
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Categories'),
                ),
                ..._categories
                    .map(
                      (category) => DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      ),
                    ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
                Provider.of<GrammarProvider>(
                  context,
                  listen: false,
                ).filterByCategory(value);
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<int?>(
              decoration: InputDecoration(
                labelText: 'Difficulty',
                labelStyle: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.surfaceContainer
                    : null,
              ),
              value: _selectedDifficultyLevel,
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('All Levels'),
                ),
                ...List.generate(_maxDifficultyLevel, (index) => index + 1)
                    .map(
                      (level) => DropdownMenuItem<int>(
                        value: level,
                        child: Row(
                          children: [
                            Icon(
                              Icons.star,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? CatppuccinTheme.mochaPeach
                                  : AppTheme.getDifficultyColor(level),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Level $level',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedDifficultyLevel = value;
                });
                Provider.of<GrammarProvider>(
                  context,
                  listen: false,
                ).filterByDifficultyLevel(value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternsList() {
    return Consumer<GrammarProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Expanded(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.filteredPatterns.isEmpty) {
          return Expanded(
            child: Center(
              child: Text(
                'No grammar patterns found',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          );
        }

        return Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: provider.filteredPatterns.length,
            itemBuilder: (context, index) {
              final pattern = provider.filteredPatterns[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: PatternCard(
                  pattern: pattern,
                  onTap: () {
                    provider.selectPattern(pattern.id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PatternDetailScreen(patternId: pattern.id),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
