import 'package:flutter/foundation.dart';

import '../models/api_models.dart';
import 'api_client.dart';

class AppController extends ChangeNotifier {
  AppController(this.api);

  final PaperChatApi api;
  bool isBootstrapping = true;
  bool isDarkMode = false;
  UserProfile? user;
  List<PaperDocument> documents = [];
  PaperDocument? selectedDocument;

  bool get isSignedIn => user != null;

  Future<void> bootstrap() async {
    try {
      final hasToken = await api.restoreToken();
      if (hasToken) {
        user = await api.getMe();
        await refreshDocuments(notify: false);
      }
    } catch (_) {
      await api.logout();
      user = null;
      documents = [];
      selectedDocument = null;
    } finally {
      isBootstrapping = false;
      notifyListeners();
    }
  }

  Future<void> login(
    String email,
    String password, {
    required bool remember,
  }) async {
    final result = await api.login(email, password, remember: remember);
    user = result.user;
    await refreshDocuments(notify: false);
    notifyListeners();
  }

  Future<void> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final result = await api.register(
      email: email,
      password: password,
      fullName: fullName,
    );
    user = result.user;
    await refreshDocuments(notify: false);
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    user = await api.getMe();
    notifyListeners();
  }

  Future<void> refreshDocuments({bool notify = true}) async {
    final oldSelectedId = selectedDocument?.id;
    documents = await api.getDocuments();
    if (oldSelectedId != null) {
      for (final item in documents) {
        if (item.id == oldSelectedId) {
          selectedDocument = item;
          break;
        }
      }
    }
    if (selectedDocument == null && documents.isNotEmpty) {
      selectedDocument = documents.first;
    }
    if (notify) notifyListeners();
  }

  void selectDocument(PaperDocument document) {
    selectedDocument = document;
    notifyListeners();
  }

  void updateLocalProgress(String documentId, int progress) {
    documents = documents
        .map((item) => item.id == documentId
            ? item.copyWith(readingProgress: progress)
            : item)
        .toList();
    if (selectedDocument?.id == documentId) {
      selectedDocument = selectedDocument!.copyWith(readingProgress: progress);
    }
    notifyListeners();
  }

  Future<void> deleteDocument(PaperDocument document) async {
    await api.deleteDocument(document.id);
    documents.removeWhere((item) => item.id == document.id);
    if (selectedDocument?.id == document.id) {
      selectedDocument = documents.isEmpty ? null : documents.first;
    }
    await refreshProfile();
    notifyListeners();
  }

  Future<void> logout() async {
    await api.logout();
    user = null;
    documents = [];
    selectedDocument = null;
    notifyListeners();
  }

  void toggleDarkMode(bool value) {
    isDarkMode = value;
    notifyListeners();
  }
}
