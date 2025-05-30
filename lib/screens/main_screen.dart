import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dictionary_provider.dart';
import '../providers/flash_card_provider.dart';
import '../providers/grammar_provider.dart';
import '../providers/word_list_provider.dart';
import '../widgets/app_bottom_nav.dart';
import 'dictionary_screen.dart';
import 'flash_card_setup_screen.dart';
import 'home_screen.dart';
import 'word_lists_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const HomeScreen(),
    const DictionaryScreen(),
    const WordListsScreen(),
    const FlashCardSetupScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize the data for the first screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    // Load grammar data for the home screen
    Provider.of<GrammarProvider>(context, listen: false).loadGrammarPatterns();
  }

  void _onNavigationTap(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    // Load data for the selected screen if needed
    if (index == 0) {
      // Home screen - grammar data
      Provider.of<GrammarProvider>(context, listen: false).loadGrammarPatterns();
    } else if (index == 1) {
      // Dictionary screen
      Provider.of<DictionaryProvider>(context, listen: false).loadDictionary();
    } else if (index == 2) {
      // Word Lists screen
      Provider.of<WordListProvider>(context, listen: false).initialize();
    } else if (index == 3) {
      // Flash Cards screen
      Provider.of<WordListProvider>(context, listen: false).initialize();
      Provider.of<FlashCardProvider>(context, listen: false).initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavigationTap,
      ),
    );
  }
}