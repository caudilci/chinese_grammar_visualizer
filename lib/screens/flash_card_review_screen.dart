import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/flash_card.dart';
import '../providers/flash_card_provider.dart';
import '../utils/pinyin_utils.dart';
import 'flash_card_results_screen.dart';

class FlashCardReviewScreen extends StatefulWidget {
  const FlashCardReviewScreen({Key? key}) : super(key: key);

  @override
  State<FlashCardReviewScreen> createState() => _FlashCardReviewScreenState();
}

class _FlashCardReviewScreenState extends State<FlashCardReviewScreen> with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _animation;
  
  bool _isAnswerShown = false;
  bool _isAnimating = false;
  String? _previousCardId;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeInOut,
      ),
    );
    
    _animation!.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        setState(() {
          _isAnswerShown = !_isAnswerShown;
          _isAnimating = false;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isAnimating || _animationController == null) return;
    
    setState(() {
      _isAnimating = true;
    });
    
    if (_isAnswerShown) {
      _animationController!.reverse();
    } else {
      _animationController!.forward();
    }
  }
  
  // Reset the card state when a new card appears
  void _resetCardState() {
    if (!mounted) return;
    
    setState(() {
      _isAnswerShown = false;
    });
    
    if (_animationController != null) {
      _animationController!.reset();
    }
  }

  void _markCard(BuildContext context, bool isCorrect) {
    if (!mounted) return;
    
    final provider = Provider.of<FlashCardProvider>(context, listen: false);
    
    // Reset the animation state before marking the card
    setState(() {
      _isAnswerShown = false;
    });
    
    if (_animationController != null) {
      _animationController!.reset();
    }
    
    // Mark the card first
    provider.markCard(isCorrect);
    
    // Check completion state after animation completes
    if (provider.currentSession?.isCompleted == true) {
      // Add a small delay to let the UI update
      Future.microtask(() {
        if (mounted) {
          _showResults();
        }
      });
    }
  }

  void _endSession() {
    final provider = Provider.of<FlashCardProvider>(context, listen: false);
    provider.endSession();
    _showResults();
  }
  
  void _showResults() {
    // Ensure we don't call this multiple times
    if (!mounted) return;
    
    // Use pushAndRemoveUntil to prevent returning to an empty session
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const FlashCardResultsScreen(),
      ),
      (route) => route.isFirst, // Keep only the first route (main screen)
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sync animation with state without modifying it during build
    // (animation values should be set in initState, didUpdateWidget, or setState callbacks)
    
    return Consumer<FlashCardProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (!provider.isSessionActive) {
          // If session is complete but we're still on this screen, show results
          if (provider.currentSession?.isCompleted == true) {
            // Use a post-frame callback to avoid build issues
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showResults();
            });
            return const Center(child: CircularProgressIndicator());
          }
            
          return Scaffold(
            appBar: AppBar(
              title: const Text('Flash Cards'),
            ),
            body: const Center(
              child: Text('No active session'),
            ),
          );
        }
          
        // Store the current card ID to detect changes
        final String? currentCardId = provider.currentCard != null 
            ? '${provider.currentCard!.entry.simplified}:${provider.currentCard!.entry.pinyin}:${provider.sessionProgress}'
            : null;
            
        // Store card ID for comparison, but don't reset during build
        if (currentCardId != null && _previousCardId != currentCardId) {
          // Just store the ID - we'll handle the state reset after build
          _previousCardId = currentCardId;
          
          // Schedule a post-frame callback to handle the card state reset
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _resetCardState();
            }
          });
        }
        
        final currentCard = provider.currentCard;
          
        if (currentCard == null) {
          // This shouldn't happen anymore with the fix for repeating cards,
          // but we'll keep this as a fallback
          return Scaffold(
            appBar: AppBar(
              title: const Text('Flash Cards'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No cards available for this session'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _endSession,
                    child: const Text('End Session'),
                  ),
                ],
              ),
            ),
          );
        }
        
        final progress = provider.sessionProgress;
        final total = provider.sessionTotal;
        // Store the current card in a local final variable to prevent issues
        // Store the current card and ensure it's not null
        final flashCard = currentCard!;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Flash Cards'),
            actions: [
              TextButton(
                onPressed: _endSession,
                child: const Text(
                  'End Session',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Progress indicator - always show it
              Stack(
                children: [
                  LinearProgressIndicator(
                    value: provider.currentSession?.isEndless == true ? null : (total > 0 ? progress / total : null),
                    backgroundColor: Colors.grey[200],
                    color: Theme.of(context).primaryColor,
                    minHeight: 6,
                  ),
                  if (provider.sessionCards.length < total && provider.sessionCards.isNotEmpty && !provider.currentSession!.isEndless)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.orange[300]!,
                              width: 1.5,
                              style: BorderStyle.solid,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text(
                      provider.currentSession?.isEndless == true
                          ? 'Endless Mode - Card ${progress + 1}'
                          : 'Card ${progress + 1} of $total',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (provider.sessionCards.length < total && provider.sessionCards.isNotEmpty && !provider.currentSession!.isEndless)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(color: Colors.orange[300]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.repeat, size: 12, color: Colors.orange[800]),
                            const SizedBox(width: 4),
                            Text(
                              'Repeating words due to limited vocabulary',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              
              // Card area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GestureDetector(
                    onTap: _flipCard,
                    child: AnimatedBuilder(
                      animation: _animation!,
                      builder: (context, child) {
                        final value = _animation!.value;
                        final angle = value * 3.1415;
                        final transform = Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle);
                        return Transform(
                          transform: transform,
                          alignment: Alignment.center,
                          child: angle < 1.57
                              ? _buildCardFront(flashCard)
                              : Transform(
                                  transform: Matrix4.identity()..rotateY(3.1415),
                                  alignment: Alignment.center,
                                  child: _buildCardBack(flashCard),
                                ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              
              // Control buttons
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildAnswerButtons(provider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardFront(FlashCard card) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [Color(0xFF1E1E2E), Color(0xFF313244)]
                : [Colors.white, Colors.blue.shade50],
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Text(
              card.entry.simplified,
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            if (card.entry.traditional != card.entry.simplified)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '(${card.entry.traditional})',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Tap to flip',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack(FlashCard card) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [Color(0xFF1E1E2E), Color(0xFF313244)]
                : [Colors.white, Colors.amber.shade50],
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Text(
              PinyinUtils.toDiacriticPinyin(card.entry.pinyin),
              style: TextStyle(
                fontSize: 28,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Color(0xFF89B4FA) // Catppuccin mocha blue
                    : Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Text(
              'Meaning:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[300]
                    : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: card.entry.definitions.map(
                    (definition) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        '• $definition',
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ).toList(),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Tap to flip back',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }



  Widget _buildAnswerButtons(FlashCardProvider provider) {
    // Now we pass the provider directly from build method
    final bool hasActiveSession = provider.isSessionActive;
    final bool hasMoreCards = provider.hasMoreCards;
        
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: hasActiveSession && hasMoreCards ? () => _markCard(context, false) : null,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledForegroundColor: Colors.white.withOpacity(0.5),
                disabledBackgroundColor: Colors.red.withOpacity(0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.close, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Didn\'t Know',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: hasActiveSession && hasMoreCards ? () => _markCard(context, true) : null,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledForegroundColor: Colors.white.withOpacity(0.5),
                disabledBackgroundColor: Colors.green.withOpacity(0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Knew It',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
    );
  }
}