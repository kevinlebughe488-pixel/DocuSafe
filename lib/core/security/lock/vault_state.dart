import 'vault_session.dart';

/// État du coffre (docs/02-architecture.md §6).
sealed class VaultState {
  const VaultState();
}

/// Lecture du stockage sécurisé en cours, au démarrage.
final class VaultInitializing extends VaultState {
  const VaultInitializing();
}

/// Aucun coffre : onboarding et création seulement.
final class VaultAbsent extends VaultState {
  const VaultAbsent();
}

/// Raison du dernier verrouillage, pour le message de l'écran de déverrouillage.
enum LockReason { startup, background, inactivity, manual, biometricChanged }

/// Coffre verrouillé : la clé n'est pas en mémoire, la base est fermée.
final class VaultLocked extends VaultState {
  const VaultLocked({
    required this.reason,
    required this.biometricEnabled,
    this.returnLocation,
  });

  final LockReason reason;
  final bool biometricEnabled;

  /// Adresse à rouvrir après le déverrouillage.
  final String? returnLocation;
}

/// Coffre déverrouillé : la session porte la base et les clés.
final class VaultUnlocked extends VaultState {
  const VaultUnlocked(this.session, {this.returnLocation});

  final VaultSession session;

  /// Adresse mémorisée avant le verrouillage, consommée par le routeur.
  final String? returnLocation;
}
