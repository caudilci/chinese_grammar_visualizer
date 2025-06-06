import 'package:flutter/material.dart';

/// A simple loading indicator widget that shows a centered circular progress indicator
class LoadingIndicator extends StatelessWidget {
  /// Size of the loading indicator
  final double size;
  
  /// Color of the loading indicator, defaults to the primary color of the theme
  final Color? color;
  
  /// Optional text to display below the indicator
  final String? text;
  
  /// Text style for the optional text
  final TextStyle? textStyle;
  
  const LoadingIndicator({
    Key? key,
    this.size = 40.0,
    this.color,
    this.text,
    this.textStyle,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final defaultColor = Theme.of(context).colorScheme.primary;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(color ?? defaultColor),
            strokeWidth: 3.0,
          ),
        ),
        if (text != null) ...[
          const SizedBox(height: 16),
          Text(
            text!,
            style: textStyle ?? TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}