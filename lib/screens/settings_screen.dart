import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/tts_provider.dart';
import '../utils/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        titleTextStyle: AppTheme.appBarTitleStyle(),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Appearance'),
          _buildThemeSelector(context),
          const Divider(),
          _buildSectionHeader(context, 'Text-to-Speech'),
          _buildTtsSettings(context),
          const Divider(),
          _buildSectionHeader(context, 'About'),
          ListTile(
            leading: Icon(
              Icons.info_outline,
              color: brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            title: Text(
              'App Version',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            subtitle: Text(
              '1.0.0',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.code,
              color: brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            title: Text(
              'Open Source',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            subtitle: Text(
              'This app is open source.',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
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
                color: brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(
                'Theme Mode',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                themeProvider.isDarkMode ? 'Mocha (Dark)' : 'Latte (Light)',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
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
  
  Widget _buildTtsSettings(BuildContext context) {
    return Consumer<TtsProvider>(
      builder: (context, ttsProvider, _) {
        final brightness = Theme.of(context).brightness;
        
        // Check platform support
        bool isUnsupportedPlatform = false;
        
        try {
          if (!io.Platform.isAndroid && !io.Platform.isIOS) {
            isUnsupportedPlatform = true;
          }
        } catch (e) {
          // If Platform check fails (like on web), mark as unsupported
          isUnsupportedPlatform = true;
        }
        
        if (isUnsupportedPlatform || !ttsProvider.isSupported) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  'Chinese Text-to-Speech is not supported on this platform',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Chinese TTS is only available on Android and iOS devices.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        return Column(
          children: [
            ListTile(
              leading: Icon(
                Icons.speed,
                color: brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(
                'Speech Rate',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                'Adjust how fast text is spoken',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Text('Slow'),
                  Expanded(
                    child: Slider(
                      value: ttsProvider.speechRate,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      label: ttsProvider.speechRate.toStringAsFixed(1),
                      onChanged: (value) {
                        ttsProvider.setSpeechRate(value);
                      },
                    ),
                  ),
                  const Text('Fast'),
                ],
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.tune,
                color: brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(
                'Pitch',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                'Adjust the tone of the voice',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Text('Low'),
                  Expanded(
                    child: Slider(
                      value: ttsProvider.pitch,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      label: ttsProvider.pitch.toStringAsFixed(1),
                      onChanged: (value) {
                        ttsProvider.setPitch(value);
                      },
                    ),
                  ),
                  const Text('High'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.record_voice_over),
                label: const Text('Test Voice'),
                onPressed: () {
                  ttsProvider.speak('你好，这是中文语音合成测试');
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Chinese TTS is active on ${io.Platform.isAndroid ? 'Android' : 'iOS'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
