import 'dart:ui' show ImageFilter;
import 'package:material_ui/material_ui.dart';
import '../theme.dart';

class PremiumNavItem {
  final IconData icon;
  final String label;
  const PremiumNavItem(this.icon, this.label);
}

/// Menu du bas « premium » : pilule flottante cacao aux bords arrondis,
/// onglet actif en or avec son libellé.
class PremiumNav extends StatelessWidget {
  final int index;
  final List<PremiumNavItem> items;
  final ValueChanged<int> onTap;
  const PremiumNav(
      {super.key, required this.index, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          boxShadow: const [
            BoxShadow(color: Color(0x5924150F), blurRadius: 30, offset: Offset(0, 12)),
          ],
        ),
        child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: BackdropFilter(
        // Fond légèrement transparent + flou : on devine le contenu derrière.
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
        height: 68,
        padding: const EdgeInsets.all(8),
        color: AppColors.cacaoNuit.withOpacity(.78),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: Semantics(
                  selected: i == index,
                  button: true,
                  label: items[i].label,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        gradient: i == index
                            ? const LinearGradient(
                                colors: [Color(0xFFF4C063), AppColors.ocre])
                            : null,
                        boxShadow: i == index
                            ? const [
                                BoxShadow(
                                    color: Color(0x59E3A23B),
                                    blurRadius: 12,
                                    offset: Offset(0, 4))
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(items[i].icon,
                              size: 21,
                              color: i == index
                                  ? AppColors.cacaoNuit
                                  : const Color(0xFFE9DCCB)),
                          if (i == index) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(items[i].label,
                                  overflow: TextOverflow.fade,
                                  softWrap: false,
                                  style: const TextStyle(
                                      color: AppColors.cacaoNuit,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        ),
        ),
        ),
      ),
    );
  }
}
