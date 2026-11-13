class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    required this.storageUsedBytes,
    required this.storageLimitBytes,
    required this.planType,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String? fullName;
  final int storageUsedBytes;
  final int storageLimitBytes;
  final String planType;
  final DateTime? createdAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        fullName: json['fullName'] as String?,
        storageUsedBytes: (json['storageUsedBytes'] as num?)?.toInt() ?? 0,
        storageLimitBytes: (json['storageLimitBytes'] as num?)?.toInt() ??
            10 * 1024 * 1024 * 1024,
        planType: json['planType']?.toString() ?? 'FREE',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      );
}

class AuthResult {
  const AuthResult({required this.accessToken, required this.user});

  final String accessToken;
  final UserProfile user;

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        accessToken: json['accessToken']?.toString() ?? '',
        user: UserProfile.fromJson(
          Map<String, dynamic>.from(json['user'] as Map? ?? const {}),
        ),
      );
}

class PaperDocument {
  const PaperDocument({
    required this.id,
    required this.title,
    this.authors,
    required this.sizeBytes,
    required this.pageCount,
    required this.readingProgress,
    required this.isProcessed,
    required this.createdAt,
    this.downloadUrl = '',
  });

  final String id;
  final String title;
  final String? authors;
  final int sizeBytes;
  final int pageCount;
  final int readingProgress;
  final bool isProcessed;
  final DateTime? createdAt;
  final String downloadUrl;

  factory PaperDocument.fromJson(Map<String, dynamic> json) => PaperDocument(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Untitled document',
        authors: json['authors'] as String?,
        sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
        pageCount: (json['pageCount'] as num?)?.toInt() ?? 0,
        readingProgress: (json['readingProgress'] as num?)?.toInt() ?? 0,
        isProcessed: json['isProcessed'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
        downloadUrl: json['downloadUrl']?.toString() ?? '',
      );

  PaperDocument copyWith({int? readingProgress, int? pageCount}) =>
      PaperDocument(
        id: id,
        title: title,
        authors: authors,
        sizeBytes: sizeBytes,
        pageCount: pageCount ?? this.pageCount,
        readingProgress: readingProgress ?? this.readingProgress,
        isProcessed: isProcessed,
        createdAt: createdAt,
        downloadUrl: downloadUrl,
      );
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderRole,
    required this.content,
    this.quoteReference,
    this.citationPage,
    this.createdAt,
  });

  final String id;
  final String senderRole;
  final String content;
  final String? quoteReference;
  final int? citationPage;
  final DateTime? createdAt;

  bool get isUser => senderRole.toUpperCase() == 'USER';

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id']?.toString() ?? '',
        senderRole: json['senderRole']?.toString() ?? 'AI',
        content: json['content']?.toString() ?? '',
        quoteReference: json['quoteReference'] as String?,
        citationPage: (json['citationPage'] as num?)?.toInt(),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      );
}

class ChatSendResult {
  const ChatSendResult({
    required this.answer,
    this.citationPage,
    this.createdAt,
  });

  final String answer;
  final int? citationPage;
  final DateTime? createdAt;

  factory ChatSendResult.fromJson(Map<String, dynamic> json) => ChatSendResult(
        answer: json['answer']?.toString() ?? '',
        citationPage: (json['citationPage'] as num?)?.toInt(),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      );
}
