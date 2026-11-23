import 'dart:async';
import 'package:material_ui/material_ui.dart';
import '../models/models.dart';
import '../services/dates.dart';
import '../services/repository.dart';
import '../theme.dart';
import '../widgets/wax_pattern.dart';

/// La fiche d'un jour — équivalent d'une page du PDF.
/// Modifiable par tous les membres tant qu'elle n'est pas verrouillée ;
/// une fois validée par le valideur, elle passe en lecture seule.
class DayScreen extends StatelessWidget {
  final AppUser me;
  final String circleId;
  final DateTime date;
  const DayScreen(
      {super.key, required this.me, required this.circleId, required this.date});

  @override
  Widget build(BuildContext context) {
    final repo = Repository.instance;
    final key = Dates.key(date);
    return StreamBuilder<Circle>(
      stream: repo.watchCircle(circleId),
      builder: (context, cSnap) => StreamBuilder<DayPlan>(
        stream: repo.watchDay(circleId, key),
        builder: (context, dSnap) {
          if (!cSnap.hasData || !dSnap.hasData) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final circle = cSnap.data!;
          final plan = dSnap.data!;
          return Scaffold(
            appBar: AppBar(
              title: Text(Dates.dayLong(date)),
              backgroundColor: plan.locked ? AppColors.feuilleLight : AppColors.creme,
            ),
            body: plan.locked
                ? _LockedView(circle: circle, plan: plan, me: me)
                : _Editor(circle: circle, plan: plan, me: me),
            bottomNavigationBar: plan.locked
                ? null
                : _AgreementBar(circle: circle, plan: plan, me: me),
          );
        },
      ),
    );
  }
}

// ======================= ÉDITION =======================

class _Editor extends StatefulWidget {
  final Circle circle;
  final DayPlan plan;
  final AppUser me;
  const _Editor({required this.circle, required this.plan, required this.me});
  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  late final _notes = TextEditingController(text: widget.plan.notes);
  late final _ingredients = TextEditingController(text: widget.plan.ingredients);
  final _notesFocus = FocusNode();
  final _ingFocus = FocusNode();
  Timer? _debounce;

  String get _key => widget.plan.dateKey;

  @override
  void didUpdateWidget(covariant _Editor old) {
    super.didUpdateWidget(old);
    // Synchro en direct des textes de l'autre, sauf si je suis en train d'écrire.
    if (!_notesFocus.hasFocus && _notes.text != widget.plan.notes) {
      _notes.text = widget.plan.notes;
    }
    if (!_ingFocus.hasFocus && _ingredients.text != widget.plan.ingredients) {
      _ingredients.text = widget.plan.ingredients;
    }
  }

  void _saveTextSoon() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 900), () {
      Repository.instance.saveText(widget.circle.id, _key,
          notes: _notes.text, ingredients: _ingredients.text);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _notes.dispose();
    _ingredients.dispose();
    _notesFocus.dispose();
    _ingFocus.dispose();
    super.dispose();
  }

  Future<void> _addItem(CatalogSection sec) async {
    final name = await askText(context,
        title: 'Ajouter dans « ${sec.title} »', hint: 'Ex. : Sauce feuille');
    if (name == null || name.isEmpty) return;
    final repo = Repository.instance;
    await repo.addCatalogItem(widget.circle, sec.key, name);
    await repo.toggleChoice(widget.circle.id, _key, sec.key, name, true);
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final editor = plan.lastEditedBy;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        if (editor != null && editor != widget.me.uid)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.ocreLight, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              MemberAvatar(widget.circle.nameOf(editor), size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text('${widget.circle.nameOf(editor)} a modifié cette fiche',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        const Text('Touchez pour cocher un ou plusieurs choix par rubrique',
            style: TextStyle(color: AppColors.cacaoSoft)),
        const SizedBox(height: 10),
        for (final sec in widget.circle.catalog)
          _SectionCard(
            section: sec,
            selected: plan.selectedIn(sec.key),
            onToggle: (item, v) => Repository.instance
                .toggleChoice(widget.circle.id, _key, sec.key, item, v),
            onAdd: () => _addItem(sec),
          ),
        _TextCard(
          emoji: '📝',
          title: 'Notes / repas à préparer',
          controller: _notes,
          focus: _notesFocus,
          hint: 'Ex. : faire la sauce la veille…',
          onChanged: (_) => _saveTextSoon(),
        ),
        _TextCard(
          emoji: '🛒',
          title: 'Ingrédients à acheter',
          controller: _ingredients,
          focus: _ingFocus,
          hint: 'Ex. : 2 kg de graines, piment, gombo…',
          onChanged: (_) => _saveTextSoon(),
        ),
      ],
    );
  }
}

