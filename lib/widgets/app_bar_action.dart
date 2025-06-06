import 'package:flutter/material.dart';

/// A reusable action button for app bars
class AppBarAction extends StatelessWidget {
  /// The icon to display
  final IconData icon;
  
  /// The tooltip text to show on hover/long press
  final String tooltip;
  
  /// The callback function when the button is pressed
  final VoidCallback? onPressed;
  
  /// Optional color for the icon, defaults to the current IconTheme color
  final Color? color;
  
  /// Optional size for the icon, defaults to 24.0
  final double size;

  const AppBarAction({
    Key? key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.size = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        icon,
        color: color,
        size: size,
      ),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}