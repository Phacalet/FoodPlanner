import 'package:material_ui/material_ui.dart';
import '../models/models.dart';
import '../services/dates.dart';
import '../services/repository.dart';
import '../theme.dart';
import '../widgets/dish_carousel.dart';
import '../widgets/premium_nav.dart';
import '../widgets/wax_pattern.dart';
import 'catalog_screen.dart';
import 'circle_screen.dart';
import 'day_screen.dart';

/// Écran principal : 3 onglets — Semaine, Ma liste (catalogue), Famille.
class HomeScreen extends StatefulWidget {
  final AppUser me;
  const HomeScreen({super.key, required this.me});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Circle>(
      stream: Repository.instance.watchCircle(widget.me.circleId!),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final circle = snap.data!;
        final pages = [
          WeekView(me: widget.me, circle: circle),
          CatalogScreen(circle: circle),
          CircleScreen(me: widget.me, circle: circle),
        ];
        return Scaffold(
          body: IndexedStack(index: _tab, children: pages),
          extendBody: true,
          bottomNavigationBar: PremiumNav(
            index: _tab,
            onTap: (i) => setState(() => _tab = i),
            items: const [
              PremiumNavItem(Icons.calendar_month_rounded, 'Semaine'),
              PremiumNavItem(Icons.restaurant_menu_rounded, 'Ma liste'),
              PremiumNavItem(Icons.diversity_1_rounded, 'Famille'),
            ],
          ),
        );
      },
    );
  }
}

class WeekView extends StatefulWidget {
  final AppUser me;
  final Circle circle;
  const WeekView({super.key, required this.me, required this.circle});
  @override
  State<WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends State<WeekView> {
  DateTime _monday = Dates.mondayOf(DateTime.now());

  void _shift(int weeks) =>
      setState(() => _monday = _monday.add(Duration(days: 7 * weeks)));

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final days = Dates.weekOf(_monday);
    final keys = days.map(Dates.key).toList();

    return StreamBuilder<Map<String, DayPlan>>(
      stream: Repository.instance.watchWeek(widget.circle.id, keys),
      builder: (context, snap) {
        final plans = snap.data ?? {for (final k in keys) k: DayPlan.empty(k)};
        final filled = plans.values.where((p) => p.status != DayStatus.vide).length;
        final locked = plans.values.where((p) => p.locked).length;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: DishCarousel(
                height: 310,
                builder: (context, dish, dots) => SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const KoussoBrand(size: 24),
                          const Spacer(),
                          MemberAvatar(widget.me.name, size: 40, ring: true),
                        ]),
                        const SizedBox(height: 10),
                        DishTag(dish.name),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Bonjour ${widget.me.name} · ${widget.circle.name}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Color(0xFFF4E9DA),
                                          fontWeight: FontWeight.w800)),
                                  Text('Semaine ${Dates.weekLabel(_monday)}',
                                      style: t.titleLarge?.copyWith(color: Colors.white)),
                                ],
                              ),
                            ),
                            dots,
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Bandeau « verre » : progression + navigation de semaine
                        Container(
                          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.16),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Colors.white.withOpacity(.25)),
                          ),
                          child: Row(children: [
                            Expanded(child: _WeekProgress(filled: filled, locked: locked)),
                            const SizedBox(width: 6),
                            _RoundBtn(Icons.chevron_left, () => _shift(-1)),
                            const SizedBox(width: 4),
                            _RoundBtn(Icons.chevron_right, () => _shift(1)),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              sliver: SliverList.separated(
                itemCount: 7,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _DayCard(
                  date: days[i],
                  plan: plans[keys[i]]!,
                  circle: widget.circle,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DayScreen(
                          me: widget.me, circleId: widget.circle.id, date: days[i]),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundBtn(this.icon, this.onTap);
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white.withOpacity(.2),
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: onTap,
          constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          icon: Icon(icon, color: Colors.white),
        ),
      );
}

class _WeekProgress extends StatelessWidget {
  final int filled, locked;
  const _WeekProgress({required this.filled, required this.locked});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      for (var i = 0; i < 7; i++)
        Expanded(
          child: Container(
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: i < locked
                  ? AppColors.or
                  : i < filled
                      ? AppColors.or.withOpacity(.55)
                      : Colors.white.withOpacity(.3),
            ),
          ),
        ),
      const SizedBox(width: 10),
      Text('$locked/7 validé${locked > 1 ? 's' : ''}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
    ]);
  }
}

class _DayCard extends StatelessWidget {
  final DateTime date;
  final DayPlan plan;
  final Circle circle;
  final VoidCallback onTap;
  const _DayCard(
      {required this.date, required this.plan, required this.circle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final today = Dates.isToday(date);
    final dayName = Dates.dayLong(date).split(' ').first;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: today ? AppColors.ocre : AppColors.sable, width: today ? 2.5 : 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 64,
                decoration: BoxDecoration(
                  color: plan.locked ? AppColors.feuille : AppColors.sable,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(dayName.substring(0, 3).toUpperCase(),
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: plan.locked ? Colors.white : AppColors.terracotta)),
                  Text('${date.day}',
                      style: t.headlineSmall?.copyWith(
                          height: 1,
                          color: plan.locked ? Colors.white : AppColors.cacao)),
                ]),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(dayName, style: t.titleMedium),
                      if (today) ...[
                        const SizedBox(width: 6),
                        const Text('• aujourd\'hui',
                            style: TextStyle(
                                color: AppColors.ocre, fontWeight: FontWeight.w800)),
                      ],
                      const Spacer(),
                      StatusBadge(plan.status),
                    ]),
                    const SizedBox(height: 4),
                    Text(plan.summary(circle.catalog),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: plan.status == DayStatus.vide
                                ? AppColors.cacaoSoft
                                : AppColors.cacao,
                            fontStyle: plan.status == DayStatus.vide
                                ? FontStyle.italic
                                : FontStyle.normal)),
                    if (plan.status == DayStatus.enCours) ...[
                      const SizedBox(height: 6),
                      Row(children: [
                        for (final m in circle.members)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Opacity(
                              opacity: plan.agreements[m.uid] == true ? 1 : .3,
                              child: MemberAvatar(m.name, size: 22),
                            ),
                          ),
                        const SizedBox(width: 4),
                        Text(
                            '${plan.agreements.values.where((v) => v).length}/${circle.members.length} d\'accord',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.cacaoSoft)),
                      ]),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final DayStatus status;
  const StatusBadge(this.status, {super.key});
  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      DayStatus.vide => ('À remplir', AppColors.ocreLight, const Color(0xFF9A6410)),
      DayStatus.enCours => ('En discussion', const Color(0xFFFBE0D6), AppColors.terracottaDark),
      DayStatus.verrouille => ('🔒 Validé', AppColors.feuilleLight, AppColors.feuille),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}
