import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/core/errors/error_messages.dart';

void main() {
  RequestOptions options() => RequestOptions(path: '/test');

  group('friendlyErrorMessage', () {
    test('maps connection timeouts', () {
      final error = DioException(
        requestOptions: options(),
        type: DioExceptionType.connectionTimeout,
      );
      expect(friendlyErrorMessage(error), contains('timed out'));
    });

    test('maps connection errors to a network message', () {
      final error = DioException(
        requestOptions: options(),
        type: DioExceptionType.connectionError,
      );
      expect(friendlyErrorMessage(error), contains('No internet connection'));
    });

    test('maps 401 to a session message', () {
      final error = DioException(
        requestOptions: options(),
        response: Response(requestOptions: options(), statusCode: 401),
      );
      expect(friendlyErrorMessage(error), contains('session has expired'));
    });

    test('maps 429 to a throttling message', () {
      final error = DioException(
        requestOptions: options(),
        response: Response(requestOptions: options(), statusCode: 429),
      );
      expect(friendlyErrorMessage(error), contains('Too many requests'));
    });

    test('maps 5xx to a server message', () {
      final error = DioException(
        requestOptions: options(),
        response: Response(requestOptions: options(), statusCode: 503),
      );
      expect(friendlyErrorMessage(error), contains('temporarily unavailable'));
    });

    test('uses the server validation message for 4xx responses', () {
      final error = DioException(
        requestOptions: options(),
        response: Response(
          requestOptions: options(),
          statusCode: 400,
          data: {
            'error': {'message': 'Amount must be greater than zero'},
          },
        ),
      );
      expect(
        friendlyErrorMessage(error),
        'Amount must be greater than zero',
      );
    });

    test('falls back for non-Dio errors', () {
      expect(
        friendlyErrorMessage(StateError('boom')),
        'Something went wrong. Please try again.',
      );
    });
  });
}
