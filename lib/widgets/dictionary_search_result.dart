import 'package:flutter/material.dart';
import '../models/dictionary_entry.dart';
import '../utils/pinyin_utils.dart';

class DictionarySearchResult extends StatelessWidget {
  final DictionaryEntry entry;
  final VoidCallback onTap;

  const DictionarySearchResult({
    Key? key, 
    required this.entry,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Convert numerical pinyin to diacritic pinyin
    final String formattedPinyin = PinyinUtils.toDiacriticPinyin(entry.pinyin);
    
    // Get first definition for preview
    final String firstDefinition = entry.definitions.isNotEmpty 
        ? entry.definitions.first 
        : '';
    
    // If there are more definitions, add an ellipsis
    final String definitionPreview = entry.definitions.length > 1
        ? '$firstDefinition ...'
        : firstDefinition;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      elevation: 2.0,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.ideographic,
                children: [
                  Text(
                    entry.simplified,
                    style: const TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  if (entry.traditional != entry.simplified)
                    Text(
                      '(${entry.traditional})',
                      style: const TextStyle(
                        fontSize: 16.0,
                        color: Colors.grey,
                      ),
                    ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 4.0),
              Text(
                formattedPinyin,
                style: const TextStyle(
                  fontSize: 16.0,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                definitionPreview,
                style: const TextStyle(
                  fontSize: 14.0,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}