import 'package:material_ui/material_ui.dart';

/// Couleur d'une catégorie : fond et teinte de l'icône (docs/07-design.md §3.3).
final class CategoryColor {
  const CategoryColor({
    required this.key,
    required this.reference,
    required this.container,
    required this.onContainer,
  });

  final String key;

  /// Valeur enregistrée en base (`categories.color`).
  final Color reference;
  final Color container;
  final Color onContainer;
}

/// Couleurs ajoutées à Material 3 : états (avertissement, succès) et palette
/// des catégories (docs/07-design.md §3.2 et §3.3).
final class DsColors extends ThemeExtension<DsColors> {
  const DsColors({
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.categories,
  });

  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;

  /// Les douze couleurs de catégorie, dans l'ordre de la palette.
  final List<CategoryColor> categories;

  static const DsColors light = DsColors(
    warning: Color(0xFF865300),
    warningContainer: Color(0xFFFFDDB8),
    onWarningContainer: Color(0xFF2B1700),
    success: Color(0xFF2F6B2E),
    successContainer: Color(0xFFB0F3A6),
    onSuccessContainer: Color(0xFF002203),
    categories: _lightCategories,
  );

  static const DsColors dark = DsColors(
    warning: Color(0xFFFFB960),
    warningContainer: Color(0xFF653E00),
    onWarningContainer: Color(0xFFFFDDB8),
    success: Color(0xFF95D78C),
    successContainer: Color(0xFF145218),
    onSuccessContainer: Color(0xFFB0F3A6),
    categories: _darkCategories,
  );

  /// Palette en mode clair : fond et icône, valeurs exactes du §3.3.
  static const List<CategoryColor> _lightCategories = [
    CategoryColor(key: 'blue', reference: Color(0xFF4977C2), container: Color(0xFFD7E2FF), onContainer: Color(0xFF04458E)),
    CategoryColor(key: 'indigo', reference: Color(0xFF6D6EC4), container: Color(0xFFE1DFFF), onContainer: Color(0xFF3B3D8F)),
    CategoryColor(key: 'purple', reference: Color(0xFF8C67B1), container: Color(0xFFF0DBFF), onContainer: Color(0xFF59367D)),
    CategoryColor(key: 'pink', reference: Color(0xFFB15989), container: Color(0xFFFFD8E8), onContainer: Color(0xFF772957)),
    CategoryColor(key: 'red', reference: Color(0xFFC45349), container: Color(0xFFFFDAD6), onContainer: Color(0xFF84241E)),
    CategoryColor(key: 'orange', reference: Color(0xFFB85F00), container: Color(0xFFFFDCC5), onContainer: Color(0xFF703700)),
    CategoryColor(key: 'amber', reference: Color(0xFF9B6F00), container: Color(0xFFFFDEA7), onContainer: Color(0xFF5E4200)),
    CategoryColor(key: 'green', reference: Color(0xFF498445), container: Color(0xFFB2F3A8), onContainer: Color(0xFF165219)),
    CategoryColor(key: 'teal', reference: Color(0xFF278482), container: Color(0xFF9CF1EF), onContainer: Color(0xFF00504F)),
    CategoryColor(key: 'cyan', reference: Color(0xFF2280A1), container: Color(0xFFBDE9FF), onContainer: Color(0xFF004D64)),
    CategoryColor(key: 'brown', reference: Color(0xFF917157), container: Color(0xFFFFDCC1), onContainer: Color(0xFF5C412A)),
    CategoryColor(key: 'slate', reference: Color(0xFF707884), container: Color(0xFFDBE3F1), onContainer: Color(0xFF3F4753)),
  ];

  /// En mode sombre, fond et icône sont inversés.
  static const List<CategoryColor> _darkCategories = [
    CategoryColor(key: 'blue', reference: Color(0xFF4977C2), container: Color(0xFF04458E), onContainer: Color(0xFFD7E2FF)),
    CategoryColor(key: 'indigo', reference: Color(0xFF6D6EC4), container: Color(0xFF3B3D8F), onContainer: Color(0xFFE1DFFF)),
    CategoryColor(key: 'purple', reference: Color(0xFF8C67B1), container: Color(0xFF59367D), onContainer: Color(0xFFF0DBFF)),
    CategoryColor(key: 'pink', reference: Color(0xFFB15989), container: Color(0xFF772957), onContainer: Color(0xFFFFD8E8)),
    CategoryColor(key: 'red', reference: Color(0xFFC45349), container: Color(0xFF84241E), onContainer: Color(0xFFFFDAD6)),
    CategoryColor(key: 'orange', reference: Color(0xFFB85F00), container: Color(0xFF703700), onContainer: Color(0xFFFFDCC5)),
    CategoryColor(key: 'amber', reference: Color(0xFF9B6F00), container: Color(0xFF5E4200), onContainer: Color(0xFFFFDEA7)),
    CategoryColor(key: 'green', reference: Color(0xFF498445), container: Color(0xFF165219), onContainer: Color(0xFFB2F3A8)),
    CategoryColor(key: 'teal', reference: Color(0xFF278482), container: Color(0xFF00504F), onContainer: Color(0xFF9CF1EF)),
    CategoryColor(key: 'cyan', reference: Color(0xFF2280A1), container: Color(0xFF004D64), onContainer: Color(0xFFBDE9FF)),
    CategoryColor(key: 'brown', reference: Color(0xFF917157), container: Color(0xFF5C412A), onContainer: Color(0xFFFFDCC1)),
    CategoryColor(key: 'slate', reference: Color(0xFF707884), container: Color(0xFF3F4753), onContainer: Color(0xFFDBE3F1)),
  ];

  /// Couleur de catégorie correspondant à une valeur enregistrée en base.
  CategoryColor categoryOf(int reference) => categories.firstWhere(
    (c) => c.reference.toARGB32() == reference,
    orElse: () => categories.last,
  );

  @override
  DsColors copyWith({
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    List<CategoryColor>? categories,
  }) => DsColors(
    warning: warning ?? this.warning,
    warningContainer: warningContainer ?? this.warningContainer,
    onWarningContainer: onWarningContainer ?? this.onWarningContainer,
    success: success ?? this.success,
    successContainer: successContainer ?? this.successContainer,
    onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
    categories: categories ?? this.categories,
  );

  /// Les couleurs sont figées : pas d'interpolation entre les deux modes.
  @override
  DsColors lerp(DsColors? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}

/// Raccourci : `context.dsColors.warning`.
extension DsColorsContext on BuildContext {
  DsColors get dsColors => Theme.of(this).extension<DsColors>()!;
}
