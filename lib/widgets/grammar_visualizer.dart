import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class GrammarVisualizer extends StatelessWidget {
  final String structure;

  const GrammarVisualizer({
    super.key,
    required this.structure,
  });

  @override
  Widget build(BuildContext context) {
    // Parse the structure into components
    final components = _parseStructure(structure);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textLight.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVisualStructure(components),
          const SizedBox(height: 16),
          _buildLegend(components),
        ],
      ),
    );
  }

  List<String> _parseStructure(String structure) {
    // Split by + but keep the + as a separator
    final rawComponents = structure.split(' + ');
    final components = <String>[];
    
    for (var component in rawComponents) {
      // Clean up the component
      final cleanComponent = component.trim();
      if (cleanComponent.isNotEmpty) {
        components.add(cleanComponent);
      }
    }
    
    return components;
  }

  Widget _buildVisualStructure(List<String> components) {
    return Wrap(
      spacing: 8,
      runSpacing: 12,
      children: components.map((component) {
        // Determine color based on component type
        final color = _getComponentColor(component);
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.6),
              width: 1,
            ),
          ),
          child: Text(
            component,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLegend(List<String> components) {
    final uniqueComponents = components.toSet().toList();
    
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: uniqueComponents.map((component) {
        final color = _getComponentColor(component);
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              component,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Color _getComponentColor(String component) {
    final lowerComponent = component.toLowerCase();
    
    if (lowerComponent.contains('subject')) {
      return AppTheme.grammarColors['subject'] ?? Colors.orange;
    } else if (lowerComponent.contains('object')) {
      return AppTheme.grammarColors['object'] ?? Colors.purple;
    } else if (lowerComponent.contains('verb') || lowerComponent.contains('action')) {
      return AppTheme.grammarColors['verb'] ?? Colors.green;
    } else if (lowerComponent.contains('complement') || lowerComponent.contains('result')) {
      return AppTheme.grammarColors['complement'] ?? Colors.blue;
    } else if (lowerComponent.contains('adverb') || lowerComponent.contains('time')) {
      return AppTheme.grammarColors['adverb'] ?? Colors.lightBlue;
    } else if (lowerComponent.contains('adjective')) {
      return AppTheme.grammarColors['adjective'] ?? Colors.blue;
    } else if (lowerComponent.contains('marker') || lowerComponent.contains('particle')) {
      return AppTheme.grammarColors['marker'] ?? Colors.red;
    } else if (lowerComponent.contains('preposition')) {
      return AppTheme.grammarColors['preposition'] ?? Colors.orange;
    } else {
      // Default color
      return Colors.grey;
    }
  }
}

class AnimatedGrammarVisualizer extends StatefulWidget {
  final String structure;
  final Duration animationDuration;

  const AnimatedGrammarVisualizer({
    super.key,
    required this.structure,
    this.animationDuration = const Duration(milliseconds: 500),
  });

  @override
  State<AnimatedGrammarVisualizer> createState() => _AnimatedGrammarVisualizerState();
}

class _AnimatedGrammarVisualizerState extends State<AnimatedGrammarVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<String> _components;

  @override
  void initState() {
    super.initState();
    _components = _parseStructure(widget.structure);
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration * _components.length,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> _parseStructure(String structure) {
    final rawComponents = structure.split(' + ');
    final components = <String>[];
    
    for (var component in rawComponents) {
      final cleanComponent = component.trim();
      if (cleanComponent.isNotEmpty) {
        components.add(cleanComponent);
      }
    }
    
    return components;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textLight.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: List.generate(_components.length, (index) {
              final component = _components[index];
              final color = _getComponentColor(component);
              
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final componentDuration = widget.animationDuration;
                  final startTime = index * componentDuration.inMilliseconds / _controller.duration!.inMilliseconds;
                  final endTime = (index + 1) * componentDuration.inMilliseconds / _controller.duration!.inMilliseconds;
                  
                  final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _controller,
                      curve: Interval(startTime, endTime, curve: Curves.easeOut),
                    ),
                  );
                  
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.2, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1 * animation.value),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: color.withOpacity(0.6 * animation.value),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          component,
                          style: TextStyle(
                            color: color.withOpacity(animation.value),
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Color _getComponentColor(String component) {
    final lowerComponent = component.toLowerCase();
    
    if (lowerComponent.contains('subject')) {
      return AppTheme.grammarColors['subject'] ?? Colors.orange;
    } else if (lowerComponent.contains('object')) {
      return AppTheme.grammarColors['object'] ?? Colors.purple;
    } else if (lowerComponent.contains('verb') || lowerComponent.contains('action')) {
      return AppTheme.grammarColors['verb'] ?? Colors.green;
    } else if (lowerComponent.contains('complement') || lowerComponent.contains('result')) {
      return AppTheme.grammarColors['complement'] ?? Colors.blue;
    } else if (lowerComponent.contains('adverb') || lowerComponent.contains('time')) {
      return AppTheme.grammarColors['adverb'] ?? Colors.lightBlue;
    } else if (lowerComponent.contains('adjective')) {
      return AppTheme.grammarColors['adjective'] ?? Colors.blue;
    } else if (lowerComponent.contains('marker') || lowerComponent.contains('particle')) {
      return AppTheme.grammarColors['marker'] ?? Colors.red;
    } else if (lowerComponent.contains('preposition')) {
      return AppTheme.grammarColors['preposition'] ?? Colors.orange;
    } else {
      // Default color
      return Colors.grey;
    }
  }
}