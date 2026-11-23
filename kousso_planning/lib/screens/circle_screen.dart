import 'package:material_ui/material_ui.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/repository.dart';
import '../theme.dart';
import '../widgets/wax_pattern.dart';

/// Onglet « Famille » : membres, invitation, élection du valideur.
class CircleScreen extends StatefulWidget {
  final AppUser me;
  final Circle circle;
  const CircleScreen({super.key, required this.me, required this.circle});
  @override
  State<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends State<CircleScreen> {
  final _contact = TextEditingController();

  Future<void> _invite() async {
    if (_contact.text.trim().length < 6) return;
    await Repository.instance
        .invite(widget.circle.id, widget.circle.name, _contact.text, widget.me.name);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Invitation enregistrée ! ${_contact.text} rejoindra le cercle à sa connexion.')));
    _contact.clear();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = widget.circle;
    final validatorId = c.validatorId;
    final myVote = c.validatorVotes[widget.me.uid];

    return Scaffold(
      appBar: AppBar(title: Text(c.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
        children: [
          // ---------- Valideur ----------
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: AppColors.indigo, borderRadius: BorderRadius.circular(22)),
            child: Row(children: [
              if (validatorId != null)
                MemberAvatar(c.nameOf(validatorId), size: 52, ring: true)
              else
                const Text('🗳️', style: TextStyle(fontSize: 40)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('VALIDEUR DES MENUS',
                      style: TextStyle(
                          color: Colors.white.withOpacity(.7),
                          fontSize: 12,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w900)),
                  Text(validatorId != null ? c.nameOf(validatorId) : 'Pas encore choisi',
                      style: t.titleLarge?.copyWith(color: Colors.white)),
                  Text(
                      validatorId != null
                          ? 'Valide et verrouille les fiches quand tout le monde est d\'accord.'
                          : 'Votez ci-dessous : il faut la majorité des membres.',
                      style: TextStyle(color: Colors.white.withOpacity(.85))),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          Text('Membres du cercle', style: t.titleMedium),
          const SizedBox(height: 8),
          for (final m in c.members)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: MemberAvatar(m.name, ring: m.uid == validatorId),
                title: Text(m.uid == widget.me.uid ? '${m.name} (moi)' : m.name,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(
                    '${c.votesFor(m.uid)} vote${c.votesFor(m.uid) > 1 ? 's' : ''}'
                    '${m.uid == validatorId ? ' • Valideur ✔︎' : ''}'),
                trailing: myVote == m.uid
                    ? const Chip(
                        label: Text('Mon vote'),
                        backgroundColor: AppColors.feuilleLight,
                        labelStyle: TextStyle(
                            color: AppColors.feuille, fontWeight: FontWeight.w800),
                        side: BorderSide.none,
                      )
                    : TextButton(
                        onPressed: () =>
                            Repository.instance.voteValidator(c.id, m.uid),
                        child: const Text('Voter'),
                      ),
              ),
            ),
          const SizedBox(height: 20),
          // ---------- Invitation ----------
          Text('Ajouter quelqu\'un', style: t.titleMedium),
          const Text('Conjoint(e), grande sœur, nounou… par numéro ou e-mail.',
              style: TextStyle(color: AppColors.cacaoSoft)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _contact,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    hintText: '+225 07… ou nom@mail.com',
                    prefixIcon: Icon(Icons.person_add_alt_1_rounded)),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 56,
              child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(64, 56)),
                onPressed: _invite,
                child: const Icon(Icons.send_rounded),
              ),
            ),
          ]),
          const SizedBox(height: 32),
          const WaxBorder(),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Se déconnecter'),
            onPressed: AuthService.instance.signOut,
          ),
          TextButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (d) => AlertDialog(
                  title: const Text('Quitter le cercle ?'),
                  content: const Text('Vous ne verrez plus les menus de cette famille.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Annuler')),
                    FilledButton(
                        style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
                        onPressed: () => Navigator.pop(d, true),
                        child: const Text('Quitter')),
                  ],
                ),
              );
              if (ok == true) Repository.instance.leaveCircle(c.id);
            },
            child: const Text('Quitter ce cercle familial',
                style: TextStyle(color: AppColors.terracottaDark)),
          ),
        ],
      ),
    );
  }
}
