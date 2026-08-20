import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/dio_client.dart';
import '../models/part.dart';

/// Parts listing for the "used parts" picker during an intervention.
/// Only manager/admin-scoped in the backend today for full CRUD, but the
/// index route is reachable by any authenticated role for read access.
final partsProvider = FutureProvider.autoDispose<List<Part>>((ref) async {
  try {
    final res = await DioClient.instance.get('/parts', queryParameters: {'per_page': 100});
    final data = res.data['data'] as List;
    return data.map((json) => Part.fromJson(json)).toList();
  } catch (_) {
    return [];
  }
});
