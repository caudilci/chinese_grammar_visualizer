# Font Size Standards for Chinese Grammar Visualizer

This document outlines the standardized font sizes to be used throughout the Chinese Grammar Visualizer application. These standards have been established to ensure consistency, improved readability, and a unified look and feel across all screens.

## Font Size Constants

All font size constants are defined in `lib/utils/app_theme.dart` and should be referenced from there. Never hardcode font sizes in your UI components.

| Constant Name | Size (dp) | Usage |
|---------------|-----------|-------|
| `fontSizeXXLarge` | 32.0 | Main headers, large Chinese characters display |
| `fontSizeXLarge` | 28.0 | Very large headers, prominent information |
| `fontSizeLarge` | 24.0 | Large headers, standard Chinese characters |
| `fontSizeMediumLarge` | 20.0 | Medium-large text, section headers, app bar titles |
| `fontSizeMedium` | 18.0 | Medium text, list item headers |
| `fontSizeDefault` | 16.0 | Default body text size |
| `fontSizeSmall` | 14.0 | Small text, secondary information |
| `fontSizeXSmall` | 12.0 | Very small text, captions, hints |
| `fontSizeXXSmall` | 10.0 | Smallest text, used sparingly |

## Usage Guidelines

### How to Use Font Sizes

Instead of specifying font sizes directly, use the helper methods provided in `AppTheme`:

```dart
// Instead of this:
Text(
  'Hello World',
  style: TextStyle(
    fontSize: 16.0,
    color: Theme.of(context).colorScheme.onSurface,
  ),
)

// Do this:
Text(
  'Hello World',
  style: AppTheme.bodyDefault(context),
)

// Or with custom color:
Text(
  'Hello World',
  style: AppTheme.bodyDefault(
    context, 
    color: Theme.of(context).colorScheme.primary
  ),
)

// For app bar titles:
appBar: AppBar(
  title: const Text('Screen Title'),
  titleTextStyle: AppTheme.appBarTitleStyle(),
),
```

### Text Style Helpers

The `AppTheme` class provides several helper methods for common text styles:

#### App Bar Title Style
- `appBarTitleStyle({color, weight})` - Standard style for app bar titles (does not require context)

#### Heading Styles
- `headingXXLarge(context, {color, weight})`
- `headingXLarge(context, {color, weight})`
- `headingLarge(context, {color, weight})`
- `headingMedium(context, {color, weight})`

#### Body Text Styles
- `bodyLarge(context, {color, weight})`
- `bodyDefault(context, {color, weight})`
- `bodySmall(context, {color, weight})`

#### Caption and Label Styles
- `caption(context, {color, weight})`
- `labelSmall(context, {color, weight})`

### Specialized Text Styles

For Chinese language specific text, use these predefined styles:

- `AppTheme.chineseTextStyle` - For Chinese characters
- `AppTheme.pinyinTextStyle` - For pinyin text
- `AppTheme.translationTextStyle` - For translations

## Responsive Design Considerations

While these font sizes are standardized, consider using responsive sizing for extreme screen sizes:

```dart
// Example of responsive text sizing
double responsiveFontSize = MediaQuery.of(context).size.width < 360 
    ? AppTheme.fontSizeSmall 
    : AppTheme.fontSizeDefault;

Text(
  'Responsive Text',
  style: TextStyle(fontSize: responsiveFontSize),
)
```

## Migrating Existing Code

When updating existing widgets, replace hardcoded font sizes with the appropriate constants from `AppTheme`. For components that don't fit neatly into the provided categories, use the closest standard size.

## Theme Integration

These font sizes are integrated with both the standard `AppTheme` and the `CatppuccinTheme`, ensuring consistency regardless of which theme the user selects.