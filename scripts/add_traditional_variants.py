#!/usr/bin/env python3
import json
import os
import re
import sys
from typing import Dict

def load_cedict(cedict_path: str) -> Dict[str, str]:
    """Load the CC-CEDICT dictionary and create a simplified->traditional mapping."""
    print(f"Loading CEDICT from {cedict_path}...")
    try:
        with open(cedict_path, 'r', encoding='utf-8') as f:
            cedict_data = json.load(f)

        # Create a mapping from simplified to traditional
        simplified_to_traditional = {}
        for entry in cedict_data:
            if 'simplified' in entry and 'traditional' in entry:
                simplified_to_traditional[entry['simplified']] = entry['traditional']

        print(f"Loaded {len(simplified_to_traditional)} character mappings from CEDICT")
        return simplified_to_traditional
    except Exception as e:
        print(f"Error loading CEDICT: {e}")
        return {}

def convert_to_traditional(text: str, mapping: Dict[str, str]) -> str:
    """Convert simplified Chinese text to traditional using the mapping."""
    if not text or not isinstance(text, str):
        return text

    # Check if the text contains Chinese characters
    if not re.search(r'[\u4e00-\u9fff]', text):
        return text

    # For single characters and words directly in the dictionary
    if text in mapping:
        return mapping[text]

    # For longer texts, we need to do more complex character-by-character conversion
    result = ""
    i = 0
    while i < len(text):
        # Try to match the longest possible substring
        found = False
        for j in range(min(10, len(text) - i), 0, -1):  # Try up to 10-character substrings
            substring = text[i:i+j]
            if substring in mapping:
                result += mapping[substring]
                i += j
                found = True
                break

        # If no match found, keep the original character
        if not found:
            # Try single character
            if text[i] in mapping:
                result += mapping[text[i]]
            else:
                result += text[i]
            i += 1

    return result

def process_grammar_patterns(patterns_path: str, output_path: str, mapping: Dict[str, str]) -> None:
    """Process grammar patterns and add traditional variants."""
    print(f"Processing grammar patterns from {patterns_path}...")

    try:
        with open(patterns_path, 'r', encoding='utf-8') as f:
            patterns = json.load(f)

        pattern_count = len(patterns)
        print(f"Found {pattern_count} grammar patterns to process")

        # Process each pattern
        for pattern_index, pattern in enumerate(patterns):
            if pattern_index % 10 == 0:
                print(f"Processing pattern {pattern_index + 1}/{pattern_count}...")

            # Add traditional variants to main pattern fields
            if 'chineseTitle' in pattern:
                pattern['traditionalChineseTitle'] = convert_to_traditional(pattern['chineseTitle'], mapping)

            if 'structure' in pattern and re.search(r'[\u4e00-\u9fff]', pattern['structure']):
                pattern['traditionalStructure'] = convert_to_traditional(pattern['structure'], mapping)

            # Process structure breakdown
            if 'structureBreakdown' in pattern and isinstance(pattern['structureBreakdown'], list):
                for part in pattern['structureBreakdown']:
                    if 'text' in part and re.search(r'[\u4e00-\u9fff]', part['text']):
                        part['traditionalText'] = convert_to_traditional(part['text'], mapping)

            # Process examples
            if 'examples' in pattern and isinstance(pattern['examples'], list):
                for example in pattern['examples']:
                    if 'chineseSentence' in example:
                        example['traditionalChineseSentence'] = convert_to_traditional(
                            example['chineseSentence'], mapping
                        )

                    # Process breakdown parts
                    if 'breakdownParts' in example and isinstance(example['breakdownParts'], list):
                        for part in example['breakdownParts']:
                            if 'text' in part and re.search(r'[\u4e00-\u9fff]', part['text']):
                                part['traditionalText'] = convert_to_traditional(part['text'], mapping)

        # Save the updated patterns
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(patterns, f, ensure_ascii=False, indent=2)

        print(f"Successfully saved updated patterns to {output_path}")

    except Exception as e:
        print(f"Error processing grammar patterns: {e}")
        sys.exit(1)

def main():
    # Set up paths
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_dir = os.path.dirname(script_dir)

    cedict_path = os.path.join(project_dir, 'assets', 'data', 'cedict.json')
    grammar_patterns_path = os.path.join(project_dir, 'assets', 'data', 'grammar_patterns.json')

    # Create a backup of the original file
    backup_path = grammar_patterns_path + '.backup'
    if not os.path.exists(backup_path):
        try:
            with open(grammar_patterns_path, 'r', encoding='utf-8') as src:
                with open(backup_path, 'w', encoding='utf-8') as dst:
                    dst.write(src.read())
            print(f"Created backup at {backup_path}")
        except Exception as e:
            print(f"Warning: Failed to create backup: {e}")

    # Load the cedict mapping
    mapping = load_cedict(cedict_path)
    if not mapping:
        print("Error: Failed to load mapping from CEDICT")
        sys.exit(1)

    # Process the grammar patterns
    process_grammar_patterns(grammar_patterns_path, grammar_patterns_path, mapping)
    print("Done! You can now run the app to test the traditional character support")
    print("Use 'flutter run -d emulator-5554' to test on your specified emulator")

if __name__ == "__main__":
    main()
