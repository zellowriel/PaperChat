import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract interface class AnalyticsRepository {
  void logQuestionAsked();
  void logPdfUploaded();
}

class FirebaseAnalyticsRepository implements AnalyticsRepository {
  FirebaseAnalyticsRepository(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  void logQuestionAsked() => _logEvent('question_asked');

  @override
  void logPdfUploaded() => _logEvent('pdf_uploaded');

  void _logEvent(String name) {
    unawaited(_logEventSafely(name));
  }

  Future<void> _logEventSafely(String name) async {
    try {
      await _analytics.logEvent(name: name);
    } on FirebaseException catch (error, stackTrace) {
      _reportError(error, stackTrace);
    } on PlatformException catch (error, stackTrace) {
      _reportError(error, stackTrace);
    } on MissingPluginException catch (error, stackTrace) {
      _reportError(error, stackTrace);
    }
  }

  void _reportError(Object error, StackTrace stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'Firebase Analytics',
        context: ErrorDescription('while logging a PaperChat event'),
      ),
    );
  }
}
