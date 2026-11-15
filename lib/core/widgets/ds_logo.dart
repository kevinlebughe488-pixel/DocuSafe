import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';

/// Symbole de DocSafe (docs/07-design.md §2) : un document blanc à coin
/// replié, percé d'une serrure, sur un carré bleu aux angles arrondis.
/// Dessiné en vectoriel. Les icônes de l'application (Android, iOS, Google
/// Play) reprennent cette géométrie : tool/generate_icons.py.
final class DsLogo extends StatelessWidget {
  const DsLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'DocSafe',
    image: true,
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _LogoPainter()),
    ),
  );
}

final class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final background = Paint()..color = AppColors.brand;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(s * 0.22)),
      background,
    );

    // Document blanc à coin replié.
    final doc = Path()
      ..moveTo(s * 0.30, s * 0.20)
      ..lineTo(s * 0.58, s * 0.20)
      ..lineTo(s * 0.70, s * 0.32)
      ..lineTo(s * 0.70, s * 0.80)
      ..lineTo(s * 0.30, s * 0.80)
      ..close();
    canvas.drawPath(doc, Paint()..color = Colors.white);
    final fold = Path()
      ..moveTo(s * 0.58, s * 0.20)
      ..lineTo(s * 0.58, s * 0.32)
      ..lineTo(s * 0.70, s * 0.32)
      ..close();
    canvas.drawPath(fold, Paint()..color = const Color(0xFFD7E2FF));

    // Serrure : anse puis corps.
    final lock = Paint()
      ..color = AppColors.brand
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.05
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(s * 0.50, s * 0.49),
        width: s * 0.16,
        height: s * 0.16,
      ),
      3.14159,
      3.14159,
      false,
      lock,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(s * 0.50, s * 0.60),
          width: s * 0.24,
          height: s * 0.18,
        ),
        Radius.circular(s * 0.04),
      ),
      Paint()..color = AppColors.brand,
    );
    canvas.drawCircle(
      Offset(s * 0.50, s * 0.60),
      s * 0.03,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
