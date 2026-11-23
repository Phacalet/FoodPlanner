import 'package:material_ui/material_ui.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/dish_carousel.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _byPhone = true;
  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  final _phone = TextEditingController(text: '+225 ');
  final _code = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  Future<void> _run(Future<String?> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await action();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
    });
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
              height: 360,
              builder: (context, dish, dots) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(alignment: Alignment.topRight, child: DishTag(dish.name)),
                      const Spacer(),
                      const KoussoBrand(size: 42),
                      const SizedBox(height: 8),
                      Text('Le menu de la semaine, décidé ensemble à la maison.',
                          style: t.titleMedium?.copyWith(
                              color: const Color(0xFFF4E9DA), fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      dots,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Bienvenue chez vous', style: t.headlineSmall),
                  const SizedBox(height: 14),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('📱  Téléphone')),
                      ButtonSegment(value: false, label: Text('✉️  E-mail')),
                    ],
                    selected: {_byPhone},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => setState(() {
                      _byPhone = s.first;
                      _error = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                  if (_byPhone) ..._phoneForm() else ..._emailForm(),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.terracotta.withOpacity(.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_error!,
                          style: const TextStyle(
                              color: AppColors.terracottaDark,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _phoneForm() {
    if (!_codeSent) {
      return [
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          decoration: const InputDecoration(
              labelText: 'Votre numéro de téléphone',
              prefixIcon: Icon(Icons.phone_rounded)),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _busy
              ? null
              : () => _run(() async {
                    final err = await AuthService.instance
                        .sendSmsCode(normalizeContact(_phone.text));
                    if (err == null) setState(() => _codeSent = true);
                    return err;
                  }),
          child: _busy ? const _Loader() : const Text('Recevoir mon code par SMS'),
        ),
      ];
    }
    return [
      Text('Entrez le code reçu au ${_phone.text}',
          style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      TextField(
        controller: _code,
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 30, letterSpacing: 12, fontWeight: FontWeight.w800),
        decoration: const InputDecoration(counterText: '', hintText: '••••••'),
      ),
      const SizedBox(height: 18),
      FilledButton(
        onPressed: _busy
            ? null
            : () => _run(() => AuthService.instance.confirmSmsCode(_code.text)),
        child: _busy ? const _Loader() : const Text('Valider'),
      ),
      TextButton(
        onPressed: () => setState(() => _codeSent = false),
        child: const Text('Changer de numéro'),
      ),
    ];
  }

  List<Widget> _emailForm() => [
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
              labelText: 'Adresse e-mail', prefixIcon: Icon(Icons.mail_rounded)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          obscureText: true,
          decoration: const InputDecoration(
              labelText: 'Mot de passe (6 caractères min.)',
              prefixIcon: Icon(Icons.lock_rounded)),
        ),
        const SizedBox(height: 6),
        const Text('Pas encore de compte ? Il sera créé automatiquement.',
            style: TextStyle(color: AppColors.cacaoSoft)),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _busy
              ? null
              : () => _run(() => AuthService.instance
                  .signInOrRegisterWithEmail(_email.text, _password.text)),
          child: _busy ? const _Loader() : const Text('Continuer'),
        ),
      ];
}

class _Loader extends StatelessWidget {
  const _Loader();
  @override
  Widget build(BuildContext context) => const SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white));
}
