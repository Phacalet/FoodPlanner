import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'repository.dart';

/// Notifications push :
///  - côté serveur (functions/index.js) : rappel quotidien tant que la semaine
///    en cours n'est pas complète + alerte quand un menu est modifié / validé ;
///  - côté app : enregistrement du jeton et affichage quand l'app est ouverte.
class PushService {
  PushService._();
  static final instance = PushService._();

  final _local = FlutterLocalNotificationsPlugin();
  static const _channel = AndroidNotificationChannel(
    'planning_cuisine',
    'Kousso Planning',
    description: 'Rappels pour remplir le menu de la semaine',
    importance: Importance.high,
  );

  Future<void> init() async {
    final fm = FirebaseMessaging.instance;
    await fm.requestPermission(alert: true, badge: true, sound: true);

    await _local.initialize(settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ));
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    final token = await fm.getToken();
    if (token != null) await Repository.instance.saveFcmToken(token);
    fm.onTokenRefresh.listen(Repository.instance.saveFcmToken);

    // App ouverte : on affiche quand même la notification.
    FirebaseMessaging.onMessage.listen((msg) {
      final n = msg.notification;
      if (n == null) return;
      _local.show(
        id: n.hashCode,
        title: n.title,
        body: n.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(_channel.id, _channel.name,
              channelDescription: _channel.description,
              importance: Importance.high,
              priority: Priority.high),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    });
  }
}
