import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  static const _webOptions = FirebaseOptions(
    apiKey: 'AIzaSyCvxCPL-SzZTwwXUGhYg6CKAFbvLp5Z2bY',
    appId: '1:704733596943:web:c6548673cea4e1aafb427a',
    messagingSenderId: '704733596943',
    projectId: 'paperchat-4284a',
    authDomain: 'paperchat-4284a.firebaseapp.com',
    storageBucket: 'paperchat-4284a.firebasestorage.app',
    measurementId: 'G-GN78J48E96',
  );

  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');

  static FirebaseOptions get current {
    if (kIsWeb) {
      return _webOptions;
    }

    const required = {
      'FIREBASE_API_KEY': _apiKey,
      'FIREBASE_APP_ID': _appId,
      'FIREBASE_MESSAGING_SENDER_ID': _messagingSenderId,
      'FIREBASE_PROJECT_ID': _projectId,
    };
    final missing = required.entries
        .where((entry) => entry.value.isEmpty)
        .map((entry) => entry.key)
        .toList();
    if (missing.isNotEmpty) {
      throw StateError(
        'Firebase chưa được cấu hình. Thiếu: ${missing.join(', ')}.',
      );
    }

    return FirebaseOptions(
      apiKey: _apiKey,
      appId: _appId,
      messagingSenderId: _messagingSenderId,
      projectId: _projectId,
      authDomain: _authDomain.isEmpty ? null : _authDomain,
    );
  }
}
