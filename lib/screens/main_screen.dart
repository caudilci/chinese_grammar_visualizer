import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dictionary_provider.dart';
import '../providers/grammar_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/app_drawer.dart';
import 'dictionary_screen.dart';
import 'home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Only keep the main screens
  final List<Widget> _screens = [const HomeScreen(), const DictionaryScreen()];
  int _currentIndex = 0;

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
      Provider.of<GrammarProvider>(
        context,
        listen: false,
      ).loadGrammarPatterns();
    } else if (index == 1) {
      // Dictionary screen
      Provider.of<DictionaryProvider>(context, listen: false).loadDictionary();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = _currentIndex == 0 ? 'Grammar' : 'Dictionary';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        titleTextStyle: AppTheme.appBarTitleStyle(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AppDrawer(),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavigationTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.format_list_bulleted),
            label: 'Grammar',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Dictionary'),
        ],
      ),
    );
  }
}
