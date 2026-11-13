/// Catégories créées avec le coffre (docs/03-modele-de-donnees.md §2.2 et
/// docs/07-design.md §3.3). Identifiants fixes pour une future synchronisation.
final class DefaultCategory {
  const DefaultCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorKey,
    required this.sortOrder,
    this.isSystem = false,
  });

  final String id;
  final String name;
  final String icon;

  /// Clé de la palette des catégories (`blue`, `purple`…).
  final String colorKey;
  final int sortOrder;
  final bool isSystem;

  static const String othersId = 'default-others';

  static const List<DefaultCategory> all = [
    DefaultCategory(
      id: 'default-identity',
      name: 'Identité',
      icon: 'badge',
      colorKey: 'blue',
      sortOrder: 0,
    ),
    DefaultCategory(
      id: 'default-education',
      name: 'Éducation',
      icon: 'school',
      colorKey: 'purple',
      sortOrder: 1,
    ),
    DefaultCategory(
      id: 'default-work',
      name: 'Professionnel',
      icon: 'work',
      colorKey: 'teal',
      sortOrder: 2,
    ),
    DefaultCategory(
      id: 'default-finance',
      name: 'Finances',
      icon: 'account_balance_wallet',
      colorKey: 'green',
      sortOrder: 3,
    ),
    DefaultCategory(
      id: 'default-housing',
      name: 'Immobilier',
      icon: 'home_work',
      colorKey: 'orange',
      sortOrder: 4,
    ),
    DefaultCategory(
      id: 'default-health',
      name: 'Santé',
      icon: 'medical_services',
      colorKey: 'pink',
      sortOrder: 5,
    ),
    DefaultCategory(
      id: othersId,
      name: 'Autres',
      icon: 'folder',
      colorKey: 'slate',
      sortOrder: 6,
      isSystem: true,
    ),
  ];
}

/// Palette des catégories : la valeur « Référence » de docs/07-design.md §3.3,
/// enregistrée en base dans `categories.color` (entier ARGB).
abstract final class CategoryColors {
  static const Map<String, int> reference = {
    'blue': 0xFF4977C2,
    'indigo': 0xFF6D6EC4,
    'purple': 0xFF8C67B1,
    'pink': 0xFFB15989,
    'red': 0xFFC45349,
    'orange': 0xFFB85F00,
    'amber': 0xFF9B6F00,
    'green': 0xFF498445,
    'teal': 0xFF278482,
    'cyan': 0xFF2280A1,
    'brown': 0xFF917157,
    'slate': 0xFF707884,
  };

  /// Retrouve la clé de palette d'une valeur enregistrée (ou `slate`).
  static String keyOf(int argb) => reference.entries
      .firstWhere(
        (e) => e.value == argb,
        orElse: () => const MapEntry('slate', 0xFF707884),
      )
      .key;
}
