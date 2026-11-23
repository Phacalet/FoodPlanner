import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

/// Connexion par numéro de téléphone (code SMS) ou par e-mail + mot de passe.
class AuthService {
  AuthService._();
  static final instance = AuthService._();
  final _auth = FirebaseAuth.instance;

  Stream<User?> get userChanges => _auth.authStateChanges();
  User? get current => _auth.currentUser;

  // ---------- Téléphone ----------
  String? _verificationId;
  int? _resendToken;

  /// Envoie le code SMS. Retourne null si OK, sinon un message d'erreur.
  /// Sur Android le code peut être lu automatiquement : [onAutoSignIn] est alors appelé.
  Future<String?> sendSmsCode(String phone, {void Function()? onAutoSignIn}) {
    final c = Completer<String?>();
    _auth.verifyPhoneNumber(
      phoneNumber: phone,
      forceResendingToken: _resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (cred) async {
        await _auth.signInWithCredential(cred);
        onAutoSignIn?.call();
      },
      verificationFailed: (e) {
        if (!c.isCompleted) c.complete(_frenchError(e));
      },
      codeSent: (id, token) {
        _verificationId = id;
        _resendToken = token;
        if (!c.isCompleted) c.complete(null);
      },
      codeAutoRetrievalTimeout: (id) => _verificationId = id,
    );
    return c.future;
  }

  Future<String?> confirmSmsCode(String code) async {
    if (_verificationId == null) return 'Demandez d\'abord un code.';
    try {
      final cred = PhoneAuthProvider.credential(
          verificationId: _verificationId!, smsCode: code.trim());
      await _auth.signInWithCredential(cred);
      return null;
    } on FirebaseAuthException catch (e) {
      return _frenchError(e);
    }
  }

  // ---------- E-mail ----------
  /// Connecte, ou crée le compte s'il n'existe pas encore.
  Future<String?> signInOrRegisterWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        try {
          await _auth.createUserWithEmailAndPassword(
              email: email.trim(), password: password);
          return null;
        } on FirebaseAuthException catch (e2) {
          if (e2.code == 'email-already-in-use') return 'Mot de passe incorrect.';
          return _frenchError(e2);
        }
      }
      return _frenchError(e);
    }
  }

  Future<void> signOut() => _auth.signOut();

  String _frenchError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Numéro invalide. Exemple : +225 07 00 00 00 00';
      case 'invalid-verification-code':
        return 'Code incorrect, vérifiez le SMS.';
      case 'invalid-email':
        return 'Adresse e-mail invalide.';
      case 'weak-password':
        return 'Mot de passe trop court (6 caractères minimum).';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'too-many-requests':
        return 'Trop d\'essais. Réessayez dans quelques minutes.';
      case 'network-request-failed':
        return 'Pas de connexion internet.';
      default:
        return e.message ?? 'Une erreur est survenue.';
    }
  }
}

/// Normalise un contact pour retrouver les invitations :
/// e-mail en minuscules, téléphone au format +XXXXXXXX.
String normalizeContact(String raw) {
  final s = raw.trim();
  if (s.contains('@')) return s.toLowerCase();
  var digits = s.replaceAll(RegExp(r'[^0-9+]'), '');
  if (digits.startsWith('00')) digits = '+${digits.substring(2)}';
  if (!digits.startsWith('+')) digits = '+225$digits'; // Côte d'Ivoire par défaut
  return digits;
}
