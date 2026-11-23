# Kousso Planning

Application mobile Flutter pour planifier les repas de la semaine **en famille**,
à partir de la fiche « Planning Cuisine – Famille Ago ».

## Ce que fait l'app

**Design** : en haut des écrans d'accueil, de connexion et de création du cercle, un
**carrousel de 6 photos de plats** (attiéké poisson & alloco, foutou sauce graine, poulet yassa,
placali sauce gombo, foutou sauce arachide, riz poulet sauce tomate) défile tout seul. En bas, un **menu premium** flottant, en forme de pilule
aux bords arrondis, avec l'onglet actif en or.
Les photos sont dans `assets/plats/` : remplacez-les par d'autres photos (même nom,
format paysage 3:2, ~1200×800) ou ajoutez-en dans `lib/widgets/dish_carousel.dart`.

| Fonction | Où |
|---|---|
| Connexion par **numéro de téléphone** (code SMS) ou **e-mail** | `welcome_screen.dart` |
| Création du **cercle familial** + invitation du conjoint par numéro / e-mail | `circle_setup_screen.dart` |
| Ajout d'autres membres (sœur, nounou…) avec les mêmes droits | onglet **Famille** |
| **Élection du valideur** par vote des membres (majorité absolue) | onglet **Famille** + Cloud Function `electValidator` |
| Vue **semaine** (lun → dim), progression, statut de chaque jour | onglet **Semaine** |
| **Fiche du jour** : rubriques à cocher, notes, ingrédients à acheter — synchro en direct | `day_screen.dart` |
| Chaque membre donne son **accord** ; toute modification remet les accords à zéro | barre du bas de la fiche |
| Le valideur **valide et verrouille** quand tout le monde est d'accord ; il peut déverrouiller | `day_screen.dart` + `firestore.rules` |
| Fiche verrouillée = **consultation** en lecture seule pour tous | `_LockedView` |
| **Liste modifiable** : ajouter / renommer / supprimer un plat, une sauce, une protéine… ; créer, renommer, réordonner ou supprimer une rubrique ; revenir à la liste d'origine | onglet **Ma liste** (`catalog_screen.dart`) + bouton « Ajouter » directement dans la fiche |
| **Push** : rappel quotidien à 9 h tant que la semaine n'est pas remplie, alerte « X a modifié le menu de mardi », « Menu validé » | `functions/index.js` |

Chaque famille a **sa propre liste** (initialisée avec celle du PDF) : les modifications
d'un membre sont partagées avec tout le cercle.

## Installation (≈ 20 min)

Prérequis : Flutter 3.22+, un compte Firebase, Node 20 et `firebase-tools`.

```bash
# 1. Générer les dossiers android/ et ios/
flutter create . --org com.famille --project-name planning_cuisine
flutter pub get

# 2. Relier l'app à Firebase (remplace lib/firebase_options.dart)
dart pub global activate flutterfire_cli
flutterfire configure

# 3. Dans la console Firebase :
#    - Authentication → activer « Téléphone » et « E-mail/Mot de passe »
#    - Firestore → créer la base (région europe-west ou africa-south1)
#    - Passer au forfait Blaze (requis pour les Cloud Functions planifiées)

# 4. Déployer règles de sécurité + fonctions
firebase init firestore functions   # garder firestore.rules et functions/ existants
cd functions && npm install && cd ..
firebase deploy --only firestore:rules,functions

# 5. Nom affiché sous l'icône : « Kousso Planning »
#    android/app/src/main/AndroidManifest.xml → android:label="Kousso Planning"
#    ios/Runner/Info.plist → CFBundleDisplayName = Kousso Planning

# 6. Lancer
flutter run
```

### Réglages plateformes
- **Android** : dans `android/app/build.gradle`, `minSdkVersion 23`. Pour la connexion par SMS,
  ajouter l'empreinte SHA-256 de l'app dans les paramètres du projet Firebase.
- **iOS** : activer *Push Notifications* et *Background Modes → Remote notifications* dans Xcode,
  et téléverser la clé APNs dans Firebase → Cloud Messaging.

## Modèle de données (Firestore)

```
users/{uid}                    name, email, phone, circleId, fcmTokens[]
circles/{circleId}             name, memberIds[], memberNames{}, validatorVotes{}, validatorId,
                               catalog[ {key, title, emoji, items[]} ]
circles/{circleId}/days/{yyyy-MM-dd}
                               choices{ rubrique: [éléments] }, notes, ingredients,
                               agreements{uid: bool}, locked, lockedBy, lastEditedBy, updatedAt
invites/{circleId_contact}     contact, circleId, circleName, invitedByName, status
```

## Pour plus tard
- Envoi du menu validé / de la liste de courses par **WhatsApp** (`share_plus` ou API WhatsApp Business)
  et par **e-mail** (extension Firebase « Trigger Email ») : il suffira d'écouter le passage
  `locked: true` dans `notifyDayChange`.