class _SectionCard extends StatefulWidget {
  final CatalogSection section;
  final List<String> selected;
  final void Function(String item, bool selected) onToggle;
  final VoidCallback onAdd;
  const _SectionCard(
      {required this.section,
      required this.selected,
      required this.onToggle,
      required this.onAdd});
  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final sec = widget.section;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  Text(sec.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(sec.title.toUpperCase(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: AppColors.terracotta)),
                  ),
                  if (widget.selected.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                      decoration: BoxDecoration(
                          color: AppColors.terracotta,
                          borderRadius: BorderRadius.circular(12)),
                      child: Text('${widget.selected.length}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w800)),
                    ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.cacaoSoft),
                ]),
              ),
            ),
            if (_expanded)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in sec.items)
                    FilterChip(
                      label: Text(item),
                      selected: widget.selected.contains(item),
                      onSelected: (v) => widget.onToggle(item, v),
                      showCheckmark: true,
                      checkmarkColor: Colors.white,
                      selectedColor: AppColors.terracotta,
                      backgroundColor: AppColors.creme,
                      side: BorderSide(
                          color: widget.selected.contains(item)
                              ? AppColors.terracotta
                              : AppColors.sable),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: widget.selected.contains(item)
                            ? Colors.white
                            : AppColors.cacao,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  // Élément coché mais retiré du catalogue entre-temps : on l'affiche quand même.
                  for (final item in widget.selected.where((s) => !sec.items.contains(s)))
                    InputChip(
                      label: Text(item),
                      selected: true,
                      selectedColor: AppColors.terracotta,
                      labelStyle: const TextStyle(color: Colors.white),
                      onDeleted: () => widget.onToggle(item, false),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18, color: AppColors.feuille),
                    label: const Text('Ajouter'),
                    labelStyle: const TextStyle(
                        color: AppColors.feuille, fontWeight: FontWeight.w800),
                    backgroundColor: AppColors.feuilleLight,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    onPressed: widget.onAdd,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _TextCard extends StatelessWidget {
  final String emoji, title, hint;
  final TextEditingController controller;
  final FocusNode focus;
  final ValueChanged<String> onChanged;
  const _TextCard(
      {required this.emoji,
      required this.title,
      required this.controller,
      required this.focus,
      required this.hint,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$emoji  $title',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                focusNode: focus,
                minLines: 2,
                maxLines: 6,
                onChanged: onChanged,
                decoration: InputDecoration(
                    hintText: hint, fillColor: AppColors.creme),
              ),
            ],
          ),
        ),
      );
}

// ======================= ACCORD & VALIDATION =======================

class _AgreementBar extends StatelessWidget {
  final Circle circle;
  final DayPlan plan;
  final AppUser me;
  const _AgreementBar({required this.circle, required this.plan, required this.me});

