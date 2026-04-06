import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Вход по email ─────────────────────────────────────────────────
  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // ── Вход через Google ─────────────────────────────────────────────
  Future<String?> signInWithGoogle() async {
    // Открываем окно выбора аккаунта Google
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // пользователь закрыл окно

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;
    final uid = user.uid;

    // Проверяем есть ли пользователь в Firestore
    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists) {
      // Новый пользователь — создаём пару и профиль
      final coupleId = const Uuid().v4();
      final inviteCode = _generateCode();

      await _db.collection('couples').doc(coupleId).set({
        'members': [uid],
        'inviteCode': inviteCode,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('users').doc(uid).set({
        'name': googleUser.displayName ?? googleUser.email.split('@').first,
        'email': user.email ?? '',
        'photoUrl': googleUser.photoUrl ?? '',
        'coupleId': coupleId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // Возвращаем имя чтобы сохранить в profileProvider
    final userData = await _db.collection('users').doc(uid).get();
    return userData.data()?['name'] as String?;
  }

  // ── Регистрация ───────────────────────────────────────────────────
  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? inviteCode,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;

    if (inviteCode != null && inviteCode.isNotEmpty) {
      final coupleQuery = await _db
          .collection('couples')
          .where('inviteCode', isEqualTo: inviteCode)
          .limit(1)
          .get();

      if (coupleQuery.docs.isNotEmpty) {
        final coupleId = coupleQuery.docs.first.id;
        await _db.collection('couples').doc(coupleId).update({
          'members': FieldValue.arrayUnion([uid]),
        });
        await _db.collection('users').doc(uid).set({
          'name': name,
          'email': email,
          'coupleId': coupleId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return;
      }
    }

    final coupleId = const Uuid().v4();
    final newInviteCode = _generateCode();

    await _db.collection('couples').doc(coupleId).set({
      'members': [uid],
      'inviteCode': newInviteCode,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'coupleId': coupleId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Выход ─────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ── Данные пользователя ───────────────────────────────────────────
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = DateTime.now().millisecondsSinceEpoch;
    return List.generate(
      6,
      (i) => chars[(rand ~/ (i + 1)) % chars.length],
    ).join();
  }
}

// ── Providers ─────────────────────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserDataProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  return ref.read(authRepositoryProvider).getUserData(user.uid);
});
