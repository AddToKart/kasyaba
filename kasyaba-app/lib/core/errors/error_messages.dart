import 'package:dio/dio.dart';

/// Maps transport and API failures to short, user-friendly copy.
///
/// Raw exception strings must never reach the UI. Server-authored messages are
/// used for validation-style 4xx responses, while infrastructure failures are
/// translated locally.
String friendlyErrorMessage(
  Object? error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  if (error is! DioException) return fallback;

  final status = error.response?.statusCode;
  if (status != null) {
    switch (status) {
      case 401:
        return 'Your session has expired. Please sign in again.';
      case 403:
        return 'You do not have access to this action.';
      case 404:
        return 'This item is no longer available.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
    }

    final data = error.response?.data;
    if (data is Map && data['error'] is Map) {
      final message = data['error']['message']?.toString();
      if (message != null && message.isNotEmpty && status < 500) {
        return message;
      }
    }
    if (status >= 500) {
      return 'The server is temporarily unavailable. Please try again shortly.';
    }
  }

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'The connection timed out. Check your internet and try again.';
    case DioExceptionType.connectionError:
      return 'No internet connection. Check your network and try again.';
    case DioExceptionType.cancel:
      return 'The request was cancelled.';
    case DioExceptionType.badCertificate:
      return 'The secure connection could not be verified.';
    case DioExceptionType.badResponse:
    case DioExceptionType.transformTimeout:
    case DioExceptionType.unknown:
      return fallback;
  }
}
