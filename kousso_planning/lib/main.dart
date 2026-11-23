import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart' hide GlobalMaterialLocalizations;
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'models/models.dart';
import 'services/auth_service.dart';
import 'services/push_service.dart';
import 'services/repository.dart';
import 'screens/welcome_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/circle_setup_screen.dart';
import 'screens/home_screen.dart';
import 'theme.dart';
import 'widgets/dish_carousel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('fr_FR');
  runApp(const PlanningCuisineApp());
}

class PlanningCuisineApp extends StatelessWidget {
  const PlanningCuisineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kousso Planning',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const RootGate(),
    );
  }
}

/// Aiguillage : non connectée → accueil ; sans prénom → profil ;
/// sans cercle → création / invitation ; sinon → semaine.
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.userChanges,
      builder: (context, auth) {
        if (auth.connectionState == ConnectionState.waiting) return const _Splash();
        if (auth.data == null) return const WelcomeScreen();
        return StreamBuilder<AppUser?>(
          key: ValueKey(auth.data!.uid),
          stream: Repository.instance.watchMe(),
          builder: (context, me) {
            if (!me.hasData && me.connectionState == ConnectionState.waiting) {
              return const _Splash();
            }
            final user = me.data;
            if (user == null || user.name.isEmpty) return const ProfileScreen();
            _initPushOnce();
            if (user.circleId == null) return CircleSetupScreen(me: user);
            return HomeScreen(me: user);
          },
        );
      },
    );
  }

  static bool _pushReady = false;
  void _initPushOnce() {
    if (_pushReady) return;
    _pushReady = true;
    PushService.instance.init().catchError((Object _) {
      _pushReady = false;
    });
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: AppColors.cacaoNuit,
        body: Center(child: KoussoBrand(size: 40)),
      );
}
