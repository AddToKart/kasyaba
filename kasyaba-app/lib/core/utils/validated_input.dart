import 'package:flutter/services.dart';

/// Server-aligned text limits for free-form finance fields.
const int kMaxNameLength = 200;
const int kMaxDescriptionLength = 500;
const int kMaxNotesLength = 500;

/// Allows up to 12 integer digits and 2 decimal places, rejecting signs,
/// separators, and oversized values before they reach the API.
final TextInputFormatter currencyAmountInputFormatter =
    TextInputFormatter.withFunction((oldValue, newValue) {
      return RegExp(r'^\d{0,12}(\.\d{0,2})?$').hasMatch(newValue.text)
          ? newValue
          : oldValue;
    });
