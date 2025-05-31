import 'package:flutter/material.dart';
import '../screens/flash_card_setup_screen.dart';
import '../screens/flash_card_review_screen.dart';
import '../screens/word_lists_screen.dart';
import '../screens/settings_screen.dart';
import '../providers/flash_card_provider.dart';
import '../utils/app_theme.dart';
import 'package:provider/provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final flashCardProvider = Provider.of<FlashCardProvider>(context);
    final hasActiveSession = flashCardProvider.isSessionActive;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Chinese Grammar Visualizer',
                  style: AppTheme.headingMedium(
                    context,
                    color: Colors.white,
                    weight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Learn Chinese with ease',
                  style: AppTheme.bodySmall(
                    context,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.list,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            title: Text(
              'Word Lists',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            onTap: () {
              Navigator.of(context).pop(); // Close the drawer
              // Navigate to word lists screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const WordListsScreen(),
                ),
              );
            },
          ),
          ExpansionTile(
            leading: Icon(
              Icons.school,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            title: Text(
              'Flash Cards',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            collapsedIconColor: Theme.of(context).colorScheme.primary,
            iconColor: Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surface.withValues(alpha: 0.3),
            children: [
              if (hasActiveSession)
                ListTile(
                  leading: Icon(
                    Icons.play_arrow,
                    size: 20,
                    color: Colors.green,
                  ),
                  title: Text(
                    'Continue Session',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  dense: true,
                  onTap: () {
                    Navigator.of(context).pop(); // Close the drawer
                    // Navigate to review screen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const FlashCardReviewScreen(),
                      ),
                    );
                  },
                ),
              ListTile(
                leading: Icon(
                  Icons.add,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  'New Session',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                dense: true,
                onTap: () async {
                  Navigator.of(context).pop(); // Close the drawer

                  // If there's an active session, confirm before continuing
                  if (hasActiveSession) {
                    final shouldEnd =
                        await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Active Session'),
                            content: const Text(
                              'You have an active flash card session. Starting a new one will end the current session.\n\nDo you want to continue?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('CANCEL'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('END & START NEW'),
                              ),
                            ],
                          ),
                        ) ??
                        false;

                    if (!shouldEnd) return;

                    flashCardProvider.endSession();
                  }

                  // Navigate to setup screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FlashCardSetupScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.settings,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            title: Text(
              'Settings',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            onTap: () {
              Navigator.of(context).pop(); // Close the drawer
              // Navigate to settings screen
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
