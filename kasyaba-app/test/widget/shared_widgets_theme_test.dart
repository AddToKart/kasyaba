// LT-B shared widgets must resolve their surfaces, borders, text and accents
// from the active semantic palette in both dark and light modes. Dark values
// are the legacy tokens, so these assertions also lock pixel parity.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kasyaba/app/theme/app_theme.dart';
import 'package:kasyaba/app/theme/kasyaba_color_scheme.dart';
import 'package:kasyaba/shared/widgets/app_dialog.dart';
import 'package:kasyaba/shared/widgets/app_sheet.dart';
import 'package:kasyaba/shared/widgets/app_state_widgets.dart';
import 'package:kasyaba/shared/widgets/figma_toggle_switch.dart';
import 'package:kasyaba/shared/widgets/kasyaba_background.dart';
import 'package:kasyaba/shared/widgets/kasyaba_card.dart';
import 'package:kasyaba/shared/widgets/kasyaba_toast.dart';
import 'package:kasyaba/shared/widgets/motion_components.dart';
import 'package:kasyaba/shared/widgets/offline_status.dart';
import 'package:kasyaba/shared/widgets/pill_button.dart';

Widget _themed(ThemeMode mode, Widget home) {
  return MaterialApp(
    theme: AppTheme().light,
    darkTheme: AppTheme().dark,
    themeMode: mode,
    home: Scaffold(body: home),
  );
}

final Map<ThemeMode, KasyabaColorScheme> _palettes =
    <ThemeMode, KasyabaColorScheme>{
  ThemeMode.dark: kasyabaDarkColors,
  ThemeMode.light: kasyabaLightColors,
};

BoxDecoration _decorationOf(Widget widget) {
  if (widget is Container) return widget.decoration as BoxDecoration;
  if (widget is AnimatedContainer) {
    return widget.decoration as BoxDecoration;
  }
  throw StateError('Widget has no BoxDecoration: $widget');
}

