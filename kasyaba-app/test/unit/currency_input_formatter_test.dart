// Regression coverage for the server-aligned currency amount formatter.
//
// The formatter is a pure text gate in front of the API: it must accept up to
// 12 integer digits and 2 decimals, and silently keep the previous value when
// a keystroke would produce an invalid amount (signs, separators, exponents,
// too many digits/decimals).
//
// The implementation regex is `^\d{0,12}(\.\d{0,2})?$`. Those zero-width
// quantifiers mean the empty string and a bare/leading decimal point are
// intentionally accepted by the *formatter* (the form's submit validation is
// responsible for requiring a positive value). These tests pin the actual
// current behavior rather than an aspirational one.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/core/utils/validated_input.dart';

TextEditingValue _value(String text) {
  return TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );
}

/// Runs the real formatter exactly as Flutter does on an edit transition.
TextEditingValue _edit(
  TextEditingValue oldValue,
  TextEditingValue newValue,
) {
  return currencyAmountInputFormatter.formatEditUpdate(oldValue, newValue);
}

void main() {
  group('currencyAmountInputFormatter accepts valid server amounts', () {
    const accepted = <String>[
      '0',
      '12',
      '123456789012', // exactly 12 integer digits
      '123456789012.99', // 12 digits + 2 decimals
      '12.5', // one decimal place
    ];

    for (final text in accepted) {
      test("accepts '$text'", () {
        final oldValue = _value('7');
        final newValue = _value(text);

        final result = currencyAmountInputFormatter.formatEditUpdate(
          oldValue,
          newValue,
        );

        expect(
          result,
          same(newValue),
          reason: "Formatter must forward the new value '$text' unchanged.",
        );
      });
    }

    // The current regex uses `\d{0,12}`, so these incomplete-but-parseable
    // states are allowed while the user is still typing.
    const acceptedByRegex = <String>['', '.5', '12.', '.', '000000000000'];

    for (final text in acceptedByRegex) {
      test("matches current regex behavior for '$text'", () {
        final newValue = _value(text);

        final result = currencyAmountInputFormatter.formatEditUpdate(
          _value('7'),
          newValue,
        );

        expect(
          result,
          same(newValue),
          reason:
              "Current regex is ^\\d{0,12}(\\.\\d{0,2})?\$ and therefore "
              "allows '$text'.",
        );
      });
    }
  });

  group('currencyAmountInputFormatter rejects invalid amounts', () {
    const rejected = <String>[
      '1234567890123', // 13 integer digits
      '1.234', // 3 decimals
      '1,000', // thousands separator
      '-5', // negative sign
      'abc', // non-numeric
      '1e5', // exponent notation
      '12..3', // duplicate decimal point
      '1.2.3', // multiple decimal points
      ' 12', // leading whitespace
      '12 ', // trailing whitespace
    ];

    for (final text in rejected) {
      test("keeps the old value for '$text'", () {
        final oldValue = _value('12');
        final newValue = _value(text);

        final result = currencyAmountInputFormatter.formatEditUpdate(
          oldValue,
          newValue,
        );

        expect(
          result,
          same(oldValue),
          reason: "Invalid edit '$text' must leave the previous value intact.",
        );
        expect(result.text, '12');
      });
    }

    test('keeps the old value when an accepted amount gains a 13th digit', () {
      final oldValue = _value('123456789012');
      final newValue = _value('1234567890123');

      final result = currencyAmountInputFormatter.formatEditUpdate(
        oldValue,
        newValue,
      );

      expect(result, same(oldValue));
      expect(result.text, '123456789012');
    });

    test('keeps the old value when an accepted amount gains a 3rd decimal', () {
      final oldValue = _value('123456789012.99');
      final newValue = _value('123456789012.999');

      final result = currencyAmountInputFormatter.formatEditUpdate(
        oldValue,
        newValue,
      );

      expect(result, same(oldValue));
      expect(result.text, '123456789012.99');
    });
  });

  group('currencyAmountInputFormatter edit transitions', () {
    test('accepts deletion back to a shorter valid amount', () {
      final newValue = _value('5');

      final result = _edit(_value('55'), newValue);

      expect(result, same(newValue));
      expect(result.text, '5');
    });

    test('accepts clearing the field', () {
      final newValue = _value('');

      final result = _edit(_value('12.50'), newValue);

      expect(result.text, '');
      expect(result, same(newValue));
    });

    test('accepts typing the decimal point after an integer', () {
      final newValue = _value('12.');

      final result = _edit(_value('12'), newValue);

      expect(result, same(newValue));
      expect(result.text, '12.');
    });

    test('rejects a pasted amount with a currency symbol', () {
      final oldValue = _value('12');
      final newValue = _value('₱12.50');

      final result = currencyAmountInputFormatter.formatEditUpdate(
        oldValue,
        newValue,
      );

      expect(result, same(oldValue));
      expect(result.text, '12');
    });
  });
}
