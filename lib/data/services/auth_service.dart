import 'package:firebase_auth/firebase_auth.dart';

/// Erro de autenticação já traduzido para uma frase que o usuário
/// entende. Mensagem crua do Firebase em português técnico não ajuda
/// ninguém a descobrir o que digitou errado.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;

  factory AuthFailure.fromCode(String code) => AuthFailure(switch (code) {
        'invalid-email' => 'Esse e-mail não parece válido.',
        'user-disabled' => 'Essa conta foi desativada.',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          'E-mail ou senha incorretos.',
        'email-already-in-use' => 'Já existe uma conta com esse e-mail.',
        'weak-password' => 'A senha precisa ter pelo menos 6 caracteres.',
        'too-many-requests' => 'Muitas tentativas. Espere um pouco e tente de novo.',
        'network-request-failed' => 'Sem conexão. Verifique sua internet.',
        'operation-not-allowed' =>
          'Login por e-mail e senha não está ativado no Firebase.',
        'requires-recent-login' => 'Faça login de novo para concluir essa ação.',
        _ => 'Não deu para concluir. Tente novamente.',
      });
}

/// Autenticação por e-mail e senha. É a única forma de entrar no app.
class AuthService {
  AuthService(this._auth);

  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;

  String? get uid => _auth.currentUser?.uid;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<User> signIn({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code);
    }
  }

  Future<User> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      if (displayName.trim().isNotEmpty) {
        await user.updateDisplayName(displayName.trim());
        await user.reload();
      }
      return _auth.currentUser ?? user;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code);
    }
  }

  /// Confirma a identidade com a senha atual.
  ///
  /// Trocar a senha e excluir a conta são operações sensíveis: o Firebase
  /// só as aceita com login recente. Reautenticar antes evita depender de
  /// quanto tempo faz que a pessoa entrou.
  Future<void> reauthenticate(String password) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw const AuthFailure('Faça login de novo para concluir essa ação.');
    }

    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
    } on FirebaseAuthException catch (e) {
      // Aqui o e-mail é o da sessão, então "e-mail ou senha incorretos"
      // só confundiria: o que pode estar errado é a senha.
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw const AuthFailure('Senha atual incorreta.');
      }
      throw AuthFailure.fromCode(e.code);
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser!.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code);
    }
  }

  /// Apaga a conta do Auth. Os dados no Firestore precisam ter sido
  /// removidos antes — depois disso não há mais permissão para escrever.
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser!.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code);
    }
  }

  Future<void> signOut() => _auth.signOut();
}
