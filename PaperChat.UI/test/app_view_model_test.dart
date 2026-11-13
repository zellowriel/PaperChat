import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperchat_mobile/data/analytics_repository.dart';
import 'package:paperchat_mobile/data/auth_repository.dart';
import 'package:paperchat_mobile/data/paper_chat_repository.dart';
import 'package:paperchat_mobile/models/api_models.dart';
import 'package:paperchat_mobile/viewmodels/app_view_model.dart';

void main() {
  test(
    'bootstrap loads profile and documents for a restored session',
    () async {
      final auth = _FakeAuthRepository(restoreResult: true);
      final analytics = _FakeAnalyticsRepository();
      final repository = _FakePaperChatRepository();
      final viewModel = AppViewModel(
        analyticsRepository: analytics,
        authRepository: auth,
        repository: repository,
      );

      await viewModel.bootstrap();

      expect(viewModel.isSignedIn, isTrue);
      expect(viewModel.user, same(repository.profile));
      expect(viewModel.documents, repository.documents);
      expect(viewModel.selectedDocument, same(repository.documents.first));
      expect(repository.profileReads, 1);
      expect(repository.documentReads, 1);
      expect(viewModel.bootstrapError, isNull);
      viewModel.dispose();
    },
  );

  test(
    'bootstrap skips protected API calls without a restored session',
    () async {
      final auth = _FakeAuthRepository(restoreResult: false);
      final analytics = _FakeAnalyticsRepository();
      final repository = _FakePaperChatRepository();
      final viewModel = AppViewModel(
        analyticsRepository: analytics,
        authRepository: auth,
        repository: repository,
      );

      await viewModel.bootstrap();

      expect(viewModel.isSignedIn, isFalse);
      expect(repository.profileReads, 0);
      expect(repository.documentReads, 0);
      expect(viewModel.bootstrapError, isNull);
      viewModel.dispose();
    },
  );

  test(
    'registration skips protected API calls before email verification',
    () async {
      final auth = _FakeAuthRepository(restoreResult: false);
      final analytics = _FakeAnalyticsRepository();
      final repository = _FakePaperChatRepository();
      final viewModel = AppViewModel(
        analyticsRepository: analytics,
        authRepository: auth,
        repository: repository,
      );

      await viewModel.register(
        email: 'reader@example.com',
        password: 'secure-password',
        fullName: 'Reader',
      );

      expect(auth.signedIn, isFalse);
      expect(repository.profileReads, 0);
      expect(repository.documentReads, 0);
      viewModel.dispose();
    },
  );

  test('records a question when the user submits it', () async {
    final analytics = _FakeAnalyticsRepository();
    final viewModel = AppViewModel(
      analyticsRepository: analytics,
      authRepository: _FakeAuthRepository(restoreResult: false),
      repository: _FakePaperChatRepository(),
    );

    final result = await viewModel.sendChat(
      documentId: 'document-id',
      question: 'What is this?',
    );

    expect(result.answer, 'Test answer');
    expect(analytics.questionsAsked, 1);
    viewModel.dispose();
  });

  test('records a PDF only after the repository upload succeeds', () async {
    final analytics = _FakeAnalyticsRepository();
    final repository = _FakePaperChatRepository();
    final viewModel = AppViewModel(
      analyticsRepository: analytics,
      authRepository: _FakeAuthRepository(restoreResult: false),
      repository: repository,
    );

    final uploaded = await viewModel.uploadPdf(_FakePlatformFile());

    expect(uploaded, same(repository.documents.first));
    expect(analytics.pdfsUploaded, 1);
    viewModel.dispose();
  });
}

base class _FakePlatformFile extends PlatformFile {
  @override
  String get name => 'paper.pdf';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAnalyticsRepository implements AnalyticsRepository {
  int questionsAsked = 0;
  int pdfsUploaded = 0;

  @override
  void logQuestionAsked() => questionsAsked++;

  @override
  void logPdfUploaded() => pdfsUploaded++;
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({required this.restoreResult});

  final bool restoreResult;
  bool signedIn = false;

  @override
  bool get isSignedIn => signedIn;

  @override
  Future<String?> getIdToken() async => signedIn ? 'test-token' : null;

  @override
  Future<bool> restoreSession() async {
    signedIn = restoreResult;
    return restoreResult;
  }

  @override
  Future<void> signIn(
    String email,
    String password, {
    required bool remember,
  }) async {
    signedIn = true;
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    signedIn = false;
  }

  @override
  Future<void> signOut() async {
    signedIn = false;
  }
}

class _FakePaperChatRepository implements PaperChatRepository {
  final profile = const UserProfile(
    id: 'user-id',
    email: 'reader@example.com',
    storageUsedBytes: 0,
    storageLimitBytes: 1024,
    planType: 'FREE',
    createdAt: null,
  );
  final documents = [
    const PaperDocument(
      id: 'document-id',
      title: 'Paper',
      sizeBytes: 10,
      pageCount: 1,
      readingProgress: 0,
      isProcessed: true,
      createdAt: null,
    ),
  ];
  int profileReads = 0;
  int documentReads = 0;
  Object? uploadFailure;

  @override
  Future<UserProfile> getProfile() async {
    profileReads++;
    return profile;
  }

  @override
  Future<List<PaperDocument>> getDocuments() async {
    documentReads++;
    return documents;
  }

  @override
  Future<PaperDocument> uploadPdf(
    PlatformFile file, {
    String? title,
    String? authors,
    void Function(int sent, int total)? onProgress,
  }) async {
    if (uploadFailure != null) throw uploadFailure!;
    return documents.first;
  }

  @override
  Future<Uint8List> downloadPdf(String documentId) =>
      throw UnimplementedError();

  @override
  Future<void> updateReadingProgress(String documentId, int progress) =>
      throw UnimplementedError();

  @override
  Future<void> deleteDocument(String documentId) => throw UnimplementedError();

  @override
  Future<List<ChatMessage>> getChatHistory(String documentId) =>
      throw UnimplementedError();

  @override
  Future<ChatSendResult> sendChat({
    required String documentId,
    required String question,
    String? quote,
  }) async => const ChatSendResult(answer: 'Test answer');
}
