import 'package:material_ui/material_ui.dart';
import '../models/models.dart';
import '../services/repository.dart';
import '../theme.dart';
import 'day_screen.dart' show askText;

/// « Ma liste » : la famille personnalise la fiche.
///  - ajouter / renommer / supprimer un élément (plat, sauce, protéine…)
///  - ajouter / renommer / réordonner / supprimer une rubrique
/// Les changements sont partagés en direct avec tout le cercle familial.
class CatalogScreen extends StatelessWidget {
  final Circle circle;
  const CatalogScreen({super.key, required this.circle});

  List<CatalogSection> get _cat => [for (final s in circle.catalog) s.copyWith()];

  Future<void> _save(List<CatalogSection> c) =>
      Repository.instance.saveCatalog(circle.id, c);

  void _replace(CatalogSection updated) => _save(
      [for (final s in _cat) s.key == updated.key ? updated : s]);

  // ---------- éléments ----------
  Future<void> _addItem(BuildContext context, CatalogSection sec) async {
    final v = await askText(context,
        title: 'Ajouter dans « ${sec.title} »', hint: 'Nom de l\'élément', ok: 'Ajouter');
    if (v == null || v.isEmpty || sec.items.contains(v)) return;
    _replace(sec.copyWith(items: [...sec.items, v]));
  }

  Future<void> _renameItem(BuildContext context, CatalogSection sec, String item) async {
    final v = await askText(context, title: 'Modifier l\'élément', initial: item);
    if (v == null || v.isEmpty || v == item) return;
    _replace(sec.copyWith(items: [for (final i in sec.items) i == item ? v : i]));
  }

  void _deleteItem(BuildContext context, CatalogSection sec, String item) {
    final before = sec;
    _replace(sec.copyWith(items: sec.items.where((i) => i != item).toList()));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('« $item » supprimé'),
        action: SnackBarAction(label: 'Annuler', onPressed: () => _replace(before)),
      ));
  }

  // ---------- rubriques ----------
  Future<void> _addSection(BuildContext context) async {
    final title = await askText(context,
        title: 'Nouvelle rubrique', hint: 'Ex. : Boissons, Desserts, Petit-déjeuner', ok: 'Créer');
    if (title == null || title.isEmpty) return;
    final emoji = await _pickEmoji(context) ?? '🍽️';
    _save([
      ..._cat,
      CatalogSection(
          key: 'r${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          emoji: emoji,
          items: []),
    ]);
  }

  Future<void> _sectionMenu(BuildContext context, CatalogSection sec, String action) async {
    final list = _cat;
    final i = list.indexWhere((s) => s.key == sec.key);
    switch (action) {
      case 'rename':
        final v = await askText(context, title: 'Renommer la rubrique', initial: sec.title);
        if (v != null && v.isNotEmpty) _replace(sec.copyWith(title: v));
      case 'emoji':
        final e = await _pickEmoji(context);
        if (e != null) _replace(sec.copyWith(emoji: e));
      case 'up':
        if (i > 0) {
          list.insert(i - 1, list.removeAt(i));
          _save(list);
        }
      case 'down':
        if (i < list.length - 1) {
          list.insert(i + 1, list.removeAt(i));
          _save(list);
        }
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text('Supprimer « ${sec.title} » ?'),
            content: Text('La rubrique et ses ${sec.items.length} éléments seront retirés de la fiche.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
              FilledButton(
                  onPressed: () => Navigator.pop(c, true),
                  style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
                  child: const Text('Supprimer')),
            ],
          ),
        );
        if (ok == true) _save(list..removeAt(i));
    }
  }

  Future<String?> _pickEmoji(BuildContext context) {
    const emojis = [
      '🍲', '🍚', '🍗', '🐟', '🥩', '🥗', '🍌', '🌶️', '🧅', '🥜',
      '🍠', '🥖', '🍳', '🥤', '🧃', '☕', '🍰', '🍉', '🥭', '🍽️',
    ];
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final e in emojis)
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.pop(c, e),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(e, style: const TextStyle(fontSize: 30)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma liste de plats'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (_) async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Revenir à la liste d\'origine ?'),
                  content: const Text('Vos ajouts et modifications seront effacés.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
                    FilledButton(
                        onPressed: () => Navigator.pop(c, true),
                        style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
                        child: const Text('Rétablir')),
                  ],
                ),
              );
              if (ok == true) _save(CatalogSection.defaults());
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'reset', child: Text('Rétablir la liste d\'origine')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.feuille,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.playlist_add_rounded),
        label: const Text('Nouvelle rubrique',
            style: TextStyle(fontWeight: FontWeight.w800)),
        onPressed: () => _addSection(context),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 190),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
                'Touchez un élément pour le renommer, la croix pour le supprimer. '
                'Les changements sont partagés avec toute la famille.',
                style: TextStyle(color: AppColors.cacaoSoft)),
          ),
          for (final sec in circle.catalog)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 4, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(sec.emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('${sec.title.toUpperCase()}  ·  ${sec.items.length}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                                color: AppColors.terracotta)),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: AppColors.cacaoSoft),
                        onSelected: (a) => _sectionMenu(context, sec, a),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'rename', child: Text('✏️  Renommer')),
                          PopupMenuItem(value: 'emoji', child: Text('😀  Changer l\'icône')),
                          PopupMenuItem(value: 'up', child: Text('⬆️  Monter')),
                          PopupMenuItem(value: 'down', child: Text('⬇️  Descendre')),
                          PopupMenuItem(value: 'delete', child: Text('🗑️  Supprimer')),
                        ],
                      ),
                    ]),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final item in sec.items)
                            InputChip(
                              label: Text(item),
                              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                              backgroundColor: AppColors.creme,
                              side: const BorderSide(color: AppColors.sable),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              onPressed: () => _renameItem(context, sec, item),
                              deleteIcon: const Icon(Icons.close_rounded, size: 18),
                              onDeleted: () => _deleteItem(context, sec, item),
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
                            onPressed: () => _addItem(context, sec),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
