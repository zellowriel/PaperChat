import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../core/api_client.dart';
import '../models/api_models.dart';

abstract interface class PaperChatRepository {
  Future<UserProfile> getProfile();
  Future<List<PaperDocument>> getDocuments();
  Future<PaperDocument> uploadPdf(
    PlatformFile file, {
    String? title,
    String? authors,
    void Function(int sent, int total)? onProgress,
  });
  Future<Uint8List> downloadPdf(String documentId);
  Future<void> updateReadingProgress(String documentId, int progress);
  Future<void> deleteDocument(String documentId);
  Future<List<ChatMessage>> getChatHistory(String documentId);
  Future<ChatSendResult> sendChat({
    required String documentId,
    required String question,
    String? quote,
  });
}

class ApiPaperChatRepository implements PaperChatRepository {
  ApiPaperChatRepository(this._api);

  final PaperChatApi _api;

  @override
  Future<UserProfile> getProfile() => _api.getMe();

  @override
  Future<List<PaperDocument>> getDocuments() => _api.getDocuments();

  @override
  Future<PaperDocument> uploadPdf(
    PlatformFile file, {
    String? title,
    String? authors,
    void Function(int sent, int total)? onProgress,
  }) => _api.uploadPdf(
    file,
    title: title,
    authors: authors,
    onProgress: onProgress,
  );

  @override
  Future<Uint8List> downloadPdf(String documentId) =>
      _api.downloadPdf(documentId);

  @override
  Future<void> updateReadingProgress(String documentId, int progress) =>
      _api.updateReadingProgress(documentId, progress);

  @override
  Future<void> deleteDocument(String documentId) =>
      _api.deleteDocument(documentId);

  @override
  Future<List<ChatMessage>> getChatHistory(String documentId) =>
      _api.getChatHistory(documentId);

  @override
  Future<ChatSendResult> sendChat({
    required String documentId,
    required String question,
    String? quote,
  }) => _api.sendChat(documentId: documentId, question: question, quote: quote);
}
