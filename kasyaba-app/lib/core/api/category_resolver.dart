import 'package:dio/dio.dart';

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);

bool isCategoryUuid(String value) => _uuidPattern.hasMatch(value);

/// A [StateError] that also records whether the failure can be retried once
/// the device is back online. Online callers still observe a [StateError].
class CategoryResolutionException extends StateError {
  CategoryResolutionException(super.message, {this.queueable = false});

  final bool queueable;
}

String _categoryKey(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

bool _categoryNamesMatch(String left, String right) {
  final a = _categoryKey(left);
  final b = _categoryKey(right);
  return a == b || a.startsWith(b) || b.startsWith(a);
}

/// Resolves a UI category value into a server UUID.
///
/// UUID values pass through untouched. Legacy/placeholder ids are matched by
/// [categoryName] against `/expense-categories`, and a missing category is
/// created on demand. The thrown messages are part of the public UX contract.
Future<String> resolveCategoryId({
  required Dio dio,
  required String categoryId,
  String? categoryName,
}) async {
  if (isCategoryUuid(categoryId)) return categoryId;

  try {
    final response = await dio.get('/expense-categories');
    final categories = (response.data['data'] as List<dynamic>?) ?? [];
    final desiredName = categoryName?.trim();

    for (final raw in categories) {
      final category = raw as Map<String, dynamic>;
      final id = category['id']?.toString();
      final name = category['name']?.toString();
      if (id != null &&
          isCategoryUuid(id) &&
          desiredName != null &&
          desiredName.isNotEmpty &&
          name != null &&
          _categoryNamesMatch(desiredName, name)) {
        return id;
      }
    }

    if (desiredName == null || desiredName.isEmpty) {
      throw StateError('Choose an expense category first.');
    }

    final createResponse = await dio.post(
      '/expense-categories',
      data: {'name': desiredName, 'iconKey': 'receipt'},
    );
    final createdId = createResponse.data['data']?['id']?.toString();
    if (createdId == null || !isCategoryUuid(createdId)) {
      throw StateError('The selected expense category is unavailable.');
    }
    return createdId;
  } on DioException catch (error) {
    throw CategoryResolutionException(
      'Expense categories are unavailable. Try again when online.',
      queueable:
          error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout,
    );
  }
}
