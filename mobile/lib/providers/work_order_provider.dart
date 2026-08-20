import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/dio_client.dart';
import '../models/work_order.dart';

final myWorkOrdersProvider = FutureProvider.autoDispose<List<WorkOrder>>((ref) async {
  final res = await DioClient.instance.get('/work-orders', queryParameters: {'status': 'pending'});
  final data = res.data['data'] as List;
  return data.map((json) => WorkOrder.fromJson(json)).toList();
});
