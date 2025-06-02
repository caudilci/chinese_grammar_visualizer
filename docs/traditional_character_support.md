# Traditional Character Support Implementation Guide

## Overview

This document describes how to implement traditional Chinese character support in the Chinese Grammar Visualizer app. This feature allows users to toggle between simplified and traditional Chinese characters throughout the application.

## Components Modified

1. **Models**
   - `GrammarPattern`: Added fields for traditional variants
   - `GrammarExample`: Added traditional variants of sentences
   - `SentencePart`: Added traditional variants of text parts

2. **Providers**
   - Created new `LanguageProvider` to manage character preferences

3. **Screens**
   - Updated `SettingsScreen` with a toggle for character type
   - Updated `PatternDetailScreen` to display the correct character variant
   - Created separate `WordListDetailScreen` with traditional support

4. **Widgets**
   - Updated `SentenceBreakdown` to support traditional characters
   - Updated `GrammarExampleCard` to support traditional characters
   - Updated `DictionaryEntryDetails` and `DictionarySearchResult` widgets

5. **Utils**
   - Created `CharacterUtils` for handling character conversions

## Implementation Steps

### 1. Update JSON Data

Each grammar pattern needs traditional variants for Chinese text. The following fields need traditional variants:

- `chineseTitle` → `traditionalChineseTitle`
- `structure` → `traditionalStructure`
- For each example:
  - `chineseSentence` → `traditionalChineseSentence`
  - For each breakdownPart:
    - `text` → `traditionalText`

Use the provided script in `scripts/add_traditional_variants.py` to generate these variants using the CEDICT dictionary.

### 2. Display Logic

The app follows this pattern for displaying text:

```dart
// Determine which text to display based on user preference
final displayText = useTraditional && traditionalTextExists
    ? traditionalText
    : simplifiedText;
```

For components that display both forms, we show the preferred form first, followed by the alternative in parentheses:

```dart
// Primary text in normal style
Text(primaryText, style: normalStyle)

// Secondary text in smaller, lighter style
if (showSecondary)
  Text('($secondaryText)', style: smallerLighterStyle)
```

### 3. Testing

To test the implementation:

1. Toggle the Traditional/Simplified switch in Settings
2. Verify that Chinese text changes throughout the app:
   - Pattern titles
   - Pattern structures
   - Example sentences
   - Sentence breakdowns
   - Dictionary entries
   - Word lists

### 4. Known Limitations

- Some specialized grammar terms may not have proper traditional equivalents
- The conversion from simplified to traditional may not be 100% accurate for all cases
- External APIs (like TTS) may work better with simplified characters

## Future Improvements

1. Add a proper S→T conversion library instead of relying solely on CEDICT mappings
2. Add support for traditional character input in search
3. Extend traditional character support to flashcards and practice sections
4. Consider allowing per-pattern overrides for special grammar terminology