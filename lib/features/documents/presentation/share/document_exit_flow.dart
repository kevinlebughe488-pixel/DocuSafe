import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/l10n/generated/app_localizations.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/providers.dart';
import '../../../../core/utils/app_log.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../auth/presentation/reauth/reauth_sheet.dart';

/// Sortie volontaire d'un document (parcours 10) : partager ou exporter.
enum DocumentExit { share, export }

/// Nouvelle authentification → avertissement → déchiffrement contrôlé →
/// feuille de partage ou « Enregistrer sous » (docs/04-securite.md §13).
///
/// Pendant que le système affiche sa fenêtre, le verrouillage en arrière-plan
/// est suspendu (opération externe tolérée 5 minutes).
Future<void> runDocumentExit(
  BuildContext context,
  WidgetRef ref,
  DocumentRow document,
  DocumentExit kind,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  if (!await requestReauth(context, ref) || !context.mounted) {
    return;
  }
  final share = kind == DocumentExit.share;
  final confirmed = await confirmExit(
    context,
    icon: share ? Icons.share_outlined : Icons.download_outlined,
    title: share ? l10n.shareWarningTitle : l10n.exportWarningTitle,
    body: share ? l10n.shareWarningBody : l10n.exportWarningBody,
  );
  if (!confirmed) {
    return;
  }
  final exporter = ref.read(documentExporterProvider);
  final service = ref.read(shareServiceProvider);
  final controller = ref.read(vaultControllerProvider.notifier);
  controller.beginExternalOperation();
  try {
    if (share) {
      final file = await exporter.prepareForSharing(document);
      await service.shareFile(file.file!, mimeType: file.mimeType);
    } else {
      final file = await exporter.decryptForExport(document);
      try {
        final saved = await service.saveFile(
          fileName: file.fileName,
          bytes: file.bytes!,
          mimeType: file.mimeType,
        );
        if (saved) {
          messenger.showSnackBar(SnackBar(content: Text(l10n.exportDone)));
        }
      } finally {
        file.wipe();
      }
    }
  } on AppException catch (e, s) {
    AppLog.error('document.exit', e, s);
    messenger.showSnackBar(SnackBar(content: Text(ErrorMessages.of(l10n, e))));
  } finally {
    controller.endExternalOperation();
  }
}

/// « Exporter mes données » : archive ZIP de tous les documents, enregistrée
/// à l'emplacement choisi après authentification et avertissement.
Future<void> runExportAll(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  if (!await requestReauth(context, ref) || !context.mounted) {
    return;
  }
  final confirmed = await confirmExit(
    context,
    icon: Icons.file_download_outlined,
    title: l10n.exportAllWarningTitle,
    body: l10n.exportAllWarningBody,
  );
  if (!confirmed || !context.mounted) {
    return;
  }
  final exporter = ref.read(documentExporterProvider);
  final service = ref.read(shareServiceProvider);
  final controller = ref.read(vaultControllerProvider.notifier);
  final now = ref.read(clockProvider)();
  final date =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  messenger.showSnackBar(SnackBar(content: Text(l10n.exportAllInProgress)));
  controller.beginExternalOperation();
  try {
    final archive = await exporter.buildArchive(
      uncategorizedFolder: l10n.exportUncategorized,
      archiveName: l10n.exportArchiveName(date),
    );
    messenger.hideCurrentSnackBar();
    if (archive == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.exportAllEmpty)));
      return;
    }
    try {
      final saved = await service.saveFile(
        fileName: archive.fileName,
        bytes: archive.bytes!,
        mimeType: archive.mimeType,
      );
      if (saved) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.exportAllDone)));
      }
    } finally {
      archive.wipe();
    }
  } on AppException catch (e, s) {
    AppLog.error('vault.export', e, s);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(ErrorMessages.of(l10n, e))));
  } finally {
    controller.endExternalOperation();
  }
}

/// Avertissement avant toute sortie du coffre (maquette 10b).
Future<bool> confirmExit(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String body,
}) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(icon),
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.commonContinue),
        ),
      ],
    ),
  );
  return result ?? false;
}
