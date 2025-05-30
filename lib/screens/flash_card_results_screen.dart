import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/flash_card.dart';
import '../providers/flash_card_provider.dart';
import '../providers/word_list_provider.dart';
import 'flash_card_setup_screen.dart';

class FlashCardResultsScreen extends StatelessWidget {
  const FlashCardResultsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FlashCardProvider>(
      builder: (context, provider, child) {
        final session = provider.currentSession;
        
        if (session == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Session Results'),
            ),
            body: const Center(
              child: Text('No session data available'),
            ),
          );
        }
        
        final accuracy = session.accuracy;
        final correctCount = session.correctAnswers;
        final incorrectCount = session.incorrectAnswers;
        final totalReviewed = session.cardsReviewed;
        
        // Format duration
        final duration = session.duration;
        final minutes = duration.inMinutes;
        final seconds = duration.inSeconds % 60;
        final durationText = '$minutes:${seconds.toString().padLeft(2, '0')}';
        
        // Format date
        final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
        final dateText = dateFormat.format(session.startedAt);
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Session Results'),
            automaticallyImplyLeading: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with overall result
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Text(
                          accuracy >= 80 ? '👍 Great Job!' : 
                          accuracy >= 60 ? '👌 Good Effort!' : 
                          '🔄 Keep Practicing!',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'You scored ${accuracy.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 20,
                            color: _getAccuracyColor(accuracy),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Session completed on $dateText',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Session statistics
                const Text(
                  'Session Statistics',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatisticsCard(
                  context: context,
                  correctCount: correctCount,
                  incorrectCount: incorrectCount,
                  totalReviewed: totalReviewed,
                  duration: durationText,
                ),
                
                const SizedBox(height: 24),
                
                // Word lists studied
                const Text(
                  'Word Lists Studied',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildWordListsCard(context, session.wordListIds),
                
                const SizedBox(height: 32),
                
                // Call to action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Reset session and go back to setup
                          provider.resetSession();
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const FlashCardSetupScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('New Session'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Just reset the session and pop to previous screen
                          provider.resetSession();
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildStatisticsCard({
    required BuildContext context,
    required int correctCount,
    required int incorrectCount,
    required int totalReviewed,
    required String duration,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.check_circle,
                    iconColor: Colors.green,
                    label: 'Correct',
                    value: correctCount.toString(),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.cancel,
                    iconColor: Colors.red,
                    label: 'Incorrect',
                    value: incorrectCount.toString(),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.layers,
                    iconColor: Colors.blue,
                    label: 'Cards Reviewed',
                    value: totalReviewed.toString(),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.timer,
                    iconColor: Colors.orange,
                    label: 'Duration',
                    value: duration,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: iconColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
  
  Widget _buildWordListsCard(BuildContext context, List<String> wordListIds) {
    return Consumer<WordListProvider>(
      builder: (context, wordListProvider, child) {
        final wordLists = wordListIds
            .map((id) => wordListProvider.getWordListById(id))
            .where((list) => list != null)
            .toList();
        
        if (wordLists.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No word lists found'),
            ),
          );
        }
        
        return Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: wordLists.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final wordList = wordLists[index]!;
              return ListTile(
                title: Text(wordList.name),
                subtitle: Text('${wordList.entries.length} words'),
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    wordList.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
  
  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 80) {
      return Colors.green;
    } else if (accuracy >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}