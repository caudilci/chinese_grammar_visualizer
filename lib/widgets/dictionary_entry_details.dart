import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stroke_order_animator/stroke_order_animator.dart';
import 'package:http/http.dart' as http;

import '../models/dictionary_entry.dart';
import '../providers/tts_provider.dart';
import '../providers/word_list_provider.dart';
import '../providers/language_provider.dart';
import '../utils/pinyin_utils.dart';
import '../utils/app_theme.dart';
import '../widgets/word_list_selector.dart';

/// A custom widget that handles stroke order animation and practice
/// while preventing scrolling conflicts with the parent scrollable sheet
class StrokeOrderDrawingContainer extends StatefulWidget {
  final StrokeOrderAnimationController controller;
  final String character;
  final bool inPracticeMode;
  final ScrollController? scrollController;

  const StrokeOrderDrawingContainer({
    Key? key,
    required this.controller,
    required this.character,
    required this.inPracticeMode,
    this.scrollController,
  }) : super(key: key);

  @override
  State<StrokeOrderDrawingContainer> createState() => _StrokeOrderDrawingContainerState();
}

class _StrokeOrderDrawingContainerState extends State<StrokeOrderDrawingContainer> {
  bool _isDrawing = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      // This listener will capture pointer events before they can be
      // interpreted as scroll gestures by parent scrollable widgets
      onPointerDown: (event) {
        if (widget.inPracticeMode) {
          setState(() => _isDrawing = true);
          _lockScroll();
        }
      },
      onPointerUp: (event) {
        if (widget.inPracticeMode) {
          setState(() => _isDrawing = false);
        }
      },
      onPointerCancel: (event) {
        if (widget.inPracticeMode) {
          setState(() => _isDrawing = false);
        }
      },
      onPointerMove: (event) {
        if (widget.inPracticeMode && _isDrawing) {
          _lockScroll();
        }
      },
      // Important: use opaque to ensure we get ALL events
      behavior: HitTestBehavior.opaque,
      child: GestureDetector(
        // Double tap for hint
        onDoubleTap: widget.inPracticeMode ? () => widget.controller.animateHint() : null,
        child: StrokeOrderAnimator(
          widget.controller,
          size: const Size(200, 200),
          key: ValueKey('${widget.character}-${widget.inPracticeMode}'),
        ),
      ),
    );
  }

  void _lockScroll() {
    if (widget.scrollController != null && widget.scrollController!.hasClients) {
      widget.scrollController!.jumpTo(widget.scrollController!.offset);
    }
  }
}

class DictionaryEntryDetails extends StatefulWidget {
  final DictionaryEntry entry;
  final ScrollController? scrollController;
  final VoidCallback? onAddToList;

  const DictionaryEntryDetails({
    Key? key,
    required this.entry,
    this.scrollController,
    this.onAddToList,
  }) : super(key: key);

  /// Static helper method to show the details in a modal bottom sheet
  static void showEntryDetailsModal(
    BuildContext context, 
    DictionaryEntry entry, 
    {VoidCallback? onAddToList}
  ) {
    // Initialize the provider before showing the modal to prevent UI flicker
    Provider.of<WordListProvider>(context, listen: false).initialize();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
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
            onAddToList: onAddToList ?? () {
              showWordListSelection(context, entry);
            },
          );
        },
      ),
    );
  }
  
  /// Static helper method to show the word list selection dialog
  static void showWordListSelection(
    BuildContext context,
    DictionaryEntry entry,
  ) {
    // Initialize the provider before showing the modal to prevent UI flicker
    Provider.of<WordListProvider>(context, listen: false).initialize();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.surfaceContainer
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: WordListSelector(entry: entry),
        );
      },
    );
  }


  @override
  State<DictionaryEntryDetails> createState() => _DictionaryEntryDetailsState();
}

class _DictionaryEntryDetailsState extends State<DictionaryEntryDetails> with TickerProviderStateMixin {
  bool _showStrokeOrder = false;
  bool _practiceMode = false;
  final _httpClient = http.Client();
  StrokeOrderAnimationController? _animationController;
  String _currentCharacter = '';
  bool _isLoadingStrokeOrder = false;
  