void main() {
  for (final entry in _palettes.entries) {
    final mode = entry.key;
    final colors = entry.value;
    final label = mode.name;

    testWidgets('$label: KasyabaBackground uses the palette gradient', (
      tester,
    ) async {
      await tester.pumpWidget(
        _themed(mode, const KasyabaBackground(child: SizedBox.expand())),
      );

      final decorated = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(KasyabaBackground),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final gradient = (decorated.decoration as BoxDecoration).gradient
          as RadialGradient;
      final expected = colors.backgroundGradient;
      expect(gradient.colors, expected.colors);
      expect(gradient.stops, expected.stops);
      expect(gradient.center, expected.center);
      expect(gradient.radius, expected.radius);
    });

    testWidgets('$label: KasyabaCard variants use card surfaces', (
      tester,
    ) async {
      await tester.pumpWidget(
        _themed(
          mode,
          Column(
            children: const [
              KasyabaCard(child: Text('standard')),
              KasyabaCard(
                variant: KasyabaCardVariant.hero,
                child: Text('hero'),
              ),
              KasyabaCard(
                variant: KasyabaCardVariant.flat,
                child: Text('flat'),
              ),
            ],
          ),
        ),
      );

      final cards = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(KasyabaCard),
              matching: find.byType(Container),
            ),
          )
          .toList();
      expect(cards, hasLength(3));

      final standard = _decorationOf(cards[0]);
      final hero = _decorationOf(cards[1]);
      final flat = _decorationOf(cards[2]);

      expect(standard.color, colors.card);
      expect((standard.border as Border).top.color, colors.cardBorder);
      expect(hero.color, colors.cardHero);
      expect((hero.border as Border).top.color, colors.cardBorderStrong);
      expect(flat.color, Colors.transparent);
      expect(flat.border, isNull);
    });

    testWidgets('$label: PillButton variants resolve semantic fills', (
      tester,
    ) async {
      await tester.pumpWidget(
        _themed(
          mode,
          Column(
            children: [
              PillButton(label: 'Primary', onPressed: () {}),
              PillButton(
                label: 'Secondary',
                onPressed: () {},
                variant: PillButtonVariant.secondary,
              ),
              PillButton(
                label: 'Danger',
                onPressed: () {},
                variant: PillButtonVariant.destructive,
              ),
            ],
          ),
        ),
      );

      BoxDecoration buttonDecoration(String label) {
        final container = find
            .descendant(
              of: find.widgetWithText(PillButton, label),
              matching: find.byType(Container),
            )
            .first;
        return _decorationOf(tester.widget<Container>(container));
      }

      Color textColor(String label) =>
          tester.widget<Text>(find.text(label)).style!.color!;

      expect(buttonDecoration('Primary').color, colors.primaryButton);
      expect(textColor('Primary'), colors.onPrimaryButton);

      final secondary = buttonDecoration('Secondary');
      expect(secondary.color, Colors.transparent);
      expect((secondary.border as Border).top.color, colors.secondaryBorder);
      expect(textColor('Secondary'), colors.textPrimary);

      final danger = buttonDecoration('Danger');
      expect(danger.color, colors.dangerTint);
      expect((danger.border as Border).top.color, colors.danger);
      expect(textColor('Danger'), colors.danger);
    });

    testWidgets('$label: AppSheet chrome resolves surface and border', (
      tester,
    ) async {
      await tester.pumpWidget(
        _themed(mode, const AppSheet(child: Text('sheet body'))),
      );

      final containers = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(AppSheet),
              matching: find.byType(Container),
            ),
          )
          .toList();

      final surface = containers.firstWhere(
        (container) => _decorationOf(container).color == colors.card,
      );
      final surfaceDecoration = _decorationOf(surface);
      expect(
        (surfaceDecoration.border as Border).top.color,
        colors.cardBorderStrong,
      );

      final handle = containers.firstWhere(
        (container) =>
            _decorationOf(container).color ==
            colors.icon.withValues(alpha: 0.4),
      );
      expect(_decorationOf(handle).borderRadius, isNotNull);
    });

    testWidgets('$label: confirm dialog resolves card and CTA colors', (
      tester,
    ) async {
      await tester.pumpWidget(
        _themed(
          mode,
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showKasyabaConfirmDialog(
                context,
                title: 'Delete?',
                message: 'This cannot be undone.',
                confirmLabel: 'Delete',
                destructive: true,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(dialog.backgroundColor, colors.card);

      final title = tester.widget<Text>(find.text('Delete?'));
      expect(title.style?.color, colors.textPrimary);

      final message = tester.widget<Text>(find.text('This cannot be undone.'));
      expect(message.style?.color, colors.textSecondary);

      final confirm = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(
        confirm.style?.backgroundColor?.resolve(<WidgetState>{}),
        colors.danger,
      );
      expect(
        confirm.style?.foregroundColor?.resolve(<WidgetState>{}),
        colors.onPrimaryButton,
      );
    });

    testWidgets('$label: state widgets resolve card, text and accents', (
      tester,
    ) async {
      await tester.pumpWidget(
        _themed(
          mode,
          Column(
            children: const [
              KasyabaEmptyState(icon: Icons.inbox, title: 'Nothing here'),
              KasyabaErrorCard(message: 'Request failed'),
              KasyabaLoadingSkeleton(lines: 2),
            ],
          ),
        ),
      );

      final emptyIcon = tester.widget<Icon>(
        find.byIcon(Icons.inbox),
      );
      expect(emptyIcon.color, colors.textSecondary);

      final title = tester.widget<Text>(find.text('Nothing here'));
      expect(title.style?.color, colors.textPrimary);

      final errorIcon = tester.widget<Icon>(
        find.byIcon(Icons.error_outline_rounded),
      );
      expect(errorIcon.color, colors.danger);

      final errorText = tester.widget<Text>(find.text('Request failed'));
      expect(errorText.style?.color, colors.danger);

      final errorCard = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(KasyabaErrorCard),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(_decorationOf(errorCard).color, colors.card);
      expect(
        (_decorationOf(errorCard).border as Border).top.color,
        colors.danger.withValues(alpha: 0.35),
      );

      final skeleton = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(KasyabaLoadingSkeleton),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(_decorationOf(skeleton).color, colors.skeletonFill);
    });

    testWidgets('$label: offline notices resolve card and accents', (
      tester,
    ) async {
      await tester.pumpWidget(
        _themed(
          mode,
          Column(
            children: const [
              NeedsInternetNotice(message: 'Connect to continue'),
              OfflineQueuedNote(),
            ],
          ),
        ),
      );

      final noticeIcon = tester.widget<Icon>(
        find.byIcon(Icons.cloud_off_rounded),
      );
      expect(noticeIcon.color, colors.danger);

      final queuedIcon = tester.widget<Icon>(
        find.byIcon(Icons.cloud_upload_outlined),
      );
      expect(queuedIcon.color, colors.success);

      final noticeContainer = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(NeedsInternetNotice),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(_decorationOf(noticeContainer).color, colors.card);
      expect(
        (_decorationOf(noticeContainer).border as Border).top.color,
        colors.danger.withValues(alpha: 0.45),
      );
    });

    testWidgets('$label: toggle switch resolves track and thumb', (
      tester,
    ) async {
      await tester.pumpWidget(
        _themed(
          mode,
          Column(
            children: [
              FigmaToggleSwitch(value: true, onChanged: (_) {}),
              FigmaToggleSwitch(value: false, onChanged: (_) {}),
            ],
          ),
        ),
      );

      final tracks = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .toList();
      expect(_decorationOf(tracks[0]).color, colors.primaryButton);
      expect(
        _decorationOf(tracks[1]).color,
        colors.icon.withValues(alpha: 0.25),
      );

      final thumbs = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(AnimatedAlign),
              matching: find.byType(Container),
            ),
          )
          .toList();
      expect(_decorationOf(thumbs[0]).color, colors.onPrimaryButton);
      expect(_decorationOf(thumbs[1]).color, colors.textSecondary);
    });

    testWidgets('$label: segmented pill resolves track, pill and labels', (
      tester,
    ) async {
      await tester.pumpWidget(
        _themed(
          mode,
          SlidingSegmentedPill(
            items: const ['All', 'Income'],
            selectedIndex: 0,
            onChanged: (_) {},
          ),
        ),
      );

      final track = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(SlidingSegmentedPill),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(_decorationOf(track).color, colors.card);
      expect(
        (_decorationOf(track).border as Border).top.color,
        colors.cardBorder,
      );

      final pill = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(FractionallySizedBox),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(_decorationOf(pill).color, colors.primaryButton);

      Color labelColor(String text) {
        final style = tester
            .widget<AnimatedDefaultTextStyle>(
              find
                  .ancestor(
                    of: find.text(text),
                    matching: find.byType(AnimatedDefaultTextStyle),
                  )
                  .first,
            )
            .style;
        return style.color!;
      }

      expect(labelColor('All'), colors.onPrimaryButton);
      expect(labelColor('Income'), colors.textSecondary);
    });

    testWidgets('$label: toast uses card surface and status accents', (
      tester,
    ) async {
      await tester.pumpWidget(
        _themed(
          mode,
          Builder(
            builder: (context) => TextButton(
              onPressed: () => KasyabaToast.showSuccess(
                context,
                'Saved',
                subtitle: 'Synced',
              ),
              child: const Text('toast'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('toast'));
      await tester.pumpAndSettle();

      final toastSurface = tester
          .widgetList<Container>(find.byType(Container))
          .firstWhere(
            (container) =>
                _decorationOf(container).color == colors.card &&
                _decorationOf(container).borderRadius ==
                    BorderRadius.circular(24),
          );
      final decoration = _decorationOf(toastSurface);
      expect((decoration.border as Border).top.color, colors.cardBorder);

      final successIcon = tester.widget<Icon>(
        find.byIcon(Icons.check_circle_rounded),
      );
      expect(successIcon.color, colors.success);

      final message = tester.widget<Text>(find.text('Saved'));
      expect(message.style?.color, colors.textPrimary);

      final subtitle = tester.widget<Text>(find.text('Synced'));
      expect(subtitle.style?.color, colors.textSecondary);
    });
  }
}
