import 'package:material_ui/material_ui.dart';
import '../models/models.dart';
import '../services/repository.dart';
import '../theme.dart';
import '../widgets/dish_carousel.dart';

/// Après le prénom : rejoindre la famille qui m'a invitée,
/// ou créer mon cercle et inviter mon conjoint.
class CircleSetupScreen extends StatefulWidget {
  final AppUser me;
  const CircleSetupScreen({super.key, required this.me});
  @override
  State<CircleSetupScreen> createState() => _CircleSetupScreenState();
}

class _CircleSetupScreenState extends State<CircleSetupScreen> {
  final _family = TextEditingController(text: 'Famille ');
  final _spouse = TextEditingController();
  bool _busy = false;

  Future<void> _create() async {
    if (_family.text.trim().length < 3) return;
    setState(() => _busy = true);
    final repo = Repository.instance;
    final id = await repo.createCircle(_family.text, widget.me.name);
    if (_spouse.text.trim().isNotEmpty) {
      await repo.invite(id, _family.text.trim(), _spouse.text, widget.me.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DishCarousel(
              height: 230,
              builder: (context, dish, dots) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const KoussoBrand(size: 22),
                      const Spacer(),
                      Text('Votre cercle familial',
                          style: t.headlineMedium?.copyWith(color: Colors.white)),
                      const SizedBox(height: 8),
                      dots,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: StreamBuilder<List<Invite>>(
                stream: Repository.instance.watchMyInvites(),
                builder: (context, snap) {
                  final invites = snap.data ?? [];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final inv in invites) _InviteCard(inv, widget.me),
                      if (invites.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Center(
                            child: Text('— ou créez votre propre cercle —',
                                style: TextStyle(color: AppColors.cacaoSoft))),
                        const SizedBox(height: 16),
                      ],
                      Text('Nom de la famille', style: t.titleMedium),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _family,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 22),
                      Text('Votre conjoint(e)', style: t.titleMedium),
                      const SizedBox(height: 4),
                      const Text(
                          'Son numéro ou son e-mail. Dès qu\'il/elle se connecte, '
                          'vous partagez les mêmes fiches.',
                          style: TextStyle(color: AppColors.cacaoSoft)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _spouse,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: '+225 07… ou nom@mail.com',
                          prefixIcon: Icon(Icons.favorite_rounded,
                              color: AppColors.terracotta),
                        ),
                      ),
                      const SizedBox(height: 28),
                      FilledButton(
                        onPressed: _busy ? null : _create,
                        child: const Text('Créer notre cercle'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  final Invite inv;
  final AppUser me;
  const _InviteCard(this.inv, this.me);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.ocreLight,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('💌  ${inv.invitedByName} vous invite',
                style: Theme.of(context).textTheme.titleMedium),
            Text('à rejoindre « ${inv.circleName} »'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => Repository.instance.acceptInvite(inv, me.name),
                  child: const Text('Rejoindre'),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: () => Repository.instance.declineInvite(inv),
                child: const Text('Refuser'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
