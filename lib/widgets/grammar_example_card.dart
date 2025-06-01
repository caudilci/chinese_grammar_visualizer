import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/grammar_pattern.dart';
import '../providers/tts_provider.dart';
import '../utils/app_theme.dart';
import '../utils/pinyin_utils.dart';

class GrammarExampleCard extends StatelessWidget {
  final GrammarExample example;
  final bool isAnimated;
  final bool showFocus;

  const GrammarExampleCard({
    Key? key,
    required this.example,
    this.isAnimated = false,
    this.showFocus = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    example.chineseSentence,
                    style: AppTheme.headingLarge(
                      context,
                      weight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Consumer<TtsProvider>(
                  builder: (context, ttsProvider, _) {
                    return IconButton(
                      icon: const Icon(Icons.volume_up),
                      onPressed: ttsProvider.isSupported
                          ? () {
                              ttsProvider.speak(example.chineseSentence);
                            }
                          : null,
                      tooltip: ttsProvider.isSupported
                          ? 'Pronounce Chinese'
                          : 'TTS not supported on this platform',
                      color: Theme.of(context).colorScheme.primary,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              PinyinUtils.toDiacriticPinyin(example.pinyinSentence),
              style: AppTheme.bodyDefault(
                context,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.primary
                    : Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    example.englishTranslation,
                    style: AppTheme.bodyDefault(
                      context,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox.shrink(), // Remove Pinyin TTS button
              ],
            ),
            if (showFocus && example.note != null && example.note!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        example.note!,
                        style: AppTheme.bodySmall(
                          context,
                          color: Theme.of(context).colorScheme.primary,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
