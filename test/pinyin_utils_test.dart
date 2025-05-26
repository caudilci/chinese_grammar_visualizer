import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_grammar_visualizer/utils/pinyin_utils.dart';

void main() {
  group('PinyinUtils', () {
    test('removeToneMarks should remove all tone marks', () {
      expect(PinyinUtils.removeToneMarks('nǐ hǎo'), equals('ni hao'));
      expect(PinyinUtils.removeToneMarks('wǒ shì měi guó rén'), equals('wo shi mei guo ren'));
      expect(PinyinUtils.removeToneMarks('Zhōngguó'), equals('Zhongguo'));
      expect(PinyinUtils.removeToneMarks('hànyǔ'), equals('hanyu'));
      expect(PinyinUtils.removeToneMarks('tā bú shì wǒ de gēge'), equals('ta bu shi wo de gege'));
      expect(PinyinUtils.removeToneMarks('ǖǘǚǜ'), equals('üüüü'));
    });

    test('removeToneNumbers should remove all tone numbers', () {
      expect(PinyinUtils.removeToneNumbers('ni3 hao3'), equals('ni hao'));
      expect(PinyinUtils.removeToneNumbers('wo3 shi4 mei3 guo2 ren2'), equals('wo shi mei guo ren'));
      expect(PinyinUtils.removeToneNumbers('Zhong1guo2'), equals('Zhongguo'));
      expect(PinyinUtils.removeToneNumbers('han4yu3'), equals('hanyu'));
      expect(PinyinUtils.removeToneNumbers('ta1 bu2 shi4 wo3 de5 ge1ge5'), equals('ta bu shi wo de gege'));
      expect(PinyinUtils.removeToneNumbers('ü1ü2ü3ü4'), equals('üüüü'));
    });

    test('containsToneMarks should detect tone marks', () {
      expect(PinyinUtils.containsToneMarks('nǐ hǎo'), isTrue);
      expect(PinyinUtils.containsToneMarks('ni hao'), isFalse);
      expect(PinyinUtils.containsToneMarks('wǒ'), isTrue);
      expect(PinyinUtils.containsToneMarks('wo'), isFalse);
      expect(PinyinUtils.containsToneMarks('tā bú shì'), isTrue);
      expect(PinyinUtils.containsToneMarks('ta bu shi'), isFalse);
    });

    test('containsToneNumbers should detect tone numbers', () {
      expect(PinyinUtils.containsToneNumbers('ni3 hao3'), isTrue);
      expect(PinyinUtils.containsToneNumbers('ni hao'), isFalse);
      expect(PinyinUtils.containsToneNumbers('wo3'), isTrue);
      expect(PinyinUtils.containsToneNumbers('wo'), isFalse);
      expect(PinyinUtils.containsToneNumbers('ta1 bu2 shi4'), isTrue);
      expect(PinyinUtils.containsToneNumbers('ta bu shi'), isFalse);
    });

    test('matchesWithoutTones should find substring regardless of tone marks', () {
      // Test that "hao" matches "hǎo"
      expect(PinyinUtils.matchesWithoutTones('nǐ hǎo', 'hao'), isTrue);
      
      // Test that "hǎo" matches "hao"
      expect(PinyinUtils.matchesWithoutTones('ni hao', 'hǎo'), isTrue);
      
      // Test that "nǐ hǎo" matches "ni hao"
      expect(PinyinUtils.matchesWithoutTones('nǐ hǎo', 'ni hao'), isTrue);
      
      // Test a more complex example
      expect(PinyinUtils.matchesWithoutTones('wǒ xǐhuān chī píngguǒ', 'xihuan'), isTrue);
      
      // Test case insensitivity
      expect(PinyinUtils.matchesWithoutTones('Nǐ Hǎo', 'ni'), isTrue);
      expect(PinyinUtils.matchesWithoutTones('nǐ hǎo', 'Ni'), isTrue);
      
      // Test non-matching examples
      expect(PinyinUtils.matchesWithoutTones('nǐ hǎo', 'hello'), isFalse);
      expect(PinyinUtils.matchesWithoutTones('wǒ shì měi guó rén', 'zhongguo'), isFalse);
    });

    test('toNumericalPinyin should convert diacritic pinyin to numerical pinyin', () {
      expect(PinyinUtils.toNumericalPinyin('nǐ hǎo'), equals('ni3 hao3'));
      expect(PinyinUtils.toNumericalPinyin('wǒ shì měi guó rén'), equals('wo3 shi4 mei3 guo2 ren2'));
      expect(PinyinUtils.toNumericalPinyin('Zhōngguó'), equals('Zhongguó1'));
      expect(PinyinUtils.toNumericalPinyin('hànyǔ'), equals('hanyu43'));
      expect(PinyinUtils.toNumericalPinyin('ta bu shi'), equals('ta5 bu5 shi5')); // No tone marks
      expect(PinyinUtils.toNumericalPinyin('ǖ ǘ ǚ ǜ'), equals('ü1 ü2 ü3 ü4'));
    });

    test('toDiacriticPinyin should convert numerical pinyin to diacritic pinyin', () {
      expect(PinyinUtils.toDiacriticPinyin('ni3 hao3'), equals('nǐ hǎo'));
      expect(PinyinUtils.toDiacriticPinyin('wo3 shi4 mei3 guo2 ren2'), equals('wǒ shì měi guó rén'));
      expect(PinyinUtils.toDiacriticPinyin('Zhong1guo2'), equals('Zhōngguó'));
      expect(PinyinUtils.toDiacriticPinyin('han4yu3'), equals('hànyǔ'));
      expect(PinyinUtils.toDiacriticPinyin('ta bu shi'), equals('ta bu shi')); // No tone numbers
      expect(PinyinUtils.toDiacriticPinyin('ü1 ü2 ü3 ü4'), equals('ǖ ǘ ǚ ǜ'));
      expect(PinyinUtils.toDiacriticPinyin('ni5 hao5'), equals('ni hao')); // Neutral tone
    });

    test('isPotentialPinyin should detect valid pinyin strings', () {
      expect(PinyinUtils.isPotentialPinyin('nihao'), isTrue);
      expect(PinyinUtils.isPotentialPinyin('ni3 hao3'), isTrue);
      expect(PinyinUtils.isPotentialPinyin('nǐ hǎo'), isTrue);
      expect(PinyinUtils.isPotentialPinyin('wo shi zhongguo ren'), isTrue);
      expect(PinyinUtils.isPotentialPinyin('Hello world'), isTrue); // Has only letters
      expect(PinyinUtils.isPotentialPinyin('你好'), isFalse); // Chinese characters
      expect(PinyinUtils.isPotentialPinyin('こんにちは'), isFalse); // Non-Latin characters
      expect(PinyinUtils.isPotentialPinyin('hello!'), isFalse); // Has punctuation
    });
  });
}