import 'package:flutter/material.dart';

extension ColorExtension on Color {
  /// Returns a new color that matches this color with the alpha value changed.
  /// Alpha values are clamped to the range 0-255.
  Color withValues({int? red, int? green, int? blue, double? alpha}) {
    return Color.fromARGB(
      alpha != null ? (alpha * 255).round().clamp(0, 255) : this.alpha,
      red ?? this.red,
      green ?? this.green,
      blue ?? this.blue,
    );
  }
}