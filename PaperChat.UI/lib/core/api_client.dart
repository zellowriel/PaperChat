import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/api_models.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class PaperChatApi {
  PaperChatApi(String baseUrl)
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl.replaceFirst(RegExp(r'/+$'), ''),
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 180),
            sendTimeout: const Duration(seconds: 180),
            headers: const {'Accept': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = _accessToken ?? await _storage.read(key: _tokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
  }

  static const _tokenKey = 'paperchat_access_token';
  static const _storage = FlutterSecureStorage();

  final Dio _dio;
  String? _accessToken;

  Future<bool> restoreToken() async {
    _accessToken = await _storage.read(key: _tokenKey);
    return _accessToken != null && _accessToken!.isNotEmpty;
  }

  Future<void> _saveToken(String token, {required bool remember}) async {
    _accessToken = token;
    if (remember) {
      await _storage.write(key: _tokenKey, value: token);
    } else {
      await _storage.delete(key: _tokenKey);
    }
  }

  Future<void> logout() async {
    _accessToken = null;
    await _storage.delete(key: _tokenKey);
  }

  Future<AuthResult> login(
    String email,
    String password, {
    required bool remember,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/login',
        data: {'email': email.trim(), 'password': password},
      );
      final result = AuthResult.fromJson(response.data ?? {});
      await _saveToken(result.accessToken, remember: remember);
      return result;
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<AuthResult> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/register',
        data: {
          'email': email.trim(),
          'password': password,
          'fullName': fullName?.trim(),
        },
      );
      final result = AuthResult.fromJson(response.data ?? {});
      await _saveToken(result.accessToken, remember: true);
      return result;
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<UserProfile> getMe() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/v1/users/me');
      return UserProfile.fromJson(response.data ?? {});
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<List<PaperDocument>> getDocuments({int page = 1, int pageSize = 50}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/documents',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      final rawItems = response.data?['items'] as List? ?? const [];
      return rawItems
          .whereType<Map>()
          .map((item) => PaperDocument.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<PaperDocument> uploadPdf(
    PlatformFile file, {
    String? title,
    String? authors,
    void Function(int sent, int total)? onProgress,
  }) async {
    late final Uint8List fileBytes;
    try {
      // file_picker v13: PlatformFile không còn thuộc tính bytes.
      // Đọc nội dung thông qua readAsBytes() sau khi người dùng chọn file.
      fileBytes = await file.readAsBytes();
    } catch (_) {
      throw const ApiException(
        'Không đọc được dữ liệu file. Vui lòng chọn lại PDF.',
      );
    }

    if (fileBytes.isEmpty) {
      throw const ApiException('File PDF đang trống.');
    }

    try {
      final form = FormData.fromMap({
        'File': MultipartFile.fromBytes(
          fileBytes,
          filename: file.name,
        ),
        if (title != null && title.trim().isNotEmpty) 'Title': title.trim(),
        if (authors != null && authors.trim().isNotEmpty)
          'Authors': authors.trim(),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/documents',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: onProgress,
      );
      return PaperDocument.fromJson(response.data ?? {});
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<Uint8List> downloadPdf(String documentId) async {
    try {
      final response = await _dio.get<List<int>>(
        '/api/v1/documents/$documentId/file',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data ?? const <int>[]);
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<void> updateReadingProgress(String documentId, int progress) async {
    try {
      await _dio.patch<void>(
        '/api/v1/documents/$documentId/progress',
        data: {'readingProgress': progress.clamp(0, 100)},
      );
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<void> deleteDocument(String documentId) async {
    try {
      await _dio.delete<void>('/api/v1/documents/$documentId');
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<List<ChatMessage>> getChatHistory(String documentId) async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/v1/chat/$documentId');
      return (response.data ?? const [])
          .whereType<Map>()
          .map((item) => ChatMessage.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<ChatSendResult> sendChat({
    required String documentId,
    required String question,
    String? quote,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/chat',
        data: {
          'documentId': documentId,
          'question': question.trim(),
          'quote': quote,
          'chatHistory': <Map<String, String>>[],
        },
      );
      return ChatSendResult.fromJson(response.data ?? {});
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  ApiException _toApiException(DioException error) {
    final data = error.response?.data;
    String? message;
    if (data is Map) {
      message = data['detail']?.toString() ?? data['title']?.toString();
      final errors = data['errors'];
      if (message == null && errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) message = first.first.toString();
      }
    } else if (data is String && data.isNotEmpty) {
      message = data;
    }
    message ??= switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'Kết nối tới máy chủ quá thời gian. Vui lòng thử lại.',
      DioExceptionType.connectionError =>
        'Không thể kết nối máy chủ. Hãy kiểm tra API URL và mạng.',
      _ => error.message ?? 'Đã xảy ra lỗi khi gọi API.',
    };
    return ApiException(message, statusCode: error.response?.statusCode);
  }
}
