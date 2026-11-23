import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/menu_catalog.dart';

/// Une rubrique de la fiche (Sauce, Accompagnement, Protéines, ou ajoutée par la famille).
/// Le titre, l'emoji et la liste des éléments sont modifiables.
class CatalogSection {
  final String key;
  final String title;
  final String emoji;
  final List<String> items;
  CatalogSection({
    required this.key,
    required this.title,
    required this.emoji,
    required this.items,
  });

  factory CatalogSection.fromMap(Map<String, dynamic> m) => CatalogSection(
        key: m['key'] as String,
        title: (m['title'] ?? '') as String,
        emoji: (m['emoji'] ?? '🍽️') as String,
        items: List<String>.from(m['items'] ?? []),
      );

  Map<String, dynamic> toMap() =>
      {'key': key, 'title': title, 'emoji': emoji, 'items': items};

  CatalogSection copyWith({String? title, String? emoji, List<String>? items}) =>
      CatalogSection(
        key: key,
        title: title ?? this.title,
        emoji: emoji ?? this.emoji,
        items: items ?? List.of(this.items),
      );

  /// Catalogue de départ = celui de la fiche PDF.
  static List<CatalogSection> defaults() => [
        for (final s in menuSections)
          CatalogSection(key: s.key, title: s.title, emoji: s.emoji, items: List.of(s.items)),
      ];
}

class AppUser {
  final String uid;
  final String name;
  final String? email;
  final String? phone;
  final String? circleId;
  AppUser({
    required this.uid,
    required this.name,
    this.email,
    this.phone,
    this.circleId,
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return AppUser(
      uid: d.id,
      name: (m['name'] ?? '') as String,
      email: m['email'] as String?,
      phone: m['phone'] as String?,
      circleId: m['circleId'] as String?,
    );
  }
}

class Member {
  final String uid;
  final String name;
  Member(this.uid, this.name);
}

/// Le cercle familial : le couple + les personnes ajoutées.
class Circle {
  final String id;
  final String name;
  final List<Member> members;

  /// Vote de chaque membre : votant -> candidat au rôle de valideur.
  final Map<String, String> validatorVotes;

  /// Calculé côté serveur (Cloud Function) à partir des votes.
  final String? storedValidatorId;

  /// Rubriques et éléments propres à cette famille.
  final List<CatalogSection> catalog;

  Circle({
    required this.catalog,
    this.storedValidatorId,
    required this.id,
    required this.name,
    required this.members,
    required this.validatorVotes,
  });

  factory Circle.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    final names = Map<String, dynamic>.from(m['memberNames'] ?? {});
    final ids = List<String>.from(m['memberIds'] ?? []);
    return Circle(
      id: d.id,
      name: (m['name'] ?? 'Ma famille') as String,
      members: [for (final id in ids) Member(id, (names[id] ?? 'Membre') as String)],
      validatorVotes: Map<String, String>.from(m['validatorVotes'] ?? {}),
      storedValidatorId: m['validatorId'] as String?,
      catalog: m['catalog'] is List
          ? [
              for (final e in m['catalog'] as List)
                CatalogSection.fromMap(Map<String, dynamic>.from(e as Map)),
            ]
          : CatalogSection.defaults(),
    );
  }

  String nameOf(String uid) =>
      members.firstWhere((e) => e.uid == uid, orElse: () => Member(uid, 'Membre')).name;

  int votesFor(String uid) => validatorVotes.values.where((v) => v == uid).length;

  /// Le valideur est celui qui a la majorité absolue des votes des membres.
  /// S'il n'y a qu'un seul membre, il est valideur d'office.
  String? get validatorId => storedValidatorId ?? computedValidatorId;

  String? get computedValidatorId {
    if (members.length == 1) return members.first.uid;
    for (final m in members) {
      if (votesFor(m.uid) * 2 > members.length) return m.uid;
    }
    return null;
  }
}

enum DayStatus { vide, enCours, verrouille }

/// La fiche d'un jour (une page du PDF).
class DayPlan {
  final String dateKey; // yyyy-MM-dd
  final Map<String, List<String>> choices; // clé de rubrique -> éléments cochés
  final String notes;
  final String ingredients;
  final Map<String, bool> agreements; // uid -> "je suis d'accord"
  final bool locked;
  final String? lockedBy;
  final String? lastEditedBy;
  final DateTime? updatedAt;

  DayPlan({
    required this.dateKey,
    required this.choices,
    required this.notes,
    required this.ingredients,
    required this.agreements,
    required this.locked,
    this.lockedBy,
    this.lastEditedBy,
    this.updatedAt,
  });

  factory DayPlan.empty(String key) => DayPlan(
        dateKey: key,
        choices: {},
        notes: '',
        ingredients: '',
        agreements: {},
        locked: false,
      );

  factory DayPlan.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    if (!d.exists) return DayPlan.empty(d.id);
    final m = d.data()!;
    final c = Map<String, dynamic>.from(m['choices'] ?? {});
    return DayPlan(
      dateKey: d.id,
      choices: {
        for (final e in c.entries) e.key: List<String>.from(e.value ?? []),
      },
      notes: (m['notes'] ?? '') as String,
      ingredients: (m['ingredients'] ?? '') as String,
      agreements: Map<String, bool>.from(m['agreements'] ?? {}),
      locked: (m['locked'] ?? false) as bool,
      lockedBy: m['lockedBy'] as String?,
      lastEditedBy: m['lastEditedBy'] as String?,
      updatedAt: (m['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  int get totalChoices => choices.values.fold(0, (a, b) => a + b.length);

  DayStatus get status {
    if (locked) return DayStatus.verrouille;
    if (totalChoices == 0 && notes.isEmpty) return DayStatus.vide;
    return DayStatus.enCours;
  }

  bool everyoneAgrees(Circle c) =>
      c.members.isNotEmpty && c.members.every((m) => agreements[m.uid] == true);

  List<String> selectedIn(String sectionKey) => choices[sectionKey] ?? const [];

  /// Résumé lisible dans l'ordre des rubriques : « Sauce graines · Riz blanc · Poulet ».
  String summary(List<CatalogSection> catalog) {
    final parts = <String>[
      for (final sec in catalog)
        for (final item in selectedIn(sec.key))
          sec.key == 'sauces' ? 'Sauce ${item.toLowerCase()}' : item,
    ];
    return parts.isEmpty ? 'Rien de prévu pour le moment' : parts.join(' · ');
  }
}

class Invite {
  final String id;
  final String circleId;
  final String circleName;
  final String invitedByName;
  Invite(this.id, this.circleId, this.circleName, this.invitedByName);

  factory Invite.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return Invite(d.id, m['circleId'] as String, (m['circleName'] ?? '') as String,
        (m['invitedByName'] ?? '') as String);
  }
}
