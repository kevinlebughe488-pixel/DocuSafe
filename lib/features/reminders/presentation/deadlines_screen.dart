import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/router/routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers.dart';
import '../../../core/security/lock/vault_state.dart';
import '../../../core/utils/date_only.dart';
import '../../../core/utils/formats.dart';
import '../../../core/widgets/document_tile.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/settings_tile.dart';
import '../../../core/widgets/state_view.dart';
import '../../../core/widgets/status_badge.dart';

enum _DeadlineFilter { all, expired, soon }

/// Onglet Échéances (écran 15) : classé par urgence, trois groupes. Il reste
/// la référence même si une notification est manquée.
final class DeadlinesScreen extends ConsumerStatefulWidget {
  const DeadlinesScreen({super.key});

  @override
  ConsumerState<DeadlinesScreen> createState() => _DeadlinesScreenState();
}

final class _DeadlinesScreenState extends ConsumerState<DeadlinesScreen> {
  _DeadlineFilter _filter = _DeadlineFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final docs = ref.watch(expiringDocumentsProvider);
    final notificationsOn = ref.watch(notificationsEnabledProvider).value ?? true;
    final today = DateOnly.today();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navDeadlinesTitle),
        actions: [
          IconButton(
            tooltip: l10n.settingsNotifications,
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => context.push(Routes.settingsNotifications),
          ),
        ],
      ),
      body: switch (docs) {
        AsyncData(:final value) when value.isEmpty => StateView(
          icon: Icons.event_available_outlined,
          title: l10n.deadlinesEmptyTitle,
          body: l10n.deadlinesEmptyBody,
        ),
        AsyncData(:final value) => _list(context, value, today, notificationsOn),
        AsyncError() => StateView(
          icon: Icons.error_outline_rounded,
          title: l10n.commonErrorTitle,
          body: l10n.commonErrorBody,
          isError: true,
        ),
        _ => const Center(child: CircularProgressIndicator.adaptive()),
      },
    );
  }

  Widget _list(
    BuildContext context,
    List<DocumentRow> docs,
    DateOnly today,
    bool notificationsOn,
  ) {
    final l10n = AppLocalizations.of(context);
    final expired = <DocumentRow>[];
    final soon = <DocumentRow>[];
    final later = <DocumentRow>[];
    for (final d in docs) {
      switch (ExpiryInfo.of(l10n, d.expirationDate!, today).status) {
        case ExpiryStatus.expired:
          expired.add(d);
        case ExpiryStatus.soon:
          soon.add(d);
        case ExpiryStatus.later:
          later.add(d);
      }
    }
    // Expirés : le plus récemment expiré d'abord.
    expired.sort((a, b) => b.expirationDate!.compareTo(a.expirationDate!));

    Widget tile(DocumentRow d) {
      final exp = d.expirationDate!;
      final info = ExpiryInfo.of(l10n, exp, today);
      final isExpired = info.status == ExpiryStatus.expired;
      return DocumentTile(
        document: d,
        subtitle: isExpired
            ? l10n.expiredOn(Formats.date(exp))
            : l10n.expiresOn(Formats.date(exp)),
        trailing: isExpired
            ? StatusBadge(
                label: l10n.deadlinesExpiredSince(today.daysFrom(exp)),
                kind: StatusBadgeKind.error,
              )
            : StatusBadge.expiry(info),
        onTap: () => context.push(Routes.document(d.id)),
      );
    }

    final groups = <(String, List<DocumentRow>)>[
      if (_filter != _DeadlineFilter.soon && expired.isNotEmpty) (l10n.deadlinesGroupExpired, expired),
      if (_filter != _DeadlineFilter.expired && soon.isNotEmpty) (l10n.deadlinesGroupSoon, soon),
      if (_filter == _DeadlineFilter.all && later.isNotEmpty) (l10n.deadlinesGroupLater, later),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenMargin,
              vertical: AppSpacing.sm,
            ),
            children: [
              for (final (f, label) in [
                (_DeadlineFilter.all, l10n.deadlinesAll),
                (_DeadlineFilter.expired, l10n.deadlinesExpiredCount(expired.length)),
                (_DeadlineFilter.soon, l10n.deadlinesSoonCount(soon.length)),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FilterChip(
                    label: Text(label),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                ),
            ],
          ),
        ),
        if (!notificationsOn)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenMargin,
              AppSpacing.sm,
              AppSpacing.screenMargin,
              0,
            ),
            child: InfoBanner.text(
              kind: InfoBannerKind.info,
              text: l10n.deadlinesNotificationsOff,
            ),
          ),
        for (final (title, items) in groups) ...[
          SettingsGroupLabel(title),
          for (final d in items) tile(d),
        ],
      ],
    );
  }
}

/// Documents avec une date d'expiration, par urgence.
final expiringDocumentsProvider = StreamProvider<List<DocumentRow>>((ref) {
  if (ref.watch(vaultControllerProvider) is! VaultUnlocked) {
    return const Stream.empty();
  }
  return ref.watch(documentRepositoryProvider).watchExpiring();
});

/// Rappels activés dans les réglages.
final notificationsEnabledProvider = StreamProvider<bool>((ref) {
  final state = ref.watch(vaultControllerProvider);
  if (state is! VaultUnlocked) {
    return const Stream.empty();
  }
  return state.session.database.settingsDao.watch().map((s) => s.notificationsEnabled);
});
