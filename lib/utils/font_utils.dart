import 'package:flutter/material.dart';

/// Apply font weight delta to all text styles in [textTheme].
///
/// [weightDelta] is multiplied by 100 and added to each style's `fontWeight`
/// value, clamped to [FontWeight.w100]–[FontWeight.w900].
TextTheme applyFontWeightDelta(TextTheme textTheme, double weightDelta) {
  if (weightDelta == 0) return textTheme;

  TextStyle? adjust(TextStyle? s) {
    if (s == null) return null;
    FontWeight? fontWeight = s.fontWeight;
    if (fontWeight != null) {
      final clamped = (fontWeight.value + weightDelta * 100).round().clamp(
        FontWeight.w100.value,
        FontWeight.w900.value,
      );
      fontWeight = FontWeight(clamped);
    }
    return s.copyWith(fontWeight: fontWeight);
  }

  return textTheme.copyWith(
    displayLarge: adjust(textTheme.displayLarge),
    displayMedium: adjust(textTheme.displayMedium),
    displaySmall: adjust(textTheme.displaySmall),
    headlineLarge: adjust(textTheme.headlineLarge),
    headlineMedium: adjust(textTheme.headlineMedium),
    headlineSmall: adjust(textTheme.headlineSmall),
    titleLarge: adjust(textTheme.titleLarge),
    titleMedium: adjust(textTheme.titleMedium),
    titleSmall: adjust(textTheme.titleSmall),
    bodyLarge: adjust(textTheme.bodyLarge),
    bodyMedium: adjust(textTheme.bodyMedium),
    bodySmall: adjust(textTheme.bodySmall),
    labelLarge: adjust(textTheme.labelLarge),
    labelMedium: adjust(textTheme.labelMedium),
    labelSmall: adjust(textTheme.labelSmall),
  );
}
