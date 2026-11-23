import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette chaleureuse inspirée du pagne wax et de la fiche papier.
class AppColors {
  static const terracotta = Color(0xFFB94A2C); // couleur de la fiche
  static const terracottaDark = Color(0xFF8E3420);
  static const ocre = Color(0xFFE3A23B);
  static const ocreLight = Color(0xFFFBE7C2);
  static const or = Color(0xFFF4C063); // or du logo et des accents premium
  static const cacaoNuit = Color(0xFF24150F); // menu flottant
  static const feuille = Color(0xFF2F7A4F); // validé / d'accord
  static const feuilleLight = Color(0xFFDCEFE2);
  static const indigo = Color(0xFF2E2A5A); // verrouillé
  static const creme = Color(0xFFFBF4EA);
  static const sable = Color(0xFFF3E6D3);
  static const cacao = Color(0xFF3A2218); // texte
  static const cacaoSoft = Color(0xFF7A5C4D);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.terracotta,
      primary: AppColors.terracotta,
      secondary: AppColors.ocre,
      tertiary: AppColors.feuille,
      surface: AppColors.creme,
    ),
    scaffoldBackgroundColor: AppColors.creme,
  );
  final body = GoogleFonts.nunitoTextTheme(base.textTheme).apply(
    bodyColor: AppColors.cacao,
    displayColor: AppColors.cacao,
  );
  TextStyle? head(TextStyle? s) =>
      GoogleFonts.baloo2(textStyle: s, fontWeight: FontWeight.w700);

  return base.copyWith(
    textTheme: body.copyWith(
      displaySmall: head(body.displaySmall),
      headlineMedium: head(body.headlineMedium),
      headlineSmall: head(body.headlineSmall),
      titleLarge: head(body.titleLarge),
      titleMedium: head(body.titleMedium),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.creme,
      foregroundColor: AppColors.cacao,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.baloo2(
          fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.cacao),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.terracotta,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.terracotta,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: AppColors.terracotta, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.sable),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.sable, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.terracotta, width: 2),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
