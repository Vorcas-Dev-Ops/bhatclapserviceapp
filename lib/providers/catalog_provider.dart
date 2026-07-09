import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_providers.dart';

final categoriesProvider = FutureProvider<List<dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.dio.get('/api/categories');
  if (response.statusCode == 200) {
    return response.data;
  }
  throw Exception('Failed to load categories');
});

final subservicesProvider = FutureProvider.family<List<dynamic>, String>((ref, categoryId) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.dio.get('/api/sub-services', queryParameters: {
    'category_id': categoryId,
  });
  if (response.statusCode == 200) {
    return response.data;
  }
  throw Exception('Failed to load sub-services');
});
