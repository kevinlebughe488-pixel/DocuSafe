import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/database/daos/settings_dao.dart';
import '../../../core/providers.dart';
import '../../../core/reminders/reminder_planner.dart';
import '../../../core/reminders/reminder_service.dart';
import '../../../core/widgets/ds_logo.dart';
import '../../../core/widgets/settings_tile.dart';

/// Paramètres → Notifications (maquette 17b). L'aperçu montre exactement
/// ce qui s'affichera sur l'écran verrouillé.
final class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

final class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  ReminderSettings? _settings;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final s = await ref.read(reminderServiceProvider).settings();
    if (mounted) {
      setState(() => _settings = s);
    }
  }

  Future<void> _update(Future<void> Function(SettingsDao dao) change, {bool recompute = false}) async {
    final dao = ref.read(databaseProvider).settingsDao;
    await change(dao);
    final service = ref.read(reminderServiceProvider);
    if (recompute) {
      await service.recomputeAllDates();
    } else {
      await service.rescheduleAll();
    }
    await _load();
  }

  Future<void> _toggleOffset(int offset) async {
    final current = _settings!.defaultOffsets;
    final next = current.contains(offset)
        ? current.where((o) => o != offset).toList()
        : [...current, offset];
    await _update((dao) => dao.writeConfig(
      VaultConfigKeys.reminderOffsets,
      ReminderPlanner.normalizeOffsets(next),
    ));
  }

  Future<void> _addOffset() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final days = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final v = int.tryParse(controller.text);
          final valid = v != null && v >= 0 && v <= 3650;
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
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.commonCancel)),
              TextButton(
                onPressed: valid ? () => Navigator.of(ctx).pop(v) : null,
                child: Text(l10n.commonSave),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
    if (days != null && !_settings!.defaultOffsets.contains(days)) {
      await _toggleOffset(days);
    }
  }

  Future<void> _pickTime() async {
    final (h, m) = _settings!.time;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: h, minute: m),
    );
    if (picked != null) {
      await _update(
        (dao) => dao.writeConfig(
          VaultConfigKeys.reminderTime,
          ReminderPlanner.formatTime(picked.hour, picked.minute),
        ),
        recompute: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = _settings;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsNotifications)),
      body: s == null
          ? const Center(child: CircularProgressIndicator.adaptive())
          : ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              children: [
                SettingsTile.toggle(
                  icon: Icons.notifications_active_outlined,
                  title: l10n.notifSettingsEnabled,
                  subtitle: l10n.notifSettingsEnabledSub,
                  value: s.enabled,
                  onChanged: (v) => _update((dao) => dao.setNotificationsEnabled(v)),
                ),
                SettingsGroupLabel(l10n.notifSettingsDefaults),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final o in ReminderPlanner.normalizeOffsets([
                        ...ReminderPlanner.defaultOffsets,
                        ...s.defaultOffsets,
                      ]))
                        FilterChip(
                          label: Text(l10n.offsetChip(o)),
                          selected: s.defaultOffsets.contains(o),
                          onSelected: s.enabled ? (_) => _toggleOffset(o) : null,
                        ),
                      ActionChip(
                        avatar: const Icon(Icons.add_rounded, size: 18),
                        label: Text(l10n.notifSettingsAddOffset),
                        onPressed: s.enabled ? _addOffset : null,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenMargin,
                    AppSpacing.sm,
                    AppSpacing.screenMargin,
                    0,
                  ),
                  child: Text(
                    l10n.notifSettingsDefaultsHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SettingsTile(
                  icon: Icons.schedule_rounded,
                  title: l10n.notifSettingsTime,
                  enabled: s.enabled,
                  trailing: Text(ReminderPlanner.formatTime(s.time.$1, s.time.$2)),
                  onTap: s.enabled ? _pickTime : null,
                ),
                SettingsTile.toggle(
                  icon: s.showTitle ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  title: l10n.notifSettingsShowTitle,
                  subtitle: s.showTitle ? l10n.notifSettingsShowTitleOn : l10n.notifSettingsShowTitleOff,
                  value: s.showTitle,
                  onChanged: s.enabled
                      ? (v) => _update((dao) => dao.writeConfig(VaultConfigKeys.notificationShowsTitle, v))
                      : null,
                ),
                SettingsGroupLabel(l10n.notifSettingsPreview),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const DsLogo(size: 24),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.notifSettingsPreviewNow, style: theme.textTheme.labelSmall),
                                const SizedBox(height: 2),
                                Text(
                                  s.showTitle
                                      ? l10n.notificationTitleNamed(l10n.notifSettingsExampleTitle, 7)
                                      : l10n.notificationTitle(7),
                                  style: theme.textTheme.titleSmall,
                                ),
                                Text(
                                  l10n.notificationBody,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