  @override
  void initState() {
    super.initState();
    // Initialize the word list provider once when widget is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<WordListProvider>(context, listen: false).initialize();
      }
    });
  }

  @override
  void dispose() {
    _httpClient.close();
    if (_animationController != null) {
      _animationController?.stopAnimation();
      _animationController?.stopQuiz();
      _animationController?.dispose();
      _animationController = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            color: Colors.black.withOpacity(0.3),
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
              // Disable scrolling when in practice mode to prevent gesture conflicts
              physics: _practiceMode ? const NeverScrollableScrollPhysics() : null,
              controller: widget.scrollController,
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
                                Consumer<LanguageProvider>(
                                  builder: (context, languageProvider, _) {
                                    final primary = languageProvider.useTraditionalCharacters
                                        ? widget.entry.traditional
                                        : widget.entry.simplified;
                                    final secondary = languageProvider.useTraditionalCharacters
                                        ? widget.entry.simplified
                                        : widget.entry.traditional;
                                    final showSecondary = primary != secondary;
                                        
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          primary,
                                          style: AppTheme.headingXXLarge(
                                            context,
                                            weight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                        if (showSecondary)
                                          Text(
                                            '($secondary)',
                                            style: AppTheme.headingLarge(
                                              context,
                                              weight: FontWeight.w300,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.8),
                                            ),
                                          ),
                                      ],
                                    );
                                  }
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
                                            final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
                                            ttsProvider.speak(languageProvider.useTraditionalCharacters
                                                ? widget.entry.traditional
                                                : widget.entry.simplified);
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
                    if (widget.onAddToList != null)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.playlist_add),
                        label: const Text('Add to List'),
                        onPressed: widget.onAddToList,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        PinyinUtils.toDiacriticPinyin(widget.entry.pinyin),
                        style: AppTheme.headingMedium(
                          context,
                          weight: FontWeight.normal,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).colorScheme.primary
                              : Colors.blue,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _showStrokeOrder ? Icons.brush_outlined : Icons.brush,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        setState(() {
                          _showStrokeOrder = !_showStrokeOrder;
                          if (_showStrokeOrder) {
                            _loadCharacterStrokeOrder();
                          } else {
                            // Reset practice mode when closing stroke order view
                            _practiceMode = false;
                          }
                        });
                      },
                      tooltip: _showStrokeOrder ? 'Hide stroke order' : 'Show stroke order',
                    ),
                  ],
                ),
                if (_showStrokeOrder) _buildStrokeOrderView(context),
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
                ...widget.entry.definitions.map(
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
                _buildWordListChips(context, widget.entry),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Load stroke order data for the current character
  void _loadCharacterStrokeOrder() {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final character = languageProvider.useTraditionalCharacters
        ? widget.entry.traditional
        : widget.entry.simplified;
    
    // If the entry contains multiple characters, we'll only show the first one
    final firstChar = character.isNotEmpty ? character[0] : '';
    
    if (firstChar.isNotEmpty && (firstChar != _currentCharacter || _animationController == null)) {
      _currentCharacter = firstChar;
      // Dispose previous controller if exists
      _animationController?.dispose();
      
      // Set loading state
      setState(() {
        _isLoadingStrokeOrder = true;
        _practiceMode = false; // Reset practice mode when loading a new character
      });
      
      // Load the stroke order data
      downloadStrokeOrder(firstChar, _httpClient).then((value) {
        if (mounted) {
          setState(() {
            _isLoadingStrokeOrder = false;
            _animationController = StrokeOrderAnimationController(
              StrokeOrder(value),
              this,
              onQuizCompleteCallback: (summary) {
                setState(() {
                  _practiceMode = false;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Practice completed with ${summary.nTotalMistakes} mistakes',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  );
                });
              },
              onCorrectStrokeCallback: (_) {
                // Optional: add feedback for correct strokes
              },
              onWrongStrokeCallback: (_) {
                // Optional: add feedback for wrong strokes
              },
            );
            
            // Set theme colors
            _animationController?.setStrokeColor(Theme.of(context).colorScheme.primary);
            _animationController?.setOutlineColor(Theme.of(context).colorScheme.outline);
            _animationController?.setMedianColor(Theme.of(context).colorScheme.secondary.withOpacity(0.5));
            _animationController?.setRadicalColor(Theme.of(context).colorScheme.tertiary);
            _animationController?.setHintColor(Theme.of(context).colorScheme.tertiary.withOpacity(0.7));
            _animationController?.setBrushColor(Theme.of(context).colorScheme.primary);
            
            // Configure hint behavior - show hint after 3 wrong strokes
            _animationController?.setHintAfterStrokes(3);
            
            // Start the animation automatically
            _animationController?.startAnimation();
          });
        }
      }).catchError((error) {
        print('Error loading stroke order data: $error');
        if (mounted) {
          setState(() {
            _isLoadingStrokeOrder = false;
          });
        }
      });
    }
  }

  /// Build stroke order animator for the current character
  Widget _buildStrokeOrderView(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final character = languageProvider.useTraditionalCharacters
        ? widget.entry.traditional
        : widget.entry.simplified;
    
    // If the entry contains multiple characters, we'll only show the first one
    // as the stroke order animator only works with single characters
    final firstChar = character.isNotEmpty ? character[0] : '';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stroke Order:',
            style: AppTheme.bodyDefault(
              context,
              weight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: firstChar.isEmpty
                  ? Center(
                      child: Text(
                        'No character available',
                        style: AppTheme.bodyDefault(
                          context,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    )
                  : _isLoadingStrokeOrder
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : _animationController == null
                          ? Center(
                              child: Text(
                                'Character data not found',
                                style: AppTheme.bodyDefault(
                                  context,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            )
                          : StrokeOrderDrawingContainer(
                              controller: _animationController!,
                              character: firstChar,
                              inPracticeMode: _practiceMode,
                              scrollController: widget.scrollController,
                            ),
            ),
          ),
          if (_animationController != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.restart_alt,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () => _animationController?.reset(),
                        tooltip: 'Reset animation',
                      ),
                      if (!_practiceMode)
                        IconButton(
                          icon: Icon(
                            Icons.play_arrow,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () => _animationController?.startAnimation(),
                          tooltip: 'Play animation',
                        ),
                      if (!_practiceMode)
                        IconButton(
                          icon: Icon(
                            Icons.stop,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () => _animationController?.stopAnimation(),
                          tooltip: 'Stop animation',
                        ),
                      IconButton(
                        icon: Icon(
                          _practiceMode ? Icons.edit_off : Icons.edit,
                          color: _practiceMode 
                              ? Theme.of(context).colorScheme.tertiary
                              : Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () {
                          setState(() {
                            _practiceMode = !_practiceMode;
                            if (_practiceMode) {
                              // Prevent scrolling when entering practice mode
                              if (widget.scrollController != null) {
                                widget.scrollController!.jumpTo(widget.scrollController!.offset);
                              }
                              
                              _animationController?.stopAnimation();
                              _animationController?.startQuiz();
                              
                              // Show instruction to the user
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Practice mode enabled. Draw the strokes in order.',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                    ),
                                  ),
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            } else {
                              _animationController?.stopQuiz();
                              // Reset the controller to clear user strokes
                              _animationController?.reset();
                            }
                          });
                        },
                        tooltip: _practiceMode ? 'Exit practice mode' : 'Practice writing',
                      ),
                    ],
                  ),
                  if (_practiceMode)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        children: [
                          Text(
                            'Draw the strokes in the correct order',
                            style: AppTheme.bodySmall(
                              context,
                              color: Theme.of(context).colorScheme.secondary,
                              weight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Double-tap for hints when you get stuck',
                            style: AppTheme.caption(
                              context,
                              color: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                              weight: FontWeight.normal,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // Show the next stroke as a hint
                              _animationController?.animateHint();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.secondary,
                              foregroundColor: Theme.of(context).colorScheme.onSecondary,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: const Size(120, 36),
                            ),
                            child: const Text('Show Hint'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          if (character.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Note: Only showing stroke order for the first character.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
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

        // Just return empty widget if not initialized yet - we're already initializing in initState
        if (!provider.isInitialized) {
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
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
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
}