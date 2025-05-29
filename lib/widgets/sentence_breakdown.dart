import 'package:flutter/material.dart';
import '../models/grammar_pattern.dart';
import '../utils/app_theme.dart';
import '../services/color_service.dart';
import '../utils/dictionary_utils.dart';

class SentenceBreakdown extends StatefulWidget {
  final List<SentencePart> parts;
  final Map<String, String>? colorCoding;

  const SentenceBreakdown({
    super.key,
    required this.parts,
    this.colorCoding,
  });

  @override
  State<SentenceBreakdown> createState() => _SentenceBreakdownState();
}

class _SentenceBreakdownState extends State<SentenceBreakdown> {
  int? _selectedPartIndex;
  final ColorService _colorService = ColorService();
  Map<String, Color> _colors = {};
  bool _colorsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadColors();
  }
  
  Future<void> _loadColors() async {
    _colors = await _colorService.getAllColors();
    setState(() {
      _colorsLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSentenceVisualization(),
        const SizedBox(height: 16),
        if (_selectedPartIndex != null) _buildDetailPanel(),
      ],
    );
  }

  Widget _buildSentenceVisualization() {
    return Wrap(
      spacing: 4,
      runSpacing: 8,
      children: List.generate(widget.parts.length, (index) {
        final part = widget.parts[index];
        final isSelected = _selectedPartIndex == index;
        
        // Get color based on part of speech instead of grammar function
        Color componentColor = const Color(0xFF009688); // Teal default color
        if (_colorsLoaded) {
          // First try to get color by part of speech
          if (part.partOfSpeech.isNotEmpty && _colors.containsKey(part.partOfSpeech.toLowerCase())) {
            componentColor = _colors[part.partOfSpeech.toLowerCase()]!;
          } 
          // If not found, try to match by grammar function 
          else if (part.grammarFunction != null && _colors.containsKey(part.grammarFunction!.toLowerCase())) {
            componentColor = _colors[part.grammarFunction!.toLowerCase()]!;
          }
          // If still not found, try partial matching
          else {
            for (final entry in _colors.entries) {
              if ((part.partOfSpeech.toLowerCase().contains(entry.key) || 
                  entry.key.contains(part.partOfSpeech.toLowerCase())) ||
                  (part.grammarFunction != null && 
                   (part.grammarFunction!.toLowerCase().contains(entry.key) || 
                    entry.key.contains(part.grammarFunction!.toLowerCase())))) {
                componentColor = entry.value;
                break;
              }
            }
          }
        } 
        // Legacy fallback
        else if (widget.colorCoding != null && part.grammarFunction != null && 
                 widget.colorCoding!.containsKey(part.grammarFunction)) {
          componentColor = HexColor.fromHex(widget.colorCoding![part.grammarFunction]!);
        }
        
        return InkWell(
          onTap: () {
            setState(() {
              if (_selectedPartIndex == index) {
                _selectedPartIndex = null;
              } else {
                _selectedPartIndex = index;
              }
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected 
                ? componentColor.withOpacity(0.3)
                : componentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected 
                  ? componentColor 
                  : componentColor.withOpacity(0.5),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  part.text,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? componentColor : AppTheme.chineseCharColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  part.pinyin,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? componentColor : AppTheme.pinyinColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDetailPanel() {
    if (_selectedPartIndex == null || _selectedPartIndex! >= widget.parts.length) {
      return const SizedBox.shrink();
    }
    
    // Ensure colors are loaded
    if (!_colorsLoaded && mounted) {
      _loadColors();
    }
    
    final part = widget.parts[_selectedPartIndex!];
    Color componentColor = const Color(0xFF009688); // Teal default color
    
    if (_colorsLoaded) {
      // First try to get color by part of speech
      if (part.partOfSpeech.isNotEmpty && _colors.containsKey(part.partOfSpeech.toLowerCase())) {
        componentColor = _colors[part.partOfSpeech.toLowerCase()]!;
      } 
      // If not found, try to match by grammar function 
      else if (part.grammarFunction != null && _colors.containsKey(part.grammarFunction!.toLowerCase())) {
        componentColor = _colors[part.grammarFunction!.toLowerCase()]!;
      }
      // If still not found, try partial matching
      else {
        for (final entry in _colors.entries) {
          if ((part.partOfSpeech.toLowerCase().contains(entry.key) || 
              entry.key.contains(part.partOfSpeech.toLowerCase())) ||
              (part.grammarFunction != null && 
               (part.grammarFunction!.toLowerCase().contains(entry.key) || 
                entry.key.contains(part.grammarFunction!.toLowerCase())))) {
            componentColor = entry.value;
            break;
          }
        }
      }
    } 
    // Legacy fallback
    else if (widget.colorCoding != null && part.grammarFunction != null && 
             widget.colorCoding!.containsKey(part.grammarFunction)) {
      componentColor = HexColor.fromHex(widget.colorCoding![part.grammarFunction]!);
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: componentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: componentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: componentColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  part.grammarFunction ?? 'Unknown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  part.partOfSpeech,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chinese Character',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      part.text,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pinyin',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      part.pinyin,
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppTheme.pinyinColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (part.meaning != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Meaning',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.menu_book, size: 16),
                  label: const Text('Dictionary', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    DictionaryUtils.findAndShowDictionaryEntry(context, part);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              part.meaning!,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (part.grammarFunction != null) ...[
            const Text(
              'Grammatical Function',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getFunctionDescription(part.grammarFunction!),
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.menu_book),
            label: const Text('Open in Dictionary'),
            onPressed: () {
              DictionaryUtils.findAndShowDictionaryEntry(context, part);
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(36),
              side: BorderSide(color: componentColor),
              foregroundColor: componentColor,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getFunctionDescription(String grammarFunction) {
    // Simple mapping of grammar functions to descriptions
    final descriptions = {
      'subject': 'The subject is the doer of the action in the sentence.',
      'object': 'The object receives the action in the sentence.',
      'action': 'The action verb describes what is happening in the sentence.',
      'verb': 'The verb describes what is happening in the sentence.',
      'marker': 'A grammar marker that indicates a specific grammatical feature.',
      'emphasis marker 1': 'First part of the emphasis structure.',
      'emphasis marker 2': 'Second part of the emphasis structure.',
      'time (emphasized)': 'The emphasized time when an action occurs.',
      'method (emphasized)': 'The emphasized method or means of an action.',
      'topic': 'The topic sets what the sentence is about.',
      'determiner': 'Specifies which item is being referred to.',
      'time adverb': 'Describes when an action takes place.',
      'aspect marker (experience)': 'Indicates that an action has been experienced before.',
      'completion marker': 'Indicates that an action is completed.',
      'degree modifier': 'Shows the extent or degree of something.',
      'predicate': 'The part of the sentence that makes a statement about the subject.',
      'comparison marker': 'Indicates a comparison between two things.',
      'object of comparison': 'The thing being compared against.',
      'comparative quality': 'The quality being compared.',
      'degree complement': 'Shows the extent of a comparison or quality.',
      'passive marker': 'Indicates that the subject is being acted upon.',
      'agent': 'The doer of the action in a passive sentence.',
      'subject (affected)': 'The subject that receives or is affected by the action.',
      'possessive': 'Shows ownership or possession.',
      'time': 'Indicates when an action takes place.',
      'change of state marker': 'Shows that a situation has changed.',
      'quantity': 'Indicates an amount or number.',
    };
    
    return descriptions[grammarFunction] ?? 
      'This part functions as the $grammarFunction in the sentence.';
  }
}

// Extension to convert hex color strings to Color objects
extension HexColor on Color {
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length <= 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}