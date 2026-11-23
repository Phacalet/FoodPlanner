/// Catalogue repris à l'identique de la fiche « Planning Cuisine – Famille Ago ».
class MenuSection {
  final String key;
  final String title;
  final String emoji;
  final List<String> items;
  const MenuSection(this.key, this.title, this.emoji, this.items);
}

const sauces = MenuSection('sauces', 'Sauce / Préparation', '🍲', [
  'Akpi', 'Tomate', 'Aubergine', 'Gouagouassou', 'Gombo sec',
  'Gombo frais + dah', 'Arachide', 'Graines', 'Pistache', 'Dida',
  'Pâte passe-partout', 'Pâte piment akpessi', 'Piment poudre + poisson pilé',
  'Yassa', 'Sauce claire', 'Feuilles de manioc', 'Kopè', 'Feuille de patate',
  'Koko', 'Oignon', 'Moutarde', 'Légumes',
]);

const accompagnements = MenuSection('accompagnements', 'Accompagnement', '🍚', [
  'Riz blanc', 'Riz parfumé', 'Riz gras', 'Riz aux légumes', 'Foutou banane',
  'Foufou manioc', 'Attiéké', 'Atoukou', 'Alloco', 'Claclo', 'Igname bouillie',
  'Igname frite', 'Patate douce', 'Pomme de terre', 'Manioc bouilli', 'Placali',
  'Pâtes alimentaires', 'Spaghetti', 'Macaroni', 'Gari', 'Couscous de mil',
  'Purée de pommes de terre',
]);

const proteines = MenuSection('proteines', 'Protéines', '🍗', [
  'Poulet', 'Poulet fumé', 'Bœuf', 'Mouton', 'Porc', 'Veau', 'Dinde',
  'Pintade', 'Canard', 'Escargot', 'Tilapia / carpe', 'Capitaine', 'Thon',
  'Maquereau', 'Sardine', 'Poisson fumé', 'Poisson sec', 'Silure', 'Crabe',
  'Crevettes', 'Écrevisses', 'Champignons', 'Œufs', 'Calamar', 'Moules',
]);

const menuSections = [sauces, accompagnements, proteines];

const joursSemaine = [
  'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
];