  @override
  Widget build(BuildContext context) {
    final repo = Repository.instance;
    final iAgree = plan.agreements[me.uid] == true;
    final allAgree = plan.everyoneAgrees(circle);
    final validatorId = circle.validatorId;
    final iAmValidator = validatorId == me.uid;
    final empty = plan.status == DayStatus.vide;

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(blurRadius: 16, color: Color(0x1A3A2218))],
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            for (final m in circle.members)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Stack(clipBehavior: Clip.none, children: [
                  Opacity(
                    opacity: plan.agreements[m.uid] == true ? 1 : .35,
                    child: MemberAvatar(m.name, size: 34, ring: m.uid == validatorId),
                  ),
                  if (plan.agreements[m.uid] == true)
                    const Positioned(
                      right: -3,
                      bottom: -3,
                      child: CircleAvatar(
                        radius: 9,
                        backgroundColor: AppColors.feuille,
                        child: Icon(Icons.check, size: 12, color: Colors.white),
                      ),
                    ),
                ]),
              ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                allAgree
                    ? 'Tout le monde est d\'accord 🎉'
                    : '${plan.agreements.values.where((v) => v).length} sur ${circle.members.length} d\'accord',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          if (allAgree && iAmValidator)
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.feuille),
              icon: const Icon(Icons.lock_rounded),
              label: const Text('Valider et verrouiller'),
              onPressed: () => repo.lockDay(circle.id, plan.dateKey),
            )
          else if (allAgree)
            _Info(validatorId == null
                ? 'Choisissez un valideur dans l\'onglet Famille pour verrouiller ce menu.'
                : 'En attente de la validation de ${circle.nameOf(validatorId)}.')
          else
            iAgree
                ? OutlinedButton.icon(
                    icon: const Icon(Icons.undo_rounded),
                    label: const Text('Je retire mon accord'),
                    onPressed: () => repo.setAgreement(circle.id, plan.dateKey, false),
                  )
                : FilledButton.icon(
                    icon: const Icon(Icons.thumb_up_alt_rounded),
                    label: const Text('Je suis d\'accord avec ce menu'),
                    onPressed: empty
                        ? null
                        : () => repo.setAgreement(circle.id, plan.dateKey, true),
                  ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final String text;
  const _Info(this.text);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColors.feuilleLight, borderRadius: BorderRadius.circular(16)),
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.feuille, fontWeight: FontWeight.w800)),
      );
}

// ======================= CONSULTATION (VERROUILLÉ) =======================

class _LockedView extends StatelessWidget {
  final Circle circle;
  final DayPlan plan;
  final AppUser me;
  const _LockedView({required this.circle, required this.plan, required this.me});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final isValidator = circle.validatorId == me.uid;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: AppColors.feuille, borderRadius: BorderRadius.circular(22)),
          child: Row(children: [
            const Text('🔒', style: TextStyle(fontSize: 34)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Menu validé',
                    style: t.titleLarge?.copyWith(color: Colors.white)),
                Text(
                    'par ${circle.nameOf(plan.lockedBy ?? '')} • accepté par toute la famille',
                    style: TextStyle(color: Colors.white.withOpacity(.9))),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        for (final sec in circle.catalog)
          if (plan.selectedIn(sec.key).isNotEmpty)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                leading: Text(sec.emoji, style: const TextStyle(fontSize: 30)),
                title: Text(sec.title.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 12,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w900,
                        color: AppColors.terracotta)),
                subtitle: Text(plan.selectedIn(sec.key).join(', '),
                    style: t.titleMedium),
              ),
            ),
        if (plan.notes.isNotEmpty) _ReadCard('📝 Notes', plan.notes),
        if (plan.ingredients.isNotEmpty) _ReadCard('🛒 À acheter', plan.ingredients),
        if (isValidator) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.lock_open_rounded),
            label: const Text('Déverrouiller pour modifier'),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Déverrouiller ce menu ?'),
                  content: const Text(
                      'Tout le monde pourra de nouveau le modifier et devra redonner son accord.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('Annuler')),
                    FilledButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('Déverrouiller')),
                  ],
                ),
              );
              if (ok == true) {
                Repository.instance.unlockDay(circle.id, plan.dateKey);
              }
            },
          ),
        ],
      ],
    );
  }
}

class _ReadCard extends StatelessWidget {
  final String title, body;
  const _ReadCard(this.title, this.body);
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(body, style: const TextStyle(fontSize: 16)),
          ]),
        ),
      );
}

/// Petite boîte de saisie réutilisable.
Future<String?> askText(BuildContext context,
    {required String title, String? hint, String initial = '', String ok = 'Enregistrer'}) {
  final c = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: c,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: hint),
        onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
          onPressed: () => Navigator.pop(ctx, c.text.trim()),
          child: Text(ok),
        ),
      ],
    ),
  );
}
