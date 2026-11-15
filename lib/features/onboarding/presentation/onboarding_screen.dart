import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/router/routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/bottom_actions.dart';
import '../../../core/widgets/illustration_circle.dart';

/// Onboarding en quatre pages courtes (docs/05-parcours-utilisateurs.md §1).
final class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

final class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  static const int _pageCount = 4;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < _pageCount - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _createVault() => context.go(Routes.setup);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final last = _index == _pageCount - 1;
    final pages = [
      _Page(
        icon: Icons.shield_rounded,
        title: l10n.onboardingTitle1,
        body: l10n.onboardingBody1,
      ),
      _Page(
        icon: Icons.smartphone_rounded,
        title: l10n.onboardingTitle2,
        body: l10n.onboardingBody2,
      ),
      _Page(
        icon: Icons.enhanced_encryption_rounded,
        title: l10n.onboardingTitle3,
        body: l10n.onboardingBody3,
      ),
      _Page(
        icon: Icons.verified_user_rounded,
        title: l10n.onboardingTitle4,
        body: l10n.onboardingBody4,
        footer: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => context.push(Routes.legalPrivacy),
              child: Text(l10n.onboardingPrivacyLink),
            ),
            TextButton(
              onPressed: () => context.push(Routes.legalTerms),
              child: Text(l10n.onboardingTermsLink),
            ),
          ],
        ),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: last
                      ? null
                      : TextButton(
                          onPressed: _createVault,
                          child: Text(l10n.commonSkip),
                        ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                children: pages,
              ),
            ),
            Semantics(
              label: l10n.onboardingPageLabel(_index + 1, _pageCount),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pageCount; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: i == _index
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            BottomActions(
              children: [
                if (last)
                  LargeFilledButton(
                    label: l10n.onboardingCreateVault,
                    icon: Icons.lock_rounded,
                    onPressed: _createVault,
                  )
                else
                  LargeFilledButton(label: l10n.commonNext, onPressed: _next),
                TextButton(
                  onPressed: () => context.push(Routes.restore),
                  child: Text(l10n.onboardingRestore),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _Page extends StatelessWidget {
  const _Page({
    required this.icon,
    required this.title,
    required this.body,
    this.footer,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          IllustrationCircle(icon: icon),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.lg),
            footer!,
          ],
        ],
      ),
    );
  }
}
