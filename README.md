# Chinese Grammar Pattern Visualizer

A Flutter application designed to help Chinese language learners understand grammar patterns through visual representations.

## Features

- **Visual Grammar Breakdowns**: Interactive visualizations of Chinese grammar structures
- **Sentence Components**: Color-coded parts of speech for easy identification
- **Example Sentences**: Real-world examples with pinyin, translations, and detailed explanations
- **Difficulty Levels**: Grammar patterns organized by difficulty level
- **Search & Filtering**: Find patterns by category, difficulty, or keyword

## Grammar Patterns Included

- 把 (bǎ) Sentence Structure
- 是...的 (shì...de) Construction
- Topic-Comment Structure
- 比 (bǐ) Comparative Structure
- 被 (bèi) Passive Structure
- 了 (le) Particle Usage

## Technical Details

Built with Flutter using:
- Provider for state management
- JSON data storage for grammar patterns
- Custom animations and transitions
- Responsive design for multiple screen sizes
- Standardized font sizes for consistent UI

### Font Size Standards

The app uses a standardized font system to maintain consistency across all screens:

```dart
// Use the standardized font sizes from AppTheme
Text(
  'Example Text',
  style: AppTheme.bodyDefault(context),
)

// For headings
Text(
  'Heading Text',
  style: AppTheme.headingLarge(context),
)
```

See `docs/font_size_standards.md` for complete documentation.

## Getting Started

1. Clone this repository
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the application

## Future Enhancements

- Add more grammar patterns
- Implement interactive exercises
- Add audio pronunciation
- Support for offline usage
- User progress tracking
- Expand theme and design system
