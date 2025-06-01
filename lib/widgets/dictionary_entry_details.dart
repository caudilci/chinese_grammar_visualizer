import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dictionary_entry.dart';
import '../providers/tts_provider.dart';
import '../providers/word_list_provider.dart';
import '../utils/pinyin_utils.dart';
import '../utils/app_theme.dart';
import '../extensions/color_extension.dart';

class DictionaryEntryDetails extends StatelessWidget {
  final DictionaryEntry entry;
  final ScrollController? scrollController;
  final VoidCallback? onAddToList;

  const DictionaryEntryDetails({
    Key? key,
    required this.entry,
    this.scrollController,
    this.onAddToList,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize the word list provider if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WordListProvider>(context, listen: false).initialize();
    });

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surfaceContainer
            : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16.0),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[600]
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.simplified,
                                  style: AppTheme.headingXXLarge(
                                    context,
                                    weight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                if (entry.traditional != entry.simplified)
                                  Text(
                                    '(${entry.traditional})',
                                    style: AppTheme.headingLarge(
                                      context,
                                      weight: FontWeight.w300,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.8),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Consumer<TtsProvider>(
                            builder: (context, ttsProvider, _) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.volume_up),
                                    onPressed: ttsProvider.isSupported
                                        ? () {
                                            ttsProvider.speak(entry.simplified);
                                          }
                                        : null,
                                    tooltip: ttsProvider.isSupported
                                        ? 'Pronounce Chinese'
                                        : 'TTS not supported on this platform',
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    if (onAddToList != null)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.playlist_add),
                        label: const Text('Add to List'),
                        onPressed: onAddToList,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        PinyinUtils.toDiacriticPinyin(entry.pinyin),
                        style: AppTheme.headingMedium(
                          context,
                          weight: FontWeight.normal,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).colorScheme.primary
                              : Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox.shrink(), // No additional TTS buttons
                  ],
                ),
                const Divider(height: 32),
                Text(
                  'Definitions:',
                  style: AppTheme.bodyDefault(
                    context,
                    weight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                ...entry.definitions.map(
                  (definition) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      '• $definition',
                      style: AppTheme.bodyDefault(
                        context,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildWordListChips(context, entry),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build word list chips showing which lists this entry belongs to
  Widget _buildWordListChips(BuildContext context, DictionaryEntry entry) {
    return Consumer<WordListProvider>(
      builder: (context, provider, child) {
        final containingLists = provider.getListsContainingEntry(entry);

        if (!provider.isInitialized) {
          provider.initialize();
          return const SizedBox.shrink();
        }

        if (containingLists.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'In Word Lists:',
              style: AppTheme.bodyDefault(
                context,
                weight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: containingLists.map((list) {
                return Chip(
                  label: Text(list.name),
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () {
                    provider.removeEntryFromList(list.id, entry);
                  },
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  /// Static helper method to show the details in a modal bottom sheet
  static void showEntryDetailsModal(
    BuildContext context, 
    DictionaryEntry entry, 
    {VoidCallback? onAddToList}
  ) {
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
          return DictionaryEntryDetails(
            entry: entry,
            scrollController: controller,
            onAddToList: onAddToList,
          );
        },
      ),
    );
  }
}