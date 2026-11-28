import 'package:flutter/material.dart';
import 'package:settle_app/i18n/l10n/app_localizations.dart';

class OnboardingCard extends StatelessWidget {
  const OnboardingCard({
    super.key,
    required this.onDismiss,
    required this.onOpenGuide,
  });

  final VoidCallback onDismiss;
  final VoidCallback onOpenGuide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return DecoratedBox(
      key: const Key('onboarding_card'),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 12),
        child: Row(
          children: [
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Text(l10n.onboardingTitle, style: theme.textTheme.labelLarge),
                  TextButton(
                    key: const Key('onboarding_open_guide'),
                    onPressed: onOpenGuide,
                    child: Text(l10n.onboardingOpenGuide),
                  ),
                ],
              ),
            ),
            IconButton(
              key: const Key('onboarding_close'),
              tooltip: l10n.onboardingClose,
              icon: const Icon(Icons.close, size: 16),
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}
