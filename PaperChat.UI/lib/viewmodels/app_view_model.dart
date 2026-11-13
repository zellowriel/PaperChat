import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../models/api_models.dart';
import '../data/analytics_repository.dart';
import '../data/auth_repository.dart';
import '../data/paper_chat_repository.dart';

class AppViewModel extends ChangeNotifier {
  AppViewModel({
    required AnalyticsRepository analyticsRepository,
    required AuthRepository authRepository,
    required PaperChatRepository repository,
  }) : _analyticsRepository = analyticsRepository,
       _authRepository = authRepository,
       _repository = repository;

  final AnalyticsRepository _analyticsRepository;
  final AuthRepository _authRepository;
  final PaperChatRepository _repository;
  bool isBootstrapping = true;
  bool isDarkMode = false;
  String? bootstrapError;
  UserProfile? user;
  List<PaperDocument> documents = [];
  PaperDocument? selectedDocument;

  bool get isSignedIn => user != null;

  Future<void> bootstrap() async {
    try {
      if (await _authRepository.restoreSession()) {
        user = await _repository.getProfile();
        await refreshDocuments(notify: false);
      }
    } catch (error) {
      bootstrapError = error.toString();
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
    await _authRepository.signIn(email, password, remember: remember);
    await _loadAuthenticatedState();
  }

  Future<void> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    await _authRepository.register(
      email: email,
      password: password,
      fullName: fullName,
    );
  }

  Future<void> _loadAuthenticatedState() async {
    user = await _repository.getProfile();
    await refreshDocuments(notify: false);
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    user = await _repository.getProfile();
    notifyListeners();
  }

  Future<void> refreshDocuments({bool notify = true}) async {
    final oldSelectedId = selectedDocument?.id;
    documents = await _repository.getDocuments();
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
        .map(
          (item) => item.id == documentId
              ? item.copyWith(readingProgress: progress)
              : item,
        )
        .toList();
    if (selectedDocument?.id == documentId) {
      selectedDocument = selectedDocument!.copyWith(readingProgress: progress);
    }
    notifyListeners();
  }

  Future<void> deleteDocument(PaperDocument document) async {
    await _repository.deleteDocument(document.id);
    documents.removeWhere((item) => item.id == document.id);
    if (selectedDocument?.id == document.id) {
      selectedDocument = documents.isEmpty ? null : documents.first;
    }
    await refreshProfile();
    notifyListeners();
  }

  Future<void> logout() async {
    await _authRepository.signOut();
    user = null;
    documents = [];
    selectedDocument = null;
    notifyListeners();
  }

  Future<PaperDocument> uploadPdf(
    PlatformFile file, {
    String? title,
    String? authors,
    void Function(int sent, int total)? onProgress,
  }) async {
    final document = await _repository.uploadPdf(
      file,
      title: title,
      authors: authors,
      onProgress: onProgress,
    );
    _analyticsRepository.logPdfUploaded();
    return document;
  }

  Future<Uint8List> downloadPdf(String documentId) =>
      _repository.downloadPdf(documentId);

  Future<void> updateReadingProgress(String documentId, int progress) =>
      _repository.updateReadingProgress(documentId, progress);

  Future<List<ChatMessage>> getChatHistory(String documentId) =>
      _repository.getChatHistory(documentId);

  Future<ChatSendResult> sendChat({
    required String documentId,
    required String question,
    String? quote,
  }) {
    _analyticsRepository.logQuestionAsked();
    return _repository.sendChat(
      documentId: documentId,
      question: question,
      quote: quote,
    );
  }

  void toggleDarkMode(bool value) {
    isDarkMode = value;
    notifyListeners();
  }
}
