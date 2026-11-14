import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers.dart';
import '../../../core/reminders/reminder_planner.dart';
import '../../../core/security/lock/vault_state.dart';
import '../../../core/utils/date_only.dart';
import '../../../core/utils/formats.dart';
import '../../../core/widgets/document_tile.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/settings_tile.dart';
import '../../../core/widgets/status_badge.dart';
import 'deadlines_screen.dart';
import 'notification_permission.dart';

/// Rappels d'un document (écran 16) : date d'expiration modifiable, chaque
/// rappel activable, ajout d'un délai personnalisé. Les rappels passés sont
/// grisés.
final class DocumentRemindersScreen extends ConsumerWidget {
  const DocumentRemindersScreen({super.key, required this.documentId});

  final String documentId;

  Future<void> _pickDate(BuildContext context, WidgetRef ref, DocumentRow doc) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: doc.expirationDate?.toLocalDateTime() ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 50),
      locale: const Locale('fr'),
    );
    if (picked == null) {
      return;
    }
    await ref.read(documentRepositoryProvider).setExpiration(doc.id, DateOnly.fromDateTime(picked));
    await ref.read(reminderServiceProvider).syncDocument(doc.id);
    if (context.mounted) {
      await maybeAskNotificationPermission(context, ref);
    }
  }

  Future<void> _addOffset(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final days = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final value = int.tryParse(controller.text);
          final valid = value != null && value >= 0 && value <= 3650;
          return AlertDialog.adaptive(
            title: Text(l10n.remindersAddTitle),
            content: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.remindersAddLabel,
                errorText: controller.text.isEmpty || valid ? null : l10n.remindersAddInvalid,
              ),
              onChanged: (_) => setState(() {}),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.commonCancel),
              ),
              TextButton(
                onPressed: valid ? () => Navigator.of(ctx).pop(value) : null,
                child: Text(l10n.commonSave),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
    if (days != null) {
      await ref.read(reminderServiceProvider).addOffset(documentId, days);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final doc = ref.watch(_documentProvider(documentId)).value;
    final reminders = ref.watch(_remindersProvider(documentId)).value ?? const [];
    final settings = ref.watch(_settingsProvider).value;
    final enabledGlobally = ref.watch(notificationsEnabledProvider).value ?? true;
    final now = DateTime.now();
    final today = DateOnly.today();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.remindersTitle)),
      body: doc == null
          ? const Center(child: CircularProgressIndicator.adaptive())
          : ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenMargin),
                  child: Card(
                    child: DocumentTile(
                      document: doc,
                      subtitle: doc.expirationDate == null
                          ? null
                          : l10n.expiresOn(Formats.date(doc.expirationDate!)),
                      trailing: doc.expirationDate == null
                          ? null
                          : StatusBadge.expiry(ExpiryInfo.of(l10n, doc.expirationDate!, today)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.field),
                    onTap: () => _pickDate(context, ref, doc),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: l10n.editExpirationDate,
                        suffixIcon: const Icon(Icons.calendar_month_outlined),
                      ),
                      isEmpty: doc.expirationDate == null,
                      child: Text(
                        doc.expirationDate == null ? '' : Formats.date(doc.expirationDate!),
                      ),
                    ),
                  ),
                ),
                if (doc.expirationDate == null)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.screenMargin),
                    child: Text(l10n.remindersNoDate),
                  )
                else ...[
                  SettingsGroupLabel(l10n.remindersSection),
                  if (!enabledGlobally)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
                      child: InfoBanner.text(
                        kind: InfoBannerKind.info,
                        text: l10n.remindersDisabledGlobally,
                      ),
                    ),
                  for (final r in reminders)
                    _ReminderTile(reminder: r, now: now),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => _addOffset(context, ref),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(l10n.remindersAdd),
                      ),
                    ),
                  ),
                  if (settings != null && !settings.$2)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.screenMargin),
                      child: InfoBanner.text(
                        kind: InfoBannerKind.info,
                        text: l10n.remindersDiscretion,
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}

final class _ReminderTile extends ConsumerWidget {
  const _ReminderTile({required this.reminder, required this.now});

  final ReminderRow reminder;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final when = reminder.reminderDate.toLocal();
    final past = !when.isAfter(now);
    final date = Formats.dateTime(when);
    final time = ReminderPlanner.formatTime(when.hour, when.minute);
    return SettingsTile.toggle(
      icon: past ? Icons.notifications_off_outlined : Icons.notifications_none_rounded,
      title: l10n.remindersOffset(reminder.offsetDays),
      subtitle: past ? l10n.remindersPast(date) : l10n.remindersAt(date, time),
      value: reminder.isEnabled && !past,
      onChanged: past
          ? null
          : (v) => unawaited(ref.read(reminderServiceProvider).setEnabled(reminder.id, v)),
    );
  }
}

final _documentProvider = StreamProvider.autoDispose.family<DocumentRow?, String>((ref, id) {
  if (ref.watch(vaultControllerProvider) is! VaultUnlocked) {
    return const Stream.empty();
  }
  return ref.watch(documentRepositoryProvider).watchDocument(id);
});

final _remindersProvider = StreamProvider.autoDispose.family<List<ReminderRow>, String>((ref, id) {
  final state = ref.watch(vaultControllerProvider);
  if (state is! VaultUnlocked) {
    return const Stream.empty();
  }
  return state.session.database.remindersDao.watchForDocument(id);
});

/// (rappels activés, nom affiché dans les notifications).
final _settingsProvider = FutureProvider.autoDispose<(bool, bool)>((ref) async {
  final s = await ref.watch(reminderServiceProvider).settings();
  return (s.enabled, s.showTitle);
});
