/// Droits d'utilisation : version gratuite ou Premium (cahier des charges §8).
///
/// Le MVP est entièrement gratuit : [FreeEntitlementService] répond toujours
/// « gratuit ». Aucune fonction Premium n'est affichée, simulée ni payante.
/// Quand les achats intégrés arriveront (paquet in_app_purchase, Google Play
/// Billing et App Store), une autre implémentation de cette interface les
/// lira ; le reste de l'application n'aura pas à changer.
library;

/// Formules d'abonnement. Seule la formule gratuite existe aujourd'hui.
enum Plan { free }

/// Fonctions envisagées pour la version Premium (§8). Aucune n'existe encore.
enum PremiumFeature {
  advancedOcr,
  advancedFullTextSearch,
  multiDeviceSync,
  advancedBackup,
  smartClassification,
}

abstract interface class EntitlementService {
  Plan get plan;

  /// La fonction est-elle accessible à l'utilisateur ?
  bool isUnlocked(PremiumFeature feature);
}

final class FreeEntitlementService implements EntitlementService {
  const FreeEntitlementService();

  @override
  Plan get plan => Plan.free;

  @override
  bool isUnlocked(PremiumFeature feature) => false;
}
