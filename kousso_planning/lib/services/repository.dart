import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import 'auth_service.dart';

/// Accès aux données Firestore. Tout est en temps réel (streams) :
/// quand un membre coche un plat, les autres le voient immédiatement.
///
/// Structure :
///   users/{uid}                     nom, email, phone, circleId, fcmTokens
///   circles/{circleId}              name, memberIds, memberNames, validatorVotes, validatorId
///   circles/{circleId}/days/{date}  choices, notes, ingredients, agreements, locked…
///   invites/{circleId_contact}      contact, circleId, circleName, invitedByName, status
class Repository {
  Repository._();
  static final instance = Repository._();
  final _db = FirebaseFirestore.instance;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  // ---------------- Utilisateur ----------------
  Stream<AppUser?> watchMe() => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((d) => d.exists ? AppUser.fromDoc(d) : null);

  Future<void> saveProfile(String name) {
    final u = FirebaseAuth.instance.currentUser!;
    return _db.collection('users').doc(u.uid).set({
      'name': name.trim(),
      'email': u.email?.toLowerCase(),
      'phone': u.phoneNumber,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---------------- Cercle familial ----------------
  Stream<Circle> watchCircle(String circleId) =>
      _db.collection('circles').doc(circleId).snapshots().map(Circle.fromDoc);

  Future<String> createCircle(String circleName, String myName) async {
    final ref = _db.collection('circles').doc();
    final batch = _db.batch();
    batch.set(ref, {
      'name': circleName.trim(),
      'createdBy': uid,
      'memberIds': [uid],
      'memberNames': {uid: myName},
      'validatorVotes': {},
      'catalog': [for (final c in CatalogSection.defaults()) c.toMap()],
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(_db.collection('users').doc(uid), {'circleId': ref.id},
        SetOptions(merge: true));
    await batch.commit();
    return ref.id;
  }

  /// Invite un conjoint ou un proche par numéro ou e-mail.
  Future<void> invite(
      String circleId, String circleName, String rawContact, String myName) {
    final contact = normalizeContact(rawContact);
    final id = '${circleId}_$contact';
    return _db.collection('invites').doc(id).set({
      'contact': contact,
      'circleId': circleId,
      'circleName': circleName,
      'invitedBy': uid,
      'invitedByName': myName,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Invitations en attente pour mon e-mail ou mon numéro.
  Stream<List<Invite>> watchMyInvites() {
    final u = FirebaseAuth.instance.currentUser!;
    final contacts = [
      if (u.email != null) u.email!.toLowerCase(),
      if (u.phoneNumber != null) u.phoneNumber!,
    ];
    if (contacts.isEmpty) return Stream.value([]);
    return _db
        .collection('invites')
        .where('contact', whereIn: contacts)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs.map(Invite.fromDoc).toList());
  }

  Future<void> acceptInvite(Invite inv, String myName) async {
    final batch = _db.batch();
    batch.update(_db.collection('circles').doc(inv.circleId), {
      'memberIds': FieldValue.arrayUnion([uid]),
      'memberNames.$uid': myName,
    });
    batch.set(_db.collection('users').doc(uid), {'circleId': inv.circleId},
        SetOptions(merge: true));
    batch.update(_db.collection('invites').doc(inv.id),
        {'status': 'accepted', 'acceptedBy': uid});
    await batch.commit();
  }

  Future<void> declineInvite(Invite inv) =>
      _db.collection('invites').doc(inv.id).update({'status': 'declined'});

  /// Enregistre le catalogue modifié (rubriques + éléments) pour toute la famille.
  Future<void> saveCatalog(String circleId, List<CatalogSection> catalog) =>
      _db.collection('circles').doc(circleId).update({
        'catalog': [for (final c in catalog) c.toMap()],
      });

  /// Ajoute un élément à une rubrique (depuis la fiche du jour, bouton « + Ajouter »).
  Future<void> addCatalogItem(Circle circle, String sectionKey, String item) {
    final updated = [
      for (final s in circle.catalog)
        s.key == sectionKey && !s.items.contains(item)
            ? s.copyWith(items: [...s.items, item])
            : s,
    ];
    return saveCatalog(circle.id, updated);
  }

  /// Chaque membre vote pour la personne qui validera les menus.
  Future<void> voteValidator(String circleId, String candidateUid) =>
      _db.collection('circles').doc(circleId).update({
        'validatorVotes.$uid': candidateUid,
      });

  Future<void> leaveCircle(String circleId) async {
    final batch = _db.batch();
    batch.update(_db.collection('circles').doc(circleId), {
      'memberIds': FieldValue.arrayRemove([uid]),
      'memberNames.$uid': FieldValue.delete(),
      'validatorVotes.$uid': FieldValue.delete(),
    });
    batch.update(_db.collection('users').doc(uid), {'circleId': FieldValue.delete()});
    await batch.commit();
  }

  // ---------------- Fiches du jour ----------------
  CollectionReference<Map<String, dynamic>> _days(String circleId) =>
      _db.collection('circles').doc(circleId).collection('days');

  Stream<DayPlan> watchDay(String circleId, String dateKey) =>
      _days(circleId).doc(dateKey).snapshots().map(DayPlan.fromDoc);

  /// Toutes les fiches de la semaine (7 dates) en un seul flux.
  Stream<Map<String, DayPlan>> watchWeek(String circleId, List<String> keys) =>
      _days(circleId)
          .where(FieldPath.documentId, whereIn: keys)
          .snapshots()
          .map((s) => {
                for (final k in keys) k: DayPlan.empty(k),
                for (final d in s.docs) d.id: DayPlan.fromDoc(d),
              });

  /// Coche / décoche un plat. Toute modification remet les accords à zéro :
  /// chacun doit redonner son accord sur la nouvelle version.
  Future<void> toggleChoice(
      String circleId, String dateKey, String section, String item, bool selected) {
    return _days(circleId).doc(dateKey).set({
      'choices': {
        section: selected
            ? FieldValue.arrayUnion([item])
            : FieldValue.arrayRemove([item]),
      },
      'lastEditedBy': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).then((_) => _resetAgreements(circleId, dateKey));
  }

  Future<void> saveText(String circleId, String dateKey,
      {String? notes, String? ingredients}) async {
    await _days(circleId).doc(dateKey).set({
      if (notes != null) 'notes': notes,
      if (ingredients != null) 'ingredients': ingredients,
      'lastEditedBy': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _resetAgreements(circleId, dateKey);
  }

  // set(merge) fusionne les maps : on vide explicitement « agreements ».
  Future<void> _resetAgreements(String circleId, String dateKey) =>
      _days(circleId).doc(dateKey).update({'agreements': <String, bool>{}});

  Future<void> setAgreement(String circleId, String dateKey, bool agree) =>
      _days(circleId).doc(dateKey).set({
        'agreements': {uid: agree},
      }, SetOptions(merge: true));

  /// Réservé au valideur (contrôlé aussi par les règles Firestore).
  Future<void> lockDay(String circleId, String dateKey) =>
      _days(circleId).doc(dateKey).update({
        'locked': true,
        'lockedBy': uid,
        'lockedAt': FieldValue.serverTimestamp(),
      });

  Future<void> unlockDay(String circleId, String dateKey) =>
      _days(circleId).doc(dateKey).update({
        'locked': false,
        'lockedBy': FieldValue.delete(),
        'agreements': <String, bool>{},
      });

  // ---------------- Notifications ----------------
  Future<void> saveFcmToken(String token) =>
      _db.collection('users').doc(uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));
}
