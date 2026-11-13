/// Espacements, arrondis et tailles (docs/07-design.md §5).
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Marge latérale des écrans.
  static const double screenMargin = 16;

  /// Zone tactile minimale.
  static const double touchTarget = 48;

  /// Hauteur du grand bouton en bas d'un écran d'étape.
  static const double largeButtonHeight = 56;

  /// Touches du clavier du code.
  static const double keypadKeySize = 72;
}

/// Arrondis (docs/07-design.md §5).
abstract final class AppRadius {
  static const double field = 4;
  static const double chip = 8;
  static const double categoryIcon = 12;
  static const double card = 16;
  static const double sheet = 28;
}
