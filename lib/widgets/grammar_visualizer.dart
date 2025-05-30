import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/catppuccin_theme.dart';
import '../services/color_service.dart';
import '../models/grammar_pattern.dart';
import '../utils/colors.dart';

class GrammarVisualizer extends StatefulWidget {
  final String structure;
  final List<StructurePart>? structureBreakdown;

  const GrammarVisualizer({
    super.key,
    required this.structure,
    this.structureBreakdown,
  });

  @override
  State<GrammarVisualizer> createState() => _GrammarVisualizerState();
}

class _GrammarVisualizerState extends State<GrammarVisualizer> {
  final ColorService _colorService = ColorService();
  Map<String, Color> _colors = {};
  bool _colorsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadColors();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safe to access Theme here
    PartOfSpeechColors.isDarkMode = Theme.of(context).brightness == Brightness.dark;
    _loadColors();
  }
  
  Future<void> _loadColors() async {
    _colors = await _colorService.getAllColors();
    if (mounted) {
      setState(() {
        _colorsLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Parse the structure into components
    final components = _parseStructure(widget.structure);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surfaceContainer
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.2),
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
    // If we have a structureBreakdown, use that instead of parsing the structure string
    if (widget.structureBreakdown != null && widget.structureBreakdown!.isNotEmpty) {
      return Wrap(
        spacing: 8,
        runSpacing: 12,
        children: widget.structureBreakdown!.map((part) {
          // Get color based on the part of speech
          final color = _colorsLoaded && _colors.containsKey(part.partOfSpeech.toLowerCase())
              ? _colors[part.partOfSpeech.toLowerCase()]!
              : _getComponentColor(part.text);
          
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
              part.text,
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
    
    // Fallback to the old method if no structureBreakdown is provided
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
    // If we have a structureBreakdown, use that for the legend
    if (widget.structureBreakdown != null && widget.structureBreakdown!.isNotEmpty) {
      return Wrap(
        spacing: 16,
        runSpacing: 8,
        children: widget.structureBreakdown!.map((part) {
          final color = _colorsLoaded && _colors.containsKey(part.partOfSpeech.toLowerCase())
              ? _colors[part.partOfSpeech.toLowerCase()]!
              : _getComponentColor(part.text);
          
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
                part.text + (part.description != null ? ' (${part.description})' : ''),
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
    
    // Fallback to the old method if no structureBreakdown is provided
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
    
    // If colors are loaded, use the centralized color system
    if (_colorsLoaded) {
      // Direct match
      if (_colors.containsKey(lowerComponent)) {
        return _colors[lowerComponent]!;
      }
      
      // Partial match
      for (final entry in _colors.entries) {
        if (lowerComponent.contains(entry.key.toLowerCase()) || 
            entry.key.toLowerCase().contains(lowerComponent)) {
          return entry.value;
        }
      }
      
      // Return default color if defined
      if (_colors.containsKey('default')) {
        return _colors['default']!;
      }
    }
    
    // Fallback to the theme-aware color system
    return PartOfSpeechColors.getColor(lowerComponent, context);
  }
}

class AnimatedGrammarVisualizer extends StatefulWidget {
  final String structure;
  final List<StructurePart>? structureBreakdown;
  final Duration animationDuration;

  const AnimatedGrammarVisualizer({
    super.key,
    required this.structure,
    this.structureBreakdown,
    this.animationDuration = const Duration(milliseconds: 500),
  });

  @override
  State<AnimatedGrammarVisualizer> createState() => _AnimatedGrammarVisualizerState();
}

class _AnimatedGrammarVisualizerState extends State<AnimatedGrammarVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<String> _components;
  final ColorService _colorService = ColorService();
  Map<String, Color> _colors = {};
  bool _colorsLoaded = false;

  @override
  void initState() {
    super.initState();
    // For backwards compatibility, parse the structure string if no breakdown is provided
    _components = _parseStructure(widget.structure);
    
    // Calculate the duration based on either components or structure breakdown
    final itemCount = widget.structureBreakdown?.length ?? _components.length;
    
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration * itemCount,
    );
    _controller.forward();
    _loadColors();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safe to access Theme here
    PartOfSpeechColors.isDarkMode = Theme.of(context).brightness == Brightness.dark;
    _loadColors();
  }
  
  Future<void> _loadColors() async {
    _colors = await _colorService.getAllColors();
    if (mounted) {
      setState(() {
        _colorsLoaded = true;
      });
    }
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
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surfaceContainer
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: widget.structureBreakdown != null
                ? _buildAnimatedStructureBreakdown()
                : _buildAnimatedComponents(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAnimatedStructureBreakdown() {
    return List.generate(widget.structureBreakdown!.length, (index) {
      final part = widget.structureBreakdown![index];
      final color = _colorsLoaded && _colors.containsKey(part.partOfSpeech.toLowerCase())
          ? _colors[part.partOfSpeech.toLowerCase()]!
          : _getComponentColor(part.text);
      
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
                  part.text,
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
    });
  }

  List<Widget> _buildAnimatedComponents() {
    return List.generate(_components.length, (index) {
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
    });
  }

  Color _getComponentColor(String component) {
    final lowerComponent = component.toLowerCase();
    
    // If colors are loaded, use the centralized color system
    if (_colorsLoaded) {
      // Direct match
      if (_colors.containsKey(lowerComponent)) {
        return _colors[lowerComponent]!;
      }
      
      // Partial match
      for (final entry in _colors.entries) {
        if (lowerComponent.contains(entry.key.toLowerCase()) || 
            entry.key.toLowerCase().contains(lowerComponent)) {
          return entry.value;
        }
      }
      
      // Return default color if defined
      if (_colors.containsKey('default')) {
        return _colors['default']!;
      }
    }
    
    // Fallback to the theme-aware color system
    return PartOfSpeechColors.getColor(lowerComponent, context);
  }
}