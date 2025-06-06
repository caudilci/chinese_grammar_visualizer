import 'package:flutter/material.dart';

/// A reusable empty state widget that displays an icon, title, and optional subtitle
/// Use this when a screen or section has no data to display
class EmptyState extends StatelessWidget {
  /// The icon to display
  final IconData icon;
  
  /// Size of the icon
  final double iconSize;
  
  /// Color of the icon, defaults to a muted gray
  final Color? iconColor;
  
  /// The primary message to display
  final String title;
  
  /// An optional secondary message with more details
  final String? subtitle;
  
  /// Optional widget to display below the text, often an action button
  final Widget? action;
  
  /// Padding around the entire widget
  final EdgeInsets padding;

  const EmptyState({
    Key? key,
    required this.icon,
    this.iconSize = 64,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.action,
    this.padding = const EdgeInsets.all(24.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}