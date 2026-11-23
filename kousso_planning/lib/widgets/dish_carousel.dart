import 'dart:async';
import 'package:material_ui/material_ui.dart';
import '../theme.dart';

class Dish {
  final String asset;
  final String name;
  const Dish(this.asset, this.name);
}

/// Plats affichés en haut de l'app. Pour mettre vos propres photos :
/// déposez-les dans assets/plats/ et ajoutez-les ici.
const dishes = [
  Dish('assets/plats/attieke_poisson_alloco.jpg', 'Attiéké poisson braisé & alloco'),
  Dish('assets/plats/foutou_sauce_graine.jpg', 'Foutou banane, sauce graine'),
  Dish('assets/plats/poulet_yassa_riz.jpg', 'Poulet yassa & riz'),
  Dish('assets/plats/placali_sauce_gombo.jpg', 'Placali, sauce gombo'),
  Dish('assets/plats/foutou_sauce_arachide.jpg', 'Foutou, sauce arachide au poulet'),
  Dish('assets/plats/riz_poulet_tomate.jpg', 'Riz, poulet sauce tomate'),
];

/// Carrousel de plats qui défile tout seul (toutes les 3,5 s), coins bas arrondis,
/// dégradé sombre pour la lisibilité. [builder] dessine le contenu par-dessus
/// et reçoit les points de navigation à placer où l'on veut.
class DishCarousel extends StatefulWidget {
  final double height;
  final Widget Function(BuildContext context, Dish current, Widget dots) builder;
  const DishCarousel({super.key, required this.height, required this.builder});

  @override
  State<DishCarousel> createState() => _DishCarouselState();
}

class _DishCarouselState extends State<DishCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (!_controller.hasClients) return;
      final next = (_index + 1) % dishes.length;
      _controller.animateToPage(next,
          duration: const Duration(milliseconds: 700), curve: Curves.easeInOutCubic);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final d in dishes) {
      precacheImage(AssetImage(d.asset), context);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Widget _dots() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < dishes.length; i++)
            GestureDetector(
              onTap: () => _controller.animateToPage(i,
                  duration: const Duration(milliseconds: 500), curve: Curves.easeOut),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _index ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _index ? AppColors.or : Colors.white.withOpacity(.55),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: dishes.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => Image.asset(
                dishes[i].asset,
                fit: BoxFit.cover,
                semanticLabel: dishes[i].name,
              ),
            ),
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, .3, .48, 1],
                    colors: [
                      Color(0x8C140A05),
                      Color(0x00140A05),
                      Color(0x00140A05),
                      Color(0xD1140A05),
                    ],
                  ),
                ),
              ),
            ),
            widget.builder(context, dishes[_index], _dots()),
          ],
        ),
      ),
    );
  }
}

/// Logo texte « Kousso Planning ».
class KoussoBrand extends StatelessWidget {
  final double size;
  const KoussoBrand({super.key, this.size = 24});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme.titleLarge!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('Kousso',
            style: t.copyWith(
                fontSize: size, color: Colors.white, fontWeight: FontWeight.w800, height: 1)),
        const SizedBox(width: 6),
        Text('Planning',
            style: t.copyWith(
                fontSize: size, color: AppColors.or, fontWeight: FontWeight.w600, height: 1)),
      ],
    );
  }
}

/// Petite étiquette « nom du plat » sur la photo.
class DishTag extends StatelessWidget {
  final String text;
  const DishTag(this.text, {super.key});
  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: Container(
          key: ValueKey(text),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0x73140A05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(text,
              style: const TextStyle(
                  color: Color(0xFFFFF6EC), fontWeight: FontWeight.w800, fontSize: 13)),
        ),
      );
}
