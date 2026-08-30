import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../models/app_user.dart';
import '../services/firestore_refs.dart';

class UserRepository {
  UserRepository(this._refs);

  final FirestoreRefs _refs;

  /// Espelha a conta do Auth em `users/{uid}`.
  ///
  /// Chamado a cada login: mantém o e-mail atualizado e é o que torna
  /// possível convidar alguém digitando o e-mail.
  Future<AppUser> syncFromAuth(fb.User user) async {
    final email = AppUser.normalizeEmail(user.email ?? '');
    final ref = _refs.user(user.uid);
    final existing = await ref.get();

    final displayName = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : (existing.data()?['displayName'] as String?) ?? AppUser.nameFromEmail(email);

    final appUser = AppUser(
      uid: user.uid,
      email: email,
      displayName: displayName,
      emoji: (existing.data()?['emoji'] as String?) ?? '🙂',
      createdAt: (existing.data()?['createdAt'] as Timestamp?)?.toDate(),
    );

    await ref.set(appUser.toMap(), SetOptions(merge: true));
    return appUser;
  }

  Stream<AppUser?> watchUser(String uid) =>
      _refs.user(uid).snapshots().map((doc) => doc.exists ? AppUser.fromDoc(doc) : null);

  /// Procura uma conta pelo e-mail.
  ///
  /// Devolve `null` quando ninguém com aquele e-mail criou conta ainda —
  /// é assim que o app avisa "essa pessoa ainda não tem cadastro".
  Future<AppUser?> findByEmail(String email) async {
    final normalized = AppUser.normalizeEmail(email);
    if (normalized.isEmpty) return null;

    final snap = await _refs.users
        .where('email', isEqualTo: normalized)
        .limit(1)
        .get();

    return snap.docs.isEmpty ? null : AppUser.fromDoc(snap.docs.first);
  }

  Future<void> updateProfile(String uid, {String? displayName, String? emoji}) =>
      _refs.user(uid).set({
        'displayName': ?displayName,
        'emoji': ?emoji,
      }, SetOptions(merge: true));
}
