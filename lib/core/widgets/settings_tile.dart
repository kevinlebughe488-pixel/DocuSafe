import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_spacing.dart';

/// Ligne de réglage : icône, titre, sous-titre, et soit une flèche, soit un
/// interrupteur, soit une valeur.
final class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.danger = false,
    this.enabled = true,
  });

  /// Ligne avec interrupteur.
  factory SettingsTile.toggle({
    Key? key,
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) => SettingsTile(
    key: key,
    icon: icon,
    title: title,
    subtitle: subtitle,
    enabled: onChanged != null,
    onTap: onChanged == null ? null : () => onChanged(!value),
    trailing: Switch.adaptive(value: value, onChanged: onChanged),
  );

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool danger;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = danger ? scheme.error : null;
    return ListTile(
      enabled: enabled,
      leading: Icon(icon, color: color ?? scheme.onSurfaceVariant),
      title: Text(title, style: TextStyle(color: color)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing:
          trailing ??
          (onTap == null
              ? null
              : Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant)),
      onTap: onTap,
    );
  }
}

/// Titre de groupe dans une liste de réglages.
final class SettingsGroupLabel extends StatelessWidget {
  const SettingsGroupLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.xl,
        AppSpacing.screenMargin,
        AppSpacing.sm,
      ),
      child: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
