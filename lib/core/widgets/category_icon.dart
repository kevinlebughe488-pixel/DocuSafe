import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_spacing.dart';
import '../../app/theme/ds_colors.dart';

/// Icônes de catégorie proposées (docs/maquettes 11b), toutes intégrées à
/// Flutter en version arrondie.
abstract final class CategoryIcons {
  static const Map<String, IconData> all = {
    'badge': Icons.badge_rounded,
    'school': Icons.school_rounded,
    'work': Icons.work_rounded,
    'account_balance_wallet': Icons.account_balance_wallet_rounded,
    'home_work': Icons.home_work_rounded,
    'medical_services': Icons.medical_services_rounded,
    'folder': Icons.folder_rounded,
    'favorite': Icons.favorite_rounded,
    'receipt_long': Icons.receipt_long_rounded,
    'flight': Icons.flight_rounded,
    'directions_car': Icons.directions_car_rounded,
    'sell': Icons.sell_rounded,
    'pets': Icons.pets_rounded,
    'child_care': Icons.child_care_rounded,
    'gavel': Icons.gavel_rounded,
    'bolt': Icons.bolt_rounded,
  };

  static IconData of(String name) => all[name] ?? Icons.folder_rounded;
}

/// Icône sur fond coloré, trois tailles.
final class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
  });

  /// Nom de l'icône tel qu'enregistré en base.
  final String icon;

  /// Valeur de couleur enregistrée en base.
  final int color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.dsColors.categoryOf(color);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.container,
        borderRadius: BorderRadius.circular(
          size >= 56 ? AppRadius.card : AppRadius.categoryIcon,
        ),
      ),
      child: Icon(CategoryIcons.of(icon), color: c.onContainer, size: size * 0.55),
    );
  }
}
