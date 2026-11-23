import 'package:material_ui/material_ui.dart';
import '../services/repository.dart';
import '../theme.dart';

/// Première connexion : on demande juste le prénom.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Text('👋🏾', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text('Bienvenue !', style: t.displaySmall),
              const SizedBox(height: 6),
              Text('Comment voulez-vous qu\'on vous appelle dans la famille ?',
                  style: t.titleMedium?.copyWith(color: AppColors.cacaoSoft)),
              const SizedBox(height: 24),
              TextField(
                controller: _name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(hintText: 'Ex. : Maman Adjoua'),
              ),
              const Spacer(flex: 2),
              FilledButton(
                onPressed: _busy
                    ? null
                    : () async {
                        if (_name.text.trim().isEmpty) return;
                        setState(() => _busy = true);
                        await Repository.instance.saveProfile(_name.text);
                      },
                child: const Text('C\'est moi !'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
