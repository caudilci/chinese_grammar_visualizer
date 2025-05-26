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

    test('containsToneMarks should detect tone marks', () {
      expect(PinyinUtils.containsToneMarks('nǐ hǎo'), isTrue);
      expect(PinyinUtils.containsToneMarks('ni hao'), isFalse);
      expect(PinyinUtils.containsToneMarks('wǒ'), isTrue);
      expect(PinyinUtils.containsToneMarks('wo'), isFalse);
      expect(PinyinUtils.containsToneMarks('tā bú shì'), isTrue);
      expect(PinyinUtils.containsToneMarks('ta bu shi'), isFalse);
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
  });
}