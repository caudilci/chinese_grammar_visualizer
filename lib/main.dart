import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/grammar_provider.dart';
import 'providers/dictionary_provider.dart';
import 'providers/practice_provider.dart';
import 'providers/word_list_provider.dart';
import 'providers/flash_card_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/main_screen.dart';
import 'utils/catppuccin_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => GrammarProvider()),
        ChangeNotifierProvider(create: (context) => DictionaryProvider()),
        ChangeNotifierProvider(create: (context) => PracticeProvider()),
        ChangeNotifierProvider(create: (context) => WordListProvider()),
        ChangeNotifierProvider<FlashCardProvider>(
          create: (context) => FlashCardProvider(
            Provider.of<WordListProvider>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Chinese Grammar Visualizer',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.currentTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CatppuccinTheme.mochaBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.language,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 24),
            Text(
              '汉语语法可视化',
              style: GoogleFonts.notoSansSc(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Chinese Grammar Visualizer',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.w300,
              ),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
