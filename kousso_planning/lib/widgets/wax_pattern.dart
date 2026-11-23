import 'package:material_ui/material_ui.dart';
import '../theme.dart';

/// Motif géométrique façon pagne wax (cercles concentrés + losanges),
/// dessiné en code : aucune image à embarquer.
class WaxPattern extends StatelessWidget {
  final double height;
  final Color background;
  final Widget? child;
  const WaxPattern({
    super.key,
    this.height = 180,
    this.background = AppColors.terracotta,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _WaxPainter(background),
        child: child,
      ),
    );
  }
}

class _WaxPainter extends CustomPainter {
  final Color bg;
  _WaxPainter(this.bg);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = bg);
    const cell = 56.0;
    final ocre = Paint()..color = AppColors.ocre.withOpacity(.55);
    final creme = Paint()
      ..color = AppColors.creme.withOpacity(.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final dark = Paint()..color = AppColors.terracottaDark.withOpacity(.6);

    for (double y = -cell / 2; y < size.height + cell; y += cell) {
      final row = (y / cell).round();
      for (double x = -cell / 2; x < size.width + cell; x += cell) {
        final cx = x + (row.isOdd ? cell / 2 : 0);
        final c = Offset(cx, y);
        canvas.drawCircle(c, 17, dark);
        canvas.drawCircle(c, 11, ocre);
        canvas.drawCircle(c, 22, creme);
        // petit losange entre les cercles
        final d = Offset(cx + cell / 2, y + cell / 2);
        final path = Path()
          ..moveTo(d.dx, d.dy - 7)
          ..lineTo(d.dx + 7, d.dy)
          ..lineTo(d.dx, d.dy + 7)
          ..lineTo(d.dx - 7, d.dy)
          ..close();
        canvas.drawPath(path, Paint()..color = AppColors.creme.withOpacity(.35));
      }
    }
    // dégradé bas pour lisibilité du texte
    final shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [bg.withOpacity(.15), bg.withOpacity(.92)],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _WaxPainter old) => old.bg != bg;
}

/// Liseré décoratif fin (frise) à placer sous un en-tête.
class WaxBorder extends StatelessWidget {
  const WaxBorder({super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 10,
        width: double.infinity,
        child: CustomPaint(painter: _BorderPainter()),
      );
}

class _BorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final colors = [AppColors.terracotta, AppColors.ocre, AppColors.feuille, AppColors.indigo];
    const w = 14.0;
    for (var i = 0; i * w < size.width; i++) {
      final p = Path()
        ..moveTo(i * w, size.height)
        ..lineTo(i * w + w / 2, 0)
        ..lineTo(i * w + w, size.height)
        ..close();
      canvas.drawPath(p, Paint()..color = colors[i % colors.length]);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Avatar rond avec initiale, couleur stable par personne.
class MemberAvatar extends StatelessWidget {
  final String name;
  final double size;
  final bool ring;
  const MemberAvatar(this.name, {super.key, this.size = 40, this.ring = false});

  static const _palette = [
    AppColors.terracotta, AppColors.feuille, AppColors.indigo,
    Color(0xFFC17A12), Color(0xFF8A3D6B),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _palette[name.hashCode.abs() % _palette.length];
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: ring ? Border.all(color: AppColors.ocre, width: 3) : null,
      ),
      alignment: Alignment.center,
      child: Text(initial,
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: size * .42)),
    );
  }
}
