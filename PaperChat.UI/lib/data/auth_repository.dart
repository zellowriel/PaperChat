import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/app_exception.dart';

abstract interface class AuthRepository {
  bool get isSignedIn;
  Future<bool> restoreSession();
  Future<String?> getIdToken();
  Future<void> signIn(String email, String password, {required bool remember});
  Future<void> register({
    required String email,
    required String password,
    String? fullName,
  });
  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  static const _rememberKey = 'paperchat_remember_session';
  static const _legacyTokenKey = 'paperchat_access_token';
  static const _storage = FlutterSecureStorage();

  final FirebaseAuth _auth;

  @override
  bool get isSignedIn => _auth.currentUser != null;

  @override
  Future<bool> restoreSession() async {
    await _storage.delete(key: _legacyTokenKey);
    final remember = await _storage.read(key: _rememberKey);
    if (remember == 'false') {
      await _auth.signOut();
      await _storage.delete(key: _rememberKey);
      return false;
    }
    return isSignedIn;
  }

  @override
  Future<String?> getIdToken() async => _auth.currentUser?.getIdToken();

  @override
  Future<void> signIn(
    String email,
    String password, {
    required bool remember,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _storage.write(key: _rememberKey, value: remember.toString());
    } on FirebaseAuthException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final name = fullName?.trim();
      if (name != null && name.isNotEmpty) {
        await credential.user?.updateDisplayName(name);
      }
      await credential.user?.sendEmailVerification();
      await _auth.signOut();
      await _storage.delete(key: _rememberKey);
    } on FirebaseAuthException catch (error) {
      throw AppException(_messageFor(error));
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    await _storage.delete(key: _rememberKey);
    await _storage.delete(key: _legacyTokenKey);
  }

  String _messageFor(FirebaseAuthException error) => switch (error.code) {
    'invalid-email' => 'Email không hợp lệ.',
    'user-disabled' => 'Tài khoản này đã bị vô hiệu hóa.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'Email hoặc mật khẩu không chính xác.',
    'email-already-in-use' => 'Email này đã được đăng ký.',
    'weak-password' => 'Mật khẩu chưa đủ mạnh.',
    'network-request-failed' =>
      'Không thể kết nối Firebase. Hãy kiểm tra kết nối mạng.',
    'too-many-requests' => 'Bạn đã thử quá nhiều lần. Vui lòng thử lại sau.',
    _ => error.message ?? 'Không thể xác thực tài khoản.',
  };
}
