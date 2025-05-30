import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/catppuccin_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Appearance'),
          _buildThemeSelector(context),
          const Divider(),
          _buildSectionHeader(context, 'About'),
          ListTile(
            leading: Icon(Icons.info_outline, 
              color: brightness == Brightness.dark ? Theme.of(context).colorScheme.primary : null),
            title: Text('App Version', 
              style: TextStyle(color: Theme.of(context).colorScheme.onBackground)),
            subtitle: Text('1.0.0', 
              style: TextStyle(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7))),
          ),
          ListTile(
            leading: Icon(Icons.code,
              color: brightness == Brightness.dark ? Theme.of(context).colorScheme.primary : null),
            title: Text('Open Source',
              style: TextStyle(color: Theme.of(context).colorScheme.onBackground)),
            subtitle: Text('This app is open source.',
              style: TextStyle(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7))),
            onTap: () {
              // Open GitHub repository or show license info
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final brightness = Theme.of(context).brightness;
        
        return Column(
          children: [
            ListTile(
              leading: Icon(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: brightness == Brightness.dark ? Theme.of(context).colorScheme.primary : null
              ),
              title: Text(
                'Theme Mode',
                style: TextStyle(color: Theme.of(context).colorScheme.onBackground)
              ),
              subtitle: Text(
                themeProvider.isDarkMode ? 'Mocha (Dark)' : 'Latte (Light)',
                style: TextStyle(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7))
              ),
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleTheme();
                },
              ),
            ),
          ],
        );
      },
    );
  }
  
  // Theme color indicator no longer needed since we only have a simple toggle
}