import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bugaoshan/injection/injector.dart';
import 'package:bugaoshan/l10n/app_localizations.dart';
import 'package:bugaoshan/providers/app_config_provider.dart';
import 'package:bugaoshan/utils/font_utils.dart';
import 'package:bugaoshan/widgets/common/third_center.dart';

class SetFontPage extends StatelessWidget {
  const SetFontPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final appConfig = getIt<AppConfigProvider>();

    return ListenableBuilder(
      listenable: Listenable.merge([
        appConfig.useGoogleFonts,
        appConfig.fontScale,
        appConfig.fontWeightDelta,
      ]),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: Text(localizations.setFont)),
          body: Column(
            children: [
              // Preview area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ThirdCenter(
                    x: -1,
                    child: _FontPreview(
                      localizations: localizations,
                      appConfig: appConfig,
                    ),
                  ),
                ),
              ),
              // Control panel
              _ControlPanel(localizations: localizations, appConfig: appConfig),
            ],
          ),
        );
      },
    );
  }
}

/// Preview area that shows how text looks with current font settings.
class _FontPreview extends StatelessWidget {
  final AppLocalizations localizations;
  final AppConfigProvider appConfig;

  const _FontPreview({required this.localizations, required this.appConfig});

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;
    if (appConfig.useGoogleFonts.value) {
      textTheme = GoogleFonts.notoSansScTextTheme(textTheme);
    }
    textTheme = applyFontWeightDelta(
      textTheme,
      appConfig.fontWeightDelta.value,
    );

    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(appConfig.fontScale.value)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(localizations.setFont, style: textTheme.headlineLarge),
          const SizedBox(height: 32),
          Text('红豆生南国，春来发几枝。\n愿君多采撷，此物最相思。', style: textTheme.bodyLarge),
          const SizedBox(height: 16),
          Text(
            'The quick brown fox jumps over the lazy dog.\nPack my box with five dozen liquor jugs.',
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  final AppLocalizations localizations;
  final AppConfigProvider appConfig;

  const _ControlPanel({required this.localizations, required this.appConfig});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Google Fonts toggle
            Material(
              color: Colors.transparent,
              child: SwitchListTile(
                title: Text(localizations.useGoogleFonts),
                subtitle: const Text('Noto Sans SC'),
                value: appConfig.useGoogleFonts.value,
                onChanged: (v) => appConfig.useGoogleFonts.value = v,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const Divider(),
            // Font scale
            _DeltaSlider(
              label: localizations.fontScale,
              value: appConfig.fontScale.value,
              min: 0.8,
              max: 1.5,
              divisions: 7,
              formatValue: (v) => '${(v * 100).round()}%',
              accentColor: colorScheme.primary,
              leftLabelStyle: const TextStyle(fontSize: 13),
              rightLabelStyle: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
              onChanged: (v) => appConfig.fontScale.value = v,
            ),
            const SizedBox(height: 4),
            // Font weight delta
            _DeltaSlider(
              label: localizations.fontWeightDelta,
              value: appConfig.fontWeightDelta.value,
              min: -4,
              max: 4,
              divisions: null,
              formatValue: (v) => '${v >= 0 ? '+' : ''}${v.toStringAsFixed(1)}',
              accentColor: colorScheme.primary,
              leftLabelStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w100,
              ),
              rightLabelStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
              onChanged: (v) => appConfig.fontWeightDelta.value = v,
            ),
            const SizedBox(height: 8),
            // Reset button
            TextButton.icon(
              onPressed: () {
                appConfig.useGoogleFonts.value = true;
                appConfig.fontScale.value = 1.0;
                appConfig.fontWeightDelta.value = 0.0;
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(localizations.resetToDefault),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeltaSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String Function(double) formatValue;
  final Color accentColor;
  final TextStyle leftLabelStyle;
  final TextStyle rightLabelStyle;
  final ValueChanged<double> onChanged;

  const _DeltaSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.formatValue,
    required this.accentColor,
    required this.leftLabelStyle,
    required this.rightLabelStyle,
    required this.onChanged,
  });

  static const _labelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
  static const _valueStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: _labelStyle)),
            Text(
              formatValue(value),
              style: _valueStyle.copyWith(color: accentColor),
            ),
          ],
        ),
        Row(
          children: [
            Text('A', style: leftLabelStyle),
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
              ),
            ),
            Text('A', style: rightLabelStyle),
          ],
        ),
      ],
    );
  }
}
